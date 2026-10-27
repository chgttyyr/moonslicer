///|
/// Unit & Integration tests for Offset Collision Detection, Clearance Clamping & Dual-Hole Overlap Prevention.

///|
test "collision/offset_clearance_clamping_between_holes" {
  // Island: 100x50 outer rectangle
  let outer = Polygon2::new([
    Vec2::new(0.0, 0.0),
    Vec2::new(100.0, 0.0),
    Vec2::new(100.0, 50.0),
    Vec2::new(0.0, 50.0),
  ])

  // Hole 1: [20, 15] to [40, 35]
  let hole1 = Polygon2::new([
    Vec2::new(20.0, 15.0),
    Vec2::new(40.0, 15.0),
    Vec2::new(40.0, 35.0),
    Vec2::new(20.0, 35.0),
  ])

  // Hole 2: [41.2, 15] to [61.2, 35]
  // The gap between Hole 1 and Hole 2 is strictly 1.2mm!
  let hole2 = Polygon2::new([
    Vec2::new(41.2, 15.0),
    Vec2::new(61.2, 15.0),
    Vec2::new(61.2, 35.0),
    Vec2::new(41.2, 35.0),
  ])

  let expoly = ExPolygon::new(outer, holes=[hole1, hole2])

  // Verify clearance between holes is 1.2mm
  let gap = hole1.distance_to_polygon(hole2)
  inspect(gap > 1.19 && gap < 1.21, content="true")

  // Generate 2 walls with line_width = 0.4mm.
  // Requested expansion per hole: Wall 0 (0.2mm) + Wall 1 (0.4mm) = 0.6mm each.
  // 0.6mm + 0.6mm = 1.2mm! At 1.2mm, two 0.4mm extrusion beads would overlap and collide!
  let perims = generate_expolygon_perimeters(expoly, 2, 0.4)

  // 1. Collision detection must trigger!
  inspect(perims.collisions.length() > 0, content="true")

  // 2. The resolution action should clamp or suppress overlapping walls
  let has_suppressed = perims.collisions
    .iter()
    .any(fn(c) { c.action == "WallSuppressed" || c.action == "Clamped" })
  inspect(has_suppressed, content="true")

  // 3. CRITICAL: Test that the resulting hole walls DO NOT collide or intersect each other!
  let hw1 = perims.hole_walls[0]
  let hw2 = perims.hole_walls[1]

  for w1 in hw1 {
    for w2 in hw2 {
      // Must not intersect!
      inspect(w1.intersects_polygon(w2), content="false")
      // Clearance must remain non-negative
      inspect(w1.distance_to_polygon(w2) >= 0.0, content="true")
    }
  }
}

///|
test "collision/hole_outer_wall_collision_prevention" {
  // Thin-walled boss: outer 30x30, hole 2x2 to 28x28 (web thickness only 2.0mm around)
  // With 3 walls of 0.4mm (outer = 1.2mm, inner = 1.2mm, total 2.4mm > 2.0mm!),
  // collision must be detected and walls clamped.
  let outer = Polygon2::new([
    Vec2::new(0.0, 0.0),
    Vec2::new(30.0, 0.0),
    Vec2::new(30.0, 30.0),
    Vec2::new(0.0, 30.0),
  ])
  let hole = Polygon2::new([
    Vec2::new(2.0, 2.0),
    Vec2::new(28.0, 2.0),
    Vec2::new(28.0, 28.0),
    Vec2::new(2.0, 28.0),
  ])
  let expoly = ExPolygon::new(outer, holes=[hole])

  let perims = generate_expolygon_perimeters(expoly, 3, 0.4)
  inspect(perims.collisions.length() > 0, content="true")

  // Ensure no hole wall crosses any outer wall
  for hw in perims.hole_walls[0] {
    for ow in perims.outer_walls {
      inspect(hw.edges_intersect(ow), content="false")
    }
  }
}

///|
test "collision/end_to_end_dual_holes_collision_fixture" {
  let fixture_path = "fixtures/dual_holes_collision.stl"
  try {
    let bytes = @fs.read_file_to_bytes(fixture_path)
    let mesh = parse_stl(bytes).unwrap()
    let stats = get_mesh_slice_stats(mesh)
    inspect(stats.triangle_count, content="44")
    inspect(stats.width, content="30")
    inspect(stats.depth, content="15")
    inspect(stats.height, content="4")

    let mut config = SlicerConfig::default()
    config = {
      ..config,
      layer_height: 1.0,
      initial_layer_height: 1.0,
      wall_count: 2,
    }
    let centered = mesh.center_to_bed()
    let layers = slice_mesh(centered, config)

    // Slice layers should have 1 ExPolygon with 2 holes
    let mid_l = layers[layers.length() / 2]
    inspect(mid_l.expolygons.length(), content="1")
    inspect(mid_l.expolygons[0].holes.length(), content="2")

    // End-to-end G-code synthesis
    let gcode_res = generate_gcode(layers, config)

    // Verify collision resolution was activated and logged in G-code!
    inspect(gcode_res.total_collisions_resolved > 0, content="true")
    inspect(gcode_res.gcode.contains("[COLLISION RESOLVED]"), content="true")
  } catch {
    _ => inspect(false, content="true")
  }
}

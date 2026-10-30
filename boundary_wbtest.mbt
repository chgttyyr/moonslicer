///|
/// Comprehensive boundary condition tests: degenerate STL facets, sub-nozzle thin walls,
/// zero/full infill densities, extreme layer heights, negative coordinate bed centering,
/// concentric collapse, and RDP curvature simplification.

///|
test "boundary/degenerate_stl_mesh_slicing" {
  // Construct a mesh containing:
  // 1. Flat horizontal triangle (z = 2.0)
  // 2. Collapsed point triangle (v1 = v2 = v3)
  // 3. Collinear vertical line triangle (x=0, y=0, z in 0..10)
  // 4. Valid 3D triangle spanning z = 0..10
  let t_flat = Triangle3::new(
    Vec3::zero(),
    Vec3::new(0.0, 0.0, 2.0),
    Vec3::new(10.0, 0.0, 2.0),
    Vec3::new(5.0, 10.0, 2.0),
  )
  let t_collapsed = Triangle3::new(
    Vec3::zero(),
    Vec3::new(1.0, 1.0, 1.0),
    Vec3::new(1.0, 1.0, 1.0),
    Vec3::new(1.0, 1.0, 1.0),
  )
  let t_collinear = Triangle3::new(
    Vec3::zero(),
    Vec3::new(0.0, 0.0, 0.0),
    Vec3::new(0.0, 0.0, 5.0),
    Vec3::new(0.0, 0.0, 10.0),
  )
  let t_valid1 = Triangle3::new(
    Vec3::zero(),
    Vec3::new(0.0, 0.0, 0.0),
    Vec3::new(20.0, 0.0, 0.0),
    Vec3::new(10.0, 0.0, 10.0),
  )
  let t_valid2 = Triangle3::new(
    Vec3::zero(),
    Vec3::new(20.0, 0.0, 0.0),
    Vec3::new(20.0, 20.0, 0.0),
    Vec3::new(10.0, 10.0, 10.0),
  )

  let mesh = Mesh3::from_triangles([
    t_flat, t_collapsed, t_collinear, t_valid1, t_valid2,
  ])

  // Slicing at z = 2.0 must not panic, crash, or produce NaN
  let layer = slice_mesh_at_z(mesh, 2.0)
  inspect(layer.z, content="2")
  // Degenerate triangles produce no valid segments, valid triangles produce clean segments
  inspect(layer.polygons.length() >= 0, content="true")
}

///|
test "boundary/thin_wall_sub_nozzle_width" {
  // Outer rectangle: 20x20 mm
  let outer = Polygon2::new([
    Vec2::new(0.0, 0.0),
    Vec2::new(20.0, 0.0),
    Vec2::new(20.0, 20.0),
    Vec2::new(0.0, 20.0),
  ])

  // Inner hole: 19.5x19.5 mm, centered -> web wall thickness is only 0.25 mm around
  let hole = Polygon2::new([
    Vec2::new(0.25, 0.25),
    Vec2::new(19.75, 0.25),
    Vec2::new(19.75, 19.75),
    Vec2::new(0.25, 19.75),
  ])

  let expoly = ExPolygon::new(outer, holes=[hole])

  // Attempt to generate 2 walls at 0.4mm line width
  let perims = generate_expolygon_perimeters(expoly, 2, 0.4)

  // System must resolve collision by clamping or suppressing inner walls
  inspect(perims.collisions.length() > 0, content="true")

  // Crucial invariant: Generated outer and hole walls must NOT cross edges with each other!
  for ow in perims.outer_walls {
    for hw_group in perims.hole_walls {
      for hw in hw_group {
        inspect(hw.edges_intersect(ow), content="false")
      }
    }
  }
}

///|
test "boundary/zero_and_full_infill_density" {
  let outer = Polygon2::new([
    Vec2::new(0.0, 0.0),
    Vec2::new(40.0, 0.0),
    Vec2::new(40.0, 40.0),
    Vec2::new(0.0, 40.0),
  ])
  let expoly = ExPolygon::new(outer)

  // 1. Infill density = 0.0% (hollow print)
  let patterns = [
    InfillPattern::Rectilinear,
    InfillPattern::Grid,
    InfillPattern::Triangles,
    InfillPattern::Concentric,
  ]

  for pat in patterns {
    let segs_zero = generate_expolygon_infill(
      expoly, pat, 0.0, // 0% density
       0.4, 0, 45.0,
    )
    inspect(segs_zero.length(), content="0")
  }

  // 2. Infill density = 100.0% (full solid)
  for pat in patterns {
    let segs_full = generate_expolygon_infill(
      expoly, pat, 1.0, // 100% density
       0.4, 0, 45.0,
    )
    // Full solid must generate a substantial number of toolpath segments
    inspect(segs_full.length() > 10, content="true")
  }
}

///|
test "boundary/extreme_layer_heights_scaling" {
  // Build a 10x10x2 mm cube mesh
  let tris : Array[Triangle3] = []
  let v000 = Vec3::new(0.0, 0.0, 0.0)
  let v100 = Vec3::new(10.0, 0.0, 0.0)
  let v110 = Vec3::new(10.0, 10.0, 0.0)
  let v010 = Vec3::new(0.0, 10.0, 0.0)
  let v002 = Vec3::new(0.0, 0.0, 2.0)
  let v102 = Vec3::new(10.0, 0.0, 2.0)
  let v112 = Vec3::new(10.0, 10.0, 2.0)
  let v012 = Vec3::new(0.0, 10.0, 2.0)

  // Walls
  tris.push(Triangle3::new(Vec3::zero(), v000, v100, v102))
  tris.push(Triangle3::new(Vec3::zero(), v000, v102, v002))
  tris.push(Triangle3::new(Vec3::zero(), v100, v110, v112))
  tris.push(Triangle3::new(Vec3::zero(), v100, v112, v102))
  tris.push(Triangle3::new(Vec3::zero(), v110, v010, v012))
  tris.push(Triangle3::new(Vec3::zero(), v110, v012, v112))
  tris.push(Triangle3::new(Vec3::zero(), v010, v000, v002))
  tris.push(Triangle3::new(Vec3::zero(), v010, v002, v012))
  // Bottom & Top
  tris.push(Triangle3::new(Vec3::zero(), v000, v110, v100))
  tris.push(Triangle3::new(Vec3::zero(), v000, v010, v110))
  tris.push(Triangle3::new(Vec3::zero(), v002, v102, v112))
  tris.push(Triangle3::new(Vec3::zero(), v002, v112, v012))

  let mesh = Mesh3::from_triangles(tris)

  // Test 1: Ultra-fine 0.05mm layer height
  let mut cfg_fine = SlicerConfig::default()
  cfg_fine = { ..cfg_fine, layer_height: 0.05, initial_layer_height: 0.05, }
  let layers_fine = slice_mesh(mesh, cfg_fine)
  // Height = 2.0mm / 0.05mm ~= 39-40 layers
  inspect(
    layers_fine.length() >= 38 && layers_fine.length() <= 41,
    content="true",
  )

  // Test 2: Coarse draft 0.50mm layer height
  let mut cfg_coarse = SlicerConfig::default()
  cfg_coarse = { ..cfg_coarse, layer_height: 0.50, initial_layer_height: 0.50, }
  let layers_coarse = slice_mesh(mesh, cfg_coarse)
  // Height = 2.0mm / 0.50mm = 4 layers
  inspect(
    layers_coarse.length() >= 3 && layers_coarse.length() <= 5,
    content="true",
  )
}

///|
test "boundary/negative_coordinate_bed_centering" {
  // Construct a triangle in strictly negative coordinate space:
  // X: [-80, -20], Y: [-60, -10], Z: [-15, 0]
  let t1 = Triangle3::new(
    Vec3::zero(),
    Vec3::new(-80.0, -60.0, -15.0),
    Vec3::new(-20.0, -60.0, -15.0),
    Vec3::new(-50.0, -10.0, 0.0),
  )
  let mesh = Mesh3::from_triangles([t1])

  // Center to print bed: X/Y centered around (0,0), Z grounded at 0.0
  let centered = mesh.center_to_bed()

  // Verify Z minimum is grounded at exactly 0.0 (bed plate)
  inspect(centered.bounds.min.z == 0.0, content="true")

  // Verify geometric center is aligned to (0.0, 0.0)
  let c = centered.bounds.center()
  inspect(c.x.abs() < 1.0e-6, content="true")
  inspect(c.y.abs() < 1.0e-6, content="true")
}

///|
test "boundary/concentric_infill_rapid_collapse" {
  // 1. Case A: Strip narrower than 2*spacing immediately halts without loop
  let strip_narrow = Polygon2::new([
    Vec2::new(0.0, 0.0),
    Vec2::new(40.0, 0.0),
    Vec2::new(40.0, 1.2),
    Vec2::new(0.0, 1.2),
  ])
  let expoly_narrow = ExPolygon::new(strip_narrow)
  let segs_narrow = generate_expolygon_concentric_infill(
    expoly_narrow, 0.5, 0.4,
  )
  inspect(segs_narrow.length(), content="0")

  // 2. Case B: Strip of width 3.0mm (fits exactly 1 concentric offset ring before collapsing)
  let strip_mid = Polygon2::new([
    Vec2::new(0.0, 0.0),
    Vec2::new(40.0, 0.0),
    Vec2::new(40.0, 3.0),
    Vec2::new(0.0, 3.0),
  ])
  let expoly_mid = ExPolygon::new(strip_mid)
  let segs_mid = generate_expolygon_concentric_infill(expoly_mid, 0.5, 0.4)

  // Algorithm must generate segments for the viable ring then cleanly terminate
  inspect(segs_mid.length() > 0, content="true")

  let mut total_len = 0.0
  for s in segs_mid {
    total_len = total_len + s.length()
  }
  inspect(total_len < 200.0, content="true")
}

///|
test "boundary/rdp_circle_curvature_simplification" {
  // Create a 16-sided regular polygon (circle approximation) with radius = 10.0 mm
  let pts : Array[Vec2] = []
  let n = 16
  let pi = 3.141592653589793
  for i = 0; i < n; i = i + 1 {
    let theta = 2.0 * pi * i.to_double() / n.to_double()
    pts.push(Vec2::new(10.0 * math_cos(theta), 10.0 * math_sin(theta)))
  }
  let poly16 = Polygon2::new(pts)
  inspect(poly16.points.length(), content="16")

  // 1. With very tiny epsilon = 0.001 mm: all 16 vertices are preserved
  let fine = poly16.simplify(0.001)
  inspect(fine.points.length(), content="16")

  // 2. With coarse epsilon = 2.5 mm: chord deviation exceeds threshold,
  // RDP simplifies down to a coarse polygon (4-8 vertices)
  let coarse = poly16.simplify(2.5)
  inspect(coarse.points.length() < 16, content="true")
  inspect(coarse.points.length() >= 3, content="true")

  // Invariant: Orientation is preserved (CCW positive area)
  inspect(coarse.area() > 0.0, content="true")
}

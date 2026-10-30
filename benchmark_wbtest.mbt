///|
/// Performance benchmarks, multi-hole stress tests, physical mass & cost metrics, and non-convex boundary tests.

///|
test "benchmark/multi_hole_dense_collision_stress" {
  // Outer contour: 150x100 mm plate
  let outer = Polygon2::new([
    Vec2::new(0.0, 0.0),
    Vec2::new(150.0, 0.0),
    Vec2::new(150.0, 100.0),
    Vec2::new(0.0, 100.0),
  ])

  // Create a dense 2x3 grid of 6 square holes (20x20mm each)
  // Each pair is separated by exactly 1.2mm in X and 1.5mm in Y!
  let holes : Array[Polygon2] = []
  let hole_size = 20.0
  let gap_x = 1.2
  let gap_y = 1.5

  for row = 0; row < 2; row = row + 1 {
    for col = 0; col < 3; col = col + 1 {
      let x0 = 20.0 + col.to_double() * (hole_size + gap_x)
      let y0 = 20.0 + row.to_double() * (hole_size + gap_y)
      let h = Polygon2::new([
        Vec2::new(x0, y0),
        Vec2::new(x0 + hole_size, y0),
        Vec2::new(x0 + hole_size, y0 + hole_size),
        Vec2::new(x0, y0 + hole_size),
      ])
      holes.push(h)
    }
  }

  let expoly = ExPolygon::new(outer, holes~)
  inspect(expoly.holes.length(), content="6")

  // Generate 2 perimeter walls with line_width = 0.4mm
  // In dense multi-hole packing, each hole must detect clearance to adjacent neighbors
  let perims = generate_expolygon_perimeters(expoly, 2, 0.4)

  // Verify multiple collisions are detected and safely resolved
  inspect(perims.collisions.length() >= 6, content="true")

  // Crucial invariant: Across all 6 holes, NO hole wall may intersect another hole wall!
  let n_holes = perims.hole_walls.length()
  for i = 0; i < n_holes; i = i + 1 {
    for j = i + 1; j < n_holes; j = j + 1 {
      for w1 in perims.hole_walls[i] {
        for w2 in perims.hole_walls[j] {
          inspect(w1.intersects_polygon(w2), content="false")
        }
      }
    }
  }
}

///|
test "benchmark/physical_material_mass_and_cost" {
  let poly = Polygon2::new([
    Vec2::new(-10.0, -10.0),
    Vec2::new(10.0, -10.0),
    Vec2::new(10.0, 10.0),
    Vec2::new(-10.0, 10.0),
  ])
  let layer = SliceLayer::new(0.2, [poly])

  // 1. PLA test (density 1.24 g/cm3)
  let mut cfg_pla = SlicerConfig::default()
  cfg_pla = {
    ..cfg_pla,
    material: FilamentMaterial::PLA,
    filament_cost_per_kg: 120.0,
  }
  let res_pla = generate_gcode([layer], cfg_pla)
  inspect(res_pla.total_filament_grams > 0.0, content="true")
  inspect(res_pla.estimated_cost > 0.0, content="true")

  // 2. ABS test (density 1.04 g/cm3, lighter than PLA)
  let mut cfg_abs = SlicerConfig::default()
  cfg_abs = {
    ..cfg_abs,
    material: FilamentMaterial::ABS,
    filament_cost_per_kg: 120.0,
  }
  let res_abs = generate_gcode([layer], cfg_abs)

  // Same geometry extruded with ABS must weigh strictly less than PLA!
  inspect(
    res_abs.total_filament_grams < res_pla.total_filament_grams,
    content="true",
  )

  // 3. Cost ratio matches density ratio: 1.04 / 1.24 ~= 0.8387
  let ratio = res_abs.total_filament_grams / res_pla.total_filament_grams
  inspect(ratio > 0.83 && ratio < 0.85, content="true")
}

///|
test "boundary/concave_c_shaped_polygon_interior_point" {
  // C-shaped polygon where the bounding box center / centroid falls in the empty hollow cutout!
  let c_shape = Polygon2::new([
    Vec2::new(0.0, 0.0),
    Vec2::new(30.0, 0.0),
    Vec2::new(30.0, 10.0),
    Vec2::new(10.0, 10.0), // inward notch
    Vec2::new(10.0, 20.0),
    Vec2::new(30.0, 20.0),
    Vec2::new(30.0, 30.0),
    Vec2::new(0.0, 30.0),
  ])
  let expoly = ExPolygon::new(c_shape)

  // Centroid of C-shape: cx = 13.75, cy = 15.0
  // Note that (20, 15) is outside the C-shape!
  inspect(expoly.contains_point(Vec2::new(20.0, 15.0)), content="false")

  // ExPolygon::interior_point() must return a point that is GUARANTEED inside the solid material!
  let pt = expoly.interior_point()
  inspect(expoly.contains_point(pt), content="true")
}

///|
test "boundary/bridge_fan_boost_and_flow_rate" {
  let p_small = Polygon2::new([
    Vec2::new(-5.0, -5.0),
    Vec2::new(5.0, -5.0),
    Vec2::new(5.0, 5.0),
    Vec2::new(-5.0, 5.0),
  ])
  let p_large = Polygon2::new([
    Vec2::new(-50.0, -50.0),
    Vec2::new(50.0, -50.0),
    Vec2::new(50.0, 50.0),
    Vec2::new(-50.0, 50.0),
  ])

  // Layer 0: small pillar 10x10
  let layer0 = SliceLayer::new(0.2, [p_small])
  // Layer 1: large platform 100x100 (creates bridging overhang)
  let layer1 = SliceLayer::new(0.4, [p_large])
  // Layer 2: top roof layer
  let layer2 = SliceLayer::new(0.6, [p_large])

  let mut cfg = SlicerConfig::default()
  cfg = {
    ..cfg,
    bottom_solid_layers: 1,
    top_solid_layers: 1,
    bridge_fan_speed: 255,
    bridge_speed: 20.0,
    bridge_flow_ratio: 0.90,
  }

  let res = generate_gcode([layer0, layer1, layer2], cfg)

  // Verify G-code triggers bridge fan boost and restores fan
  inspect(res.gcode.contains("; bridge fan boost"), content="true")
  inspect(res.gcode.contains("; restore standard fan"), content="true")
  inspect(res.gcode.contains("; TYPE: Bridge infill"), content="true")
}

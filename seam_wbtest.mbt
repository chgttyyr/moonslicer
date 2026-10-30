///|
/// Unit tests for Seam Placement Strategies (Sharpest Corner, Nearest, Aligned, Random).

///|
test "seam/rotate_start_invariance" {
  let poly = Polygon2::new([
    Vec2::new(0.0, 0.0),
    Vec2::new(10.0, 0.0),
    Vec2::new(10.0, 10.0),
    Vec2::new(0.0, 10.0),
  ])

  let rot1 = poly.rotate_start(1)
  inspect(rot1.points[0].x, content="10")
  inspect(rot1.points[0].y, content="0")

  // Geometric area and shape must remain identical after start rotation
  inspect(rot1.area(), content="100")
  inspect(rot1.is_ccw(), content="true")

  let rot2 = poly.rotate_start(2)
  inspect(rot2.points[0].x, content="10")
  inspect(rot2.points[0].y, content="10")

  let rot_full = poly.rotate_start(4)
  inspect(rot_full.points[0].x, content="0")
  inspect(rot_full.points[0].y, content="0")
}

///|
test "seam/sharpest_corner_detection" {
  // Arrowhead polygon with an acute sharp tip at (50, 0)
  let arrow = Polygon2::new([
    Vec2::new(0.0, -10.0),
    Vec2::new(50.0, 0.0), // sharp tip (acute angle)
    Vec2::new(0.0, 10.0),
    Vec2::new(10.0, 0.0), // reflex interior angle
  ])

  let sharpest = arrow.sharpest_corner_idx()
  // Index 1 (50, 0) is the sharpest convex corner
  inspect(sharpest, content="1")
}

///|
test "seam/nearest_vertex_detection" {
  let poly = Polygon2::new([
    Vec2::new(0.0, 0.0),
    Vec2::new(100.0, 0.0),
    Vec2::new(100.0, 100.0),
    Vec2::new(0.0, 100.0),
  ])

  // Target close to (100, 100)
  let target = Vec2::new(95.0, 98.0)
  let nearest = poly.nearest_vertex_idx(target)
  inspect(nearest, content="2") // vertex 2 is (100, 100)
}

///|
test "seam/gcode_generation_with_seam_modes" {
  let poly = Polygon2::new([
    Vec2::new(-20.0, -20.0),
    Vec2::new(20.0, -20.0),
    Vec2::new(20.0, 20.0),
    Vec2::new(-20.0, 20.0),
  ])
  let layer = SliceLayer::new(0.2, [poly])

  // 1. SharpestCorner seam
  let mut cfg_sharp = SlicerConfig::default()
  cfg_sharp = { ..cfg_sharp, seam_mode: SeamMode::SharpestCorner, }
  let res_sharp = generate_gcode([layer], cfg_sharp)
  inspect(
    res_sharp.gcode.contains("; Seam Mode: SharpestCorner"),
    content="true",
  )

  // 2. Aligned seam
  let mut cfg_aligned = SlicerConfig::default()
  cfg_aligned = { ..cfg_aligned, seam_mode: SeamMode::Aligned, }
  let res_aligned = generate_gcode([layer], cfg_aligned)
  inspect(res_aligned.gcode.contains("; Seam Mode: Aligned"), content="true")

  // 3. Nearest seam
  let mut cfg_nearest = SlicerConfig::default()
  cfg_nearest = { ..cfg_nearest, seam_mode: SeamMode::Nearest, }
  let res_nearest = generate_gcode([layer], cfg_nearest)
  inspect(res_nearest.gcode.contains("; Seam Mode: Nearest"), content="true")
}

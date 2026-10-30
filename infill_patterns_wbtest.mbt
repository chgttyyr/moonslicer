///|
/// Comprehensive tests for Advanced Infill Patterns: Grid, Triangles, and Concentric.

///|
test "infill/grid_pattern_generation" {
  let poly = Polygon2::new([
    Vec2::new(-20.0, -20.0),
    Vec2::new(20.0, -20.0),
    Vec2::new(20.0, 20.0),
    Vec2::new(-20.0, 20.0),
  ])
  let expoly = ExPolygon::new(poly)

  // 20% grid infill on a 40x40mm square
  let segs = generate_expolygon_grid_infill(expoly, 0.2, 0.4, 45.0)

  // Grid prints orthogonal scanlines in two directions (45 deg and 135 deg)
  inspect(segs.length() > 0, content="true")

  // Verify segments exist with both positive and negative slopes (45° and 135°)
  let mut has_pos_slope = false
  let mut has_neg_slope = false
  for s in segs {
    let dx = s.p2.x - s.p1.x
    let dy = s.p2.y - s.p1.y
    if dx.abs() > 1.0e-3 {
      let slope = dy / dx
      if slope > 0.0 {
        has_pos_slope = true
      }
      if slope < 0.0 {
        has_neg_slope = true
      }
    }
  }
  inspect(has_pos_slope, content="true")
  inspect(has_neg_slope, content="true")
}

///|
test "infill/triangles_pattern_generation" {
  let poly = Polygon2::new([
    Vec2::new(-30.0, -30.0),
    Vec2::new(30.0, -30.0),
    Vec2::new(30.0, 30.0),
    Vec2::new(-30.0, 30.0),
  ])
  let expoly = ExPolygon::new(poly)

  let segs = generate_expolygon_triangles_infill(expoly, 0.15, 0.4, 0.0)
  inspect(segs.length() >= 6, content="true")

  // All midpoints must reside strictly inside the square
  for s in segs {
    let mid = s.p1.add(s.p2).scale(0.5)
    inspect(expoly.contains_point(mid), content="true")
  }
}

///|
test "infill/concentric_pattern_generation" {
  let poly = Polygon2::new([
    Vec2::new(-25.0, -25.0),
    Vec2::new(25.0, -25.0),
    Vec2::new(25.0, 25.0),
    Vec2::new(-25.0, 25.0),
  ])
  let expoly = ExPolygon::new(poly)

  // Concentric with spacing = 0.4 / 0.2 = 2.0mm
  let segs = generate_expolygon_concentric_infill(expoly, 0.2, 0.4)
  inspect(segs.length() > 0, content="true")

  // For a square, concentric infill generates 4 segments per concentric ring
  inspect(segs.length() % 4, content="0")
}

///|
test "infill/universal_dispatcher" {
  let poly = Polygon2::new([
    Vec2::new(0.0, 0.0),
    Vec2::new(50.0, 0.0),
    Vec2::new(50.0, 50.0),
    Vec2::new(0.0, 50.0),
  ])
  let expoly = ExPolygon::new(poly)

  let r_segs = generate_expolygon_infill(
    expoly,
    InfillPattern::Rectilinear,
    0.2,
    0.4,
    0,
    45.0,
  )
  let g_segs = generate_expolygon_infill(
    expoly,
    InfillPattern::Grid,
    0.2,
    0.4,
    0,
    45.0,
  )
  let t_segs = generate_expolygon_infill(
    expoly,
    InfillPattern::Triangles,
    0.2,
    0.4,
    0,
    0.0,
  )
  let c_segs = generate_expolygon_infill(
    expoly,
    InfillPattern::Concentric,
    0.2,
    0.4,
    0,
    0.0,
  )

  inspect(r_segs.length() > 0, content="true")
  inspect(g_segs.length() > 0, content="true")
  inspect(t_segs.length() > 0, content="true")
  inspect(c_segs.length() > 0, content="true")

  // Zero density should generate zero segments
  let zero_segs = generate_expolygon_infill(
    expoly,
    InfillPattern::Grid,
    0.0,
    0.4,
    0,
    45.0,
  )
  inspect(zero_segs.is_empty(), content="true")
}

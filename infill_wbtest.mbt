///|
test "infill/axis_aligned_and_diagonal_scanline" {
  let square = Polygon2::new([
    Vec2::new(0.0, 0.0),
    Vec2::new(10.0, 0.0),
    Vec2::new(10.0, 10.0),
    Vec2::new(0.0, 10.0),
  ])

  // Horizontal scanlines at 0 degrees, spacing 2.0mm (density 0.2, line_width 0.4)
  let horiz = generate_rectilinear_infill(square, 0.2, 0.4, 0.0)
  inspect(horiz.length(), content="5")

  // Check each horizontal line length is 10.0mm
  for seg in horiz {
    let len = seg.length()
    inspect(len > 9.99 && len < 10.01, content="true")
  }

  // Diagonal 45 degrees
  let diag45 = generate_rectilinear_infill(square, 0.2, 0.4, 45.0)
  inspect(diag45.length() > 0, content="true")

  // Diagonal 135 degrees
  let diag135 = generate_rectilinear_infill(square, 0.2, 0.4, 135.0)
  inspect(diag135.length() > 0, content="true")

  // Zero density produces zero lines
  let zero = generate_rectilinear_infill(square, 0.0, 0.4, 45.0)
  inspect(zero.length(), content="0")
}

///|
test "infill/expolygon_hole_clipping" {
  // Outer square 100x100
  let outer = Polygon2::new([
    Vec2::new(0.0, 0.0),
    Vec2::new(100.0, 0.0),
    Vec2::new(100.0, 100.0),
    Vec2::new(0.0, 100.0),
  ])
  // Hole in middle: 30x30 to 70x70
  let hole = Polygon2::new([
    Vec2::new(30.0, 30.0),
    Vec2::new(70.0, 30.0),
    Vec2::new(70.0, 70.0),
    Vec2::new(30.0, 70.0),
  ])
  let expoly = ExPolygon::new(outer, holes=[hole])

  // Horizontal infill at 0 deg, spacing = 10mm (density = 0.04, line_width = 0.4)
  let lines = generate_expolygon_rectilinear_infill(expoly, 0.04, 0.4, 0.0)
  inspect(lines.length() > 0, content="true")

  // For any generated segment, its midpoint must NOT be inside the hole
  for seg in lines {
    let mid = seg.p1.add(seg.p2).scale(0.5)
    inspect(hole.contains_point(mid), content="false")
    inspect(expoly.contains_point(mid), content="true")
  }
}

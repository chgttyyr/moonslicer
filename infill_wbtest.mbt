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

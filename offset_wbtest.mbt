///|
test "offset/square_inward_offset" {
  // 10x10 square: (0,0) -> (10,0) -> (10,10) -> (0,10)
  let square = Polygon2::new([
    Vec2::new(0.0, 0.0),
    Vec2::new(10.0, 0.0),
    Vec2::new(10.0, 10.0),
    Vec2::new(0.0, 10.0),
  ])

  // Inward offset by 1.0mm
  let offset_opt = offset_polygon_inward(square, 1.0)
  inspect(offset_opt is Some(_), content="true")

  let offset_poly = offset_opt.unwrap()
  // 8x8 square has area 64.0
  let area = offset_poly.area()
  inspect(area > 63.9 && area < 64.1, content="true")

  // Check corner positions
  inspect(
    offset_poly.points[0].x > 0.99 && offset_poly.points[0].x < 1.01,
    content="true",
  )
  inspect(
    offset_poly.points[0].y > 0.99 && offset_poly.points[0].y < 1.01,
    content="true",
  )

  // Oversized offset (collapsing)
  let collapsed = offset_polygon_inward(square, 6.0)
  inspect(collapsed is None, content="true")
}

///|
test "offset/multi_wall_perimeter_generation" {
  let square = Polygon2::new([
    Vec2::new(0.0, 0.0),
    Vec2::new(10.0, 0.0),
    Vec2::new(10.0, 10.0),
    Vec2::new(0.0, 10.0),
  ])

  // 2 walls with line_width 0.4mm
  let (walls, infill_bound) = generate_perimeters(square, 2, 0.4)
  inspect(walls.length(), content="2")
  inspect(infill_bound is Some(_), content="true")

  let w0_area = walls[0].area()
  let w1_area = walls[1].area()
  let infill_area = infill_bound.unwrap().area()

  // Wall 0 area > Wall 1 area > Infill boundary area
  inspect(w0_area > w1_area, content="true")
  inspect(w1_area > infill_area, content="true")
}

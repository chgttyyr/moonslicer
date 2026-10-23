///|
test "geom/vec3_operations" {
  let v1 = Vec3::new(1.0, 2.0, 3.0)
  let v2 = Vec3::new(4.0, 5.0, 6.0)

  let sum = v1.add(v2)
  inspect(sum.x, content="5")
  inspect(sum.y, content="7")
  inspect(sum.z, content="9")

  let cross = Vec3::new(1.0, 0.0, 0.0).cross(Vec3::new(0.0, 1.0, 0.0))
  inspect(cross.z, content="1")
  inspect(cross.x, content="0")
}

///|
test "geom/polygon_area_and_point_in_poly" {
  // 10x10 square in CCW order: (0,0) -> (10,0) -> (10,10) -> (0,10)
  let poly = Polygon2::new([
    Vec2::new(0.0, 0.0),
    Vec2::new(10.0, 0.0),
    Vec2::new(10.0, 10.0),
    Vec2::new(0.0, 10.0),
  ])

  inspect(poly.area(), content="100")
  inspect(poly.is_ccw(), content="true")

  // Point containment
  inspect(poly.contains_point(Vec2::new(5.0, 5.0)), content="true")
  inspect(poly.contains_point(Vec2::new(15.0, 5.0)), content="false")
  inspect(poly.contains_point(Vec2::new(-1.0, 5.0)), content="false")

  // CW reversal
  let cw = poly.ensure_cw()
  inspect(cw.area(), content="-100")
  inspect(cw.is_ccw(), content="false")
}

///|
test "geom/expolygon_and_multi_island_holes" {
  // Island 1: 100x100 square with 40x40 hole
  let outer1 = Polygon2::new([
    Vec2::new(0.0, 0.0),
    Vec2::new(100.0, 0.0),
    Vec2::new(100.0, 100.0),
    Vec2::new(0.0, 100.0),
  ])
  let hole1 = Polygon2::new([
    Vec2::new(30.0, 30.0),
    Vec2::new(70.0, 30.0),
    Vec2::new(70.0, 70.0),
    Vec2::new(30.0, 70.0),
  ])

  // Island 2: separate 20x20 square at (200, 200)
  let outer2 = Polygon2::new([
    Vec2::new(200.0, 200.0),
    Vec2::new(220.0, 200.0),
    Vec2::new(220.0, 220.0),
    Vec2::new(200.0, 220.0),
  ])

  let expolys = build_expolygons([outer1, hole1, outer2])
  inspect(expolys.length(), content="2")

  // The first expolygon should have 1 hole
  let ep1 = expolys[0]
  inspect(ep1.holes.length(), content="1")
  inspect(ep1.area(), content="8400") // 10000 - 1600 = 8400

  // Point in solid material vs in hole
  inspect(ep1.contains_point(Vec2::new(10.0, 10.0)), content="true")
  inspect(ep1.contains_point(Vec2::new(50.0, 50.0)), content="false") // Inside the hole!
  inspect(ep1.contains_point(Vec2::new(150.0, 50.0)), content="false") // Outside

  // The second expolygon has 0 holes
  let ep2 = expolys[1]
  inspect(ep2.holes.length(), content="0")
  inspect(ep2.area(), content="400")
  inspect(ep2.contains_point(Vec2::new(210.0, 210.0)), content="true")
}

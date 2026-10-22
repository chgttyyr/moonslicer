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

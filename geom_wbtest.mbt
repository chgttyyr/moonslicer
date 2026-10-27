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

///|
test "geom/segment_intersection_and_clearance" {
  let s1 = Segment2::new(Vec2::new(0.0, 0.0), Vec2::new(10.0, 10.0))
  let s2 = Segment2::new(Vec2::new(0.0, 10.0), Vec2::new(10.0, 0.0))

  // Crossing segments
  match s1.intersect(s2) {
    Some(pt) => {
      inspect(pt.x, content="5")
      inspect(pt.y, content="5")
    }
    None => inspect(false, content="true")
  }

  // Parallel disjoint segments
  let s3 = Segment2::new(Vec2::new(0.0, 2.0), Vec2::new(10.0, 12.0))
  inspect(s1.intersect(s3) is None, content="true")

  // Distance from point to segment
  let p = Vec2::new(5.0, 0.0)
  let horiz = Segment2::new(Vec2::new(0.0, 5.0), Vec2::new(10.0, 5.0))
  inspect(horiz.distance_to_point(p), content="5")
}

///|
test "geom/polygon_clearance_and_collision" {
  // Box 1: [0, 0] to [10, 10]
  let b1 = Polygon2::new([
    Vec2::new(0.0, 0.0),
    Vec2::new(10.0, 0.0),
    Vec2::new(10.0, 10.0),
    Vec2::new(0.0, 10.0),
  ])

  // Box 2: [12, 0] to [22, 10] (gap of 2.0mm)
  let b2 = Polygon2::new([
    Vec2::new(12.0, 0.0),
    Vec2::new(22.0, 0.0),
    Vec2::new(22.0, 10.0),
    Vec2::new(12.0, 10.0),
  ])

  // Clearance between b1 and b2 should be exactly 2.0mm
  let dist = b1.distance_to_polygon(b2)
  inspect(dist > 1.99 && dist < 2.01, content="true")
  inspect(b1.intersects_polygon(b2), content="false")

  // Box 3: [8, 0] to [18, 10] (overlapping with b1 from X=8 to 10!)
  let b3 = Polygon2::new([
    Vec2::new(8.0, 0.0),
    Vec2::new(18.0, 0.0),
    Vec2::new(18.0, 10.0),
    Vec2::new(8.0, 10.0),
  ])

  // Should detect collision!
  inspect(b1.intersects_polygon(b3), content="true")
  inspect(b1.distance_to_polygon(b3), content="0")
}

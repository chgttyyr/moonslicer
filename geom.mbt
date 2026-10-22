///|
/// Geometric primitives: 2D/3D vectors, line segments, bounding boxes, and polygons.

///|
pub(all) struct Vec3 {
  x : Double
  y : Double
  z : Double
} derive(Debug, Eq)

///|
pub fn Vec3::new(x : Double, y : Double, z : Double) -> Vec3 {
  { x, y, z, }
}

///|
pub fn Vec3::zero() -> Vec3 {
  { x: 0.0, y: 0.0, z: 0.0, }
}

///|
pub fn Vec3::add(self : Vec3, other : Vec3) -> Vec3 {
  { x: self.x + other.x, y: self.y + other.y, z: self.z + other.z, }
}

///|
pub fn Vec3::sub(self : Vec3, other : Vec3) -> Vec3 {
  { x: self.x - other.x, y: self.y - other.y, z: self.z - other.z, }
}

///|
pub fn Vec3::scale(self : Vec3, factor : Double) -> Vec3 {
  { x: self.x * factor, y: self.y * factor, z: self.z * factor, }
}

///|
pub fn Vec3::dot(self : Vec3, other : Vec3) -> Double {
  self.x * other.x + self.y * other.y + self.z * other.z
}

///|
pub fn Vec3::cross(self : Vec3, other : Vec3) -> Vec3 {
  {
    x: self.y * other.z - self.z * other.y,
    y: self.z * other.x - self.x * other.z,
    z: self.x * other.y - self.y * other.x,
  }
}

///|
pub fn Vec3::length_sq(self : Vec3) -> Double {
  self.dot(self)
}

///|
pub fn Vec3::length(self : Vec3) -> Double {
  let len_sq = self.length_sq()
  if len_sq <= 0.0 {
    0.0
  } else {
    len_sq.sqrt()
  }
}

///|
pub fn Vec3::distance(self : Vec3, other : Vec3) -> Double {
  self.sub(other).length()
}

///|
pub fn Vec3::normalize(self : Vec3) -> Vec3 {
  let len = self.length()
  if len < 1.0e-9 {
    Vec3::zero()
  } else {
    self.scale(1.0 / len)
  }
}

///|
pub(all) struct Vec2 {
  x : Double
  y : Double
} derive(Debug, Eq)

///|
pub fn Vec2::new(x : Double, y : Double) -> Vec2 {
  { x, y, }
}

///|
pub fn Vec2::zero() -> Vec2 {
  { x: 0.0, y: 0.0, }
}

///|
pub fn Vec2::add(self : Vec2, other : Vec2) -> Vec2 {
  { x: self.x + other.x, y: self.y + other.y, }
}

///|
pub fn Vec2::sub(self : Vec2, other : Vec2) -> Vec2 {
  { x: self.x - other.x, y: self.y - other.y, }
}

///|
pub fn Vec2::scale(self : Vec2, factor : Double) -> Vec2 {
  { x: self.x * factor, y: self.y * factor, }
}

///|
pub fn Vec2::dot(self : Vec2, other : Vec2) -> Double {
  self.x * other.x + self.y * other.y
}

///|
/// 2D cross product (perp-dot product): u.x * v.y - u.y * v.x
pub fn Vec2::cross(self : Vec2, other : Vec2) -> Double {
  self.x * other.y - self.y * other.x
}

///|
pub fn Vec2::length_sq(self : Vec2) -> Double {
  self.x * self.x + self.y * self.y
}

///|
pub fn Vec2::length(self : Vec2) -> Double {
  let len_sq = self.length_sq()
  if len_sq <= 0.0 {
    0.0
  } else {
    len_sq.sqrt()
  }
}

///|
pub fn Vec2::distance_sq(self : Vec2, other : Vec2) -> Double {
  self.sub(other).length_sq()
}

///|
pub fn Vec2::distance(self : Vec2, other : Vec2) -> Double {
  self.sub(other).length()
}

///|
pub fn Vec2::normalize(self : Vec2) -> Vec2 {
  let len = self.length()
  if len < 1.0e-9 {
    Vec2::zero()
  } else {
    self.scale(1.0 / len)
  }
}

///|
/// Left-hand 90-degree normal: (-y, x)
pub fn Vec2::left_normal(self : Vec2) -> Vec2 {
  { x: -self.y, y: self.x, }
}

///|
pub(all) struct Segment2 {
  p1 : Vec2
  p2 : Vec2
} derive(Debug, Eq)

///|
pub fn Segment2::new(p1 : Vec2, p2 : Vec2) -> Segment2 {
  { p1, p2, }
}

///|
pub fn Segment2::length(self : Segment2) -> Double {
  self.p1.distance(self.p2)
}

///|
pub fn Segment2::direction(self : Segment2) -> Vec2 {
  self.p2.sub(self.p1).normalize()
}

///|
/// A closed 2D polygon boundary.
pub(all) struct Polygon2 {
  points : Array[Vec2]
} derive(Debug, Eq)

///|
pub fn Polygon2::new(points : Array[Vec2]) -> Polygon2 {
  { points, }
}

///|
/// Signed area via Green's theorem / Shoelace formula.
/// Positive area = CCW (outer contour), Negative area = CW (hole).
pub fn Polygon2::area(self : Polygon2) -> Double {
  let n = self.points.length()
  if n < 3 {
    return 0.0
  }
  let mut sum = 0.0
  for i = 0; i < n; i = i + 1 {
    let curr = self.points[i]
    let next = self.points[(i + 1) % n]
    sum = sum + (curr.x * next.y - next.x * curr.y)
  }
  sum * 0.5
}

///|
pub fn Polygon2::is_ccw(self : Polygon2) -> Bool {
  self.area() > 0.0
}

///|
pub fn Polygon2::reverse(self : Polygon2) -> Polygon2 {
  let pts : Array[Vec2] = []
  let n = self.points.length()
  for i = n - 1; i >= 0; i = i - 1 {
    pts.push(self.points[i])
  }
  { points: pts, }
}

///|
pub fn Polygon2::ensure_ccw(self : Polygon2) -> Polygon2 {
  if self.is_ccw() {
    self
  } else {
    self.reverse()
  }
}

///|
pub fn Polygon2::ensure_cw(self : Polygon2) -> Polygon2 {
  if !self.is_ccw() {
    self
  } else {
    self.reverse()
  }
}

///|
/// Ray-casting point-in-polygon containment test (Even-Odd rule).
pub fn Polygon2::contains_point(self : Polygon2, pt : Vec2) -> Bool {
  let n = self.points.length()
  if n < 3 {
    return false
  }
  let mut inside = false
  let mut j = n - 1
  for i = 0; i < n; i = i + 1 {
    let pi = self.points[i]
    let pj = self.points[j]
    if (pi.y > pt.y) != (pj.y > pt.y) {
      let x_intersect = (pj.x - pi.x) * (pt.y - pi.y) / (pj.y - pi.y) + pi.x
      if pt.x < x_intersect {
        inside = !inside
      }
    }
    j = i
  }
  inside
}

///|
/// 3D Axis-Aligned Bounding Box.
pub(all) struct BBox3 {
  min : Vec3
  max : Vec3
} derive(Debug, Eq)

///|
pub fn BBox3::new(min : Vec3, max : Vec3) -> BBox3 {
  { min, max, }
}

///|
pub fn BBox3::width(self : BBox3) -> Double {
  self.max.x - self.min.x
}

///|
pub fn BBox3::depth(self : BBox3) -> Double {
  self.max.y - self.min.y
}

///|
pub fn BBox3::height(self : BBox3) -> Double {
  self.max.z - self.min.z
}

///|
pub fn BBox3::center(self : BBox3) -> Vec3 {
  self.min.add(self.max).scale(0.5)
}

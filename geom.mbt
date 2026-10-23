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
pub fn Polygon2::centroid(self : Polygon2) -> Vec2 {
  let n = self.points.length()
  if n == 0 {
    return Vec2::zero()
  }
  let mut cx = 0.0
  let mut cy = 0.0
  for p in self.points {
    cx += p.x
    cy += p.y
  }
  Vec2::new(cx / n.to_double(), cy / n.to_double())
}

///|
/// Check whether this polygon completely contains another polygon.
/// A smaller polygon can never contain a larger one, and all vertices of the other must lie inside.
pub fn Polygon2::contains_polygon(self : Polygon2, other : Polygon2) -> Bool {
  if other.points.is_empty() {
    return false
  }
  if self.area().abs() <= other.area().abs() {
    return false
  }
  for p in other.points {
    if !self.contains_point(p) {
      return false
    }
  }
  true
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

///|
/// An exterior polygon contour together with its interior holes (PrusaSlicer-compatible ExPolygon).
pub(all) struct ExPolygon {
  contour : Polygon2
  holes : Array[Polygon2]
} derive(Debug, Eq)

///|
pub fn ExPolygon::new(
  contour : Polygon2,
  holes~ : Array[Polygon2] = [],
) -> ExPolygon {
  let normalized_holes : Array[Polygon2] = []
  for h in holes {
    normalized_holes.push(h.ensure_cw())
  }
  { contour: contour.ensure_ccw(), holes: normalized_holes, }
}

///|
/// Net cross-sectional area (outer contour area minus all interior holes).
pub fn ExPolygon::area(self : ExPolygon) -> Double {
  let mut a = self.contour.area().abs()
  for h in self.holes {
    a -= h.area().abs()
  }
  if a < 0.0 {
    0.0
  } else {
    a
  }
}

///|
/// Find a guaranteed interior point in the solid material (not inside any hole).
pub fn ExPolygon::interior_point(self : ExPolygon) -> Vec2 {
  let pts = self.contour.points
  let n = pts.length()
  if n < 3 {
    return Vec2::zero()
  }
  for i = 0; i < n; i = i + 1 {
    let p1 = pts[i]
    let p2 = pts[(i + 1) % n]
    let mid = p1.add(p2).scale(0.5)
    let edge_dir = p2.sub(p1).normalize()
    let inward_norm = edge_dir.left_normal()
    let cand1 = mid.add(inward_norm.scale(0.2))
    if self.contains_point(cand1) {
      return cand1
    }
    let cand2 = mid.add(inward_norm.scale(0.5))
    if self.contains_point(cand2) {
      return cand2
    }
    let cand3 = mid.add(inward_norm.scale(1.0))
    if self.contains_point(cand3) {
      return cand3
    }
  }
  self.contour.centroid()
}

///|
/// Point containment: inside the outer contour and not inside any interior hole.
pub fn ExPolygon::contains_point(self : ExPolygon, pt : Vec2) -> Bool {
  if !self.contour.contains_point(pt) {
    return false
  }
  for h in self.holes {
    if h.contains_point(pt) {
      return false
    }
  }
  true
}

///|
/// Build topological hierarchy (ExPolygons) from an arbitrary array of sliced closed polygons.
/// Accurately classifies multi-island outer contours vs inner holes and nested islands.
pub fn build_expolygons(polygons : Array[Polygon2]) -> Array[ExPolygon] {
  // 1. Filter degenerate polygons
  let valid : Array[Polygon2] = []
  for poly in polygons {
    if poly.points.length() >= 3 && poly.area().abs() > 1.0e-5 {
      valid.push(poly)
    }
  }

  let n = valid.length()
  if n == 0 {
    return []
  }

  // 2. Sort by absolute area descending (largest outer contours first)
  for i = 0; i < n; i = i + 1 {
    for j = i + 1; j < n; j = j + 1 {
      if valid[i].area().abs() < valid[j].area().abs() {
        let tmp = valid[i]
        valid[i] = valid[j]
        valid[j] = tmp
      }
    }
  }

  // 3. Compute containment depth for each polygon
  let depths : Array[Int32] = []
  for i = 0; i < n; i = i + 1 {
    let mut d = 0
    for j = 0; j < n; j = j + 1 {
      if i != j && valid[j].contains_polygon(valid[i]) {
        d += 1
      }
    }
    depths.push(d)
  }

  // 4. Distinguish outer islands (even depth) from holes (odd depth)
  let expolys : Array[ExPolygon] = []
  let island_indices : Array[Int32] = []

  for i = 0; i < n; i = i + 1 {
    if depths[i] % 2 == 0 {
      // Even depth: outer island
      island_indices.push(i)
      expolys.push(ExPolygon::new(valid[i]))
    }
  }

  // 5. Assign each hole (odd depth) to its immediately containing island
  for i = 0; i < n; i = i + 1 {
    if depths[i] % 2 == 1 {
      // Odd depth: hole
      let hole_poly = valid[i]
      let mut best_island_idx = -1
      let mut min_island_area = 1.0e30

      for k = 0; k < island_indices.length(); k = k + 1 {
        let island_pos = island_indices[k]
        if depths[island_pos] == depths[i] - 1 &&
          valid[island_pos].contains_polygon(hole_poly) {
          let a = valid[island_pos].area().abs()
          if a < min_island_area {
            min_island_area = a
            best_island_idx = k
          }
        }
      }

      if best_island_idx >= 0 {
        expolys[best_island_idx].holes.push(hole_poly.ensure_cw())
      }
    }
  }

  expolys
}

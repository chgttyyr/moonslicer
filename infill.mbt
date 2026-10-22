///|
/// Infill path generator: alternating rectilinear scanline infill.
const PI : Double = 3.141592653589793

///|
const TWO_PI : Double = 6.283185307179586

///|
/// High-precision sine approximation for arbitrary angles.
pub fn math_sin(rad : Double) -> Double {
  let mut x = rad % TWO_PI
  if x < 0.0 {
    x = x + TWO_PI
  }
  if x > PI {
    x = x - TWO_PI
  }
  let x2 = x * x
  let x3 = x * x2
  let x5 = x3 * x2
  let x7 = x5 * x2
  let x9 = x7 * x2
  let x11 = x9 * x2
  x - x3 / 6.0 + x5 / 120.0 - x7 / 5040.0 + x9 / 362880.0 - x11 / 39916800.0
}

///|
/// High-precision cosine approximation.
pub fn math_cos(rad : Double) -> Double {
  math_sin(rad + PI * 0.5)
}

///|
/// Helper for sorting intersection points along a scanline.
priv struct InfillHit {
  s : Double
  pt : Vec2
}

///|
/// Generate rectilinear infill lines for a boundary polygon.
/// - density: 0.0 to 1.0 (e.g. 0.2 = 20%)
/// - line_width: extrusion width in mm (e.g. 0.4)
/// - angle_deg: angle of infill lines in degrees (e.g. 45.0 or 135.0)
pub fn generate_rectilinear_infill(
  poly : Polygon2,
  density : Double,
  line_width : Double,
  angle_deg : Double,
) -> Array[Segment2] {
  let infill_segments : Array[Segment2] = []
  if density <= 0.001 || poly.points.length() < 3 {
    return infill_segments
  }

  // Spacing between infill lines: e.g. 0.4 / 0.2 = 2.0mm
  let spacing = line_width / density

  // Direction along scanline, and normal perpendicular to it
  let (cos_a, sin_a) = if (angle_deg - 0.0).abs() < 1.0e-3 {
    (1.0, 0.0)
  } else if (angle_deg - 90.0).abs() < 1.0e-3 {
    (0.0, 1.0)
  } else if (angle_deg - 45.0).abs() < 1.0e-3 {
    (0.7071067811865476, 0.7071067811865476)
  } else if (angle_deg - 135.0).abs() < 1.0e-3 {
    (-0.7071067811865476, 0.7071067811865476)
  } else {
    let rad = angle_deg * (PI / 180.0)
    (math_cos(rad), math_sin(rad))
  }

  let dir = Vec2::new(cos_a, sin_a)
  let norm = Vec2::new(-sin_a, cos_a)

  // Find min and max projection onto normal
  let pts = poly.points
  let n = pts.length()
  let mut min_proj = pts[0].dot(norm)
  let mut max_proj = min_proj

  for i = 1; i < n; i = i + 1 {
    let proj = pts[i].dot(norm)
    if proj < min_proj {
      min_proj = proj
    }
    if proj > max_proj {
      max_proj = proj
    }
  }

  // Step through scanlines
  let mut d = min_proj + spacing * 0.5
  while d < max_proj {
    let hits : Array[InfillHit] = []

    for i = 0; i < n; i = i + 1 {
      let a = pts[i]
      let b = pts[(i + 1) % n]
      let proj_a = a.dot(norm)
      let proj_b = b.dot(norm)

      let diff = proj_b - proj_a
      if diff.abs() > 1.0e-9 {
        let t = (d - proj_a) / diff
        if t >= 0.0 && t <= 1.0 {
          let ix = a.x + t * (b.x - a.x)
          let iy = a.y + t * (b.y - a.y)
          let pt = Vec2::new(ix, iy)
          let s = pt.dot(dir)
          hits.push({ s, pt, })
        }
      }
    }

    // Sort hits along scanline direction
    hits.sort_by(fn(h1, h2) { h1.s.compare(h2.s) })

    // Pair up hits by even-odd parity
    let num_pairs = hits.length() / 2
    for p = 0; p < num_pairs; p = p + 1 {
      let p1 = hits[p * 2].pt
      let p2 = hits[p * 2 + 1].pt
      if p1.distance(p2) > 1.0e-3 {
        infill_segments.push(Segment2::new(p1, p2))
      }
    }

    d = d + spacing
  }

  infill_segments
}

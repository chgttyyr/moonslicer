///|
/// Polygon offsetting for 3D printing perimeters and infill boundary generation.

///|
/// Offset a single closed polygon inward by distance d (d > 0).
/// Uses angle bisector normal displacement with miter clamping.
/// Returns Some(offset_poly) if valid, or None if the polygon collapsed.
pub fn offset_polygon_inward(
  poly : Polygon2,
  d : Double,
  miter_limit~ : Double = 2.5,
) -> Polygon2? {
  let pts = poly.ensure_ccw().points
  let n = pts.length()
  if n < 3 || d <= 0.0 {
    return None
  }

  let offset_pts : Array[Vec2] = []
  let max_displacement = d * miter_limit

  for i = 0; i < n; i = i + 1 {
    let prev = pts[(i - 1 + n) % n]
    let curr = pts[i]
    let next = pts[(i + 1) % n]

    let e1 = curr.sub(prev)
    let e2 = next.sub(curr)

    let len1 = e1.length()
    let len2 = e2.length()

    if len1 < 1.0e-9 || len2 < 1.0e-9 {
      continue
    }

    let u1 = e1.scale(1.0 / len1)
    let u2 = e2.scale(1.0 / len2)

    // Inward normal for CCW polygon is left-hand normal: (-y, x)
    let n1 = u1.left_normal()
    let n2 = u2.left_normal()

    let denom = 1.0 + n1.dot(n2)
    let disp = if denom < 1.0e-4 {
      n1.scale(d)
    } else {
      let b = n1.add(n2)
      b.scale(d / denom)
    }

    // Miter limit clamping
    let disp_len = disp.length()
    let clamped_disp = if disp_len > max_displacement {
      disp.scale(max_displacement / disp_len)
    } else {
      disp
    }

    offset_pts.push(curr.add(clamped_disp))
  }

  // Edge inversion check: offset edge must point in the same direction as original edge
  for i = 0; i < n; i = i + 1 {
    let orig_e = pts[(i + 1) % n].sub(pts[i])
    let offset_e = offset_pts[(i + 1) % n].sub(offset_pts[i])
    if offset_e.dot(orig_e) <= 0.0 {
      return None
    }
  }

  // Remove degenerate consecutive vertices
  let clean_pts : Array[Vec2] = []
  let count = offset_pts.length()
  if count < 3 {
    return None
  }

  for i = 0; i < count; i = i + 1 {
    let p = offset_pts[i]
    let next_p = offset_pts[(i + 1) % count]
    if p.distance(next_p) > 1.0e-4 {
      clean_pts.push(p)
    }
  }

  if clean_pts.length() < 3 {
    return None
  }

  let result = Polygon2::new(clean_pts)
  // An inward offset of a CCW polygon must remain CCW with positive area
  if result.area() > 1.0e-4 {
    Some(result)
  } else {
    None
  }
}

///|
/// Offset a hole polygon outward into the surrounding solid material.
/// Uses angle bisector normal displacement on clockwise hole boundary.
pub fn offset_polygon_outward(
  poly : Polygon2,
  d : Double,
  miter_limit~ : Double = 2.5,
) -> Polygon2? {
  let pts = poly.ensure_cw().points
  let n = pts.length()
  if n < 3 || d <= 0.0 {
    return None
  }

  let offset_pts : Array[Vec2] = []
  let max_displacement = d * miter_limit

  for i = 0; i < n; i = i + 1 {
    let prev = pts[(i - 1 + n) % n]
    let curr = pts[i]
    let next = pts[(i + 1) % n]

    let e1 = curr.sub(prev)
    let e2 = next.sub(curr)

    let len1 = e1.length()
    let len2 = e2.length()

    if len1 < 1.0e-9 || len2 < 1.0e-9 {
      continue
    }

    let u1 = e1.scale(1.0 / len1)
    let u2 = e2.scale(1.0 / len2)

    // Left-hand normal for CW polygon points outward into material
    let n1 = u1.left_normal()
    let n2 = u2.left_normal()

    let denom = 1.0 + n1.dot(n2)
    let disp = if denom < 1.0e-4 {
      n1.scale(d)
    } else {
      let b = n1.add(n2)
      b.scale(d / denom)
    }

    let disp_len = disp.length()
    let clamped_disp = if disp_len > max_displacement {
      disp.scale(max_displacement / disp_len)
    } else {
      disp
    }

    offset_pts.push(curr.add(clamped_disp))
  }

  // Edge inversion check
  for i = 0; i < n; i = i + 1 {
    let orig_e = pts[(i + 1) % n].sub(pts[i])
    let offset_e = offset_pts[(i + 1) % n].sub(offset_pts[i])
    if offset_e.dot(orig_e) <= 0.0 {
      return None
    }
  }

  let clean_pts : Array[Vec2] = []
  let count = offset_pts.length()
  if count < 3 {
    return None
  }

  for i = 0; i < count; i = i + 1 {
    let p = offset_pts[i]
    let next_p = offset_pts[(i + 1) % count]
    if p.distance(next_p) > 1.0e-4 {
      clean_pts.push(p)
    }
  }

  if clean_pts.length() < 3 {
    return None
  }

  let result = Polygon2::new(clean_pts).ensure_cw()
  Some(result)
}

///|
/// Generate multiple perimeter walls for a single polygon contour.
/// Returns (perimeters, infill_boundary).
pub fn generate_perimeters(
  poly : Polygon2,
  wall_count : Int32,
  line_width : Double,
) -> (Array[Polygon2], Polygon2?) {
  let perimeters : Array[Polygon2] = []
  let mut current_boundary = poly.ensure_ccw()

  let first_offset = line_width * 0.5
  match offset_polygon_inward(current_boundary, first_offset) {
    Some(w0) => {
      perimeters.push(w0)
      current_boundary = w0

      for _w = 1; _w < wall_count; _w = _w + 1 {
        match offset_polygon_inward(current_boundary, line_width) {
          Some(w) => {
            perimeters.push(w)
            current_boundary = w
          }
          None => break
        }
      }
    }
    None => ()
  }

  let infill_boundary = if perimeters.is_empty() {
    None
  } else {
    offset_polygon_inward(current_boundary, line_width * 0.5)
  }

  (perimeters, infill_boundary)
}

///|
/// Structure holding perimeter paths and infill boundary for an ExPolygon (contour + holes).
pub(all) struct ExPolygonPerimeters {
  outer_walls : Array[Polygon2]
  hole_walls : Array[Array[Polygon2]]
  infill_boundary : ExPolygon?
} derive(Debug)

///|
/// Generate perimeters for an ExPolygon (inward for outer contour, outward for holes).
pub fn generate_expolygon_perimeters(
  expoly : ExPolygon,
  wall_count : Int32,
  line_width : Double,
) -> ExPolygonPerimeters {
  // 1. Generate outer walls
  let (outer_walls, maybe_infill_contour) = generate_perimeters(
    expoly.contour,
    wall_count,
    line_width,
  )

  // 2. Generate perimeters for each hole
  let all_hole_walls : Array[Array[Polygon2]] = []
  let infill_holes : Array[Polygon2] = []

  for hole in expoly.holes {
    let hole_perims : Array[Polygon2] = []
    let mut current_h = hole.ensure_cw()

    match offset_polygon_outward(current_h, line_width * 0.5) {
      Some(h0) => {
        hole_perims.push(h0)
        current_h = h0

        for _w = 1; _w < wall_count; _w = _w + 1 {
          match offset_polygon_outward(current_h, line_width) {
            Some(hw) => {
              hole_perims.push(hw)
              current_h = hw
            }
            None => break
          }
        }

        // Expand hole boundary for infill
        match offset_polygon_outward(current_h, line_width * 0.5) {
          Some(ih) => infill_holes.push(ih)
          None => ()
        }
      }
      None => ()
    }

    all_hole_walls.push(hole_perims)
  }

  // 3. Construct infill boundary ExPolygon
  let infill_boundary = match maybe_infill_contour {
    Some(ic) => {
      // Keep only infill holes that are still contained within the infill contour
      let valid_ih : Array[Polygon2] = []
      for ih in infill_holes {
        if ic.contains_polygon(ih) {
          valid_ih.push(ih)
        }
      }
      Some(ExPolygon::new(ic, holes=valid_ih))
    }
    None => None
  }

  { outer_walls, hole_walls: all_hole_walls, infill_boundary, }
}

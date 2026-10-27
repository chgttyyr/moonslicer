///|
/// Polygon offsetting for 3D printing perimeters, infill boundaries, and collision resolution.

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
/// Record of an offset path collision and the resolution action taken.
pub(all) struct OffsetCollisionEvent {
  hole_a_idx : Int32
  hole_b_idx : Int32 // -1 indicates collision with outer contour/wall
  clearance : Double
  requested_offset : Double
  clamped_offset : Double
  action : String // "Clamped", "WallSuppressed", "IntersectionPruned"
} derive(Debug, Eq)

///|
/// Structure holding perimeter paths, infill boundary, and collision resolution events.
pub(all) struct ExPolygonPerimeters {
  outer_walls : Array[Polygon2]
  hole_walls : Array[Array[Polygon2]]
  infill_boundary : ExPolygon?
  collisions : Array[OffsetCollisionEvent]
} derive(Debug)

///|
/// Generate perimeters for an ExPolygon with full collision detection and resolution.
/// Prevents contour overlap between adjacent holes or between holes and outer walls.
pub fn generate_expolygon_perimeters(
  expoly : ExPolygon,
  wall_count : Int32,
  line_width : Double,
) -> ExPolygonPerimeters {
  let collisions : Array[OffsetCollisionEvent] = []

  // 1. Generate outer walls
  let (outer_walls, maybe_infill_contour) = generate_perimeters(
    expoly.contour,
    wall_count,
    line_width,
  )

  let num_holes = expoly.holes.length()
  let all_hole_walls : Array[Array[Polygon2]] = []
  let infill_holes : Array[Polygon2] = []

  // Precompute clearances to outer boundary
  let hole_outer_clearance : Array[Double] = []
  for i = 0; i < num_holes; i = i + 1 {
    let d = expoly.holes[i].distance_to_polygon(expoly.contour)
    hole_outer_clearance.push(d)
  }

  // Precompute pairwise clearances between all holes
  let min_inter_hole_gap : Array[Double] = []
  let nearest_hole_idx : Array[Int32] = []
  for i = 0; i < num_holes; i = i + 1 {
    let mut min_g = 1.0e9
    let mut nearest_idx = -1
    for j = 0; j < num_holes; j = j + 1 {
      if i != j {
        let g = expoly.holes[i].distance_to_polygon(expoly.holes[j])
        if g < min_g {
          min_g = g
          nearest_idx = j
        }
      }
    }
    min_inter_hole_gap.push(min_g)
    nearest_hole_idx.push(nearest_idx)
  }

  // 2. Generate perimeters for each hole with adaptive clearance clamping
  for i = 0; i < num_holes; i = i + 1 {
    let hole = expoly.holes[i]
    let hole_perims : Array[Polygon2] = []
    let mut current_h = hole.ensure_cw()

    let inter_gap = min_inter_hole_gap[i]
    let outer_gap = hole_outer_clearance[i]
    let max_safe_expansion = if num_holes > 1 && inter_gap < outer_gap {
      inter_gap * 0.48
    } else {
      (outer_gap - line_width * wall_count.to_double() * 0.5) * 0.95
    }

    let mut cumulative_offset = 0.0

    // Wall 0
    let step0 = line_width * 0.5
    let req0 = cumulative_offset + step0
    let (actual_step0, clamped0) = if req0 > max_safe_expansion &&
      max_safe_expansion > 0.02 {
      (max_safe_expansion - cumulative_offset, true)
    } else {
      (step0, false)
    }

    if clamped0 {
      let other_id = if num_holes > 1 && inter_gap < outer_gap {
        nearest_hole_idx[i]
      } else {
        -1
      }
      collisions.push({
        hole_a_idx: i,
        hole_b_idx: other_id,
        clearance: if other_id >= 0 {
          inter_gap
        } else {
          outer_gap
        },
        requested_offset: req0,
        clamped_offset: actual_step0,
        action: "Clamped",
      })
    }

    match offset_polygon_outward(current_h, actual_step0) {
      Some(h0) => {
        hole_perims.push(h0)
        current_h = h0
        cumulative_offset += actual_step0

        // Subsequent walls
        for _w = 1; _w < wall_count; _w = _w + 1 {
          let req_step = line_width
          let req_total = cumulative_offset + req_step
          if req_total > max_safe_expansion {
            let other_id = if num_holes > 1 && inter_gap < outer_gap {
              nearest_hole_idx[i]
            } else {
              -1
            }
            collisions.push({
              hole_a_idx: i,
              hole_b_idx: other_id,
              clearance: if other_id >= 0 {
                inter_gap
              } else {
                outer_gap
              },
              requested_offset: req_total,
              clamped_offset: cumulative_offset,
              action: "WallSuppressed",
            })
            break
          }

          match offset_polygon_outward(current_h, req_step) {
            Some(hw) => {
              hole_perims.push(hw)
              current_h = hw
              cumulative_offset += req_step
            }
            None => break
          }
        }

        // Expand hole boundary for infill
        let infill_req = cumulative_offset + line_width * 0.5
        let infill_step = if infill_req > max_safe_expansion {
          0.0
        } else {
          line_width * 0.5
        }
        if infill_step > 0.01 {
          match offset_polygon_outward(current_h, infill_step) {
            Some(ih) => infill_holes.push(ih)
            None => infill_holes.push(current_h)
          }
        } else {
          infill_holes.push(current_h)
        }
      }
      None => ()
    }

    all_hole_walls.push(hole_perims)
  }

  // 3. Post-offset geometric validation (explicit intersection test)
  for i = 0; i < all_hole_walls.length(); i = i + 1 {
    let mut w_idx = all_hole_walls[i].length() - 1
    while w_idx >= 0 {
      let hw = all_hole_walls[i][w_idx]
      let mut has_intersect = false

      // Check outer walls: hole wall must not cross outer wall
      for ow in outer_walls {
        if hw.edges_intersect(ow) {
          has_intersect = true
          break
        }
      }

      // Check other holes
      if !has_intersect {
        for j = 0; j < all_hole_walls.length(); j = j + 1 {
          if i != j {
            for other_hw in all_hole_walls[j] {
              if hw.intersects_polygon(other_hw) {
                has_intersect = true
                break
              }
            }
            if has_intersect {
              break
            }
          }
        }
      }

      if has_intersect {
        collisions.push({
          hole_a_idx: i,
          hole_b_idx: -1,
          clearance: 0.0,
          requested_offset: line_width,
          clamped_offset: 0.0,
          action: "IntersectionPruned",
        })
        all_hole_walls[i].remove(w_idx) |> ignore
      }
      w_idx = w_idx - 1
    }
  }

  // 4. Construct infill boundary ExPolygon
  let infill_boundary = match maybe_infill_contour {
    Some(ic) => {
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

  { outer_walls, hole_walls: all_hole_walls, infill_boundary, collisions, }
}

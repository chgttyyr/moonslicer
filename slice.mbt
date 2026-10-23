///|
/// 3D Mesh Slicing Engine: Triangle-Plane intersection and topological loop stitching.

///|
/// Intersect a 3D triangle with horizontal plane Z = z.
/// Returns Some(Segment2) if intersection is a valid segment, None otherwise.
pub fn intersect_triangle_plane(tri : Triangle3, z : Double) -> Segment2? {
  let min_z = tri.min_z()
  let max_z = tri.max_z()

  // Strict bounding check
  if z < min_z || z > max_z {
    return None
  }

  // Collect intersection points on edges
  let pts : Array[Vec2] = []
  let edges = [(tri.v1, tri.v2), (tri.v2, tri.v3), (tri.v3, tri.v1)]

  for edge in edges {
    let a = edge.0
    let b = edge.1

    let diff_z = b.z - a.z
    if diff_z.abs() > 1.0e-9 {
      // Check if z is strictly between a.z and b.z, or matches a.z
      let t = (z - a.z) / diff_z
      if t >= 0.0 && t <= 1.0 {
        let x = a.x + t * (b.x - a.x)
        let y = a.y + t * (b.y - a.y)
        let pt = Vec2::new(x, y)

        // Avoid adding duplicated points if an edge vertex lies exactly on plane
        let mut duplicate = false
        for existing in pts {
          if pt.distance_sq(existing) < 1.0e-10 {
            duplicate = true
            break
          }
        }
        if !duplicate {
          pts.push(pt)
        }
      }
    }
  }

  if pts.length() >= 2 {
    let p1 = pts[0]
    let p2 = pts[1]
    if p1.distance_sq(p2) > 1.0e-8 {
      // Ensure orientation: (p2 - p1) cross normal.xy should align with surface
      Some(Segment2::new(p1, p2))
    } else {
      None
    }
  } else {
    None
  }
}

///|
/// Stitch a collection of unordered 2D line segments into closed Polygon2 loops.
pub fn stitch_segments_into_loops(
  segments : Array[Segment2],
  tolerance~ : Double = 1.0e-3,
) -> Array[Polygon2] {
  let loops : Array[Polygon2] = []
  let n = segments.length()
  if n == 0 {
    return loops
  }

  let used : Array[Bool] = Array::make(n, false)
  let tol_sq = tolerance * tolerance

  for i = 0; i < n; i = i + 1 {
    if used[i] {
      continue
    }

    used[i] = true
    let seg = segments[i]
    let chain : Array[Vec2] = [seg.p1, seg.p2]
    let mut current_end = seg.p2
    let chain_start = seg.p1

    let mut extended = true
    while extended {
      extended = false
      let mut best_idx = -1
      let mut best_dist_sq = 1.0e9
      let mut flip = false

      for j = 0; j < n; j = j + 1 {
        if !used[j] {
          let s = segments[j]
          let d_start = current_end.distance_sq(s.p1)
          if d_start < tol_sq && d_start < best_dist_sq {
            best_dist_sq = d_start
            best_idx = j
            flip = false
          }
          let d_end = current_end.distance_sq(s.p2)
          if d_end < tol_sq && d_end < best_dist_sq {
            best_dist_sq = d_end
            best_idx = j
            flip = true
          }
        }
      }

      if best_idx >= 0 {
        used[best_idx] = true
        let matched = segments[best_idx]
        if flip {
          chain.push(matched.p1)
          current_end = matched.p1
        } else {
          chain.push(matched.p2)
          current_end = matched.p2
        }
        extended = true

        // If loop is closed back to start
        if current_end.distance_sq(chain_start) < tol_sq {
          break
        }
      }
    }

    // Only accept polygons with at least 3 points
    if chain.length() >= 3 {
      // Remove closing vertex if it's virtually identical to start
      let last = chain[chain.length() - 1]
      let pts : Array[Vec2] = []
      let count = if last.distance_sq(chain[0]) < tol_sq {
        chain.length() - 1
      } else {
        chain.length()
      }
      for k = 0; k < count; k = k + 1 {
        pts.push(chain[k])
      }
      if pts.length() >= 3 {
        loops.push(Polygon2::new(pts))
      }
    }
  }

  loops
}

///|
/// A sliced 2D layer containing reconstructed boundary polygons and topological ExPolygons.
pub(all) struct SliceLayer {
  z : Double
  polygons : Array[Polygon2]
  expolygons : Array[ExPolygon]
} derive(Debug)

///|
pub fn SliceLayer::new(
  z : Double,
  polygons : Array[Polygon2],
  expolygons? : Array[ExPolygon],
) -> SliceLayer {
  let eps = match expolygons {
    Some(e) => e
    None => build_expolygons(polygons)
  }
  { z, polygons, expolygons: eps, }
}

///|
/// Slice a 3D mesh at a specific Z height into closed polygons.
pub fn slice_mesh_at_z(mesh : Mesh3, z : Double) -> SliceLayer {
  let segments : Array[Segment2] = []

  // Slight epsilon jitter to prevent degenerate exact vertex slicing
  let eval_z = z + 1.0e-5

  for tri in mesh.triangles {
    match intersect_triangle_plane(tri, eval_z) {
      Some(seg) => segments.push(seg)
      None => ()
    }
  }

  let polygons = stitch_segments_into_loops(segments)
  let expolygons = build_expolygons(polygons)
  { z, polygons, expolygons, }
}

///|
/// Slice an entire 3D mesh into layers according to layer_height settings.
pub fn slice_mesh(mesh : Mesh3, config : SlicerConfig) -> Array[SliceLayer] {
  let layers : Array[SliceLayer] = []
  let min_z = mesh.bounds.min.z
  let max_z = mesh.bounds.max.z

  if max_z <= min_z {
    return layers
  }

  let mut current_z = min_z + config.initial_layer_height
  while current_z <= max_z {
    let layer = slice_mesh_at_z(mesh, current_z)
    if !layer.polygons.is_empty() {
      layers.push(layer)
    }
    current_z = current_z + config.layer_height
  }

  layers
}

///|
/// Cross-layer surface classification engine (PrusaSlicer-compatible).
/// Identifies Top Solid, Bottom Solid / Bridge, and Internal Sparse surfaces.

///|
/// Classify the overall layer surface type based on layer index and solid layer settings.
pub fn classify_layer(
  layer_idx : Int32,
  total_layers : Int32,
  config : SlicerConfig,
) -> SurfaceType {
  if layer_idx < config.bottom_solid_layers {
    BottomSolid
  } else if layer_idx >= total_layers - config.top_solid_layers {
    TopSolid
  } else {
    InternalSparse
  }
}

///|
/// Classify an individual 2D island (ExPolygon) by comparing with adjacent layers.
pub fn classify_island_surface(
  island : ExPolygon,
  layer_idx : Int32,
  layers : Array[SliceLayer],
  config : SlicerConfig,
) -> SurfaceType {
  let total_layers = layers.length()
  if layer_idx < config.bottom_solid_layers {
    return BottomSolid
  }
  if layer_idx >= total_layers - config.top_solid_layers {
    return TopSolid
  }

  let center = island.interior_point()

  // 1. Check for air beneath (Overhang / Bridge / Internal Floor)
  if layer_idx > 0 {
    let lower_layer = layers[layer_idx - 1]
    let mut covered_below = false
    for ep in lower_layer.expolygons {
      if ep.contains_point(center) {
        covered_below = true
        break
      }
    }
    if !covered_below {
      return BottomSolid
    }
  }

  // 2. Check for air above (Stepped Roof / Internal Ceiling)
  if layer_idx + 1 < total_layers {
    let upper_layer = layers[layer_idx + 1]
    let mut covered_above = false
    for ep in upper_layer.expolygons {
      if ep.contains_point(center) {
        covered_above = true
        break
      }
    }
    if !covered_above {
      return TopSolid
    }
  }

  InternalSparse
}

///|
/// Classify a single infill segment by testing if its midpoint has support below and ceiling above.
pub fn classify_infill_segment(
  seg : Segment2,
  layer_idx : Int32,
  layers : Array[SliceLayer],
  config : SlicerConfig,
) -> SurfaceType {
  let total_layers = layers.length()
  if layer_idx < config.bottom_solid_layers {
    return BottomSolid
  }
  if layer_idx >= total_layers - config.top_solid_layers {
    return TopSolid
  }

  let mid = seg.p1.add(seg.p2).scale(0.5)

  // Check support below
  if layer_idx > 0 {
    let lower = layers[layer_idx - 1]
    let mut supported = false
    for ep in lower.expolygons {
      if ep.contains_point(mid) {
        supported = true
        break
      }
    }
    if !supported {
      return BottomSolid
    }
  }

  // Check cover above
  if layer_idx + 1 < total_layers {
    let upper = layers[layer_idx + 1]
    let mut covered = false
    for ep in upper.expolygons {
      if ep.contains_point(mid) {
        covered = true
        break
      }
    }
    if !covered {
      return TopSolid
    }
  }

  InternalSparse
}

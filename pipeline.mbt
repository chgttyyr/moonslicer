///|
/// Slicing pipeline orchestrator connecting STL parsing, mesh centering, layer slicing, and G-code synthesis.

///|
/// Summary statistics for a 3D mesh slicing job.
pub(all) struct MeshSliceStats {
  triangle_count : Int32
  width : Double
  depth : Double
  height : Double
  estimated_layers : Int32
  min_z : Double
  max_z : Double
} derive(Debug)

///|
/// Calculate summary statistics for slicing a mesh.
pub fn get_mesh_slice_stats(
  mesh : Mesh3,
  config~ : SlicerConfig = SlicerConfig::default(),
) -> MeshSliceStats {
  let b = mesh.bounds
  let w = b.width()
  let d = b.depth()
  let h = b.height()
  let est_layers = if h <= 0.0 {
    0
  } else if h <= config.initial_layer_height {
    1
  } else {
    1 + ((h - config.initial_layer_height) / config.layer_height).to_int()
  }

  {
    triangle_count: mesh.triangles.length(),
    width: w,
    depth: d,
    height: h,
    estimated_layers: est_layers,
    min_z: b.min.z,
    max_z: b.max.z,
  }
}

///|
/// Slice a 3D mesh into G-code end-to-end.
pub fn slice_mesh_to_gcode(
  mesh : Mesh3,
  config~ : SlicerConfig = SlicerConfig::default(),
  bed_center_x~ : Double = 100.0,
  bed_center_y~ : Double = 100.0,
) -> GCodeResult {
  let centered = mesh.center_to_bed()
  let layers = slice_mesh(centered, config)
  generate_gcode(layers, config, bed_center_x~, bed_center_y~)
}

///|
/// Parse raw STL bytes (ASCII or binary) and slice directly to G-code.
pub fn slice_stl_bytes_to_gcode(
  bytes : Bytes,
  config~ : SlicerConfig = SlicerConfig::default(),
  bed_center_x~ : Double = 100.0,
  bed_center_y~ : Double = 100.0,
) -> Result[GCodeResult, SlicerError] {
  match parse_stl(bytes) {
    Ok(mesh) =>
      Ok(slice_mesh_to_gcode(mesh, config~, bed_center_x~, bed_center_y~))
    Err(e) => Err(e)
  }
}

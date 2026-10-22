///|
test "slice calibration cube fixture" {
  let fixture_path = "fixtures/calibration_cube_ascii.stl"
  try {
    let bytes = @fs.read_file_to_bytes(fixture_path)
    inspect(bytes.length() > 500, content="true")

    let mesh_res = parse_stl(bytes)
    inspect(mesh_res is Ok(_), content="true")

    match mesh_res {
      Ok(mesh) => {
        let stats = get_mesh_slice_stats(mesh)
        inspect(stats.triangle_count, content="12")
        inspect(stats.width, content="20")
        inspect(stats.depth, content="20")
        inspect(stats.height, content="20")

        let mut config = SlicerConfig::default()
        config = {
          ..config,
          initial_layer_height: 0.3,
          layer_height: 0.2,
          wall_count: 2,
          infill_density: 0.15,
        }

        let gcode_res = slice_mesh_to_gcode(mesh, config~)
        // 20mm height: first layer at 0.3, then every 0.2mm up to < 20.0
        // (20.0 - 0.3) / 0.2 = 98.5 -> 1 + 98 = 99 layers
        inspect(gcode_res.total_layers, content="99")
        inspect(gcode_res.total_filament_mm > 100.0, content="true")
        inspect(gcode_res.estimated_print_time_sec > 10.0, content="true")

        // Check header and layer markers in generated G-code
        inspect(gcode_res.gcode.contains("; Total Layers: 99"), content="true")
        inspect(gcode_res.gcode.contains("; LAYER: 0"), content="true")
        inspect(gcode_res.gcode.contains("; LAYER: 98"), content="true")
      }
      Err(_) => inspect(false, content="true")
    }
  } catch {
    _ => inspect(false, content="true")
  }
}

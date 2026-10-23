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

///|
test "slice hollow box with hole fixture" {
  let fixture_path = "fixtures/hollow_box_with_hole.stl"
  try {
    let bytes = @fs.read_file_to_bytes(fixture_path)
    let mesh = parse_stl(bytes).unwrap()
    let stats = get_mesh_slice_stats(mesh)
    inspect(stats.triangle_count, content="32")
    inspect(stats.width, content="30")
    inspect(stats.height, content="10")

    let mut config = SlicerConfig::default()
    config = { ..config, layer_height: 1.0, initial_layer_height: 1.0, }
    let centered = mesh.center_to_bed()
    let layers = slice_mesh(centered, config)

    // Check layer count: 10mm / 1.0mm = 9 layers sliced
    inspect(layers.length() > 0, content="true")

    // In each layer, should have 1 ExPolygon with 1 hole
    let mid_layer = layers[layers.length() / 2]
    inspect(mid_layer.expolygons.length(), content="1")
    inspect(mid_layer.expolygons[0].holes.length(), content="1")

    let gcode_res = generate_gcode(layers, config)
    inspect(gcode_res.gcode.contains("; TYPE: Hole perimeter"), content="true")
    inspect(gcode_res.gcode.contains("; TYPE: Outer perimeter"), content="true")
  } catch {
    _ => inspect(false, content="true")
  }
}

///|
test "slice two pillars multi island fixture" {
  let fixture_path = "fixtures/two_pillars_multi_island.stl"
  try {
    let bytes = @fs.read_file_to_bytes(fixture_path)
    let mesh = parse_stl(bytes).unwrap()
    let stats = get_mesh_slice_stats(mesh)
    inspect(stats.triangle_count, content="24")
    inspect(stats.width, content="30")

    let mut config = SlicerConfig::default()
    config = { ..config, layer_height: 1.0, initial_layer_height: 1.0, }
    let centered = mesh.center_to_bed()
    let layers = slice_mesh(centered, config)

    inspect(layers.length() > 0, content="true")

    // Each layer should contain 2 distinct islands (two pillars)
    let mid_layer = layers[layers.length() / 2]
    inspect(mid_layer.expolygons.length(), content="2")
    inspect(mid_layer.expolygons[0].holes.length(), content="0")
    inspect(mid_layer.expolygons[1].holes.length(), content="0")

    let gcode_res = generate_gcode(layers, config)
    inspect(gcode_res.total_layers, content="9")
    inspect(gcode_res.total_filament_mm > 0.0, content="true")
  } catch {
    _ => inspect(false, content="true")
  }
}

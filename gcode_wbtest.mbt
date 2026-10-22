///|
test "extrusion calculations" {
  // Line width = 0.4, layer height = 0.2
  // Bead area = (0.4 - 0.2) * 0.2 + pi * 0.1^2 = 0.04 + 0.0314159... ~= 0.0714159
  let area = calculate_extrusion_area(0.4, 0.2)
  inspect(area > 0.071 && area < 0.072, content="true")

  // Filament 1.75mm diameter: radius = 0.875, area = pi * 0.875^2 ~= 2.40528
  // Move 100mm -> volume = 7.14159 mm^3 -> delta_e ~= 7.14159 / 2.40528 ~= 2.969 mm
  let delta_e = calculate_delta_e(100.0, 0.4, 0.2, 1.75)
  inspect(delta_e > 2.9 && delta_e < 3.0, content="true")
}

///|
test "format_f3 helper" {
  inspect(format_f3(0.0), content="0.000")
  inspect(format_f3(1.2345), content="1.235")
  inspect(format_f3(10.05), content="10.050")
  inspect(format_f3(-2.5), content="-2.500")
}

///|
test "generate_gcode synthesis" {
  let config = SlicerConfig::default()
  // Create a 20x20 square layer
  let sq_pts = [
    Vec2::new(-10.0, -10.0),
    Vec2::new(10.0, -10.0),
    Vec2::new(10.0, 10.0),
    Vec2::new(-10.0, 10.0),
  ]
  let poly = Polygon2::new(sq_pts)
  let layer0 = SliceLayer::{ z: 0.2, polygons: [poly], }
  let layer1 = SliceLayer::{ z: 0.4, polygons: [poly], }

  let res = generate_gcode(
    [layer0, layer1],
    config,
    bed_center_x=100.0,
    bed_center_y=100.0,
  )

  inspect(res.total_layers, content="2")
  inspect(res.total_filament_mm > 0.0, content="true")
  inspect(res.estimated_print_time_sec > 0.0, content="true")

  // Verify key G-code commands are generated
  inspect(res.gcode.contains("G21 ; set units to millimeters"), content="true")
  inspect(res.gcode.contains("G90 ; use absolute coordinates"), content="true")
  inspect(res.gcode.contains("; LAYER: 0"), content="true")
  inspect(res.gcode.contains("; LAYER: 1"), content="true")
  inspect(res.gcode.contains("M104 S0 ; turn off hotend"), content="true")
  inspect(res.gcode.contains("M84 ; disable stepper motors"), content="true")
  inspect(res.gcode.contains("; wall 0"), content="true")
  inspect(res.gcode.contains("; infill"), content="true")
}

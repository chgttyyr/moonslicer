///|
/// MoonSlicer Command-Line Interface.

///|
fn print_usage() -> Unit {
  println("==================================================")
  println("  MoonSlicer: Pure MoonBit 3D Printing Slicer")
  println("==================================================")
  println("")
  println("Usage:")
  println("  moonslicer <subcommand> [options]")
  println("")
  println("Subcommands:")
  println(
    "  slice   Slice an STL model (ASCII or binary) into Marlin/RepRap G-code",
  )
  println(
    "  info    Inspect 3D mesh dimensions, facet count, and estimated layers",
  )
  println("  help    Show this help message")
  println("")
  println("Slice Options:")
  println("  -i <path>              Input STL file path (required)")
  println(
    "  -o <path>              Output G-code file path (default: output.gcode)",
  )
  println("  --layer-height <mm>    Layer height in millimeters (default: 0.2)")
  println("  --initial-height <mm>  First layer height in mm (default: 0.3)")
  println("  --line-width <mm>      Extrusion line width in mm (default: 0.4)")
  println("  --walls <count>        Number of perimeter walls (default: 2)")
  println("  --bottom-solid <count> Number of bottom solid layers (default: 3)")
  println("  --top-solid <count>    Number of top solid layers (default: 3)")
  println(
    "  --density <ratio>      Infill density from 0.0 to 1.0 (default: 0.2)",
  )
  println(
    "  --speed <mm/s>         Print movement speed in mm/s (default: 60.0)",
  )
  println(
    "  --solid-speed <mm/s>   Solid infill movement speed in mm/s (default: 40.0)",
  )
  println(
    "  --travel-speed <mm/s>  Travel movement speed in mm/s (default: 120.0)",
  )
  println("  --bed-x <mm>           Bed center X coordinate (default: 100.0)")
  println("  --bed-y <mm>           Bed center Y coordinate (default: 100.0)")
}

///|
fn parse_double_arg(s : String, default_val : Double) -> Double {
  let mut res = 0.0
  let mut frac = 0.0
  let mut div = 1.0
  let mut in_frac = false
  for c in s {
    if c == '.' {
      in_frac = true
    } else {
      let d = c.to_int() - '0'.to_int()
      if d >= 0 && d <= 9 {
        if in_frac {
          div = div * 10.0
          frac = frac + d.to_double() / div
        } else {
          res = res * 10.0 + d.to_double()
        }
      }
    }
  }
  if res == 0.0 && frac == 0.0 && s != "0" && s != "0.0" {
    default_val
  } else {
    res + frac
  }
}

///|
fn parse_int_arg(s : String, default_val : Int32) -> Int32 {
  let mut res = 0
  for c in s {
    let d = c.to_int() - '0'.to_int()
    if d >= 0 && d <= 9 {
      res = res * 10 + d
    }
  }
  if res == 0 && s != "0" {
    default_val
  } else {
    res
  }
}

///|
fn run_info(input_path : String) -> Unit {
  if input_path.is_empty() {
    println("Error: Missing input file. Use: moonslicer info -i <model.stl>")
    return
  }

  try {
    let bytes = @fs.read_file_to_bytes(input_path)
    println("Reading STL file: \{input_path} (\{bytes.length()} bytes)...")

    match @moonslicer.parse_stl(bytes) {
      Ok(mesh) => {
        let stats = @moonslicer.get_mesh_slice_stats(mesh)
        println("----------------------------------------")
        println("Mesh Inspection Report:")
        println("  Triangle Facets:   \{stats.triangle_count}")
        println("  Bounding Width (X):\{stats.width} mm")
        println("  Bounding Depth (Y):\{stats.depth} mm")
        println("  Bounding Height (Z):\{stats.height} mm")
        println("  Z Range:           [\{stats.min_z}, \{stats.max_z}] mm")
        println("  Estimated Layers:  \{stats.estimated_layers} (at 0.2mm)")
        println("----------------------------------------")
      }
      Err(err) => println("Error parsing STL: \{err}")
    }
  } catch {
    @fs.IOError(msg) => println("File I/O error: \{msg}")
  }
}

///|
fn run_slice(args : Array[String]) -> Unit {
  let mut input_path = ""
  let mut output_path = "output.gcode"
  let mut layer_height = 0.2
  let mut initial_height = 0.3
  let mut line_width = 0.4
  let mut walls = 2
  let mut bottom_solid = 3
  let mut top_solid = 3
  let mut density = 0.2
  let mut speed = 60.0
  let mut solid_speed = 40.0
  let mut travel_speed = 120.0
  let mut bed_x = 100.0
  let mut bed_y = 100.0

  let n = args.length()
  let mut i = 2
  while i < n {
    let arg = args[i]
    if (arg == "-i" || arg == "--input") && i + 1 < n {
      input_path = args[i + 1]
      i += 2
    } else if (arg == "-o" || arg == "--output") && i + 1 < n {
      output_path = args[i + 1]
      i += 2
    } else if arg == "--layer-height" && i + 1 < n {
      layer_height = parse_double_arg(args[i + 1], 0.2)
      i += 2
    } else if arg == "--initial-height" && i + 1 < n {
      initial_height = parse_double_arg(args[i + 1], 0.3)
      i += 2
    } else if arg == "--line-width" && i + 1 < n {
      line_width = parse_double_arg(args[i + 1], 0.4)
      i += 2
    } else if arg == "--walls" && i + 1 < n {
      walls = parse_int_arg(args[i + 1], 2)
      i += 2
    } else if arg == "--bottom-solid" && i + 1 < n {
      bottom_solid = parse_int_arg(args[i + 1], 3)
      i += 2
    } else if arg == "--top-solid" && i + 1 < n {
      top_solid = parse_int_arg(args[i + 1], 3)
      i += 2
    } else if arg == "--density" && i + 1 < n {
      density = parse_double_arg(args[i + 1], 0.2)
      i += 2
    } else if arg == "--speed" && i + 1 < n {
      speed = parse_double_arg(args[i + 1], 60.0)
      i += 2
    } else if arg == "--solid-speed" && i + 1 < n {
      solid_speed = parse_double_arg(args[i + 1], 40.0)
      i += 2
    } else if arg == "--travel-speed" && i + 1 < n {
      travel_speed = parse_double_arg(args[i + 1], 120.0)
      i += 2
    } else if arg == "--bed-x" && i + 1 < n {
      bed_x = parse_double_arg(args[i + 1], 100.0)
      i += 2
    } else if arg == "--bed-y" && i + 1 < n {
      bed_y = parse_double_arg(args[i + 1], 100.0)
      i += 2
    } else {
      i += 1
    }
  }

  if input_path.is_empty() {
    println("Error: Input file (-i <path>) is required.")
    println("Run 'moonslicer help' for usage instructions.")
    return
  }

  let mut config = @moonslicer.SlicerConfig::default()
  config = {
    ..config,
    layer_height,
    initial_layer_height: initial_height,
    line_width,
    wall_count: walls,
    bottom_solid_layers: bottom_solid,
    top_solid_layers: top_solid,
    infill_density: density,
    print_speed: speed,
    solid_infill_speed: solid_speed,
    travel_speed,
  }

  println("Loading model from: \{input_path}...")
  try {
    let bytes = @fs.read_file_to_bytes(input_path)
    println("Parsing mesh (\{bytes.length()} bytes)...")

    match @moonslicer.parse_stl(bytes) {
      Ok(mesh) => {
        let stats = @moonslicer.get_mesh_slice_stats(mesh, config~)
        println(
          "Mesh: \{stats.triangle_count} facets, \{stats.width}x\{stats.depth}x\{stats.height} mm",
        )
        println(
          "Slicing layers (height: \{layer_height} mm, infill: \{density * 100.0}%)...",
        )

        let result = @moonslicer.slice_mesh_to_gcode(
          mesh,
          config~,
          bed_center_x=bed_x,
          bed_center_y=bed_y,
        )

        println("Synthesizing G-code (\{result.total_layers} layers)...")
        @fs.write_string_to_file(output_path, result.gcode)

        println("----------------------------------------")
        println("Slicing Completed Successfully!")
        println("  Output File:        \{output_path}")
        println("  Total Layers:       \{result.total_layers}")
        println("  Collisions Resolved:\{result.total_collisions_resolved}")
        println("  Filament Extruded:  \{result.total_filament_mm} mm")
        println(
          "  Est. Print Time:    \{result.estimated_print_time_sec / 60.0} min",
        )
        println("----------------------------------------")
      }
      Err(err) => println("Error parsing STL mesh: \{err}")
    }
  } catch {
    @fs.IOError(msg) => println("File I/O error: \{msg}")
  }
}

///|
fn main {
  let args = @env.args()

  if args.length() <= 1 {
    print_usage()
    return
  }

  let subcmd = args[1]
  if subcmd == "slice" {
    run_slice(args)
  } else if subcmd == "info" {
    let mut input_path = ""
    let n = args.length()
    let mut i = 2
    while i < n {
      if (args[i] == "-i" || args[i] == "--input") && i + 1 < n {
        input_path = args[i + 1]
        i += 2
      } else {
        i += 1
      }
    }
    run_info(input_path)
  } else if subcmd == "help" || subcmd == "-h" || subcmd == "--help" {
    print_usage()
  } else {
    println("Unknown subcommand: '\{subcmd}'. Run 'moonslicer help' for usage.")
  }
}

///|
/// MoonSlicer: 3D printing slicer in pure MoonBit.
///
/// Error types, configuration parameters, and core data structures.

///|
pub(all) enum SlicerError {
  InvalidStl(String)
  IoError(String)
  EmptyMesh
  SlicingFailed(String)
} derive(Debug, Eq)

///|
pub impl Show for SlicerError with fn output(
  self : SlicerError,
  logger : &Logger,
) -> Unit {
  match self {
    InvalidStl(s) => logger.write_string("InvalidStl(" + s + ")")
    IoError(s) => logger.write_string("IoError(" + s + ")")
    EmptyMesh => logger.write_string("EmptyMesh")
    SlicingFailed(s) => logger.write_string("SlicingFailed(" + s + ")")
  }
}

///|
/// Slicing and printing configuration.
pub(all) struct SlicerConfig {
  layer_height : Double
  initial_layer_height : Double
  line_width : Double
  wall_count : Int
  infill_density : Double
  infill_angle : Double
  filament_diameter : Double
  nozzle_temp : Int
  bed_temp : Int
  print_speed : Double
  travel_speed : Double
  retract_distance : Double
  retract_speed : Double
} derive(Debug)

///|
/// Default printing profile (0.4mm nozzle, 0.2mm layer height, 2 walls, 20% infill).
pub fn SlicerConfig::default() -> SlicerConfig {
  {
    layer_height: 0.2,
    initial_layer_height: 0.28,
    line_width: 0.4,
    wall_count: 2,
    infill_density: 0.2,
    infill_angle: 45.0,
    filament_diameter: 1.75,
    nozzle_temp: 205,
    bed_temp: 60,
    print_speed: 50.0,
    travel_speed: 120.0,
    retract_distance: 1.0,
    retract_speed: 40.0,
  }
}

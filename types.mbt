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
/// PrusaSlicer-compatible surface region classification.
pub(all) enum SurfaceType {
  TopSolid
  BottomSolid
  InternalSparse
} derive(Debug, Eq)

///|
pub impl Show for SurfaceType with fn output(
  self : SurfaceType,
  logger : &Logger,
) -> Unit {
  match self {
    TopSolid => logger.write_string("TopSolid")
    BottomSolid => logger.write_string("BottomSolid")
    InternalSparse => logger.write_string("InternalSparse")
  }
}

///|
/// Slicing and printing configuration.
pub(all) struct SlicerConfig {
  layer_height : Double
  initial_layer_height : Double
  line_width : Double
  wall_count : Int32
  bottom_solid_layers : Int32
  top_solid_layers : Int32
  infill_density : Double
  infill_angle : Double
  filament_diameter : Double
  nozzle_temp : Int32
  bed_temp : Int32
  print_speed : Double
  solid_infill_speed : Double
  travel_speed : Double
  retract_distance : Double
  retract_speed : Double
} derive(Debug)

///|
/// Default printing profile (0.4mm nozzle, 0.2mm layer height, 2 walls, 3 top/bottom solid layers, 20% infill).
pub fn SlicerConfig::default() -> SlicerConfig {
  {
    layer_height: 0.2,
    initial_layer_height: 0.28,
    line_width: 0.4,
    wall_count: 2,
    bottom_solid_layers: 3,
    top_solid_layers: 3,
    infill_density: 0.2,
    infill_angle: 45.0,
    filament_diameter: 1.75,
    nozzle_temp: 205,
    bed_temp: 60,
    print_speed: 50.0,
    solid_infill_speed: 40.0,
    travel_speed: 120.0,
    retract_distance: 1.0,
    retract_speed: 40.0,
  }
}

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
/// Supported internal infill geometric patterns.
pub(all) enum InfillPattern {
  Rectilinear
  Grid
  Triangles
  Concentric
} derive(Debug, Eq)

///|
pub impl Show for InfillPattern with fn output(
  self : InfillPattern,
  logger : &Logger,
) -> Unit {
  match self {
    Rectilinear => logger.write_string("Rectilinear")
    Grid => logger.write_string("Grid")
    Triangles => logger.write_string("Triangles")
    Concentric => logger.write_string("Concentric")
  }
}

///|
/// Seam placement strategies for perimeter start vertices.
pub(all) enum SeamMode {
  Nearest
  Aligned
  SharpestCorner
  Random
} derive(Debug, Eq)

///|
pub impl Show for SeamMode with fn output(self : SeamMode, logger : &Logger) -> Unit {
  match self {
    Nearest => logger.write_string("Nearest")
    Aligned => logger.write_string("Aligned")
    SharpestCorner => logger.write_string("SharpestCorner")
    Random => logger.write_string("Random")
  }
}

///|
/// Standard 3D printing filament materials with physical density (g/cm^3).
pub(all) enum FilamentMaterial {
  PLA
  PETG
  ABS
  TPU
} derive(Debug, Eq)

///|
pub fn FilamentMaterial::density(self : FilamentMaterial) -> Double {
  match self {
    PLA => 1.24
    PETG => 1.27
    ABS => 1.04
    TPU => 1.21
  }
}

///|
pub impl Show for FilamentMaterial with fn output(
  self : FilamentMaterial,
  logger : &Logger,
) -> Unit {
  match self {
    PLA => logger.write_string("PLA")
    PETG => logger.write_string("PETG")
    ABS => logger.write_string("ABS")
    TPU => logger.write_string("TPU")
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
  infill_pattern : InfillPattern
  seam_mode : SeamMode
  material : FilamentMaterial
  filament_cost_per_kg : Double
  filament_diameter : Double
  nozzle_temp : Int32
  bed_temp : Int32
  fan_speed : Int32
  bridge_fan_speed : Int32
  bridge_speed : Double
  bridge_flow_ratio : Double
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
    infill_pattern: Rectilinear,
    seam_mode: SharpestCorner,
    material: PLA,
    filament_cost_per_kg: 100.0,
    filament_diameter: 1.75,
    nozzle_temp: 205,
    bed_temp: 60,
    fan_speed: 255,
    bridge_fan_speed: 255,
    bridge_speed: 25.0,
    bridge_flow_ratio: 0.95,
    print_speed: 50.0,
    solid_infill_speed: 40.0,
    travel_speed: 120.0,
    retract_distance: 1.0,
    retract_speed: 40.0,
  }
}

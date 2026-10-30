# MoonSlicer

<p align="center">
  <b>A Pure MoonBit 3D Printing Slicer & Toolpath Engine (Zero FFI)</b><br>
  <i>用纯 MoonBit 实现的 3D 打印切片与刀路生成引擎</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Language-MoonBit-purple.svg" alt="MoonBit">
  <img src="https://img.shields.io/badge/Architecture-Zero--FFI%20Pure%20MoonBit-brightgreen.svg" alt="Zero FFI">
  <img src="https://img.shields.io/badge/Target-Native%20%7C%20Wasm-blue.svg" alt="Targets">
  <img src="https://img.shields.io/badge/Tests-26%2F26%20Passing-success.svg" alt="Tests">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache--2.0-blue.svg" alt="License"></a>
</p>

---

## Overview

**MoonSlicer** is a modern, deterministic 3D printing slicer and toolpath generation engine implemented entirely in [MoonBit](https://www.moonbitlang.com/). It converts 3D triangle meshes (Binary and ASCII STL) into standard, print-ready G-code (Marlin / RepRap / Klipper compatible).

Designed with zero foreign function interface (FFI) bindings, MoonSlicer operates entirely within pure MoonBit memory and compiles natively to both high-performance native machine code and WebAssembly (WASM / Wasm-GC). It features an integrated computational geometry core, robust topological chaining, clearance-aware perimeter offsetting, interior-hole clipping infill, and physical volumetric extrusion modeling.

---

## Core Capabilities

- **3D Mesh Parsing & Spatial Normalization**
  - Streaming IEEE 754 single-precision float32 binary STL and ASCII STL decoder.
  - Automatic 3D Axis-Aligned Bounding Box (AABB) computation and bed centering with $Z=0$ alignment.

- **Planar Slicing & Topological Loop Stitching**
  - Triangle-plane intersection with adaptive $\epsilon$-jitter to eliminate vertex degeneracy.
  - Spatial $\epsilon$-chaining to reconstruct unordered line segments into strict, continuous closed 2D polygon boundaries.

- **ExPolygon Topological Hierarchy**
  - Jordan curve even-odd depth containment tree distinguishing exterior island contours (CCW, positive area) from nested interior holes (CW, negative area).
  - Native multi-island and multi-hole geometric representation aligned with modern slicer architectures.

- **Collision-Aware Perimeter Offsetting**
  - Normal displacement along angle bisectors with miter clamping and edge-inversion collapse checking.
  - **Pairwise Clearance Field Analysis**: Evaluates Euclidean clearance between adjacent holes and outer contours to calculate dynamic safe expansion bounds $d_{safe}$.
  - **Adaptive Offset Clamping & Wall Suppression**: Dynamically clamps perimeter expansion in narrow features and suppresses overlapping internal perimeters (`WallSuppressed`) to eliminate duplicate extrusions and nozzle collisions.
  - **Post-Offset Geometric Validation**: Exhaustive edge-crossing verification (`edges_intersect`) ensuring self-intersection-free toolpaths.

- **Cross-Layer Surface Classification**
  - Evaluates vertical geometric overlap between layer $Z_i$ and adjacent layers $Z_{i-1}$ / $Z_{i+1}$.
  - Classifies surfaces into `TopSolid` (roof), `BottomSolid` (floor / bridge), and `InternalSparse`.

- **Alternating Rectilinear Infill**
  - 45° and 135° scanline infill generation with automatic ray-polygon parity clipping.
  - Automatically suppresses infill strokes traversing interior holes and islands.
  - Enforces 100% solid density on top/bottom shells, and configurable density (e.g. 20%) on internal sparse layers.

- **Physical Volumetric Extrusion Modeling**
  - Precise extrusion calculation based on the standard stadium bead cross-section: $A = (W - H)H + \pi (H / 2)^2$.
  - Computes exact volumetric flow $V = A \times L$ and E-axis absolute feed increments.
  - Synthesizes temperature control, axis homing, layer-end retractions, and structured G-code metadata.

- **Toolpath Visualizer**
  - Lightweight, browser-based HTML5 Canvas toolpath viewer (`examples/visualizer.html`).
  - Supports layer scrubbing, animation playback, color-coded feature paths (outer perimeter, hole perimeter, inner perimeter, solid infill, sparse infill), and collision resolution tracking.

---

## Slicing Pipeline

```
+---------------------------------------------------------------+
| Input: 3D Mesh (.stl Binary / ASCII)                         |
+---------------------------------------------------------------+
                               |
                               v
+---------------------------------------------------------------+
| 1. STL Decoding & Bed Centering (center_to_bed)               |
|    Stream parser, AABB calculation, translate to bed center   |
+---------------------------------------------------------------+
                               |
                               v
+---------------------------------------------------------------+
| 2. Triangle-Plane Intersection (slice_mesh_at_z)              |
|    Linear intersection at Z = z_i with epsilon-jitter         |
+---------------------------------------------------------------+
                               |
                               v
+---------------------------------------------------------------+
| 3. Topological Loop Stitching (stitch_segments_into_loops)    |
|    Greedy epsilon-chaining into closed Polygon2 loops         |
+---------------------------------------------------------------+
                               |
                               v
+---------------------------------------------------------------+
| 4. ExPolygon Topology Tree (build_expolygons)                 |
|    Even-odd depth test: CCW Outer Islands vs CW Inner Holes   |
+---------------------------------------------------------------+
                               |
                               v
+---------------------------------------------------------------+
| 5. Clearance-Aware Offsetting (generate_expolygon_perimeters) |
|    Clearance field analysis, adaptive clamping & suppression  |
+---------------------------------------------------------------+
                               |
                               v
+---------------------------------------------------------------+
| 6. Surface Classification & Infill (infill.mbt / surface.mbt) |
|    Top/Bottom solid shells & 45°/135° parity-clipped infill   |
+---------------------------------------------------------------+
                               |
                               v
+---------------------------------------------------------------+
| 7. Volumetric G-code Synthesis (generate_gcode)               |
|    Stadium bead calculus, absolute E feed, Marlin/RepRap G10  |
+---------------------------------------------------------------+
```

---

## Project Structure

```
moonslicer/
├── types.mbt            # Slicer configuration, surface types, error definitions
├── geom.mbt             # 2D/3D vectors, segments, Polygon2, ExPolygon topology tree
├── stl.mbt              # IEEE 754 float32 decoder, Binary & ASCII STL parser
├── slice.mbt            # Triangle-plane intersection and topological loop stitching
├── offset.mbt           # Angle bisector offsetting, clearance clamping & suppression
├── surface.mbt          # Cross-layer surface classification engine
├── infill.mbt           # 45°/135° scanline infill generator with hole clipping
├── gcode.mbt            # Stadium bead calculus & Marlin/RepRap G-code synthesis
├── pipeline.mbt         # End-to-end slicing orchestrator and mesh inspection
├── cmd/main/            # CLI executable (slice / info / help)
├── fixtures/            # Standard test models (calibration cube, dual-hole collision STL, etc.)
├── examples/            # Interactive HTML5 Canvas toolpath visualizer
└── docs/                # Mathematical derivations & architecture specification
    └── architecture.md  # Comprehensive technical whitepaper
```

---

## Getting Started

### Prerequisites

- [MoonBit CLI Toolchain](https://www.moonbitlang.com/) (version `>= v0.1.20260920`)

### Building and Testing

```bash
# Static type checking
moon check

# Verify WebAssembly target compatibility
moon check --target wasm
moon check --target wasm-gc

# Execute full test suite (26 unit & integration tests)
moon test

# Format check
moon fmt --check
```

---

## Command-Line Interface (CLI)

MoonSlicer provides a standalone command-line tool supporting model inspection and toolpath slicing.

### 1. Model Inspection (`info`)

Inspect mesh vertex/facet counts, bounding box dimensions, and estimated layer counts:

```bash
moon run cmd/main -- info -i fixtures/dual_holes_collision.stl
```

Output:
```
Reading STL file: fixtures/dual_holes_collision.stl (5597 bytes)...
----------------------------------------
Mesh Inspection Report:
  Triangle Facets:   44
  Bounding Width (X):30 mm
  Bounding Depth (Y):15 mm
  Bounding Height (Z):4 mm
  Z Range:           [0, 4] mm
  Estimated Layers:  19 (at 0.2mm)
----------------------------------------
```

### 2. Slicing Model to G-code (`slice`)

Slice an STL model with customizable print parameters:

```bash
moon run cmd/main -- slice -i fixtures/dual_holes_collision.stl -o output.gcode \
  --layer-height 0.2 \
  --initial-height 0.3 \
  --line-width 0.4 \
  --walls 2 \
  --bottom-solid 3 \
  --top-solid 3 \
  --density 0.2 \
  --speed 60.0
```

Output:
```
Loading model from: fixtures/dual_holes_collision.stl...
Parsing mesh (5597 bytes)...
Mesh: 44 facets, 30x15x4 mm
Slicing layers (height: 0.2 mm, infill: 20%)...
Synthesizing G-code (19 layers)...
----------------------------------------
Slicing Completed Successfully!
  Output File:        output.gcode
  Total Layers:       19
  Collisions Resolved:38
  Filament Extruded:  298.22 mm
  Est. Print Time:    3.18 min
----------------------------------------
```

---

## Interactive Visualizer

MoonSlicer includes an out-of-the-box HTML5 Canvas toolpath visualizer located at [`examples/visualizer.html`](examples/visualizer.html).

- **Zero Dependencies**: Directly open `examples/visualizer.html` in any modern web browser without a local web server.
- **Layer-by-Layer Scrubbing**: Interactive slider to inspect individual print layers or scrub through the print progression.
- **Color-Coded Paths**:
  - Outer Perimeters: Red
  - Hole Perimeters: Orange
  - Inner Perimeters: Green
  - Solid Infill (Top & Bottom shells): Cyan
  - Internal Sparse Infill: Yellow
  - Non-print Travel Moves (G0): Dashed Gray
- **Clearance HUD**: Real-time display of active clearance events, layer height, filament consumption, and estimated print duration.

---

## Technical Specifications & Roadmap

### Supported Specifications

| Domain | Supported Feature Set |
| :--- | :--- |
| **Input Format** | Watertight 2-manifold STL (Binary IEEE 754 float32 and ASCII formats) |
| **Geometry** | Arbitrary closed planar polygons, multi-island contours, and nested multi-hole topologies |
| **Perimeters** | Inward & outward normal bisector offset with miter limit clamping, clearance clamping, and wall suppression |
| **Infill** | 45°/135° alternating rectilinear infill with automatic interior-hole parity clipping |
| **Extrusion** | Stadium bead cross-section volumetric flow calculus with absolute E coordinates |
| **Firmware** | Standard Marlin, RepRap, and Klipper compatible G-code output |

### Roadmap

- [ ] Support generation system (Tree and linear contact supports)
- [ ] Non-planar and conformal infill geometries (Gyroid, Honeycomb, Concentric)
- [ ] Curvature-based adaptive layer height
- [ ] Seam placement strategies (Rear, Sharpest Corner, Scarf Joint)
- [ ] Multi-extruder toolchanger support

---

## License

MoonSlicer is licensed under the [Apache-2.0 License](LICENSE).

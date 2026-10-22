///|
/// Helper to construct a canonical 3D cube mesh of given size.
pub fn create_cube_mesh(size : Double) -> Mesh3 {
  let triangles : Array[Triangle3] = []

  let p000 = Vec3::new(0.0, 0.0, 0.0)
  let p100 = Vec3::new(size, 0.0, 0.0)
  let p110 = Vec3::new(size, size, 0.0)
  let p010 = Vec3::new(0.0, size, 0.0)
  let p001 = Vec3::new(0.0, 0.0, size)
  let p101 = Vec3::new(size, 0.0, size)
  let p111 = Vec3::new(size, size, size)
  let p011 = Vec3::new(0.0, size, size)

  let add_quad = fn(v1 : Vec3, v2 : Vec3, v3 : Vec3, v4 : Vec3, normal : Vec3) {
    triangles.push(Triangle3::new(normal, v1, v2, v3))
    triangles.push(Triangle3::new(normal, v1, v3, v4))
  }

  // 6 faces of the cube
  let nz_neg = Vec3::new(0.0, 0.0, -1.0)
  let nz_pos = Vec3::new(0.0, 0.0, 1.0)
  let ny_neg = Vec3::new(0.0, -1.0, 0.0)
  let ny_pos = Vec3::new(0.0, 1.0, 0.0)
  let nx_neg = Vec3::new(-1.0, 0.0, 0.0)
  let nx_pos = Vec3::new(1.0, 0.0, 0.0)

  add_quad(p000, p010, p110, p100, nz_neg) // Bottom
  add_quad(p001, p101, p111, p011, nz_pos) // Top
  add_quad(p000, p100, p101, p001, ny_neg) // Front
  add_quad(p110, p010, p011, p111, ny_pos) // Back
  add_quad(p010, p000, p001, p011, nx_neg) // Left
  add_quad(p100, p110, p111, p101, nx_pos) // Right

  Mesh3::from_triangles(triangles)
}

///|
test "slice/cube_intersection_and_stitching" {
  let cube = create_cube_mesh(10.0)
  inspect(cube.triangles.length(), content="12")
  inspect(cube.bounds.width(), content="10")
  inspect(cube.bounds.height(), content="10")

  // Slice at Z = 5.0 (middle of the cube)
  let layer = slice_mesh_at_z(cube, 5.0)

  // Should reconstruct exactly 1 closed polygon boundary
  inspect(layer.polygons.length(), content="1")

  let poly = layer.polygons[0]
  // Sliced polygon should have 4 corners and area approximately 100.0
  inspect(poly.points.length() >= 4, content="true")
  let area = poly.area().abs()
  inspect(area > 99.0 && area < 101.0, content="true")
}

///|
test "slice/multi_layer_slicing" {
  let cube = create_cube_mesh(2.0)
  let mut cfg = SlicerConfig::default()
  cfg = { ..cfg, initial_layer_height: 0.5, layer_height: 0.5, }

  let layers = slice_mesh(cube, cfg)
  // Cube from 0 to 2mm with 0.5mm layer height should produce 3~4 layers
  inspect(layers.length() >= 3, content="true")
  inspect(layers[0].z, content="0.5")
}

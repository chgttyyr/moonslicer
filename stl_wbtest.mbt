///|
fn str_to_ascii_bytes(s : String) -> Bytes {
  let arr : Array[Byte] = []
  for c in s {
    arr.push(c.to_int().to_byte())
  }
  Bytes::from_array(arr[:])
}

///|
test "stl/parse_ascii_stl" {
  let ascii_str =
    #|solid test_tri
    #|  facet normal 0.0 0.0 1.0
    #|    outer loop
    #|      vertex 0.0 0.0 10.0
    #|      vertex 10.0 0.0 10.0
    #|      vertex 10.0 10.0 10.0
    #|    endloop
    #|  endfacet
    #|endsolid test_tri
  let bytes = str_to_ascii_bytes(ascii_str)
  let mesh = parse_stl(bytes).unwrap()

  inspect(mesh.triangles.length(), content="1")
  inspect(mesh.bounds.min.z, content="10")
  inspect(mesh.bounds.max.x, content="10")
  inspect(mesh.bounds.width(), content="10")
  inspect(mesh.bounds.height(), content="0")
}

///|
test "stl/parse_binary_stl" {
  // Binary STL: 80 bytes header + 4 bytes num_triangles (1) + 50 bytes triangle = 134 bytes
  let raw : Array[Byte] = Array::make(134, b'\x00')
  raw[80] = b'\x01' // 1 triangle

  // Normal: (0, 0, 1) -> nz = 1.0f at offset 84 + 8 = 92
  raw[94] = b'\x80'
  raw[95] = b'\x3f'

  // v1: (0, 0, 0)
  // v2: (20, 0, 0) -> x=20.0f at offset 84 + 24 = 108
  raw[110] = b'\xa0'
  raw[111] = b'\x41'

  // v3: (0, 30, 0) -> y=30.0f at offset 84 + 40 = 124
  raw[126] = b'\xf0'
  raw[127] = b'\x41'

  let bytes = Bytes::from_array(raw[:])
  let mesh = parse_stl(bytes).unwrap()

  inspect(mesh.triangles.length(), content="1")
  inspect(mesh.bounds.max.x, content="20")
  inspect(mesh.bounds.max.y, content="30")

  // Test center to bed
  let centered = mesh.center_to_bed()
  inspect(centered.bounds.center().x, content="0")
  inspect(centered.bounds.center().y, content="0")
  inspect(centered.bounds.min.z, content="0")
}

///|
test "end-to-end slice ascii stl" {
  let ascii_stl =
    #|solid cube
    #|  facet normal 0 0 -1
    #|    outer loop
    #|      vertex 0 0 0
    #|      vertex 0 10 0
    #|      vertex 10 10 0
    #|    endloop
    #|  endfacet
    #|  facet normal 0 0 -1
    #|    outer loop
    #|      vertex 0 0 0
    #|      vertex 10 10 0
    #|      vertex 10 0 0
    #|    endloop
    #|  endfacet
    #|  facet normal 0 0 1
    #|    outer loop
    #|      vertex 0 0 10
    #|      vertex 10 10 10
    #|      vertex 0 10 10
    #|    endloop
    #|  endfacet
    #|  facet normal 0 0 1
    #|    outer loop
    #|      vertex 0 0 10
    #|      vertex 10 0 10
    #|      vertex 10 10 10
    #|    endloop
    #|  endfacet
    #|  facet normal 0 -1 0
    #|    outer loop
    #|      vertex 0 0 0
    #|      vertex 10 0 0
    #|      vertex 10 0 10
    #|    endloop
    #|  endfacet
    #|  facet normal 0 -1 0
    #|    outer loop
    #|      vertex 0 0 0
    #|      vertex 10 0 10
    #|      vertex 0 0 10
    #|    endloop
    #|  endfacet
    #|  facet normal 0 1 0
    #|    outer loop
    #|      vertex 0 10 0
    #|      vertex 0 10 10
    #|      vertex 10 10 10
    #|    endloop
    #|  endfacet
    #|  facet normal 0 1 0
    #|    outer loop
    #|      vertex 0 10 0
    #|      vertex 10 10 10
    #|      vertex 10 10 0
    #|    endloop
    #|  endfacet
    #|  facet normal -1 0 0
    #|    outer loop
    #|      vertex 0 0 0
    #|      vertex 0 0 10
    #|      vertex 0 10 10
    #|    endloop
    #|  endfacet
    #|  facet normal -1 0 0
    #|    outer loop
    #|      vertex 0 0 0
    #|      vertex 0 10 10
    #|      vertex 0 10 0
    #|    endloop
    #|  endfacet
    #|  facet normal 1 0 0
    #|    outer loop
    #|      vertex 10 0 0
    #|      vertex 10 10 0
    #|      vertex 10 10 10
    #|    endloop
    #|  endfacet
    #|  facet normal 1 0 0
    #|    outer loop
    #|      vertex 10 0 0
    #|      vertex 10 10 10
    #|      vertex 10 0 10
    #|    endloop
    #|  endfacet
    #|endsolid cube

  let b_arr : Array[Byte] = []
  for i = 0; i < ascii_stl.length(); i = i + 1 {
    let c = ascii_stl[i]
    b_arr.push(c.to_int().to_byte())
  }
  let bytes = Bytes::from_array(b_arr)

  let mesh_res = @moonslicer.parse_stl(bytes)
  inspect(mesh_res is Ok(_), content="true")

  match mesh_res {
    Ok(mesh) => {
      let stats = @moonslicer.get_mesh_slice_stats(mesh)
      inspect(stats.triangle_count, content="12")
      inspect(stats.width, content="10")
      inspect(stats.height, content="10")

      let mut cfg = @moonslicer.SlicerConfig::default()
      cfg = { ..cfg, layer_height: 1.0, initial_layer_height: 1.0, }

      let gcode_res = @moonslicer.slice_mesh_to_gcode(mesh, config=cfg)
      inspect(gcode_res.total_layers, content="9")
      inspect(gcode_res.total_filament_mm > 0.0, content="true")
      inspect(gcode_res.gcode.contains("; LAYER: 8"), content="true")
    }
    Err(_) => ()
  }
}

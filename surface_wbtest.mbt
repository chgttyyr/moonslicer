///|
test "surface/layer_surface_classification" {
  let mut config = SlicerConfig::default()
  config = { ..config, bottom_solid_layers: 3, top_solid_layers: 3, }

  let total_layers = 10
  inspect(classify_layer(0, total_layers, config), content="BottomSolid")
  inspect(classify_layer(1, total_layers, config), content="BottomSolid")
  inspect(classify_layer(2, total_layers, config), content="BottomSolid")
  inspect(classify_layer(3, total_layers, config), content="InternalSparse")
  inspect(classify_layer(4, total_layers, config), content="InternalSparse")
  inspect(classify_layer(5, total_layers, config), content="InternalSparse")
  inspect(classify_layer(6, total_layers, config), content="InternalSparse")
  inspect(classify_layer(7, total_layers, config), content="TopSolid")
  inspect(classify_layer(8, total_layers, config), content="TopSolid")
  inspect(classify_layer(9, total_layers, config), content="TopSolid")
}

///|
test "surface/cross_layer_overhang_and_roof" {
  let mut config = SlicerConfig::default()
  config = { ..config, bottom_solid_layers: 1, top_solid_layers: 1, }

  // Layer 0: small pillar 20x20 at (0,0)
  let p0 = Polygon2::new([
    Vec2::new(-10.0, -10.0),
    Vec2::new(10.0, -10.0),
    Vec2::new(10.0, 10.0),
    Vec2::new(-10.0, 10.0),
  ])
  let ep0 = ExPolygon::new(p0)
  let layer0 = SliceLayer::new(0.2, [p0], expolygons=[ep0])

  // Layer 1: large platform 100x100 at (0,0) (extends far beyond layer 0!)
  let p1 = Polygon2::new([
    Vec2::new(-50.0, -50.0),
    Vec2::new(50.0, -50.0),
    Vec2::new(50.0, 50.0),
    Vec2::new(-50.0, 50.0),
  ])
  let ep1 = ExPolygon::new(p1)
  let layer1 = SliceLayer::new(0.4, [p1], expolygons=[ep1])

  // Layer 2: small pillar 20x20 at (0,0) (leaves platform outer regions exposed to air above!)
  let layer2 = SliceLayer::new(0.6, [p0], expolygons=[ep0])

  let layers = [layer0, layer1, layer2]

  // Test an infill segment on layer 1 that is over the overhang (e.g. at x = 30)
  let overhang_seg = Segment2::new(Vec2::new(30.0, 20.0), Vec2::new(30.0, 40.0))
  // Midpoint is (30, 30). Layer 0 does NOT cover (30, 30).
  // Therefore, this overhang segment should be classified as BottomSolid (Bridge)!
  inspect(
    classify_infill_segment(overhang_seg, 1, layers, config),
    content="BottomSolid",
  )

  // Test an infill segment in the middle at (0, 0)
  let mid_seg = Segment2::new(Vec2::new(-5.0, 0.0), Vec2::new(5.0, 0.0))
  // Midpoint is (0, 0). Covered by layer 0 below AND layer 2 above.
  inspect(
    classify_infill_segment(mid_seg, 1, layers, config),
    content="InternalSparse",
  )
}

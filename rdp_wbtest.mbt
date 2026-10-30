///|
/// Unit tests for Ramer-Douglas-Peucker (RDP) polygon simplification.

///|
test "rdp/collinear_vertex_pruning" {
  // A square where each edge is subdivided with 10 collinear points (total 40 points)
  let pts : Array[Vec2] = []

  // Bottom edge (0,0) to (10,0)
  for i = 0; i < 10; i = i + 1 {
    pts.push(Vec2::new(i.to_double(), 0.0))
  }
  // Right edge (10,0) to (10,10)
  for i = 0; i < 10; i = i + 1 {
    pts.push(Vec2::new(10.0, i.to_double()))
  }
  // Top edge (10,10) to (0,10)
  for i = 0; i < 10; i = i + 1 {
    pts.push(Vec2::new(10.0 - i.to_double(), 10.0))
  }
  // Left edge (0,10) to (0,0)
  for i = 0; i < 10; i = i + 1 {
    pts.push(Vec2::new(0.0, 10.0 - i.to_double()))
  }

  let dense_poly = Polygon2::new(pts)
  inspect(dense_poly.points.length(), content="40")

  // Simplify with tolerance = 0.05mm
  let simplified = dense_poly.simplify(0.05)

  // Collinear intermediate points should be eliminated, leaving the 4 corners
  inspect(simplified.points.length() <= 6, content="true")

  // The simplified polygon must preserve exact area
  let diff_area = (simplified.area() - 100.0).abs()
  inspect(diff_area < 0.1, content="true")
}

///|
test "rdp/submicron_jitter_noise_filtering" {
  // Line from (0,0) to (100,0) with 0.001mm jitter
  let pts : Array[Vec2] = [
    Vec2::new(0.0, 0.0),
    Vec2::new(25.0, 0.0005),
    Vec2::new(50.0, -0.0004),
    Vec2::new(75.0, 0.0003),
    Vec2::new(100.0, 0.0),
    Vec2::new(100.0, 50.0),
    Vec2::new(0.0, 50.0),
  ]
  let noisy_poly = Polygon2::new(pts)
  inspect(noisy_poly.points.length(), content="7")

  let cleaned = noisy_poly.simplify(0.01)
  // Jittered intermediate vertices within 0.01mm are stripped
  inspect(cleaned.points.length(), content="4")
}

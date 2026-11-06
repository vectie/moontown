///|
/// Rotate in the planning plane, preserving the projection's shear. The nearest
/// cardinal axis becomes parallel to the actual frontage street, at any angle.
fn frontage_axes(e : Point, n : Point, direction : Point) -> (Point, Point) {
  let det = e.x * n.y - n.x * e.y
  let u = (n.y * direction.x - n.x * direction.y) / det
  let v = (e.x * direction.y - e.y * direction.x) / det
  let angle = @math.atan2(v, u)
  let turn = angle - (angle / (@math.PI / 2)).round() * (@math.PI / 2)
  let c = @math.cos(turn)
  let s = @math.sin(turn)
  // These are directions, not graph nodes; don't quantize their angle.
  (
    { x: e.x * c + n.x * s, y: e.y * c + n.y * s, },
    { x: n.x * c - e.x * s, y: n.y * c - e.y * s, },
  )
}

///|
/// Same conservative oriented reservation as the renderer. Store the entrance
/// here so walking and painting never invent separate frontage connections.
fn frontage_entry(
  center : Point,
  e : Point,
  n : Point,
  size : Int32,
  road : Point,
) -> Point {
  let span = (size.to_double() / (e.x.abs() + n.x.abs())).min(
    size.to_double() / (e.y.abs() + n.y.abs()),
  )
  let det = e.x * n.y - n.x * e.y
  let dx = road.x - center.x
  let dy = road.y - center.y
  let u = ((n.y * dx - n.x * dy) / det / span).clamp(min=-0.5, max=0.5)
  let v = ((e.x * dy - e.y * dx) / det / span).clamp(min=-0.5, max=0.5)
  point(
    center.x + (e.x * u + n.x * v) * span,
    center.y + (e.y * u + n.y * v) * span,
  )
}

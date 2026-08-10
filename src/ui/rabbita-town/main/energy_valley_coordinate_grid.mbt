///|
/// Keep the review grid readable at every camera scale without changing the
/// underlying 256×144 world coordinate system.
fn energy_valley_coordinate_grid_spacing(zoom : Double) -> Int {
  if zoom < 0.26 {
    32
  } else if zoom < 0.75 {
    16
  } else {
    8
  }
}

///|
/// Draw a quiet isometric coordinate grid over the current map. The grid is a
/// review aid only: roads, buildings, hit testing, and world state remain the
/// same. Major intersections carry sparse `x,y` labels.
extern "js" fn golden_draw_energy_valley_coordinate_grid(
  context : @dom.CanvasRenderingContext2D,
  camera_x : Double,
  camera_y : Double,
  zoom : Double,
  viewport_width : Int,
  viewport_height : Int,
  spacing : Int,
) -> Unit =
  #| (context, cameraX, cameraY, zoom, width, height, spacing) => {
  #|   const screen = (x, y) => [
  #|     ((x - y) * 32 - cameraX) * zoom + width / 2,
  #|     ((x + y) * 16 - cameraY) * zoom + height / 2,
  #|   ];
  #|   const trace = (start, end) => {
  #|     const a = screen(start[0], start[1]);
  #|     const b = screen(end[0], end[1]);
  #|     context.beginPath();
  #|     context.moveTo(a[0], a[1]);
  #|     context.lineTo(b[0], b[1]);
  #|     context.stroke();
  #|   };
  #|   context.save();
  #|   context.lineWidth = 1;
  #|   context.setLineDash([]);
  #|   for (let x = 0; x <= 256; x += spacing) {
  #|     context.strokeStyle = x % 32 === 0
  #|       ? "rgba(35,58,51,0.14)" : "rgba(35,58,51,0.065)";
  #|     trace([x, 0], [x, 144]);
  #|   }
  #|   for (let y = 0; y <= 144; y += spacing) {
  #|     context.strokeStyle = y % 32 === 0
  #|       ? "rgba(35,58,51,0.14)" : "rgba(35,58,51,0.065)";
  #|     trace([0, y], [256, y]);
  #|   }
  #|   context.font = "700 9px ui-monospace, SFMono-Regular, monospace";
  #|   context.textAlign = "center";
  #|   context.textBaseline = "middle";
  #|   for (let x = 0; x <= 256; x += 64) {
  #|     for (let y = 0; y <= 144; y += 64) {
  #|       const point = screen(x, y);
  #|       if (point[0] < 28 || point[0] > width - 28 ||
  #|           point[1] < 18 || point[1] > height - 18) continue;
  #|       const label = `${x},${y}`;
  #|       const labelWidth = context.measureText(label).width + 8;
  #|       context.fillStyle = "rgba(246,243,232,0.78)";
  #|       context.fillRect(
  #|         point[0] - labelWidth / 2, point[1] - 7, labelWidth, 14,
  #|       );
  #|       context.fillStyle = "rgba(34,52,47,0.78)";
  #|       context.fillText(label, point[0], point[1] + 0.5);
  #|     }
  #|   }
  #|   context.restore();
  #| }

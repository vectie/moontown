///|
/// A short ground-level path joins each accepted roadside lot to its nearest
/// reviewed street. It is decoration, never a fabricated navigation edge.
/// Draw before the street pass so the path terminates cleanly at the sidewalk.
extern "js" fn town_scene_draw_lot_access(
  context : @dom.CanvasRenderingContext2D,
  x : Double,
  y : Double,
  camera_x : Double,
  camera_y : Double,
  zoom : Double,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit =
  #| (context, x, y, cameraX, cameraY, zoom, width, height) => {
  #|   const graph = globalThis.__moontownEnergyValleyCartoonRoadGraph;
  #|   if (!Array.isArray(graph?.edges)) return;
  #|   let nearest = null;
  #|   let distance = 49;
  #|   for (const edge of graph.edges) {
  #|     for (let i = 1; i < edge.pathMillis.length; i += 1) {
  #|       const a = edge.pathMillis[i - 1].map(v => v / 1000);
  #|       const b = edge.pathMillis[i].map(v => v / 1000);
  #|       const dx = b[0] - a[0], dy = b[1] - a[1];
  #|       const length2 = dx * dx + dy * dy;
  #|       const t = length2 ? Math.max(0, Math.min(1, ((x - a[0]) * dx + (y - a[1]) * dy) / length2)) : 0;
  #|       const p = [a[0] + t * dx, a[1] + t * dy];
  #|       const d = (p[0] - x) ** 2 + (p[1] - y) ** 2;
  #|       if (d < distance) { distance = d; nearest = p; }
  #|     }
  #|   }
  #|   if (!nearest) return;
  #|   context.save();
  #|   context.transform(32 * zoom, 16 * zoom, -32 * zoom, 16 * zoom,
  #|     width / 2 - cameraX * zoom, height / 2 - cameraY * zoom);
  #|   context.beginPath();
  #|   context.rect(0, 0, 256, 144);
  #|   context.clip();
  #|   context.lineCap = "butt";
  #|   context.setLineDash([]);
  #|   context.beginPath();
  #|   context.moveTo(x, y);
  #|   context.lineTo(nearest[0], nearest[1]);
  #|   context.strokeStyle = "rgba(123,136,106,0.35)";
  #|   context.lineWidth = 0.65;
  #|   context.stroke();
  #|   context.strokeStyle = "#e9e1ce";
  #|   context.lineWidth = 0.52;
  #|   context.stroke();
  #|   context.restore();
  #| }

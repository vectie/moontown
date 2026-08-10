///|
/// The checked-in road graph is the single map presentation once it validates.
/// The URL no longer selects a separate preview surface.
fn energy_valley_intersection_reference_requested() -> Bool {
  if reference_osm_block_graph_ready() {
    reference_osm_cartoon_road_graph_prepare()
  } else {
    reference_intersection_preview_graph_ready()
  }
}

///|
fn intersection_reference_kind_glyph(kind : String) -> String {
  match kind {
    "t" => "T"
    "cross" => "+"
    "complex" => "*"
    _ => ""
  }
}

///|
extern "js" fn intersection_reference_draw_marker(
  context : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  glyph : String,
  confidence : String,
) -> Unit =
  #| (context, sx, sy, glyph, confidence) => {
  #|   const cartoon = confidence === "cartoon";
  #|   const color = cartoon ? "#596b74" : confidence === "high" ? "#4f7cff" :
  #|     confidence === "medium" ? "#f59e0b" : "#d946ef";
  #|   const review = confidence === "review";
  #|   context.save();
  #|   context.beginPath();
  #|   context.arc(sx, sy, cartoon ? 4.5 : 5.2, 0, Math.PI * 2);
  #|   context.fillStyle = "rgba(255,255,255,0.94)";
  #|   context.fill();
  #|   context.beginPath();
  #|   context.arc(sx, sy, cartoon ? 3.2 : 3.9, 0, Math.PI * 2);
  #|   context.fillStyle = review ? "rgba(29,23,36,0.88)" : color;
  #|   context.fill();
  #|   context.strokeStyle = cartoon ? "rgba(44,55,60,0.88)" :
  #|     review ? color : "rgba(20,28,42,0.88)";
  #|   context.lineWidth = review ? 1.5 : 1.0;
  #|   context.stroke();
  #|   context.fillStyle = review ? color : "#101827";
  #|   context.font = `800 ${cartoon ? 6.1 : 6.6}px ui-monospace, SFMono-Regular, monospace`;
  #|   context.textAlign = "center";
  #|   context.textBaseline = "middle";
  #|   context.fillText(glyph, sx, sy + 0.2);
  #|   context.restore();
  #| }

///|
/// Projects immutable authoring points through the same camera as the normal
/// map. The overlay has no hit targets and never participates in world state.
fn intersection_reference_draw_points(
  context : @dom.CanvasRenderingContext2D,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  if !reference_intersection_snapshot_ready() {
    return
  }
  for index in 0..<reference_intersection_count() {
    let x = reference_intersection_x_millis(index).to_double() / 1000.0
    let y = reference_intersection_y_millis(index).to_double() / 1000.0
    let sx = golden_screen_x(x, y, viewport_width)
    let sy = golden_screen_y(x, y, viewport_height)
    if sx < -12.0 ||
      sx > viewport_width.to_double() + 12.0 ||
      sy < -12.0 ||
      sy > viewport_height.to_double() + 12.0 {
      continue
    }
    intersection_reference_draw_marker(
      context,
      sx,
      sy,
      intersection_reference_kind_glyph(reference_intersection_kind(index)),
      reference_intersection_confidence(index),
    )
  }
}

///|
/// Compact calibration cue over the existing HUD. Detailed provenance stays
/// in the authoring asset instead of displacing normal map controls.
fn render_intersection_reference_legend() -> @rabbita.Html {
  if !reference_intersection_snapshot_ready() {
    return div(class="intersection-reference-legend pointer-events-none", [
      span(class="intersection-reference-badge", "!"),
      span(class="intersection-reference-summary", "路口校准未加载"),
      span(class="intersection-reference-cue", "原地图不变"),
    ])
  }
  if reference_intersection_preview_graph_ready() {
    if reference_osm_block_graph_ready() {
      return div(class="intersection-reference-legend pointer-events-none", [
        span(class="intersection-reference-badge", "路"),
        span(
          class="intersection-reference-summary",
          "完整路网 · \{reference_osm_cartoon_road_junction_count()} 路口 / \{reference_osm_cartoon_road_edge_count()} 路段",
        ),
        span(
          class="intersection-reference-detail",
          "· 保留原始线路 · \{reference_osm_cartoon_road_cycle_count()} 个环路",
        ),
        span(class="intersection-reference-cue", "338 点坐标校对"),
        span(
          id="energy-valley-coordinate-readout",
          class="intersection-reference-coordinate",
          "X — · Y —",
        ),
      ])
    }
    return div(class="intersection-reference-legend pointer-events-none", [
      span(class="intersection-reference-badge", "+"),
      span(
        class="intersection-reference-summary",
        "路口路网 · \{reference_intersection_preview_node_count()} 点 / \{reference_intersection_preview_edge_count()} 段",
      ),
      span(
        class="intersection-reference-detail",
        "· 桥段 \{reference_intersection_preview_bridge_count()} · 高 \{reference_intersection_high_count()} · 中 \{reference_intersection_medium_count()} · 复核 \{reference_intersection_review_count()}（端点 \{reference_intersection_source_branch_count()}）",
      ),
      span(
        class="intersection-reference-cue",
        if reference_osm_block_graph_ready() {
          "OSM 街区路网"
        } else {
          "当前路网"
        },
      ),
      span(
        id="energy-valley-coordinate-readout",
        class="intersection-reference-coordinate",
        "X — · Y —",
      ),
    ])
  }
  div(class="intersection-reference-legend pointer-events-none", [
    span(class="intersection-reference-badge", "!"),
    span(
      class="intersection-reference-summary",
      "路网未通过校验 · 原地图 + \{reference_intersection_count()} 路口",
    ),
    span(
      class="intersection-reference-detail",
      "· 高 \{reference_intersection_high_count()} · 中 \{reference_intersection_medium_count()} · 复核 \{reference_intersection_review_count()}",
    ),
    span(class="intersection-reference-cue", "仅校准"),
    span(
      id="energy-valley-coordinate-readout",
      class="intersection-reference-coordinate",
      "X — · Y —",
    ),
  ])
}

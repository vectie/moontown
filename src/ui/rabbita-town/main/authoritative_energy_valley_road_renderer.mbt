///|
/// Conservative screen-space culling for one digest-validated transport
/// polyline. Bounds use the transport envelope's fixed one-thousandth-tile
/// units and are projected with the same isometric camera as the town canvas.
fn authoritative_energy_valley_transport_record_visible(
  minimum_x_millis : Int,
  minimum_y_millis : Int,
  maximum_x_millis : Int,
  maximum_y_millis : Int,
  camera_x : Double,
  camera_y : Double,
  zoom : Double,
  viewport_width : Int,
  viewport_height : Int,
  margin : Double,
) -> Bool {
  let minimum_x = minimum_x_millis.to_double() / 1000.0
  let minimum_y = minimum_y_millis.to_double() / 1000.0
  let maximum_x = maximum_x_millis.to_double() / 1000.0
  let maximum_y = maximum_y_millis.to_double() / 1000.0
  let screen_minimum_x = ((minimum_x - maximum_y) * 32.0 - camera_x) * zoom +
    viewport_width.to_double() / 2.0
  let screen_maximum_x = ((maximum_x - minimum_y) * 32.0 - camera_x) * zoom +
    viewport_width.to_double() / 2.0
  let screen_minimum_y = ((minimum_x + minimum_y) * 16.0 - camera_y) * zoom +
    viewport_height.to_double() / 2.0
  let screen_maximum_y = ((maximum_x + maximum_y) * 16.0 - camera_y) * zoom +
    viewport_height.to_double() / 2.0
  screen_maximum_x >= -margin &&
  screen_minimum_x <= viewport_width.to_double() + margin &&
  screen_maximum_y >= -margin &&
  screen_minimum_y <= viewport_height.to_double() + margin
}

///|
fn authoritative_energy_valley_transport_visible_indices_json(
  bridge : Bool,
  camera_x : Double,
  camera_y : Double,
  zoom : Double,
  viewport_width : Int,
  viewport_height : Int,
) -> String {
  let visible : Array[String] = []
  for index in 0..<authoritative_energy_valley_transport_record_count(bridge) {
    if authoritative_energy_valley_transport_record_visible(
        authoritative_energy_valley_transport_record_bound(bridge, index, 0),
        authoritative_energy_valley_transport_record_bound(bridge, index, 1),
        authoritative_energy_valley_transport_record_bound(bridge, index, 2),
        authoritative_energy_valley_transport_record_bound(bridge, index, 3),
        camera_x,
        camera_y,
        zoom,
        viewport_width,
        viewport_height,
        56.0,
      ) {
      visible.push(index.to_string())
    }
  }
  "[\{visible.join(",")}]"
}

///|
fn authoritative_energy_valley_transport_building_masks_json(
  buildings : Array[TownCanvasBuilding],
) -> String {
  let masks = buildings.map(building => {
    "[\{building.x},\{building.y},\{building.width},\{building.depth}]"
  })
  "[\{masks.join(",")}]"
}

///|
/// Draws casing, asphalt, and restrained markings in class passes so named
/// arterial spines remain legible over local streets. A broad overview
/// corridor bed visually joins divided carriageways without deleting their
/// exact OSM geometry. Link ramps arrive only at close zoom. Bridge ways use
/// a pale grounded deck without any floating shadow or elevation transform.
extern "js" fn golden_draw_authoritative_energy_valley_transport(
  context : @dom.CanvasRenderingContext2D,
  road_indices_json : String,
  bridge_indices_json : String,
  building_masks_json : String,
  camera_x : Double,
  camera_y : Double,
  zoom : Double,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit =
  #| (
  #|   context, roadIndicesJson, bridgeIndicesJson, buildingMasksJson,
  #|   cameraX, cameraY, zoom, viewportWidth, viewportHeight,
  #| ) => {
  #|   const transport = globalThis.__moontownEnergyValleyTransport;
  #|   if (transport?.schema !== "moontown.energy-valley.transport.v1") return;
  #|   let roadIndices;
  #|   let bridgeIndices;
  #|   let buildingMasks;
  #|   try {
  #|     roadIndices = JSON.parse(roadIndicesJson);
  #|     bridgeIndices = JSON.parse(bridgeIndicesJson);
  #|     buildingMasks = JSON.parse(buildingMasksJson);
  #|   } catch (_) {
  #|     return;
  #|   }
  #|   const toScreen = point => {
  #|     const x = point[0] / 1000;
  #|     const y = point[1] / 1000;
  #|     return [
  #|       ((x - y) * 32 - cameraX) * zoom + viewportWidth / 2,
  #|       ((x + y) * 16 - cameraY) * zoom + viewportHeight / 2,
  #|     ];
  #|   };
  #|   const trace = record => {
  #|     const points = record?.points;
  #|     if (!Array.isArray(points) || points.length < 2) return false;
  #|     const first = toScreen(points[0]);
  #|     context.beginPath();
  #|     context.moveTo(first[0], first[1]);
  #|     if (points.length === 2) {
  #|       const last = toScreen(points[1]);
  #|       context.lineTo(last[0], last[1]);
  #|       return true;
  #|     }
  #|     for (let index = 1; index < points.length - 1; index += 1) {
  #|       const current = toScreen(points[index]);
  #|       const next = toScreen(points[index + 1]);
  #|       context.quadraticCurveTo(
  #|         current[0], current[1],
  #|         (current[0] + next[0]) / 2,
  #|         (current[1] + next[1]) / 2,
  #|       );
  #|     }
  #|     const last = toScreen(points[points.length - 1]);
  #|     context.lineTo(last[0], last[1]);
  #|     return true;
  #|   };
  #|   const visibleAtZoom = record => {
  #|     if (record?.detail === "ramp" && zoom < 0.72) return false;
  #|     return record?.class === "arterial" ||
  #|       (record?.class === "collector" && zoom >= 0.60) ||
  #|       (record?.class === "local" && zoom >= 0.78);
  #|   };
  #|   const styles = {
  #|     local: {
  #|       casing: "rgba(242,240,232,0.88)", asphalt: "#879198",
  #|       casingWidth: Math.max(1.8, 3.8 * zoom),
  #|       asphaltWidth: Math.max(1.2, 2.4 * zoom),
  #|     },
  #|     collector: {
  #|       casing: "rgba(246,243,234,0.94)", asphalt: "#77848d",
  #|       casingWidth: Math.max(2.4, 5.0 * zoom),
  #|       asphaltWidth: Math.max(1.6, 3.4 * zoom),
  #|     },
  #|     arterial: {
  #|       casing: "#f5f1e7", asphalt: "#5d6f7a",
  #|       casingWidth: Math.max(4.4, 8.2 * zoom),
  #|       asphaltWidth: Math.max(2.5, 5.2 * zoom),
  #|     },
  #|   };
  #|   const regularRoads = roadIndices
  #|     .map(index => transport.displayRoads?.[index])
  #|     .filter(record => record && visibleAtZoom(record));
  #|   const bridgeRoads = bridgeIndices
  #|     .map(index => transport.bridges?.[index])
  #|     .filter(record => record && visibleAtZoom(record));
  #|   const roads = regularRoads
  #|     .concat(bridgeRoads)
  #|     .filter(record => record && visibleAtZoom(record));
  #|   context.save();
  #|   context.lineCap = "round";
  #|   context.lineJoin = "round";
  #|   // The town buildings keep their original placement. Cut their exact
  #|   // isometric footprints out of the display-only road overlay so an OSM
  #|   // stroke never shines through a transparent sprite apron.
  #|   context.beginPath();
  #|   context.rect(0, 0, viewportWidth, viewportHeight);
  #|   for (const mask of buildingMasks) {
  #|     if (!Array.isArray(mask) || mask.length !== 4) continue;
  #|     const [x, y, width, depth] = mask;
  #|     const corners = [
  #|       toScreen([x * 1000, y * 1000]),
  #|       toScreen([(x + width) * 1000, y * 1000]),
  #|       toScreen([(x + width) * 1000, (y + depth) * 1000]),
  #|       toScreen([x * 1000, (y + depth) * 1000]),
  #|     ];
  #|     context.moveTo(corners[0][0], corners[0][1]);
  #|     for (let index = 1; index < corners.length; index += 1) {
  #|       context.lineTo(corners[index][0], corners[index][1]);
  #|     }
  #|     context.closePath();
  #|   }
  #|   context.clip("evenodd");
  #|   // At overview scale, paired OSM carriageways share one calm corridor
  #|   // bed instead of reading as separate cables. Their exact centerlines
  #|   // remain visible in the asphalt pass and at closer zoom.
  #|   const overviewMainlines = regularRoads.filter(record =>
  #|     record.class === "arterial" && record.detail === "mainline"
  #|   );
  #|   if (zoom < 0.65 && overviewMainlines.length > 0) {
  #|     context.setLineDash([]);
  #|     context.strokeStyle = "rgba(247,244,235,0.96)";
  #|     context.lineWidth = Math.max(7.0, 13.5 * zoom);
  #|     for (const record of overviewMainlines) {
  #|       if (trace(record)) context.stroke();
  #|     }
  #|   }
  #|   // Bridge spans get a slightly wider pale deck, but never a translated
  #|   // shadow: the unchanged Wenyu terrain has no cadastral registration.
  #|   context.setLineDash([]);
  #|   context.strokeStyle = "rgba(252,249,240,0.98)";
  #|   for (const record of bridgeRoads) {
  #|     const style = styles[record.class] || styles.collector;
  #|     context.lineWidth = style.casingWidth + Math.max(1.4, 2.5 * zoom);
  #|     if (trace(record)) context.stroke();
  #|   }
  #|   for (const roadClass of ["local", "collector", "arterial"]) {
  #|     const style = styles[roadClass];
  #|     const records = roads.filter(record => record.class === roadClass);
  #|     context.setLineDash([]);
  #|     context.strokeStyle = style.casing;
  #|     context.lineWidth = style.casingWidth;
  #|     for (const record of records) if (trace(record)) context.stroke();
  #|     context.strokeStyle = style.asphalt;
  #|     context.lineWidth = style.asphaltWidth;
  #|     for (const record of records) if (trace(record)) context.stroke();
  #|     if (roadClass !== "local" && zoom >= 0.65) {
  #|       context.strokeStyle = "rgba(248,245,233,0.72)";
  #|       context.lineWidth = Math.max(0.55, 0.9 * zoom);
  #|       context.setLineDash([Math.max(3, 7 * zoom), Math.max(3, 7 * zoom)]);
  #|       for (const record of records) if (trace(record)) context.stroke();
  #|     }
  #|   }
  #|   context.restore();
  #| }

///|
fn golden_draw_authoritative_energy_valley_transport_overlay(
  context : @dom.CanvasRenderingContext2D,
  buildings : Array[TownCanvasBuilding],
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  if !authoritative_energy_valley_transport_ready() {
    return
  }
  let camera_x = golden_valley_camera_x()
  let camera_y = golden_valley_camera_y()
  let zoom = golden_valley_camera_zoom()
  golden_draw_authoritative_energy_valley_transport(
    context,
    authoritative_energy_valley_transport_visible_indices_json(
      false, camera_x, camera_y, zoom, viewport_width, viewport_height,
    ),
    authoritative_energy_valley_transport_visible_indices_json(
      true, camera_x, camera_y, zoom, viewport_width, viewport_height,
    ),
    authoritative_energy_valley_transport_building_masks_json(buildings),
    camera_x,
    camera_y,
    zoom,
    viewport_width,
    viewport_height,
  )
}

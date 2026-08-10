///|
extern "js" fn reference_tile_code_at(grid_x : Int, grid_y : Int) -> String =
  #| (gridX, gridY) => globalThis.__wenyuReferenceLabels?.rows?.[gridY]?.[gridX] || ""

///|
extern "js" fn reference_tile_snapshot_ready() -> Bool =
  #| () => Array.isArray(globalThis.__wenyuReferenceLabels?.rows)

///|
extern "js" fn reference_road_graph_code_at(
  grid_x : Int,
  grid_y : Int,
) -> String =
  #| (gridX, gridY) => globalThis.__wenyuReferenceRoadGraph?.rows?.[gridY]?.[gridX] || ""

///|
extern "js" fn reference_road_graph_snapshot_ready() -> Bool =
  #| () => (
  #|   globalThis.__wenyuReferenceRoadGraph?.schema ===
  #|     "moontown.wenyu_road_graph.v1" &&
  #|   Array.isArray(globalThis.__wenyuReferenceRoadGraph?.rows)
  #| )

///|
/// Presentation ranks curate the visual hierarchy without replacing the
/// semantic road rows consumed by world compilation and pathfinding.
extern "js" fn reference_road_presentation_snapshot_ready() -> Bool =
  #| () => {
  #|   const graph = globalThis.__wenyuReferenceRoadGraph;
  #|   const rows = graph?.presentationRows;
  #|   return graph?.schema === "moontown.wenyu_road_graph.v1" &&
  #|     Array.isArray(graph.rows) && graph.rows.length === 144 &&
  #|     graph.rows.every(row => typeof row === "string" && row.length === 256) &&
  #|     Array.isArray(rows) && rows.length === 144 &&
  #|     rows.every(row => typeof row === "string" &&
  #|       row.length === 256 && /^[PSA.]+$/.test(row));
  #| }

///|
extern "js" fn reference_road_presentation_code_at(
  grid_x : Int,
  grid_y : Int,
) -> String =
  #| (gridX, gridY) => globalThis.__wenyuReferenceRoadGraph
  #|   ?.presentationRows?.[gridY]?.[gridX] || ""

///|
/// Line 17 is accepted only as part of the same native-coordinate road asset.
/// Millitile integers keep the JavaScript bridge deterministic.
extern "js" fn reference_line17_snapshot_ready() -> Bool =
  #| () => {
  #|   const graph = globalThis.__wenyuReferenceRoadGraph;
  #|   const line = graph?.line17;
  #|   const inBounds = (x, y) => Number.isInteger(x) && Number.isInteger(y) &&
  #|     x >= 0 && x < 256000 && y >= 0 && y < 144000;
  #|   const validPoint = point => Array.isArray(point) && point.length === 2 &&
  #|     inBounds(point[0], point[1]);
  #|   const validExit = exit => exit && typeof exit.label === "string" &&
  #|     exit.label.length > 0 && typeof exit.destination === "string" &&
  #|     inBounds(exit.xMillis, exit.yMillis);
  #|   const validStation = station => station &&
  #|     typeof station.name === "string" && station.name.length > 0 &&
  #|     inBounds(station.xMillis, station.yMillis) &&
  #|     Array.isArray(station.exits) && station.exits.length > 0 &&
  #|     station.exits.every(validExit) && line.path.some(point =>
  #|       point[0] === station.xMillis && point[1] === station.yMillis);
  #|   return graph?.schema === "moontown.wenyu_road_graph.v1" &&
  #|     Array.isArray(graph.rows) && graph.rows.length === 144 &&
  #|     graph.rows.every(row => typeof row === "string" && row.length === 256) &&
  #|     Array.isArray(line?.path) && line.path.length >= 2 &&
  #|     line.path.every(validPoint) && Array.isArray(line.stations) &&
  #|     line.stations.length === 2 && line.stations.every(validStation) &&
  #|     new Set(line.stations.map(station => station.name)).size === 2;
  #| }

///|
extern "js" fn reference_line17_path_count() -> Int =
  #| () => globalThis.__wenyuReferenceRoadGraph?.line17?.path?.length ?? 0

///|
extern "js" fn reference_line17_path_x_millis(index : Int) -> Int =
  #| index => globalThis.__wenyuReferenceRoadGraph?.line17?.path?.[index]?.[0] ?? 0

///|
extern "js" fn reference_line17_path_y_millis(index : Int) -> Int =
  #| index => globalThis.__wenyuReferenceRoadGraph?.line17?.path?.[index]?.[1] ?? 0

///|
extern "js" fn reference_line17_station_count() -> Int =
  #| () => globalThis.__wenyuReferenceRoadGraph?.line17?.stations?.length ?? 0

///|
extern "js" fn reference_line17_station_name(index : Int) -> String =
  #| index => globalThis.__wenyuReferenceRoadGraph?.line17?.stations?.[index]
  #|   ?.name || ""

///|
extern "js" fn reference_line17_station_x_millis(index : Int) -> Int =
  #| index => globalThis.__wenyuReferenceRoadGraph?.line17?.stations?.[index]
  #|   ?.xMillis ?? 0

///|
extern "js" fn reference_line17_station_y_millis(index : Int) -> Int =
  #| index => globalThis.__wenyuReferenceRoadGraph?.line17?.stations?.[index]
  #|   ?.yMillis ?? 0

///|
extern "js" fn reference_line17_exit_count(station_index : Int) -> Int =
  #| stationIndex => globalThis.__wenyuReferenceRoadGraph?.line17
  #|   ?.stations?.[stationIndex]?.exits?.length ?? 0

///|
extern "js" fn reference_line17_exit_label(
  station_index : Int,
  exit_index : Int,
) -> String =
  #| (stationIndex, exitIndex) => globalThis.__wenyuReferenceRoadGraph?.line17
  #|   ?.stations?.[stationIndex]?.exits?.[exitIndex]?.label || ""

///|
extern "js" fn reference_line17_exit_destination(
  station_index : Int,
  exit_index : Int,
) -> String =
  #| (stationIndex, exitIndex) => globalThis.__wenyuReferenceRoadGraph?.line17
  #|   ?.stations?.[stationIndex]?.exits?.[exitIndex]?.destination || ""

///|
extern "js" fn reference_line17_exit_x_millis(
  station_index : Int,
  exit_index : Int,
) -> Int =
  #| (stationIndex, exitIndex) => globalThis.__wenyuReferenceRoadGraph?.line17
  #|   ?.stations?.[stationIndex]?.exits?.[exitIndex]?.xMillis ?? 0

///|
extern "js" fn reference_line17_exit_y_millis(
  station_index : Int,
  exit_index : Int,
) -> Int =
  #| (stationIndex, exitIndex) => globalThis.__wenyuReferenceRoadGraph?.line17
  #|   ?.stations?.[stationIndex]?.exits?.[exitIndex]?.yMillis ?? 0

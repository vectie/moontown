///|
/// The browser publishes this transport envelope only after its schema,
/// bounded geometry, forbidden-map-field, and canonical SHA-256 checks pass.
/// It is presentation authority for roads and semantic authority for Line 17;
/// the original town generator remains authority for terrain, buildings,
/// modules, parcels, and pathfinding roads.
extern "js" fn authoritative_energy_valley_transport_ready() -> Bool =
  #| () => globalThis.__moontownEnergyValleyTransport?.schema ===
  #|   "moontown.energy-valley.transport.v1"

///|
extern "js" fn authoritative_energy_valley_transport_digest() -> String =
  #| () => globalThis.__moontownEnergyValleyTransport?.payloadSha256 || ""

///|
extern "js" fn authoritative_energy_valley_transport_record_count(
  bridge : Bool,
) -> Int =
  #| bridge => {
  #|   const transport = globalThis.__moontownEnergyValleyTransport;
  #|   if (transport?.schema !== "moontown.energy-valley.transport.v1") return 0;
  #|   return (bridge ? transport.bridges : transport.displayRoads)?.length ?? 0;
  #| }

///|
extern "js" fn authoritative_energy_valley_transport_record_bound(
  bridge : Bool,
  index : Int,
  bound_index : Int,
) -> Int =
  #| (bridge, index, boundIndex) => {
  #|   const transport = globalThis.__moontownEnergyValleyTransport;
  #|   if (transport?.schema !== "moontown.energy-valley.transport.v1") return -1;
  #|   const records = bridge ? transport.bridges : transport.displayRoads;
  #|   return records?.[index]?.bounds?.[boundIndex] ?? -1;
  #| }

///|
extern "js" fn authoritative_energy_valley_metro_path_count() -> Int =
  #| () => globalThis.__moontownEnergyValleyTransport?.schema ===
  #|   "moontown.energy-valley.transport.v1"
  #|     ? globalThis.__moontownEnergyValleyTransport.metro?.path?.length ?? 0
  #|     : 0

///|
extern "js" fn authoritative_energy_valley_metro_path_x(index : Int) -> Int =
  #| index => globalThis.__moontownEnergyValleyTransport?.schema ===
  #|   "moontown.energy-valley.transport.v1"
  #|     ? globalThis.__moontownEnergyValleyTransport.metro?.path?.[index]?.[0] ?? 0
  #|     : 0

///|
extern "js" fn authoritative_energy_valley_metro_path_y(index : Int) -> Int =
  #| index => globalThis.__moontownEnergyValleyTransport?.schema ===
  #|   "moontown.energy-valley.transport.v1"
  #|     ? globalThis.__moontownEnergyValleyTransport.metro?.path?.[index]?.[1] ?? 0
  #|     : 0

///|
extern "js" fn authoritative_energy_valley_metro_station_count() -> Int =
  #| () => globalThis.__moontownEnergyValleyTransport?.schema ===
  #|   "moontown.energy-valley.transport.v1"
  #|     ? globalThis.__moontownEnergyValleyTransport.metro?.stations?.length ?? 0
  #|     : 0

///|
extern "js" fn authoritative_energy_valley_metro_station_name(
  index : Int,
) -> String =
  #| index => globalThis.__moontownEnergyValleyTransport?.schema ===
  #|   "moontown.energy-valley.transport.v1"
  #|     ? globalThis.__moontownEnergyValleyTransport.metro?.stations?.[index]?.name || ""
  #|     : ""

///|
extern "js" fn authoritative_energy_valley_metro_station_x(index : Int) -> Int =
  #| index => globalThis.__moontownEnergyValleyTransport?.schema ===
  #|   "moontown.energy-valley.transport.v1"
  #|     ? globalThis.__moontownEnergyValleyTransport.metro?.stations?.[index]?.xMillis ?? 0
  #|     : 0

///|
extern "js" fn authoritative_energy_valley_metro_station_y(index : Int) -> Int =
  #| index => globalThis.__moontownEnergyValleyTransport?.schema ===
  #|   "moontown.energy-valley.transport.v1"
  #|     ? globalThis.__moontownEnergyValleyTransport.metro?.stations?.[index]?.yMillis ?? 0
  #|     : 0

///|
extern "js" fn authoritative_energy_valley_metro_exit_count(
  station_index : Int,
) -> Int =
  #| stationIndex => globalThis.__moontownEnergyValleyTransport?.schema ===
  #|   "moontown.energy-valley.transport.v1"
  #|     ? globalThis.__moontownEnergyValleyTransport.metro?.stations?.[stationIndex]?.exits?.length ?? 0
  #|     : 0

///|
extern "js" fn authoritative_energy_valley_metro_exit_label(
  station_index : Int,
  exit_index : Int,
) -> String =
  #| (stationIndex, exitIndex) => globalThis.__moontownEnergyValleyTransport?.schema ===
  #|   "moontown.energy-valley.transport.v1"
  #|     ? globalThis.__moontownEnergyValleyTransport.metro?.stations?.[stationIndex]?.exits?.[exitIndex]?.label || ""
  #|     : ""

///|
extern "js" fn authoritative_energy_valley_metro_exit_destination(
  station_index : Int,
  exit_index : Int,
) -> String =
  #| (stationIndex, exitIndex) => globalThis.__moontownEnergyValleyTransport?.schema ===
  #|   "moontown.energy-valley.transport.v1"
  #|     ? globalThis.__moontownEnergyValleyTransport.metro?.stations?.[stationIndex]?.exits?.[exitIndex]?.destination || ""
  #|     : ""

///|
extern "js" fn authoritative_energy_valley_metro_exit_x(
  station_index : Int,
  exit_index : Int,
) -> Int =
  #| (stationIndex, exitIndex) => globalThis.__moontownEnergyValleyTransport?.schema ===
  #|   "moontown.energy-valley.transport.v1"
  #|     ? globalThis.__moontownEnergyValleyTransport.metro?.stations?.[stationIndex]?.exits?.[exitIndex]?.xMillis ?? 0
  #|     : 0

///|
extern "js" fn authoritative_energy_valley_metro_exit_y(
  station_index : Int,
  exit_index : Int,
) -> Int =
  #| (stationIndex, exitIndex) => globalThis.__moontownEnergyValleyTransport?.schema ===
  #|   "moontown.energy-valley.transport.v1"
  #|     ? globalThis.__moontownEnergyValleyTransport.metro?.stations?.[stationIndex]?.exits?.[exitIndex]?.yMillis ?? 0
  #|     : 0

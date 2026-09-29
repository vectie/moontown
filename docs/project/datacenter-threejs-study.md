# MoonTown data-center explorer

Built 2026-09-08, on `main`. Standalone review surface:
`http://127.0.0.1:17843/datacenter.html`.

This rebuild is a new Three.js study, not a replacement deployment of the town's
existing underground route. The town, landmark studies and office interior remain
available. Review the spatial model before integrating it into the town journey.

## What is implemented

- Five independently orbitable scales: campus, machine hall, 42U rack, open 2U
  server, motherboard. Breadcrumb navigation, selected rack/U context, pointer
  picking, keyboard camera controls, reverse/top/reset views and selective labels.
- A campus with a glazed front, canopy, standing-seam roof, landscaping, external
  cooling plant, electrical equipment and standby generator.
- A contained cold aisle with two inward-facing six-rack rows, hot-side circulation,
  overhead ladder trays, CRAH units, electrical cabinets and a network area.
- Rack-unit divisions, twelve selectable 2U chassis per rack, two 1U ToR switches,
  blanking panels, rear patch leads and two vertical power distribution strips.
- Open server chassis, eight front drive carriers, storage backplane, six fan
  modules, two PSUs, PCB, two CPU packages and removable finned heatsinks,
  sixteen DIMMs, VRM components, generic PCIe accelerator, NIC and M.2 device.
- Model-authored signal, electrical, cooling-medium and heat paths. User-controlled
  playback, pause, per-path explanations and reduced-motion behavior. Paths are
  schematic overlays visible through objects, not installed cable routing.
- Deterministic planning totals, a load scenario slider, per-rack capacity table,
  JSON/CSV report preview, download/copy options and a printable report.
- Existing compute-room contract ingestion via explicit same-origin GET or local
  file selection, with schema/authority validation, bounded parsing, allowlisted
  output, observation times, stale labels and unavailable-service handling.

All geometry is a presentation-scale concept, not a surveyed building, a vendor
CAD replica or a construction-ready layout. Component spacing is simplified for
legibility. Moving the heatsinks is an exploded illustration; flow paths continue
to represent the assembled configuration. The generator is standby and is not
animated as an active normal power source.

## What the existing system actually provides

Inspected `src/cmd/desktop_server/compute_room_projection.mbt`, the read-only
`GET /secret-compute-room.json` route, the Rabbita compute-room parser and sibling
LunaNexa's README and observability types.

- MoonTown projects LunaNexa node state, accelerator count, architecture,
  total/free accelerator memory and running deployment count. These are not CPU
  utilization, system RAM or measured facility power.
- MoonGate contributes gateway reachability, model count and evidence that a
  provider route was observed. An observed route is not evidence of an active job.
- The current node alias is based on array order (`local-node-1`, etc.). It is not
  safe as a persistent physical asset ID. This viewer intentionally does not bind
  those aliases to A1/B1 or a rack slot.
- Physical location, CPU/board inventory, electrical meters, inlet temperature,
  fan telemetry, water measurements, network counters and time-series history are
  absent from the consumed projection. The UI leaves these unavailable.
- LunaNexa observability owns bounded operational events/counters and external
  export readiness; it does not make the MoonTown projection a physical sensor feed.

No credentials, addresses, node commands, deployment controls or provider tokens
were added to the browser. The static preview has no live compute endpoint;
404 is an expected, explicitly explained state. Snapshot import stays in memory
and is not uploaded or persisted. Remote providers stay in the logical service
list; no Codex/DeepSeek/GLM/Kimi rack location is fabricated.

## Architecture and arithmetic

The nested `src/ui/landmark-studio` MoonBit module owns the model vocabulary,
geometry, flow definitions, planning arithmetic and snapshot validation. The
JavaScript modules are Three.js/DOM/HTTP/file adapters. Three.js remains the
existing pinned local 0.180.0 distribution; no new CDN or runtime dependency.

New public APIs are `data_center_study`, `data_center_report` and
`data_center_observation`. Other exported studies remain unchanged.

Planning scenario, explicitly not telemetry:

```
12 racks × (12 servers × 2U + 2 leaf switches × 1U) = 312 / 504 U
server W = 180 + 420 × workload_scenario_fraction
rack kW = (12 × server_W + 120) / 1000
rack IT kW = 12 × rack_kW
planning headroom = 96 kW - rack_IT_kW
```

At 60% the result is 63.648 kW and 32.352 kW of planning headroom. At 100%
it is 87.84 kW and 8.16 kW. These figures exclude spine switches, cooling,
UPS losses and ancillary facility loads. They are neither facility power nor a
validated redundancy/failover calculation. PUE, temperatures and throughput are
null; no invented time series, operating cost or carbon claim.

Reports distinguish report generation, snapshot receipt and source observation
times. CSV has units/provenance; text cells are protected against spreadsheet
formula interpretation. Unknown imported fields are never echoed into reports.

## Research basis

- [US DOE, Best Practices Guide for Energy-Efficient Data Center Design (2024)](https://www.energy.gov/cmei/femp/articles/best-practices-guide-energy-efficient-data-center-design):
  informed the separation of cold supply, rack exhaust, air-side heat exchange and
  facility cooling. Its energy-metrics section supports withholding PUE without
  matched facility and IT energy over a stated measurement period.
- [Dell PowerEdge R760 service manual, Inside the system](https://www.dell.com/support/manuals/en-us/poweredge-r760/per760_ism_pub/inside-the-system?guid=guid-043d9f52-a16e-4494-a65a-128c47fd4ea4&lang=en-us):
  component-location reference for a conventional rack server. The resulting model
  is generic, not a dimensional or electrical reproduction of an R760.
- [Cisco, Massively Scalable Data Center Network Fabric Design](https://www.cisco.com/c/en/us/products/collateral/switches/nexus-9000-series-switches/white-paper-c11-743245.html):
  informed leaf/spine and east-west traffic explanations. MoonGate remains a
  logical request boundary, distinct from the physical switching fabric.

## Verification and known limitations

- Nested module: `moon check`, `moon test` (17 passed), `moon info`, `moon fmt`,
  release JS build and the existing `.mbtx` assembler.
- Tests cover scale identities, entity/layer consistency, nondegenerate paths,
  positive finite geometry, mirrored rack front directions, rack/server counts,
  deterministic power arithmetic, missing telemetry, malformed snapshots, wrong
  authority, invalid memory totals and stripping unapproved fields.
- Browser reviewed all five scales, A3 → U7–8 navigation, motherboard explosion,
  flow play/pause, orbit/reset, 60%/100% estimates, missing endpoint, and a clearly
  synthetic stale snapshot with no physical binding.
- Verified JSON and CSV content via the visible export dialog. The in-app browser
  did not confirm a Blob download event, so download completion is not claimed.
  Preview/copy is the fallback. Native printing and physical-device touch input
  have not been verified.
- Responsive layout reviewed at 390×844 and normal 1280×720; temporary viewport
  override restored. Browser error log was clear before the expected endpoint 404.
- No production backend deployment, live sensor test, fault injection, CFD,
  circuit simulation, cooling sizing or electrical safety certification.

## Before town / real-machine integration

1. Approve this visual direction, then mount the explorer under the town's
   underground navigation on the same authenticated origin. Preserve the existing
   read-only server projection; do not put LunaNexa operator tokens in JS.
2. Add an explicitly approved stable asset/placement contract: facility → room →
   row → rack → U range → chassis asset ID. Report unassigned hardware honestly.
3. Map model parts to manufacturer/inventory evidence instead of assuming every
   local machine has this generic server topology. Remote API hardware stays opaque.
4. Add allowlisted metrics with units, timestamps, source, validity window and
   missing/stale states. Facility/BMS/PDU data and node/BMC metrics need distinct
   authorities and verified physical mappings.
5. Only animate live work after a trace/event contract links an actual workload to
   a routing decision and stable node identity. Keep educational overlays available
   as a separate mode. Do not derive packets, wattage or temperatures from motion.

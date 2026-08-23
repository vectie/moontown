# MoonTown Secret Compute Room

## Product intent

The Secret Compute Room is MoonTown's second spatial layer beneath the civic
town. It answers one operator question:

> Which agents can use which governed compute, and what is actually ready now?

The room is a read-only, redacted projection. “Secret” means low-visibility
infrastructure context intended for an access-controlled operator experience;
it does not mean hidden governance. The first version is protected by the
desktop service's localhost boundary and redaction, not by a new room-specific
account entitlement.
The UI therefore keeps the authority boundary, evidence freshness, and claim
ceiling visible at all times.

## Boundary

```text
MoonTown agents
    |
    | governed request; no provider credential
    v
MoonGate
    |---------------------------|
    |                           |
    v                           v
LunaNexa adapter            External providers
local model service         Codex/OpenAI, DeepSeek, GLM, Kimi
    |
    v
LunaNexa controller
    |
    v
redacted local nodes
```

- **MoonTown** owns the spatial explanation and joins live town agents with a
  safe infrastructure projection. It does not schedule GPU work.
- **MoonGate** owns provider routing, credentials, usage accounting, health,
  failover, and verified application bindings.
- **LunaNexa** owns node inventory, health, capacity, model deployment,
  scheduling, telemetry, and its node-agent protocol.
- **Agents** receive no node address, provider credential, runtime path, SSH
  access, or direct control-plane authority.

The target architecture lets MoonGate choose a LunaNexa-backed local service or
an external provider through one provider-neutral route. The first MoonTown
projection reads the two control-plane summaries separately because LunaNexa's
MoonGate adapter is not yet available; the UI still places MoonGate as the
mandatory agent boundary and does not claim a local execution receipt.

## What was learned from LunaNexa

LunaNexa is a model-as-a-service control plane, not a MoonSuite application
runtime. Its important invariants are:

- GPU nodes contain no MoonTown, MoonDesk, MoonBook, agent, product credential,
  or product policy.
- The node agent reports inventory and heartbeat, verifies signed assignments,
  manages approved runtimes and artifacts, and does not expose an arbitrary
  managed remote shell.
- Placement first applies hard constraints—health, architecture, memory,
  runtime, licence and data class—then deterministic scoring such as warm model,
  memory headroom, queue depth, reliability and utilization.
- Public results must not leak node addresses, paths, credentials, internal
  topology or container identity.
- The four DGX Spark machines are independent schedulable nodes. The controller
  sits outside those GPU nodes.

The room therefore projects only:

- a generated local alias;
- lifecycle state and freshness;
- accelerator architecture and count;
- total/free accelerator memory;
- aggregate running-workload count;
- aggregate device health.

Raw `node_id`, `device_id`, signature, deployment identity, hostname, address,
endpoint, path and credential reference are discarded server-side.

## What was learned from MoonGate

MoonGate distinguishes facts that an infrastructure visualization must not
collapse:

1. a provider is saved and enabled;
2. a provider passed a real upstream test;
3. a provider is selected for a request type;
4. an application binding was written and read back;
5. a routed execution produced a receipt.

“Selected” does not mean “connected,” and a fixture is never live-provider
evidence. The room currently marks a remote family **observed** only when
MoonGate reports a matching active target or model. Otherwise it says
**not observed**, even when MoonGate itself is reachable.

Codex is presented as “Codex / OpenAI” because Codex is an application/client
route rather than a provider brand in every deployment. DeepSeek, GLM and Kimi
are route families, not hard-coded online services.

## Projection contract

The desktop service exposes `GET /secret-compute-room.json` with schema
`moontown.secret-compute-room.v1`. The browser refreshes it with the existing
runtime snapshot loop. The contract contains:

- `authority`: fixed MoonGate and LunaNexa boundaries plus the read-only claim;
- `gateway`: reachability, redacted active-target labels and model count;
- `local_cluster`: configuration state and redacted machine summaries;
- `remote_routes`: requested provider families and their observed evidence;
- `observed_at`: projection freshness.

Malformed, oversized, or authority-drifting browser projections fail closed to
an unavailable state.

## Connecting a real LunaNexa control plane

The MoonTown desktop service accepts two server-only environment variables:

```text
MOONTOWN_LUNANEXA_ENDPOINT=https://trusted-controller.example
MOONTOWN_LUNANEXA_OPERATOR_TOKEN=<protected operator token>
```

Plain HTTP is accepted only for exact loopback hosts (`127.0.0.1` or
`localhost`). The token is sent only from the native desktop service to
LunaNexa's authenticated `GET /v1/nodes` endpoint. It is never serialized into
the browser projection.

This is an integration bridge, not the final least-privilege design. The next
LunaNexa contract should add a dedicated read-only, redacted fleet-projection
authority so MoonTown does not need an operator token.

MoonGate discovery reuses `.moonsuite/suite-status.json` and falls back to its
documented loopback port. No provider credential enters MoonTown.

## UI method

The room is a spatial topology with a parallel textual reading order:

1. live town agents;
2. central MoonGate boundary;
3. LunaNexa local machines;
4. MoonGate remote route families;
5. selected evidence and freshness.

Network diagrams have poor inherent accessibility, so every node is also a
keyboard-focusable row with a text state. Status never relies on color alone.
The mobile layout becomes a vertical evidence list, and motion is removed under
`prefers-reduced-motion`.

The visual language is inherited from the outdoor town rather than introduced
as a separate operations-dashboard theme. Indoor and underground use the same
late-morning spring palette, warm civic whites, blue-grey outlines, matte
two-value isometric faces, soft directional shadows, and outdoor resident
sprite family. Underground lowers the brightness through masonry and earth
tones, but it does not become neon, glossy, or cyberpunk.

The underground background establishes a physical room before the semantic
equipment is placed: an excavated rock canopy, structural ceiling beam, warm
work lights, supply and return pipes, ventilation, masonry wall panels,
supporting columns, an isometric service floor, and a cable trench. These are
renderer-owned architectural context. They explain why this is below the town
and make the racks, MoonGate plinth, remote wall, and Agent consoles read as
objects sharing one place rather than cards floating in a panel.

## Semantic scene mapping

Indoor and underground are graphical world scenes, not dashboard metaphors.
Every meaningful visible object is projected from an authoritative entity:

- the indoor room shell is the compiled `Place` and retains its stable ID;
- doors are `EntrancePortal` records, including the contract's primary flag;
- furnished work, meeting, exchange, exhibit, service, stage, bench, and gate
  zones are `InteractionSlot` records. Furniture shape is selected from
  `InteractionKind`. Position starts from the slot's `WorldPoint`; when civic
  map slots intentionally share a point, the renderer blends that point with a
  deterministic kind-specific furnishing bay so real objects remain separately
  visible rather than painting over one another;
- visible indoor Agents are `ActorPresence` records joined to `ActorProfile`;
  they only appear at the slot named by `interaction_slot_id`;
- underground Agent consoles are active `EnergyValleyRuntimeAgent` records;
- rack units are reported `SecretComputeMachine` records from LunaNexa;
- remote wall ports are `SecretComputeRemoteRoute` records from MoonGate;
- the central governed plinth is the fixed MoonGate authority boundary.

Walls, excavated rock, structural columns, pipes, ventilation, floor grids,
lighting, service trenches, cable trays, and vacant rack frames are
renderer-owned structure. Authored furniture form is selected by a real
`InteractionSlot`, so it has no independent identity beyond that slot. A vacant
rack means physical capacity only; a `SecretComputeMachine` replaces that frame
with an occupied rack and is the sole authority for installed server units.
These distinctions are explicitly identified in the UI, and structural objects
must never be counted, selected, or reported as system entities. Empty scenes
remain operationally empty instead of being filled with decorative Agents or
servers.

## Three spatial layers

MoonTown treats location as an explicit three-plane state instead of a
collection of overlapping panels:

1. **Outdoor** is the town map, building entrances, streets, and cross-building
   Agent movement.
2. **Indoor** is a complete building floor with contract-backed interaction
   slots, actual inside presences, current building work, and cross-building
   handoff summaries.
3. **Underground** is the secret compute room and its governed infrastructure
   projection.

Selecting a building still opens the quick inspector. `Enter indoor` then
changes the spatial layer. A secured lift inside the building opens the compute
room through MoonGate; closing it returns to the same building rather than
losing the user's location. The URL mirrors durable location with
`?layer=indoor&building=<civic-id>` or `?layer=compute`.

## UI verification status

The three-plane journey has focused MoonBit coverage for entering a building,
showing real inside presences and building work, opening the secured lift, and
returning from underground to the same building. The compiled MoonBit browser
product was exercised through the real desktop service at 1440×900 and 400×900.

The live policy-hall check rendered all five contract-backed furnishing slots
as separate authored objects and joined current `ActorPresence` records to
their assigned slots. The live underground projection rendered MoonGate, all
four remote route families, and four visibly vacant physical rack bays. It
correctly rendered no occupied LunaNexa racks or runtime Agent consoles because
the checked projection reported none; fixture-backed MoonBit tests cover the
populated machine and Agent variants without weakening that claim ceiling.
Both mobile world canvases retain the same scene rather than turning into a
card diagram. The account navigation is horizontally scrollable at the narrow
breakpoint, and the underground title, status, exit action, room, roster, and
evidence remain in a stable reading order.

The release assembler and verifier require both structural room plates and all
three prop assets. The assembled product contains 273 deterministic files and
is 68.0 MiB under the narrowly raised 69 MiB ceiling. The older empty-`#app`
bootstrap stall did not reproduce
in this pass: direct indoor and compute URLs both mounted the compiled MoonBit
UI and refreshed their projections.

## Non-goals

The room does not:

- expose or edit credentials;
- offer SSH, shell, terminal or arbitrary command execution;
- bind an agent directly to a node or provider;
- claim a provider test from local form validation;
- claim a local or remote execution without a receipt;
- perform LunaNexa placement or MoonGate routing in the browser;
- reveal raw infrastructure topology.

## Next contracts

1. Add a LunaNexa read-only redacted fleet projection and scoped monitor token.
2. Add the MoonGate LunaNexa provider adapter so local and remote execution use
   the same provider-neutral request contract.
3. Emit a route receipt joining `agent_run_id`, MoonGate route decision,
   provider family, optional opaque LunaNexa placement receipt, and freshness.
4. Add an account entitlement such as `compute.infrastructure.view`; enforce it
   both on the room entry and the projection endpoint.
5. Add stale thresholds and historical utilization only after the controller
   exposes trustworthy, bounded telemetry summaries.

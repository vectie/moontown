# Pack–Town bridge

The Pack–Town bridge is the narrow interoperability boundary between activated
MoonSuite domain packs and MoonTown. It does not define a universal domain
model and it does not make MoonTown the owner of pack workflows.

## Direction one: pack projection

An activated pack may publish `moontown.pack-projection.v1`. The pack declares
the `moontown-pack-projection@1.0.0` provider port in its host activation
projection so MoonTown can discover the projection without product-name
branching. Each projected
subject keeps its pack-owned schema identifier and arbitrary domain payload,
while exposing only the shared metadata MoonTown needs to place, filter,
inspect, relate, and select it. Operation identifiers must resolve exactly
against the pack's `moonsuite.pack-host-activation.v1` projection.

The projection is read-only. Selecting an operation does not execute it and
does not grant its authority. MoonGate and MoonFlow remain responsible for
authority resolution and execution.

## Direction two: town candidate intake

MoonTown may offer `moontown.pack-candidate-intake.v1` to an exact operation of
an activated pack. That operation must explicitly accept the
`town-pack-candidate` input schema and cannot have external-effect or
physical-effect authority. A candidate preserves its town origin, author,
rationale, evidence, and bounded claim ceiling. Successful conformance resolves
a route; it does not create a pack record or authorize the operation.

An adopting pack therefore adds the shared `town-pack-candidate` schema to its
manifest, declares one pack-owned intake tool using that input schema, and
declares the `moontown-pack-projection@1.0.0` provider port when it publishes
town subjects. Existing domain tools keep their native input schemas.

This preserves MoonTown's bottom-up method:

1. an idea or signal emerges in the town;
2. the town records a candidate with provenance;
3. an activated pack validates and reviews the candidate using its own domain
   rules;
4. any accepted workflow executes through MoonFlow and MoonGate;
5. the pack projects progress, evidence, and outcomes back into the town.

## Ownership

- Packs own domain schemas, payloads, lifecycle meaning, and operations.
- MoonLib owns pack declarations and host activation contracts.
- MoonTown owns the projection and candidate envelopes plus their civic claim
  ceiling.
- MoonDesk may author and inspect these declarations without becoming the
  domain owner.

## Common lifecycle

The host records two deliberately small state machines. Pack adoption moves
through `draft → validated → installed → active → projecting`; rejected or
failed projections move an active pack to `degraded`, and a verified recovery
returns it to `projecting`. Candidate promotion moves through
`submitted → routed → review-pending → accepted | rejected | withdrawn |
blocked`. Events use stable identities and repeated events are idempotent.

Runtime state is persisted atomically. Loading an older v1 state adds newly
introduced collection fields without discarding projections, lifecycle events,
or candidate receipts. Candidate identities are bound to both their route and
their original envelope, preventing a later submission from silently changing
the payload behind an existing receipt.

The desktop runtime exposes three localhost, same-origin endpoints:

- `GET /api/pack-bridge` discovers active bridge-ready packs and returns their
  capabilities, lifecycles, projections, and candidate receipts.
- `POST /api/pack-bridge/projections` validates and reconciles a pack-owned
  projection.
- `POST /api/pack-bridge/candidates` validates and routes a town candidate into
  the declared reviewed intake operation.

The Pack Layers panel consumes this snapshot as a fused visualization. Layers
can be selected independently, but operation selection remains explanatory;
execution authority stays in the owning pack's reviewed workflow.

## Adoption surface

MoonDesk Pack Studio supplies one lifecycle surface for new and existing packs:
inspect, create, adopt the bridge contracts, install, activate, deactivate, and
catalog. Its mutation boundary is an explicit native command with caller-
supplied workspace, authority grants, and runtime extensions. Existing manifest
extension fields are preserved during bridge adoption.

The first adopted packs are MoonPoly, MoonFind, MoonFish, and MoonCast. Each
keeps its domain model and algorithms, adds a typed local adapter, publishes
only a bounded projection, and declares exactly one reviewed candidate-intake
operation. This is shared lifecycle infrastructure, not a generalized domain
engine.

## Conformance proof

Contract tests exercise policy and media objects through the same bridge.
Runtime integration tests install a real fixture through MoonLib, discover its
capabilities, ingest a projection, route a reviewed bottom-up candidate, reload
the durable state, and migrate an older v1 state. The four production packs
also carry pack-owned typed adapter tests. Their payloads and schemas remain
different; only activation, discovery, routing, reconciliation, and lifecycle
receipts are shared.

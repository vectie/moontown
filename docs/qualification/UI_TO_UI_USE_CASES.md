# MoonTown UI-to-UI qualification

Last reviewed: 2026-07-31

MoonTown's published operator application is the interactive Rabbita Energy
Valley canvas:

```text
entrypoint id: energy-valley
service path:  /index.html?seed=20260727
default port:  17842
```

MoonTown coordinates participant books and owns civic synthesis receipts. It
does not own research truth, provider/model routing, or final acceptance.
MoonClaw is the only agent runtime. A completed salon remains pending
named-human review until MoonFind, MoonChat, and MoonBook process their own
typed stages.

## Prerequisites and launch

```sh
export MT_REPO=/Users/kq/Workspace/moontown
export MF_QUAL="${MF_QUAL:-$(mktemp -d /tmp/moonsuite-research-ui-qualification.XXXXXX)}"

cd "$MT_REPO"
./scripts/build-rabbita-ui.sh

MOONSUITE_ROOT="$MF_QUAL/suite" \
MOONTOWN_DESKTOP_STATIC_ROOT="$MT_REPO/src/ui/rabbita-town/dist" \
MOONTOWN_MOONFIND_CALLBACK_URL="http://127.0.0.1:4313/api/v1/moontown/result" \
moon run src/cmd/desktop_server
```

For MT-02, reuse the exact `MF_QUAL` exported by MoonFind rather than creating
an empty standalone workspace.

Only one process may own port `17842`. Open the canonical canvas with the
deterministic Wenyu reference seed:

```text
http://127.0.0.1:17842/index.html?seed=20260727
```

Use `/index.html?seed=20260727` in every qualification record. The bare
`/viewport.html` path is only a compatibility alias to the same canvas;
`v=wenyu`, `v=wenyu-modules`, and `surface=legacy-viewport` are retired labels
with no routing effect. There is no second raster product surface.

## MT-01 — operate the Energy Valley canvas

1. Open the URL above.
2. Confirm the accessible map label is **能源谷可交互等距地图** and the town
   badge identifies **MoonTown · 能源谷**.
3. Confirm the canonical seed label is stable after reload.
4. Change the simulation speed, weather mode, and selected tool; confirm each
   control updates without creating a civic job.
5. Select a civic building and inspect its live work/telemetry projection.
6. Open **看板**, inspect current runtime state, then return to the same map.
7. Confirm stale/blocked runtime truth remains visible without being converted
   into inferred progress.

Expected visible result:

- the full-screen procedural Wenyu canvas is the primary surface;
- roads, water, parcels, civic buildings, residents, and work projections share
  one navigable map;
- simulation and authoring controls do not create a civic job;
- runtime staleness is shown as telemetry, not confused with UI version;
- the page does not claim a successful MoonClaw run from map rendering.

## MT-02 — receive and execute a typed MoonFind salon

Start MoonFind first and use **Open typed handoff in MoonTown**, or open the
exact URL returned by MoonFind. It has this shape:

```text
http://127.0.0.1:17842/index.html?seed=20260727&handoff_contract=moontown.civic.communication.handoff.v1&handoff_id=<id>&handoff_url=http://127.0.0.1:4313/api/v1/moontown/handoff
```

1. Confirm the Energy Valley canvas remains visible behind the handoff panel.
2. Wait for the handoff panel to finish validation.
3. Confirm status **PENDING · NOT EXECUTED**.
4. Match the producer run, handoff id, participant books, topic, review gate,
   review owner, and output book to the MoonFind source.
5. Click **Start governed salon** once.
6. Keep the page open while the existing civic runtime delegates the reduction
   to MoonClaw.
7. If the result is retained because the MoonFind callback was temporarily
   unavailable, restore MoonFind and click **Reconcile same attempt**.

Expected positive result:

- status becomes **RETURNED · REVIEW PENDING**;
- execution is `completed`;
- review is `pending`;
- MoonFind callback is `delivered`;
- the UI never labels the synthesis accepted.

Evidence is written under:

```text
$MF_QUAL/suite/.moonsuite/products/moontown/research-handoffs/<handoff-id>/
$MF_QUAL/suite/.moonsuite/products/moontown/civic/
```

The exact result package is also ingested by MoonFind. A second click/reconcile
must reuse the original request, attempt, idempotency key, receipt, and output.

## MT-N1 — incomplete link

Open:

```text
http://127.0.0.1:17842/index.html?seed=20260727&handoff_id=only-an-id
```

Expected visible result:

- **Research handoff blocked**;
- the message says `handoff_url`, `handoff_contract`, and `handoff_id` are all
  required;
- the town remains unchanged;
- no Start action is available.

## MT-N2 — unsafe source or identity drift

Try one of these:

- use an `https://` or non-loopback `handoff_url`;
- use port `17842` as the handoff source;
- change `handoff_id` while leaving the source artifact unchanged;
- use any contract except
  `moontown.civic.communication.handoff.v1`.

Expected visible result:

- the panel is **BLOCKED**;
- it identifies the source-policy, contract, or identity mismatch;
- no MoonClaw attempt or callback is created.

## Failure recovery

- Source temporarily down before execution: restore MoonFind and reload the
  exact handoff URL.
- Callback fails after execution: restore MoonFind and click
  **Reconcile same attempt**. Never click a control that creates a replacement
  run.
- MoonClaw remains active: inspect the existing MoonClaw run and reconcile; do
  not switch to a template/fixture reducer in a production qualification.
- A stale standalone viewport remains visible: open
  `/index.html?seed=20260727`, rebuild the Rabbita bundle, restart the service,
  and reload without cached assets. Current builds cannot select that retired
  renderer through a query parameter.

## Qualification record

```text
date:
operator:
MoonTown commit:
suite root:
browser URL:
MT-01: PASS | FAIL | BLOCKED
MT-02: PASS | FAIL | BLOCKED
MT-N1: PASS | FAIL | BLOCKED
MT-N2: PASS | FAIL | BLOCKED
handoff id:
MoonClaw run id:
receipt refs:
screenshots:
notes:
```

# MoonTown responsibility and testability

MoonTown owns persistent civic space, residents and roles, standing goals,
supervision, scenario configuration, cross-book communication, independent
participant execution, reducer synthesis, and return receipts. It does not own
the agent runtime, generic orchestration, provider policy, accepted book truth,
or physical authority.

| Responsibility | Required evidence | UI-to-UI assertion |
| --- | --- | --- |
| Present the canonical town | map build identity, seed, asset lineage, saved town state | default route opens the current map and edit controls act on valid terrain |
| Receive a typed handoff | producer, run, scenario, participant books, callback, digest | intake is visible and remains pending until the user starts it |
| Coordinate participants | one execution identity per participant and retained dissent | progress exposes each participant without merging their books |
| Reduce a synthesis | exact input set, reducer attempt, output digest, pending-review claim | same-attempt recovery never silently starts attempt two |
| Return the result | callback status and correlated receiving receipt | delivered callback still reads pending review until a named owner decides |

The browser procedures live in
[qualification/UI_TO_UI_USE_CASES.md](qualification/UI_TO_UI_USE_CASES.md).
The canonical Wenyu map remains expressive and spatial; administrative
diagnostics must not displace the town as the primary object.

## Repository shape

| Path | Responsibility |
| --- | --- |
| `src/facade.mbt` | intentionally small public facade |
| `src/civic*`, `src/town*`, `src/roles`, `src/policy` | civic domain records, policy, projection, and runtime |
| `src/commission*`, `src/research*`, `src/town_synthesis*` | scenario intake, independent participants, and reviewed synthesis |
| `src/adapters/*`, `src/flow_adapter` | typed product boundaries; no second orchestration or agent runtime |
| `src/plugin/moongate` | MoonGate status/provider observation only |
| `src/ui/rabbita-town` | canonical civic and spatial application |
| `src/cmd/*` | thin desktop, mini-app, adapter, and developer composition roots |
| `assets/templates/books` | product-owned scenario templates, never accepted evidence by themselves |

MoonTown is a domain pack with its own application. Its civic runtime is domain
coordination, not a replacement for MoonFlow, and `src/moonclaw_runtime` is an
adapter to the sole MoonClaw runtime rather than a second model loop.

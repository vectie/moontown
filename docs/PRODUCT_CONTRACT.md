# MoonTown product contract

Class: domain pack
Visible surface: civic and spatial application
Maturity: experimental local alpha
Last reviewed: 2026-07-31

## Outcome

MoonTown coordinates multiple book domains, workers, standing goals and civic
roles as a persistent governed environment.

## Users and jobs

- Operators inspect town health, residents, work, incidents and interventions.
- Domain books participate in reviewed research and synthesis scenarios.
- Mayor and Keeper roles propose and supervise work under declared authority.
- MoonDesk presents town state without taking ownership of it.

## Ownership

MoonTown owns town membership, civic roles, standing goals, routing,
supervision, scenario state and cross-book synthesis receipts. It does not own
the model loop, generic work execution, accepted book truth, provider access or
physical authority.

MoonClaw remains the sole agent runtime. MoonFlow owns durable declared-work
state. MoonBook owns source and accepted knowledge.

## Capability status

| Capability | Status |
| --- | --- |
| Persistent town, residents, roles and supervision models | available locally |
| Rabbita town and Wenyu operator views | available locally |
| Generic civic communication synthesis | available through versioned pack adapter |
| Cross-book research-salon fixture | available as one scenario configuration |
| MoonClaw worker reduction | conditional on configured runtimes |
| Accepted MoonBook outcome history | conditional on reviewed book workflows |
| Codex ACP default | `gpt-5.6-sol`, with explicit operator override |
| Production multi-tenant town | planned |

## Integration contract

MoonTown accepts `moontown/civic-communication-handoff@1.0.0` through
`moontown/civic.communication.synthesize@0.1.0` and returns
`moontown/civic-synthesis-result@1.0.0`. `research-salon` is scenario
configuration, not an operation ID. A successful adapter execution remains a
pending review candidate; MoonTown cannot accept its own synthesis.

The product manifest, host adapter declaration and short-lived health evidence
follow MoonFlow capability truth. Reconciliation reads durable evidence and
never reruns an unknown outcome automatically. See
[MoonFlow civic adapter](MOONFLOW_CIVIC_ADAPTER.md).

## Persistence, authority and recovery

Town state, incident history and scenario evidence are durable. Actions that
mutate workspaces, communicate externally or affect a robot retain their
original authority class. Supervisor approval does not elevate an effect.

## Verification

```sh
moon check --target native
moon test --target native
moon info
moon fmt
```

Real-workflow validation must include repeated worker reductions, restart
recovery and accepted outputs in the participating books.

## Release gates and next milestones

- Prove a multi-day supervised town with restart and backup recovery.
- Replace fixture-only participants with real reviewed book histories.
- Compile the installed pack, declaration and short-lived health attestation
  through MoonFlow's capability catalog in the suite host.
- Exercise one real MoonFind handoff through MoonFlow with a configured
  MoonClaw provider and named-human settlement.
- Complete authentication and packaged supervisor operation.

# Final Integration Portfolio

Last updated: 2026-05-28

The final local integration combines the user’s current research interests with
the Wenyu civic-building protocol set. It is intentionally data-driven: change
`templates/integration/wenyu-final-integration.json` to change the portfolio.
Do not add a MoonBit branch per domain.

## Ordered Portfolio

| Order | Area | Form | Home |
| ---: | --- | --- | --- |
| 1 | OPC | `signal-watch` | `research-opc` |
| 2 | LLM training | `signal-watch` | `research-how-llms-are-trained-in-very-detail` |
| 3 | Robotics | `signal-watch` + `research-salon` | `research-embodied-robotics` and Social Square |
| 4 | Agents | `signal-watch` | `research-ai-agents` |
| 5 | Hardware | `signal-watch` | `research-ai-hardware` |
| 6 | Wenyu civic features | civic pattern manifest | all 11 Wenyu civic buildings |
| 7 | Embodied robotics exchange | `research-salon` | `wenyu-social-square` |

## Runtime Commands

```bash
moon run src/cmd/main -- integration final install
moon run src/cmd/main -- integration final status
moon run src/cmd/main -- daemon run
```

The daemon uses nonblocking MoonClaw supervision by default:

```bash
MOONTOWN_MOONCLAW_SUPERVISION_SECONDS=0
```

That means one long watcher should not block the next domain watcher or civic
pattern schedule. Use a positive value only for focused debugging when the mayor
should wait inline for a single MoonClaw run to settle.

For a bounded local check:

```bash
moon run src/cmd/main -- daemon run --once
moon run src/cmd/main -- civic protocols schedules status
moon run src/cmd/main -- civic doctor
```

## Validated Local State

Checked on 2026-05-28 12:49 CST:

- daemon runtime: healthy
- supervisor process: alive
- worker process: alive
- daemon tick: `10069`
- successful daemon cycles: `6032`
- daemon failures: `0`
- domain watch coverage: `5/5`
- standing goals: `5`
- watcher records: `370`
- current active lane: `watch-ai-agents`
- Wenyu civic service workspaces: `11/11` operable
- civic service accepted-result proof: `0/11`
- recurring communication-pattern schedules: `12`

The important interpretation is that the local 24/7 seam is alive and the
portfolio is installed, but the civic layer still needs accepted service-result
histories. Protocol rounds and watcher ledgers are operational proof; accepted
MoonBook updates are domain or civic-service proof.

Useful inspection commands:

```bash
moon run src/cmd/main -- status
moon run src/cmd/main -- daemon doctor
moon run src/cmd/main -- integration final status
moon run src/cmd/main -- civic status
moon run src/cmd/main -- civic protocols schedules status
```

## Responsibility Split

- Moontown installs the portfolio, schedules due checks, records civic pattern
  rounds, and shows truthful runtime/UI status.
- MoonBook owns durable domain/civic workspaces, wiki pages, review queues,
  generated projections, and accepted-change accounting.
- MoonClaw owns source-first watches and building reducer execution through
  role-specific skills and output contracts.

## Quality Bar

Every 24/7 cycle should account for whether it actually changed the book or
only recorded operational activity. Useful output means at least one of:

- accepted new evidence
- stronger synthesis
- new non-obvious question
- rejected weak source with reason
- reviewable civic idea or solution
- returned follow-up work to the correct home workspace

No-change and failed cycles are allowed, but they must not inflate domain
evidence or civic progress.

## UI Contract

The operator console should show the five standing watches as a portfolio, not
as one hardcoded OPC panel. It should link to the standalone Wenyu viewport
instead of embedding a second, divergent map.

Canonical viewport URLs:

- `viewport.html?assets=generated&mode=view&v=wenyu`
- `viewport.html?assets=generated&mode=editor&v=wenyu`
- `viewport.html?assets=generated&mode=output&v=wenyu`
- `viewport.html?assets=generated&mode=view&module=town-shell&v=module-town-shell`

Building interiors are URL-addressable by `module=<module-id>`. The Back To
Town control returns to the canonical map URL. Output mode is the retrieval
surface for generated MoonBook reports, projections, review queues, and bridge
records.

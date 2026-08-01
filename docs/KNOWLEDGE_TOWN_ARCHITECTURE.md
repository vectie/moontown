# Knowledge Town Architecture

MoonTown's knowledge district makes domain work visible without moving domain
truth into the map or creating another agent runtime. A registered building is
a spatial/protocol place. A domain catalog binds a portfolio of MoonBooks and
versioned generation policies to that place. MoonFlow, MoonClaw, and MoonBook
remain the owners of workflow, execution, and accepted knowledge.

## The Three Separate Layers

```text
town module registry       knowledge-domain catalog       runtime truth
placement and appearance   book/policy membership         evidence-linked work
        |                           |                              |
        +---------------------------+------------------------------+
                                    |
                         MoonTown visual projection
```

- `wenyu-town-modules.json` owns building identity, geometry, entrances,
  visual style, and the civic protocol hosted by the building.
- `assets/templates/domains/catalog.v1.json` owns stable domain, book, policy,
  cadence, review, and building-binding declarations.
- MoonFlow owns durable work declarations, assignment, recovery, and handoff.
- MoonClaw owns bounded worker execution and execution receipts.
- MoonBook owns book workspaces, evidence, review state, accepted memory, and
  projection-safe book output.
- MoonTown reads those contracts and projects them onto the town. It does not
  generate domain conclusions inside the canvas.
- The desktop runtime publishes the SHA-256 of the exact resolved catalog body;
  Rabbita independently hashes the catalog response and rejects a mismatch.

This separation prevents a visual layout edit from changing research policy,
and prevents an animation from becoming an unrecorded claim that work happened.

## What A Building Means

Not every visible building is a knowledge domain.

- A **knowledge hub** has one primary synthesis book and several specialist
  books. Robotics Lab, AI Agents Lab, OPC Research, LLM Training Lab, and AI
  Hardware Lab are examples.
- A **protocol venue** hosts typed exchange and reduction. Social Square and
  Policy Hall may have support books, but their primary meaning is the protocol
  performed there.
- A **service hub** owns an operational capability and its ledgers. Town Shell,
  Vitality Tower, Talent Avenue, and Physical Bridge are examples.
- A procedural background building is scenery until an operator explicitly
  registers it. It must not silently acquire a domain or live workers.

Each registered building resolves to a portfolio:

```text
building id
  -> domain definition
  -> primary MoonBook
  -> supporting/specialist MoonBooks
  -> generation policy
  -> optional civic communication scenarios
```

The catalog uses exact stable identifiers. The renderer must not guess a domain
from a substring in a book name.

## Book Generation Policy

Catalog policy composes the existing MoonTown `BookPolicy`, template registry,
research-quality checks, book-quality review, and repair-goal loop. It does not
replace them.

Every declared book states:

- its stable id, purpose question, role, and owning building;
- its reusable template and policy version;
- source and evidence policy;
- schedule tier and cadence;
- quality threshold, review chain, and revision ceiling;
- its current catalog state.

The lifecycle is deliberately truthful:

```text
declared
  -> workspace ready
  -> evidence gathering
  -> synthesis ready
  -> review pending
  -> accepted | revision due | blocked
```

Provisioning a book creates a durable request and, after processing, a MoonBook
workspace. It never marks the book accepted. MoonClaw may research, synthesize,
and perform independent review. The MoonBook bookkeeper or a named human owns
acceptance. A revision updates the same canonical book; it must not create a
sequence of disposable `v2`, `v3`, or `final-final` books.

The default portfolio uses three scheduling tiers so a large library does not
mean hundreds of continuously running agents:

- **Tier A**: a small set of active watches for current high-priority domains;
- **Tier B**: rotating scheduled research;
- **Tier C**: operator-triggered or cross-book-demand research.

## Visible Work Loop

The desired town loop reuses existing civic scenarios, road routing, work
stations, quality review, and home-return behavior:

```text
home/domain building
  -> research and collect evidence
  -> walk to a protocol venue when cross-book exchange is required
  -> discuss and reduce a reviewable synthesis
  -> independent review / bookkeeper decision
  -> revise in the same book when gaps remain
  -> return accepted knowledge and follow-up questions home
```

The canonical map may render these evidence-linked activity kinds:

- `walking`
- `researching`
- `synthesizing`
- `discussing`
- `reviewing`
- `revising`
- `recovering`
- `idle`

`returning` is currently an ambient-preview state only. A live return animation
requires a timestamped completion or acceptance receipt with a bounded display
window; a durable `completed` task by itself is not evidence that an agent is
still walking home. Until that receipt exists, completed and idle workers stay
inside their buildings.

Live activity must carry a task/run correlation and come from durable runtime
evidence. A stale activity freezes or becomes visibly stale. When the runtime
is unavailable or no evidence-linked worker is currently on the road, ambient
residents may demonstrate the same visual vocabulary only under an explicit
**Knowledge flow preview** label. They never contribute to live work counts.

## Existing Components Reused

- `src/policy` for typed book policy, archetypes, health, and the execute/tend
  loop;
- `src/book_templates` and `src/book_templates_runtime` for durable, auditable
  workspace requests;
- `src/research_policy`, `src/research_quality`, and `src/book_quality` for
  evidence, semantic review, and same-book repair;
- `src/adapters/moonbook` for the authoritative MoonBook catalog;
- `src/moonclaw_runtime` and the MoonClaw adapter for bounded execution;
- `src/civic` and `src/civic_runtime` for salon, watch, triage, council,
  matching, cohort, story, and incident protocols;
- `src/visual_projection` and the Energy Valley runtime projection for
  evidence-linked agent/building state;
- Rabbita pathfinding, agent sprites, building beacons, inspectors, and
  workstations for the canonical canvas.

The embodied-robotics Social Square scenario is the reference cross-book loop.
Its participant books, synthesis, review, and home-return behavior should be
generalized through catalog data, not copied into new runtimes.

## Operator Flow

Inspect the catalog without changing state:

```bash
moon run src/cmd/main -- knowledge catalog
moon run src/cmd/main -- knowledge status
```

Queue missing catalog books through the existing book-template request inbox:

```bash
moon run src/cmd/main -- knowledge seed
moon run src/cmd/main -- books template requests status
moon run src/cmd/main -- books template requests process
```

`knowledge status` is read-only. It surfaces active books whose generated
template config still lacks approved source references and never converts an
installation state into a research-readiness claim. `knowledge seed` is opt-in
and idempotent: it creates only missing empty config scaffolds, never overwrites
user source configuration, and defers new template requests until sources are
configured. After editing the reported configs, run the seed command again.
It must not bypass template installers, accepted-knowledge review, provider
authority, licensing, or budget controls.

On the canonical UI, select a registered building to inspect its domain,
primary and specialist books, policy, schedule tiers, review chain, real
MoonBook projection state, and current evidence-linked work. The user should
not need to leave the canonical canvas for a legacy interior page.

## Truth And Scale Rules

- A catalog entry is a declared book, not proof of content or quality.
- A workspace projection proves that a MoonBook workspace exists; it does not
  prove that every claim is accepted.
- A live work count requires fresh correlated runtime evidence.
- The UI must distinguish declared, queued, researching, review-pending,
  revision-due, accepted, blocked, stale, and preview states.
- Individual agent sprites are capped and aggregated at low zoom. Large book
  lists are rendered in a bounded, scrollable inspector.
- Reduced-motion users receive stable states instead of continuous traversal.

## Extension Rule

Adding another domain should normally require only:

1. a catalog domain and its book declarations;
2. an existing or newly reviewed policy/template reference;
3. an existing communication pattern or a separately reviewed generic pattern;
4. an exact building binding;
5. qualification evidence.

It should not require new canvas branches, another agent runtime, domain logic
inside MoonClaw, or direct mutation of MoonBook content by MoonTown.

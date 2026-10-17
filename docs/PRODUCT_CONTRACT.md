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
| One-off source-bound collaboration composer | local draft/save/reopen/prepare/download; pending human review |
| Shared-material discovery and reviewed domain candidate | bounded same-pack reference grouping, explicit source selection and hypothesis; pending pack review |
| Cross-pack question composer | operator-labelled multi-pack observations, portable unsent draft, explicit snapshot gaps, reviewed candidate intake |
| Observation baseline comparison | explicit local snapshot scope, before/after exploration and selected change history in pending pack intake; not a standing watch |
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

The [collaboration composer](COLLABORATION_COMPOSER.md) captures exact selected
source files and exports a one-off civic handoff, participant briefs and a
MoonChat source-bound review bundle. This authoring path neither executes work
nor installs a schedule, synthesizes ideas or changes participant Books. Its
paired MoonChat source workspace is a build prerequisite.

Town state, incident history and scenario evidence are durable. Actions that
mutate workspaces, communicate externally or affect a robot retain their
original authority class. Supervisor approval does not elevate an effect.

[Shared-material groups](SHARED_MATERIAL_GROUPS.md) connects projected local
observations to an operator-reviewed domain candidate. Exact pack-relative
reference reuse suggests a group to inspect; it is not independent corroboration
or accepted knowledge. Group membership, exclusions and the operator hypothesis
remain bound to the submitted candidate, while owning packs retain review and
execution authority. Unsent review drafts survive cancel and refresh in memory;
only native candidate intake supplies durable submission state.

[Cross-pack questions](CROSS_PACK_QUESTIONS.md) combine explicitly selected
observations from distinct packs with scope, conditions and an observable rejection
test. Download/import resumes unsent operator notes; current projection gaps remain
visible and block candidate preparation. The native candidate mailbox preserves the
exact cross-pack source context for owning-pack review. This does not infer agreement,
contradiction, genuine autonomous emergence, or acceptance by a participating Book.

[Observation baselines](OBSERVATION_BASELINES.md) let an operator discover exact
projected-field changes before naming a hypothesis. Baselines are downloaded and
explicitly imported as untrusted historical excerpts. Comparison preserves pack
scope, names unavailable/ambiguous packs, and distinguishes newly projected,
changed, unchanged and no-longer-projected observations. Selected current
observations and their before/after history flow into the existing editable
candidate intake, with its source preflight and 128 KiB complete-envelope bound.
Import does not start a watch, alter knowledge, or grant authority. Local fixture
intake is not live civic synthesis, owning-Book acceptance or release qualification.

[Vocabulary discovery](VOCABULARY_DISCOVERY.md) finds exact words recurring across
independent pack observations with different evidence paths. An editable portable
ANY/ALL lens supplies explicit scope, current matching excerpts and named coverage
gaps. The operator can select a tentative connection and continue into the existing
review-pending candidate composer. Shared words are navigation hints, not inferred
agreement, contradiction or autonomous emergence. Importing a lens does not import
knowledge, restore an uncertain POST, dispatch a goal or authorize downstream work.
The native fixture retains the exact UI candidate through mailbox/reload/replay;
configured civic synthesis and owning-Book acceptance remain unqualified.

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

## Local mini-app development fixture

The existing Node mini-app fixture supports [archived building recovery](MINIAPP_ARCHIVE_RECOVERY.md):
inspect an editable archived record and restore the same identity to a non-public
state with its conversation and run history retained. This development-service
workflow does not establish the canonical native adapter, production identity,
reviewed publication, or accepted MoonBook knowledge.

The same local development service offers [building review packets](MINIAPP_REVIEW_PACKETS.md): discover a per-building action in the town snapshot or archive, inspect its source digest and download a bound JSON/Markdown account of retained records. Read-only export does not establish native UI integration, accepted knowledge, successful execution or production security.

The local fixture's [conversation search](MINIAPP_CONVERSATION_SEARCH.md) locates
literal retained message text within currently visible buildings, with exact
message/thread/run references and digest-bound pages. This is read-only record
inspection; recorded run statuses do not establish live execution or acceptance.

The local fixture also supports [reviewed building profile edits](MINIAPP_BUILDING_PROFILE.md).
Owners preview and apply a version-bound title, summary or tag correction, then
reopen the same building and retained history. This uses the existing fixture
identity and persistence model; it grants no publication, runtime or Book authority.

The existing local snapshot also embeds a [retained-run review inbox](MINIAPP_RUN_INBOX.md), with source-bound cross-building paging and linked conversation/audit inspection. Recorded update age and status remain explicitly fixture evidence; reading this backlog neither executes work nor accepts knowledge.

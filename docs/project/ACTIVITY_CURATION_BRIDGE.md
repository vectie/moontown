# Activity curation bridge

The organizer approval and launch worker calls
`@activity_curation.prepare(activity_id, approved_dossier, activity_root)`.
This imports an actual versioned MoonBook and installs a MoonClaw draft profile.
It does not enqueue a MoonClaw job, call a language model, generate an image,
award prizes, or publish an activity. The launch worker publishes only after
validating the returned binding receipt.

## Existing ownership

- MoonTown keeps the organizer grant, approved application revision, budget,
  activity lifecycle, submissions, moderation and voting.
- MoonBook keeps the reusable curation methods, source provenance and each
  activity's immutable approved workbook. Native `agent import` initializes
  `book.toml`, `wiki.toml` and its installation receipt; the bridge never
  fabricates those files.
- MoonClaw provides the existing `coffee_curator` job profile contract. The
  bridge configures a profile without starting it. Any later runner must check
  the activity grant, supply this Book's actual cwd/workspace, verify the profile
  digest and enforce its execution policy before calling a model.
- The existing qualified image adapter owns the fixed text-to-image workflow;
  launch probes its health endpoint only. It does not select a provider from
  organizer input or reserve another independent compute allocation.

## Deployment configuration

Two server-owned environment variables are required:

```text
MOONTOWN_ACTIVITY_CURATION_PRESET_FILE=/private/config/curation-preset.json
MOONTOWN_ACTIVITY_TEMPLATE_CONFIG_FILE=/private/config/activity-template.json
```

The latter is the existing creative-contest configuration, including a trusted
`provider_origin` and model. The first has this schema (replace paths and pin the
actual installed executable):

```json
{
  "template_id": "coffee-image-v1",
  "template_version": "1",
  "book_cli": "/opt/moonbook/moonbook",
  "book_cli_cwd": "/opt/moonbook",
  "book_cli_sha256": "sha256:<installed-native-cli-sha256>",
  "bundle_path": "/opt/moonbook/presets/coffee-curator-runtime-1.2.0.moonbook-agent",
  "bundle_file_sha256": "sha256:55cccaa818a8bf7fc4b6c7d5020339ac90ddcb018d82e76d4bdda9036e50c8bf",
  "bundle_digest": "sha256:0569dd437ba243510127cec012e929b086934a8560dac3c42b6aad890999983f",
  "source_book_id": "banxing-coffee-curator",
  "book_version": "1.2.0",
  "curator_profile": "coffee_curator",
  "workflow_id": "z-image-turbo",
  "workflow_version": "1"
}
```

`book_cli_cwd` must contain the real Book CLI's `seed/` directory. Older native
Book builds resolve seed files relative to cwd when their executable isn't under
`/_build/`; copying only the executable causes an incomplete import. Ship the
trusted seed tree with the CLI, read-only. The qualified Linux executable depends
on libc/libdl/pthread and has SHA-256
`5925e3ed2a909a0c273089d97cea57dec10251e217fb67351455029905565181`.

`scripts/activity-curator-preset.mbtx` generates a pinned preset from local CLI,
bundle and trusted `program_template` metadata, with explicit installed paths.
Preset/config files and activity storage are private operator-owned paths;
browser payloads cannot choose any of them. Set private file permissions on
generated deployment configuration.

## Native runtime preset

The complete original source remains
`banxing-coffee-curator` **1.1.0**, bundle digest
`sha256:4c4ee1a279bfb9df109524b3c8146a8447d24b90c7a98efb842404d6eb2c6bf2`.
Its archive file SHA-256 is
`ee41cbb81c384ad1171251a62ed02ca416b7732e4aee42793dd23aaa8d075dbd`.
It retains the original poster/brand assets, example image and exhibition video.

The **1.2.0 runtime preset** was produced by native import of that archive into
an isolated real Book, the bounded
`scripts/activity-curator-runtime-source.mbtx` derivation, and native `agent pack`
with no portable output selection. It has 64 verified members and is about
484 KiB. It retains the actual curation skill and planbook methods; its USER,
RESOLVER and README point to the new activity-owned workbook. Its provenance
explicitly records that the shared media are absent from this per-activity
runtime, references the intact 1.1.0 archive digest, and directs visual assets to
the existing MoonTown coffee pages. The old standalone activation script becomes
an inert platform-management notice. No source Book was modified.

Qualified artifacts on management machine 175 are under the private directory
`/home/HwHiAiUser/activity-curator-bridge-20261107/`; the final package is
`coffee-curator-runtime-1.2.0.moonbook-agent`. Runtime source and qualification
Books here are private build evidence, not production activities.

## Readiness and recovery

The bridge validates the approved source identity/version, profile, workflow and
template against the installed preset. It checks CLI/package hashes and uses
the native Book CLI for verify/import. Every imported baseline member and the
actual installation receipt are checked again before readiness. Symlink member
destinations and unsafe relative paths are rejected.

`curation-intent.json` binds the canonical approved workbook and source digest.
The Book is imported under `moonbook-<activity_id>` inside the server-selected
activity directory. The bridge adds:

```text
plans/activity-launch/approved-workbook.json
wiki/planning/activity-launch.md
moonclaw.jobs.json
```

These are activity-owned overlays, explicitly excluded from seed member paths.
The seed baseline remains immutable. The activity index/log get one link/event.
`curation-ready.json` is durable and identical on retries. A changed launch or
tampered ready Book fails closed. An interrupted, unexposed import can resume
only within the same intent-owned workspace. A malformed initialized directory
requires operator inspection.

Before and after materialization, a five-second GET to the trusted adapter's
`/health` must return HTTP 200 and
`{"status":"ok","component":"qualified-image-adapter"}`. This is not a model
inference or a GPU capacity benchmark.

The receipt exposes only opaque Book ID, source/runtime version/digest, canonical
launch digest, profile digest, fixed workflow version and
`agent_state: "configured-not-started"`. Host paths and credentials are absent.

## Execution limits and performance

The configured profile has a single `job.analysis` step. Actual MoonClaw
`job/compiler.mbt` maps `enable_tools:false`, `web_search:false`, `timeout_ms`
120000 and `max_total_tokens` 3000 into its analysis configuration/policy; the
no-tools runner disallows model tool calls. Prompt text and descriptive metadata
are not a substitute for this runtime enforcement. The explicit
`execution_policy: "requires-runtime-gate"` documents the additional authorization
gate; it does not itself enforce one. This bridge offers no execution endpoint.

Measured on 175 with `/usr/bin/time -v`: the original 68 MiB archive import took
9.55 seconds with **869,216 KiB** child peak RSS, which exceeds a 512 MiB gateway
limit. The final 484 KiB runtime import took **1.50 seconds** with **20,228 KiB**
child peak RSS. Import is paid once per approved activity, never per page view or
generation. The parsed package is not retained while a native import child is
running. The launch worker should serialize creation jobs to bound concurrent
subprocess memory.

## Verification

Focused native tests cover canonical binding, traversal, source/workflow drift,
profile controls, idempotent immutable writes and baseline tampering. The
optional real integration test is enabled by
`MOONTOWN_CURATION_QUALIFY_PRESET`, `MOONTOWN_CURATION_QUALIFY_TEMPLATE` and
`MOONTOWN_CURATION_QUALIFY_ROOT`; it prepares twice, compares receipts and rejects
a changed approved dossier. Its configured provider must be the real qualified
adapter or be explicitly identified as a test fixture. No inference is sent.

On 2026-11-07 the clean-root native integration passed against the actual
qualified adapter through an authorized SSH/kubectl port-forward. It imported
the final 1.2.0 package, prepared the same activity twice with identical receipts,
and rejected a changed approved dossier. The standalone native test process
(excluding compilation) took 2.49 seconds with 35,979,264 bytes peak RSS on the
Mac; this is separate from the Linux child-only measurement above. The five
focused tests passed, and native `moon info` and scoped formatting completed.

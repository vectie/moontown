# Retained collaboration outcomes

Open Town's existing collaboration composer and use **Load / reload retained
outcomes**. This library enumerates every saved source revision, including
non-current revisions and different drafts. Filter by outcome or review state,
then inspect one exact retained result.

The library is independent of the editable draft. Inspecting an old result
does not replace unsaved draft text, reuse a result, run participants, collect
runtime status, call a provider, schedule work, submit to Book, or advance
Book's review gates. The work panel's **Collect / reconcile work status** is a
different, explicit operation that may retain newly collected results.

## Start the normal local product

Keep the delivered MoonChat and MoonTown trees as canonical siblings, as
described in [the composer build layout](COLLABORATION_COMPOSER.md). Build the
normal Rabbita assets with the existing scripts/build-rabbita-ui.sh recipe
(or its documented individual MoonBit and Node steps on hosts without zsh),
and build src/cmd/desktop_server with the native MoonBit target.

Start the normal desktop_server executable from the MoonTown source root.
Set MOONTOWN_SUITE_ROOT to the existing suite whose retained collaborations
you intend to inspect, and MOONTOWN_DESKTOP_STATIC_ROOT to the absolute
src/ui/rabbita-town/dist directory produced by that normal build. The default
local address is http://127.0.0.1:17842. In the request desk choose
**Collaboration**, then **Load / reload retained outcomes**. No runtime profile,
provider, or Book submission executable is needed for these retained-only reads.
An empty store produces an empty library without creating a collaboration store.

## Status meanings

- completed: all attributed participant contributions were retained
- partial: all participants reached a terminal state, with failures retained
- not_retained: this saved revision has no collected terminal dossier yet;
  this does not assert that work is running, failed, or successful
- unavailable: a retained entry could not be verified, including a missing
  contribution, changed source, corrupt review, or unsafe path
- pending_review, rejected, deferred, accepted: the selected historical
  review's disposition. An explicit defer is shown as deferred even though
  the underlying Chat review contract classifies an unsettled decision as
  pending_review

Review acceptance concerns the accuracy of the retained account. A partial
outcome can have an accepted account without claiming that its failed
participants succeeded. All four review states remain inspectable and
downloadable. Book submission remains a separate explicit action with its
existing named-owner approval and independent Book acceptance requirements.

## Exact review selection and download

The initial inspection pins the indexed review version and its SHA-256 digest,
along with the source revision and collected result digest. The inspector lists
earlier retained review versions. Select one explicitly to inspect/export that
historical state. Reload the library to discover later decisions.

**Download exact retained dossier (.tar)** passes this complete selection to the
native service and checks the archive digest and byte count from inspection.
Later review decisions do not change an earlier pinned archive. A missing or
changed selected version fails instead of silently downloading the latest one.
Cancel, filter changes, newer selection, clearing the composer, or leaving its
surface invalidate pending callbacks and prevent a late download from saving.
Reloading the application discards the UI selection; loading the library
reconstructs it from retained evidence.

The archive contains:

- SUMMARY.md: readable question, attributed contributions, failures,
  objection, decisions, and selected review history
- draft.json: exact saved source revision
- result.json: exact collected terminal dossier, not a synthesized consensus
- sources/: original nested captured source bytes, including binary content
- participants/<book>/terminal.json and successful report.md contributions
- review/0.json through the explicitly selected review version, plus a
  derived selected-record.json
- manifest.json: every other member's exact raw byte length and SHA-256,
  selected result/review identities, and truthful outcome/review state

The whole tar, including its manifest, is bound by the inspected archive digest
and the HTTP X-Artifact-Digest header. Tar metadata is deterministic. The
manifest does not recursively hash itself. This is unsigned local integrity
evidence, not an authenticated signature or independent proof of human identity.
Host configuration, runtime setup files and Book receipts are not added to the
dossier. Selected sources and retained contribution/failure text are preserved
exactly and can themselves contain local paths or sensitive information. Review
the archive before sharing it.

The existing **Download prepared plan package (.tar)** remains available after
Prepare. It contains the authored plan and captured inputs, not executed
contributions. Reusing a question creates a new draft and recaptures current
sources without inheriting an old result or review decisions.

## Compare two retained outcomes

The read-only [retained outcome comparison command](RETAINED_OUTCOME_COMPARISON.md)
exports a before/after change brief or structured JSON for two exact selections.
It preserves source and participant attribution, including failures, without
collecting work or changing any review.

## Native API and bounded storage

POST the existing moontown.collaboration.request.v1 envelope to
/api/collaboration with:

- outcome-list: bounded all-revision index in the reply's outcomes field
- outcome-inspect: payload is an explicit OutcomeKey; returns outcome
- outcome-export: same exact key; returns a byte-checked deterministic tar

OutcomeKey has draft_id, revision, result_digest, review_version, and
review_digest. The first two must match the request envelope. outcome-list
does not accept caller-supplied runtime or operator authority. It never reads
the live Book catalog or source files.

Reads take the same process and filesystem lock used by authoring writes,
without creating files or repairing incomplete data. The index bounds are 128
draft directories, 64 revision entries per draft, and 512 total revision rows.
Directory enumeration is bounded before allocation. Individual failures are
visible as unavailable rows; exceeding the total bound fails explicitly rather
than returning a silently truncated index. Review history is limited to 101
versions and 16 MiB; dossier members are limited to 32 MiB / 2048 files and the
complete tar to 40 MiB. Sources retain the existing 1 MiB per-file limit.

The library checks saved revision identity, captured source hashes, each
terminal receipt's participant/run identity, successful contribution digests
and exact UTF-8 text, exact assembled result bytes, the selected review's source
binding, fixed assignments, and the contiguous decision history through the
selected version. It never invokes the mutating read_oneoff collector.
Each exact draft, source, terminal and contribution buffer passed to the archive
is revalidated against that pinned snapshot. The archive then uses those same
immutable buffers, so an external same-size replacement between verification and
member assembly is rejected rather than assigned a new manifest hash.

## Verification

Focused native coverage lives in src/collaboration_authoring/outcome_wbtest.mbt
and src/collaboration_contract/outcome_test.mbt. Existing production-boundary
one-off tests also verify that actual local Claw outputs enter the library.
Rabbita tests cover rendering, stale selection, cancel/filter/route fences,
digest-checked downloads and the real native HTTP crossing when
MOONTOWN_OUTCOME_HTTP_URL is set. Without that explicit URL the HTTP test says
the crossing is not configured; that run is not HTTP evidence.

The normal asset recipe is unchanged: compile Rabbita and landmark-studio,
run the existing MoonBit landmark assembly/package scripts, then run the
existing production assembler and verifier. No fallback UI or stub bundle is
used.

## Search across retained outcomes

The read-only [retained outcome search command](RETAINED_OUTCOME_SEARCH.md) finds
literal phrases across saved questions, source metadata, attributed contributions,
failures and selected decision text. Book/review filters, bounded excerpts, exact
historical keys and explicit coverage gaps support local Markdown/JSON exploration.

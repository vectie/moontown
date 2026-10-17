# Propose an idea from actual domain-layer sources

Pack Bridge previously showed domain subjects but asked the operator to type
candidate evidence references and JSON manually. The **Pack layers** panel now
connects those observations to the existing domain-pack candidate intake.

For observations reusing one pack-relative evidence path, start with
[Shared-material groups](SHARED_MATERIAL_GROUPS.md). Review the group, include or
exclude observations, and state a tentative pattern before opening this same
composer. Group generation and exclusions are retained alongside the selected
source context. Manual selection below remains available for operator-authored
cross-pack combinations.

For a scoped multi-pack question with explicit supporting/challenging/contextual
roles, dates or conditions, and a portable unsent draft, start with
[Cross-pack questions](CROSS_PACK_QUESTIONS.md). Its reviewed context prefills this
same intake composer and remains attached to the candidate.

1. Open Pack layers and read the projected subjects. Select **Use as proposal
   source** on one to twelve subjects, possibly from independent domain packs.
   Selection survives layer filtering. A refresh clears selection so the next
   proposal starts from newly inspected observations.
2. Choose **Propose from N source(s)**. The composer shows each selected title,
   exact summary, subject reference, lifecycle, publishing time and evidence
   references. Explain each source's connection to the idea independently.
3. State contrary evidence, uncertainty or an observable rejection test. Select
   the destination intake operation and write the title, rationale and optional
   pack-specific domain JSON. Selection does not assert endorsement or consensus.
4. Submit explicitly. Before the first POST, the browser reads the current Pack
   Bridge snapshot and rejects disappeared, degraded, ambiguous, version-changed
   or materially changed selected observations. A timestamp-only republish with
   unchanged inspected fields does not invalidate the proposal. The selected
   destination operation must still exist.
5. The existing native intake writes the same `moontown.pack-candidate-intake.v1`
   envelope to the receiving pack's candidate mailbox. The exact copied source
   observations, per-source explanations and uncertainty are retained inside
   `domain_payload.moontown_source_context`. Existing domain keys are preserved;
   manually supplying that reserved field is rejected. Evidence refs are merged
   without duplicates. Inspect the returned candidate receipt in Pack layers.

## Interrupted requests

A repeated click cannot submit concurrently. Once a POST is attempted, the
composer freezes its inputs and retains the exact candidate ID, timestamp and
body. A lost or otherwise uncertain response offers **Retry same candidate**; reopening the
composer while that outcome is unresolved returns to the same dialog. Retrying
uses the original envelope and the native mailbox's existing identity check,
not a newly composed proposal. A successful receipt disables further submits. The exact native request-size
guard response (413, `request body too large`) is definite nonacceptance before
intake; it unlocks the form for correction rather than retrying an oversized
envelope. Other uncertain errors keep the original identity.

The in-progress composer is held in memory only. After a page reload, inspect
the durable candidate list and its native mailbox/receipt before creating a new
copy of an uncertain proposal. This feature does not promise browser-restart
draft recovery. Do not interpret closing a dialog as cancellation of a POST.

## Boundaries

The copied observations are historical, operator-selected context, not source
file contents, cryptographically signed attestations, semantic validation,
accepted Book knowledge or genuine autonomous emergence. A projection timestamp
is the publisher's claim. The preflight is a browser usability freshness check,
not an atomic server-side compare-and-swap or authority/security boundary;
source publication can occur between preflight and POST. Native intake still
owns active-pack routing, candidate identity, mailbox persistence and review.

The receiving pack keeps its vocabulary and decision authority. Candidate
routing cannot invoke its operation, spend, execute an experiment, accept Book
truth, publish or grant external/physical permission. This extends source-linked
bottom-up proposal authoring, distinct from the Collaboration panel's cross-Book
peer-challenge experiment. The latter workflow is unchanged.

Limits: twelve sources, 100 evidence references per source, 200 unique candidate
evidence refs, 128 KiB source context and a 128 KiB complete UTF-8 serialized candidate,
including envelope fields and JSON overhead. The complete body check is stricter
than the context-only check and matches the unchanged native HTTP guard. Projection
summaries are limited to 16,384 characters, source connection notes and contrary
evidence to 2,000 each. Source strings are rendered using textContent/value.

## Product and verification scope

Narrow PRD support: MOONTOWN-UC03/B03's cited, review-pending synthesis boundary
and MOONTOWN-B05's actionable projection/freshness principle. Domain pack
projections are used here; this does not complete the configured cross-Book
runtime, source-bounded watch, contradiction-review or always-on-service gates.

Node tests exercise the actual shipped panel, source selection, dialog handlers,
source recheck, changed/missing/degraded observations, uncertainty, interrupted
submission/retry, double clicks, pending-dialog reopening, legacy manual flow,
literal rendering and build asset declarations. Native v1 schema, object payload
validation, envelope retention and identity replay were inspected in source.
The test DOM and fetch responses are substitutes; native intake execution,
MoonBit check/test/info/fmt, full production frontend build, real browser and
accessibility, live domain packs and providers remain unrun and release-blocking.

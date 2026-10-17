# Explore changed observations before choosing a question

An operator may not yet know what question or standing goal to create. Pack
layers already exposes domain observations, but previously a return visit meant
manually remembering which excerpts changed. Observation baselines connect those
projections to an explicit local before/after comparison and the existing reviewed
candidate route. This is different from same-reference grouping, the cross-pack
question composer, CSV claim comparison and a configured Book-file watch.

## Save, resume, explore, propose

1. Open **Pack layers** and select the domain layers you want to compare. In
   **What changed since your last visit?**, name the baseline and choose **Save
   selected layers as baseline**. A download is requested and the baseline stays
   in memory. Keep the JSON file for the next visit; the browser download itself
   is not confirmed by the application.
2. On a later visit, choose that file under **Import an earlier baseline**. Read
   its label, claimed date and pack scope. **Use imported baseline** explicitly
   replaces only this comparison's retained baseline. Cancel preserves the old
   one. No file is uploaded and no request is submitted by import.
3. Inspect **Before** and **Current** excerpts. Search by title, text, pack or
   evidence reference. Choose a change type and page through all matches in
   groups of 20. The original baseline scope remains fixed even if you change
   the normal layer filters. Packs added since capture are not silently included.
4. Newly projected and changed observations have selection boxes. Choose one to
   twelve, then **Continue N change(s) to intake**. The candidate includes the
   original baseline identity, exact selected before/after snapshots, changed
   fields, omitted-change count and any named pack gaps.
5. Choose the owning intake and edit the candidate title, rationale and
   domain-specific JSON. Explain each source's relevance and contrary evidence
   or rejection test. **Submit for review** rechecks selected current sources
   and destination. A review-pending receipt is a routing result, not acceptance
   of the proposal or its underlying knowledge.
6. If a response is lost, reopen the existing candidate and **Retry same
   candidate**. The existing retained identity and bytes are reused. Do not
   create another proposal while the earlier outcome is unknown. A page reload
   does not restore an uncertain candidate: inspect native receipts first.

**Download retained baseline** saves the original comparison point.
**Download comparison** saves all compared rows, before/after excerpts and gaps,
including rows hidden by search or page selection. To deliberately advance the
comparison point, change the selected layers/label and choose **Replace baseline
with selected layers**. This requests a new download and replaces the old local
baseline only after successful serialization/download invocation.

## What a change means

- Exact title, summary, schema, lifecycle, evidence-reference array or pack-version
  changes are shown by field name. A version change may therefore flag otherwise
  unchanged text. Evidence-reference ordering counts as a field change.
- Publisher timestamp changes and subject/projection ordering alone stay quiet.
  Dates are publisher/operator claims, not verified source freshness.
- **No longer projected** means absent from the current well-formed projection.
  It does not prove deletion, rejection or removal from accepted Book knowledge.
  Such rows cannot be used as current candidate sources.
- A missing, degraded, duplicate, malformed or product-replaced pack is a named
  gap, not a set of removed observations and not a no-change result. Its complete
  historical excerpt is retained in the baseline and exported comparison.
- A refresh clears selected changes so they can be inspected again. Filtering,
  search and pagination preserve selections. The candidate's source preflight
  protects selected current observations; it is not an atomic native compare-and-
  swap and does not certify the rest of the historical comparison.

## Bounds and authority

Baselines hold one to 128 packs, at most 1,000 observations, and at most 1 MiB of
complete pretty-printed UTF-8 JSON. Current snapshots have at most 128 entries in
each bridge collection and 1,000 subjects. The normalized comparable current pack
scope is at most 1 MiB. Oversized scopes fail without a partial comparison.
Individual fields reuse source-capture limits. Complete native candidate bodies,
including historical change context, remain bounded to 128 KiB; choose fewer
observations if the historical excerpts make the candidate too large.

Imported excerpts are untrusted local data. Their exactness to live publishing
history, evidence-file bytes, dates and meanings is not authenticated. Rendering
uses text, never executable markup. Reference paths stay attributed to their
publishing pack and are not fetched automatically. No semantic importance,
consensus, contradiction, autonomous emergence or accepted knowledge is inferred.

This is an operator-driven comparison, not a recurring service or notification
watch. One baseline is retained per mounted panel; download/import supplies page-
restart recovery. Native intake preserves submitted context but does not enforce
its semantic truth. Full production assembly, paired MoonChat/Rabbita workspace,
real-browser interactions, configured civic synthesis and owning-Book acceptance
remain separate requirements.

## Focused verification

Run from the patched checkout:

```sh
node --test src/ui/rabbita-town/pack_observation_changes.test.js
```

The mounted tests exercise the actual shipped panel, file-import preview,
comparison controls and editable candidate fetch path using event-DOM/fetch
substitutes. Optional `MOONTOWN_CHANGE_SAMPLES` names an existing output directory
for the deterministic successful journey's baseline, current snapshot, comparison
and candidate JSON. The native `pack_town_bridge_runtime` test consumes those exact
files when that variable is set, otherwise its checked-in fixture files. It
installs two local fixture packs and verifies intake, mailbox, reload and replay
without changing projections. These component checks do not waive broader gates.

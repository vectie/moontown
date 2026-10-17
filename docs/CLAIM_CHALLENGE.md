# Turn a source comparison into an independent Book challenge

The Collaboration composer now starts a question directly from the JSON emitted
by `claim_compare`. It does not require successful participant outputs from a
previous run. The existing post-run collective experiment composer is unchanged.

## Journey

1. Generate a claim-comparison JSON report against explicit stable source files.
   In Collaboration, choose **Challenge a source claim comparison** and paste it.
2. Load registered Books and select one topic/context group. Inspect each exact
   quote, operator-labelled value, imported Book label/path and source digest.
3. Explicitly map every selected claim to a registered Book and a current
   workspace-relative source path. Nothing is matched automatically from an
   imported label, even if that label resembles a registered Book ID.
4. Write independent challenges, a question, an observable falsifier, a title and
   new draft ID. Name the plan reviewer. If preserving an objection, name its
   human decision owner too.
5. Choose **Verify mapped sources and save challenge draft**. The host resolves
   registered Book roots, captures sources once, verifies the reported source digest,
   byte length and literal quote against those captured buffers, then persists
   those same buffers through the ordinary draft store. A changed byte outside
   an unchanged quote is still a refusal. Correct the mapping or regenerate the
   comparison; this action cannot silently substitute current source text.
6. The saved result becomes an ordinary collaboration draft. Reopen it, inspect
   the preserved question/provenance and captured sources, then explicitly
   **Prepare one-off handoff**. The existing source packet, participant briefs,
   civic handoff and MoonChat review bundle remain pending review. Download uses
   the existing deterministic archive. Start, result review and Book intake are
   separate existing actions; this flow invokes none of them.

Changing the selected group or report clears its mappings and authored notes.
Selecting the same group again preserves them. Cancel clears the claim form and
invalidates pending callbacks while leaving the ordinary draft unchanged. An
interrupted native save may already be durable: load saved drafts before retrying.

## Boundaries

- Imported labels, values, topic/context, policy and table digest are assertions,
  not authenticated Book identity, semantic entailment or reviewed authority.
  Native verification checks selected source bytes, not the absent original CSV.
- Exact different values are candidate differences, not detected contradictions.
  Equal values do not establish truth or independent corroboration. Distinct
  contexts remain separate; selecting a group does not collapse its neighbors.
- Initial challenge save requires exact live-byte equality with the report.
  Reopening uses retained bytes without reading current files. Later ordinary
  edits/reuse keep the historical provenance in the editable question and use
  the existing current-source capture behavior; they do not revalidate the old
  report. Regenerate/import a report when a new claim comparison is needed.
- This is local authoring and preparation. Typed reviewer names are assignments,
  not authenticated decisions. No review receipts, votes, participant agreement,
  synthesis, provider execution or accepted Book knowledge are manufactured.
- The existing filesystem/symlink boundaries remain. Capturing and checking the
  same buffer prevents a check-then-reread gap; no OS-level transaction against a
  hostile concurrent filesystem writer is claimed.

## Limits and API

Report intake: 32 KiB UTF-8, exact v1 schema, 1–200 claims across at most 200
groups, 1–64 reported sources, 256 KiB per reported source and 8 MiB total.
Select a group with 2–16 claims and at least two imported labels; explicit
mappings must resolve to at least two distinct registered Books. This intake
uses the ordinary non-hidden relative path rules, which are narrower than the
standalone comparison command. No truncation or partial-group save is performed.

Titles are at most 200 UTF-16 code units; authored text/challenges at most 4,000.
The complete ordinary draft remains bounded by 64 KiB UTF-8. The existing HTTP
request limit remains 128 KiB; a heavily escaped report can exceed it even when
the local form fits. Narrow such input if the host rejects it as too large.

`POST /api/collaboration` adds action `claim-challenge` to the unchanged request
envelope. It requires an empty `revision`, the new `draft_id`, and a `payload`
matching `ClaimChallenge`: comparison JSON string, zero-based group_index,
draft_id/title/question/falsifier, reviewer and optional objection fields, and
one mapping per claim (`claim_id`, `book_id`, `source_path`, `challenge`).
Unknown payload fields are rejected. Caller-supplied workspace roots are never
accepted. Success returns the ordinary `saved` field in the existing reply.

## Qualification

Native tests generate an actual report, map different exported paths to registered
Book files, save/reopen/list, Prepare via the real civic and paired MoonChat code,
and export a portable archive. Exact generated report/input/saved fixtures are
also used by contract and mounted-renderer UI tests. Those tests cover selected
group display, literal evidence escaping, explicit payload continuity, repeated
selection, group changes, Cancel, stale replies, and the ordinary Prepare state.

This is bounded development-source evidence. It is not a graphical browser,
live HTTP host, configured civic synthesis, Claw execution, Book acceptance,
production authentication, installed desktop or release qualification.

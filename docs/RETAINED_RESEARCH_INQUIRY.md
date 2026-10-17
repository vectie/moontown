# Start a new research-salon inquiry from retained contributions

In **Collaboration → Load / reload retained outcomes**, inspect one exact
historical result and review version, then choose **Use retained contributions
in a new research-salon inquiry**. This connects the existing retained library
to the ordinary editable collaboration composer. It does not require reopening
the historical draft as the current work or recollecting its outputs.

## Journey

1. Inspect a completed or partial dossier with at least two successful retained
   Book contributions. Pending, rejected and deferred historical reviews remain
   eligible as evidence; none grants approval of new work.
2. Select at least two successful Books. Copy one exact retained passage for
   each, up to 1,000 characters, and write an independent challenge. Failed Books
   cannot be selected. Their attributed failures remain in the new question,
   and successful Books you omit remain named unselected alternatives.
3. Write a new scoped question, an observable falsifier, dissent and unresolved
   assumptions. Choose a new draft ID and title, and explicitly assign the new
   human reviewer and objection decision owner.
4. Save any existing ordinary composer edits you want to keep. Choose **Save
   new inquiry and open in composer**. The host re-verifies the exact retained
   result, selected review and source/output bytes using the library reader.
   It then uses ordinary draft saving to capture current files at the selected
   Books' original source paths. Missing current Books/files block saving.
5. The new saved draft opens in the ordinary composer. Edit its assignments,
   question or source paths as needed, save a new revision, and explicitly
   **Prepare one-off handoff**. Prepare produces the existing civic handoff,
   participant briefs, source packet and pending-review MoonChat bundle.
   Download uses the existing plan archive. Starting participants, reviewing
   their new results and sending to an owning Book remain separate actions.

## Historical evidence and current inputs

The question embeds `moontown.retained-inquiry.v1` JSON with the exact five-field
historical outcome key, dossier digest, original question, review disposition
and decisions, original objection and its owner, selected excerpts, output
identities and prior source snapshots. These identifiers come from the verified
store, not browser-supplied output fields. Literal quotes must occur in the
selected retained contribution. This checks attribution, not semantic accuracy.

The new saved draft's source snapshots contain current Book bytes. If those
bytes changed after the old result, both identities remain visible and distinct.
Saving does not claim that old findings still hold. Later edits follow ordinary
draft rules: the question is editable authored text, not a signed provenance
record; a later save recaptures current selected sources. The old dossier is
never changed. Download it separately when you need its complete retained bytes.

An exact repeat save returns the same revision while authored fields and current
source bytes match. Changed current bytes, a conflicting new draft ID, changed
retained evidence or changed selected review bytes refuse the save. A newer
review does not substitute for the explicitly selected historical review.

## Editing and interruption

Inquiry notes are local form state until save. Reopening the same inquiry form
or temporarily deselecting a Book preserves authored notes. Selecting a different
historical result/review, changing library filters or resetting the composer
clears them. Cancel clears the inquiry notes and leaves the ordinary draft alone.
Leaving the surface or canceling invalidates pending callbacks, but a host save
may already have committed; reload saved drafts before retrying after interruption.
Refreshing the application discards unsaved form notes.

The UI displays source text with the normal escaped Rabbita renderer. Retained
text is evidence data, not instructions or permission to execute it.

## API and bounds

POST the existing `moontown.collaboration.request.v1` envelope to
`/api/collaboration` with action `retained-inquiry`, the new `draft_id`, an empty
`revision`, and `payload` matching `RetainedInquiry`:

- `origin`: exact `draft_id`, `revision`, `result_digest`, `review_version`,
  `review_digest` copied from a verified retained selection
- `draft_id`, `title`, `question`, `falsifier`, `dissent`, `assumptions`
- `reviewer_id`, `reviewer_name`, `objection_reviewer_id`,
  `objection_reviewer_name`
- `contributions`: 2–16 unique successful selections with `book_id`, `quote`
  and `challenge`

Unknown payload fields are refused. Titles are bounded to 200 UTF-16 code units,
quotes to 1,000 and other authored text to 4,000. The resulting ordinary draft
has the existing 64 KiB UTF-8 limit; requests retain the existing 128 KiB limit.
Retained-dossier read limits and ordinary source-capture limits are unchanged.

## Product and authority limits

This implements the authoring/input-selection portion of MOONTOWN-UC03 and
MOONTOWN-B03. `research-salon` remains scenario configuration, not a callable
operation or authority grant. It does not call the civic synthesis operation,
execute the autonomous emergence protocol, infer consensus, copy old decisions
as new receipts, schedule work, run a provider, write Book memory or accept a
Book change. New work still requires the existing configured execution and
named-owner review paths. No PRD requirement status is promoted by this slice.

This slice selects contributions from one exact historical dossier. Combining
separate dossiers is outside this interaction. Source/output/review integrity
is unsigned local evidence; no hostile-filesystem transaction or authenticated
reviewer identity is claimed by authoring fields.

## Verification

Pure contract tests cover attribution, failed/single/duplicate/fabricated/stale
selections, bounds, explicit reviewers and callback fences. Native tests save
from a non-current revision and pinned older review, preserve named failures,
recapture changed current bytes, reopen/edit/Prepare/export, and refuse changed
historical/current evidence. The actual native input, origin and saved result
are embedded as UI test fixtures; renderer tests verify the typed request and
saved-response continuity, escaped evidence, selection, Cancel and stale replies.
These are synthetic local development tests, not a graphical browser, live HTTP,
configured provider, production authentication, owning-Book acceptance or
installed desktop/release qualification.

# Cross-dossier research inquiries

MoonTown can now bring selected successful contributions from separate historical
questions into one new research-salon inquiry. This extends the input-selection
workflow in `RETAINED_RESEARCH_INQUIRY.md` and the authoring portions of
MOONTOWN-UC03/MOONTOWN-B03. It does not change authored PRD completion status.

## Use it

1. Save any ordinary composer edits. In the retained-outcome library, inspect a
   historical result and choose “Use retained contributions in a new research-salon
   inquiry.” Select at least one successful Book, enter an exact retained quote
   and an independent challenge, then choose “Add or replace this dossier's
   selections in cross-dossier inquiry.”
2. Inspect another historical result. Added selections and the authored question
   fields remain in the basket; the new dossier's contribution controls start
   empty. Select its contributions and add them. Repeat as useful.
3. Write the new ID, title, scoped question, observable falsifier, dissent,
   unresolved assumptions and named review/objection owners. Inspect the visible
   basket. Remove any unwanted dossier, or revisit and re-add a dossier to replace
   its selected excerpts/challenges. The basket records the selections when added.
4. Choose “Save cross-dossier inquiry and open in composer.” The host re-reads
   every exact retained result/review and saves through the ordinary composer
   path, capturing the selected Books' current source files. Edit the new draft's
   assignments or source paths, save, then use the existing Prepare and explicit
   execution/review steps when appropriate.

Select two or more distinct pinned dossiers, up to sixteen selected contributions
in total, involving at least two Books. Each source dossier uses the existing
successful-contribution eligibility. The same Book may contribute from multiple
origins: it gets one ordinary assignment with both independent challenges and
the union of its selected source paths. Cancel discards the unsaved basket.

## Evidence and boundaries

Each dossier keeps its own question, five-field outcome key, archive digest,
output identity, exact quote, historical input snapshots, prior review decisions,
original objection and owner, unselected successes and failures. Contradictions
are retained as separate attributed context; no consensus or endorsement is
inferred. Current source capture does not rewrite historical evidence.

Saving creates an unrun ordinary draft. No provider is invoked, no work is
dispatched and no historical decision becomes approval of the new inquiry.
Existing size limits and named-owner release gates apply.

## API

POST the ordinary collaboration envelope to `/api/collaboration`, action
`cross-dossier-inquiry`, new `draft_id`, empty `revision`, and a payload of:

- `inquiry`: the existing `RetainedInquiry` authored fields and first origin's
  `contributions` (one selected contribution is sufficient for this origin)
- `additional`: an array of `{ origin: OutcomeKey, contributions: [...] }`

The existing `retained-inquiry` single-dossier API is unchanged. The response is
the existing saved-draft envelope, so normal editing, reopen, prepare and review
workflows apply.

## Development verification

Focused synthetic tests cover two questions with one selected contribution each,
per-origin quote and dissent retention, a Book selected from both origins, the
inspection basket, renderer/request wiring and native save/edit/reopen/Prepare
with changed current source bytes. Tests do not constitute live graphical-browser,
HTTP deployment, provider, identity-authentication or owning-Book acceptance
qualification. The development toolchain is Moon 0.1.20261016 / moonc
0.10.16+b1a0e846e; bounded syntax-only compatibility edits replace removed `try?`
expressions in required existing compilation inputs. No dependency version was
upgraded by this feature.

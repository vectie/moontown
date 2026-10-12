# Search retained collaboration outcomes

Find which retained collaboration contains a phrase without reopening every
result. `outcome_search` reads the same verified local dossiers as the outcome
library and exports attributed matches as Markdown or JSON. It searches saved
questions, assignments, successful contributions, participant diagnostics,
source metadata, and the selected review's decision text. It does not search
source file bodies, binary files, live Books, or superseded decision history.

This is a CLI workflow and reusable API. The existing desktop UI has no new
search control. No search invokes a collector, runtime, provider, Book writer,
schedule, synthesis or review decision.

## Query and run

Build the native `src/cmd/outcome_search` executable using the exact paired Chat
R68 source and root graph from [the composer](COLLABORATION_COMPOSER.md).
As with other commands, the first argument is the existing collaboration-authoring
store, not a suite root or a Book root. Write a local `query.json`:

```json
{
  "text": "incomplete observations",
  "case_sensitive": false,
  "book_id": "",
  "review_status": "",
  "selections": []
}
```

```sh
outcome_search /absolute/existing/collaboration-store query.json markdown > matches.md
outcome_search /absolute/existing/collaboration-store query.json json > matches.json
```

All five query fields are required. The phrase is literal, not a regular expression,
query language or semantic search. It can contain spaces, newlines and Unicode.
Case-insensitive matching folds ASCII letters only; non-ASCII letters remain exact.
`case_sensitive: true` matches all characters exactly. A query must contain
non-whitespace text and be at most 128 UTF-16 code units; leading/trailing spaces
are significant and are not trimmed.

- Empty `book_id` searches every field. An exact Book ID restricts matching to
  that Book's assignments, source metadata, contribution and diagnostics. Shared
  question, title and decision fields do not acquire Book attribution merely
  because that Book participated.
- Empty `review_status` accepts all selected review dispositions. Allowed filters
  are `pending_review`, `accepted`, `rejected`, and `deferred`. These refer to the
  selected historical review, never presumed live or Book-owned acceptance.
- Empty `selections` indexes every saved source revision, including non-current
  revisions, and pins its latest retained review at index time. Each dossier is
  then inspected against that exact pin. A later review does not replace it.
  This is not a transactional snapshot of a whole store or a live-state promise.
- Nonempty `selections` searches only the supplied exact OutcomeKeys. Each key
  contains `draft_id`, `revision`, `result_digest`, `review_version` and
  `review_digest`. Obtain these from the retained library's exact review selection
  or a prior search result. `outcome_compare <root> list` also lists latest retained
  review keys. Duplicate complete keys are rejected; distinct historical reviews
  of the same source revision may be searched together.

For example, save a hit's `key` into the selections array to reproduce its search
after newer decisions arrive. Older reviews retain their original disposition,
prompts and rationale. The command never silently selects a newer review.

## Results and coverage

Each hit carries the exact OutcomeKey, title, recording date, outcome and selected
review status, and verified dossier archive digest. Each matched field has its
Book ID when attributable, identity (source path, contribution reference, run or
decision ID), applicable source/output digest, and a literal excerpt. A contribution
is Book-attributed; this does not claim every sentence is sourced to every captured
file. Source metadata matches preserve the specific captured file digest.

One excerpt is emitted per matching field, centered on that field's first match.
`match_offset`, `excerpt_offset` and `field_length` refer to the original string
in UTF-16 code units. Excerpts include up to 64 units before and after the entire
phrase, extending by one unit if needed to keep a Unicode surrogate pair intact.
The maximum excerpt is 258 units. Repeated occurrences in one field are not
separate results. Excerpts are previews, not the full contribution; inspect the
exact pinned outcome for context.

The candidate count equals searched + excluded + coverage gaps. `not_retained`
means there is no terminal dossier; it does not infer runtime state. `unavailable`
means verification or exact selection failed. Such gaps remain visible even when
their Book/review membership cannot be verified. Hits alongside gaps are useful
partial coverage, not a claim that no other relevant evidence exists. Missing
stores return an empty library without creating files; missing explicit keys
remain unavailable gaps. A store-level enumeration/lock error fails the request.

The existing index bounds are 128 draft directories, 64 revisions per draft and
512 rows. Additional search bounds: 128 explicit keys, 128 matching outcomes,
256 matching fields per outcome, 4096 total matching fields, 128 MiB of inspected
archive bytes, and 4 Mi UTF-16 output units. These bounds fail explicitly and emit
no partial stdout; narrow the phrase, Book filter or exact selections. No silent
result cap or ranking hides matches. Ordering follows the sorted retained index,
or the caller's explicit key order, followed by stable field order.

A successful process exit can contain coverage gaps. Check `gaps`, counts and
`review_selection` before treating an empty hit list as meaningful. Invalid input,
store-level errors and output bounds exit nonzero with a diagnostic on stderr.
Shell redirection itself may create an empty output file on failure.

Markdown renders retained values as indented literal blocks and normalizes CR
line endings for display; JSON preserves exact strings. Search output may contain
private contribution or reviewer text. Inspect it before sharing.

## Qualification

Pure tests cover phrase and case matching, source/contribution attribution,
Book/review/pinned-key filters, missing matches, failures and decisions,
Unicode/UTF-16 excerpt edges, literal Markdown, JSON round-trip and explicit bounds.
Native tests use real retained files and production verification to cover old source
revisions, historical versus later review states, gaps, corruption, missing pins,
empty stores, deterministic output and no mutation. The actual CLI exports both
formats from the retained native fixture and is compared byte-for-byte.

This qualifies local search, not full-product runtime execution, semantic
contradiction detection, a UI, provider, human review identity or deployment.

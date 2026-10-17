# Discover vocabulary bridges before choosing a question

Pack layers can now find words recurring across independently published pack
observations, even when the observations use different evidence paths. This fills
the step before manual source selection, exact shared-material groups, or a
before/after baseline: an operator can discover a possible connection without
already knowing which observations to combine.

## Explore, edit a lens, and propose

1. Open **Pack layers → Discover words connecting different packs**. The initial
   lens uses the initially selected layers. Suggestions rank words by distinct
   publishing-pack count, then observation count, then lexical order. The counts
   are exact word occurrences across observations, not importance scores.
2. Click a suggested word to start a one-word lens, or enter your own comma-separated
   words. **ANY** finds their union; **ALL** requires every word in the same
   observation. This is whole-word matching in titles and summaries only. Paths,
   schema names and other metadata do not create lexical matches.
3. Edit **Hide noisy suggestions** to remove repeated generic vocabulary from the
   suggestion list. These words are still searchable. The built-in English stop
   list, numeric-only words and words shorter than three characters are omitted
   from suggestions, but can always be entered explicitly.
4. Read the exact matching title, summary, matched words, pack identity, source
   reference, schema, lifecycle, pack version, claimed publisher timestamp and
   pack-relative evidence paths. The explorer never fetches those evidence files.
   Page through results in groups of 20. Selections survive pagination.
5. Select two to twelve observations spanning at least two packs. Describe what
   tentative connection deserves investigation, then choose **Continue N match(es)
   to intake**. The existing candidate composer keeps the reviewed lens, selected
   matching words, omitted-match count and coverage gaps as source context.
6. Choose the receiving pack operation; edit the title, rationale, per-source
   connection, rejection test and optional domain JSON. **Submit for review**
   rechecks the selected current observations and destination. The native mailbox
   result remains review-pending; it does not accept Book knowledge or execute a
   pack operation.

Changing words, mode, ignored suggestions, lens name or scope clears selections.
Refreshing current projections also clears selections. Read and select the current
excerpts again. Normal layer filters do not silently change an established lens:
use **Use selected layers for this lens** explicitly. Packs absent from an imported
scope remain named gaps. New packs are not silently added to a retained lens.

## Portable input and output

**Download editable lens** requests a local JSON download containing the name,
explicit pack scope, words, ANY/ALL mode and ignored suggestions. On another
visit, select that JSON under **Import an editable lens**, inspect the preview,
and explicitly choose **Use imported lens**. Cancel preserves the previous lens.
The imported settings remain editable and apply to current projections. A lens
contains neither historical source excerpts nor an uncertain candidate identity.
Importing a lens never uploads, sends a candidate or grants authority.

**Download discovery results** requests a JSON snapshot containing every matching
excerpt, all ranked suggestions, the lens and named gaps, including other result
pages and unselected matches. This is a readout for review, not an importable
historical baseline. Use the separate observation-baseline workflow to compare
changes over time. Browser download invocation is tested; actual saving to disk
is not confirmed by the UI.

An uncertain candidate POST keeps its exact identity and serialized content in
the mounted panel. Reopening intake from this explorer resumes that same dialog;
**Retry same candidate** reuses the original envelope. A page reload does not
restore an uncertain POST. Inspect native candidate receipts before creating a
new copy. Download/import of a lens is not sent-candidate recovery.

## Lexical method and coverage

`nfkc-lowercase-unicode-word-runs-v1` normalizes compatible Unicode forms, applies
JavaScript lowercase and treats contiguous Unicode letters, marks and numbers as
word runs. Punctuation, including hyphens and apostrophes, is a boundary. Canonical
accent compositions normalize together; accents are not removed. There is no
stemming, translation, case-fold equivalence beyond lowercase, or language-specific
segmentation. Continuous Chinese/Japanese text, for example, remains a whole run
unless separated by punctuation or spaces. Explicit queries use these same rules.

Each observation contributes at most once to a word's count. A suggested word must
fit the same search-word length bound after normalization and occur in at least
two distinct scoped packs; their observations can still depend
on the same underlying evidence. Shared words are navigation hints, never semantic
similarity, independent corroboration, agreement, contradiction or proof of genuine
autonomous emergence. A word shared by two domains can mean different things.

Missing, degraded, duplicated or malformed scoped packs become named whole-pack
coverage gaps. A malformed observation does not silently leave a reassuring
partial scan of its pack. Available empty packs remain valid empty inputs.
The candidate preflight checks only selected source snapshots and the destination;
other matches/counts/gaps are historical reviewed discovery context. It is not
atomic with POST and is not a server-side security or acceptance boundary.

Limits: 128 entries per bridge collection, 1,000 projected observations, 1 MiB of
normalized scoped source data, 12 search words of at most 100 UTF-16 code units
each both before and after normalization,
100 ignored suggestion words, 64 KiB per complete portable lens, 4 MiB per complete
discovery export, 40 displayed ranked suggestions, 20 results per page, and 12
selected observations. Scope and size errors fail the whole scan. Source fields
and the final candidate reuse existing bounded validation, including the native
128 KiB complete request limit. Narrow a scope or candidate when necessary.

## Verification and product boundary

The vocabulary test suite exercises the actual mounted explorer and Pack layers
candidate handlers using event-DOM/fetch substitutes. Its deterministic two-pack
journey emits the exact candidate and projection fixtures consumed by a native
test. The native test installs the fixture packs, routes the real envelope, checks
the pack-owned mailbox and reload, and replays the same identity without changing
either projection. This verifies bounded local discovery-to-pending-intake output.

Run `node --test src/ui/rabbita-town/pack_vocabulary.test.js` for the focused
frontend journey. Optional `MOONTOWN_VOCABULARY_SAMPLES` names an existing output
directory for lens, discovery report, current snapshot and actual candidate JSON;
the native test reads matching candidate/snapshot files there and writes its
receipt evidence. Without the variable it uses checked-in exact fixtures.

This is narrow support for MOONTOWN-B03/UC03's explicit-input, cited and
review-pending synthesis slice. Projections are not necessarily MoonBook snapshots.
Configured civic synthesis, owning-Book review/acceptance, real-browser behavior,
full production assembly and paired MoonChat/Rabbita compilation remain separate
unqualified prerequisites. No PRD status is promoted; no standing goal, dispatch
queue, background watch, execution authority or accepted knowledge is created.

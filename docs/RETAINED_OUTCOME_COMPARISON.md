# Compare retained collaboration outcomes

Use the local `outcome_compare` command when you need to review what changed
between two retained collaboration results without opening both dossiers and
manually matching their Books. It compares two explicit historical selections;
it does not collect work, run participants, contact a provider, schedule work,
submit to Book, or change review decisions or accepted knowledge.

## Choose exact evidence

Build `src/cmd/outcome_compare` with the existing paired Town/Chat native graph.
The command takes the absolute existing `collaboration-authoring` store directory,
not the suite root or a participating Book directory. This is the same store used
by the [retained outcome library](RETAINED_OUTCOME_LIBRARY.md).

```sh
outcome_compare /absolute/state/collaboration-authoring list > outcomes.json
```

Choose two completed/partial entries and save each entry's five key fields into
its own JSON file. Entries marked `not_retained` or `unavailable` cannot provide
verified comparison inputs. The fields are `draft_id`, `revision`,
`result_digest`, `review_version`, and `review_digest`; copy their exact values
from the index. The existing UI's selected historical key can also be used.
Never substitute a newer review merely because it exists. A key file is at most
16 KiB, and must be UTF-8 JSON.

```sh
outcome_compare /absolute/state/collaboration-authoring before-key.json after-key.json markdown > changes.md
outcome_compare /absolute/state/collaboration-authoring before-key.json after-key.json json > changes.json
```

Both selected dossiers are verified through the same retained-outcome reader,
under its existing read-only store lock. A changed/missing captured source,
contribution, terminal receipt, result, or selected review makes comparison fail.
Errors exit 1 with stderr and no partial report on stdout. Shell redirection may
still create an empty destination file on failure. `list` on an absent store
returns an empty array without creating the store.

## What the brief shows

- Exact before/after keys, dossier digests, recording dates, questions, named
  reviewer, and outcome/review status, even when the question is unchanged
- Changed question/reviewer/objection context and participant assignments
- Added, removed, changed and unchanged captured sources, matched by Book ID
  plus source path, including byte digest and captured artifact locator
- Attributed contribution changes, including successful text, failure status and
  diagnostics, matched by Book ID rather than participant ordering
- Changed review decisions and rationale, matched by decision ID

Markdown shows complete before/after values for changed entries and counts the
unchanged entries. Its literal blocks keep source Markdown and HTML inert; CR/CRLF line endings
are normalized to LF in the brief only.
JSON also includes full before/after values and provenance for unchanged entries.
Both export formats have a 4 Mi UTF-16-code-unit limit (at most 12 MiB in UTF-8);
limits fail explicitly, never truncate a contribution. Each side of a section
has at most 1024 entries. Existing retained-dossier source and history bounds
continue to apply. The comparison itself is derived and unsigned.

Ordering follows the before side, with newly added entries appended in after
order. Array reordering alone cannot pair one Book with another. Assignments
compare their authored values exactly, including the order of selected source
paths. Source comparisons use digest, byte count and Book title. Their
revision-specific captured path alone does not count as changed evidence.
Contribution comparisons use exact status, detail, output digest and text;
a different packet, proposal, run, or output path alone does not count as an
evidence change. All those identities remain available in the JSON output.

## Interpretation limits

Before and after are explicit user-selected labels, not a chronological claim;
you can compare different drafts or two review versions of the same result.
An absent entry means absent from that selected scope, not a failed Book.
A failed participant retains its failure and never gains invented contribution
text. Identical contribution bytes do not prove that changed inputs remain
valid, and a changed source does not automatically invalidate or approve a
review. Exact differences are not semantic contradiction detection or a
synthesized consensus. Human interpretation and the owning Book's review and
acceptance remain separate.

There is no new UI control or API action in this slice. The shared contract and
native Store method support reuse, while the native command is the complete
local user-facing workflow. Exports may contain sensitive captured-source
identifiers and participant text; inspect them before sharing.

## Verification

Pure contract tests are in `src/collaboration_contract/outcome_comparison_test.mbt`.
Native store tests in `src/collaboration_authoring/outcome_comparison_wbtest.mbt`
construct two real saved revisions, retain local fixture contributions/failures,
compare selected historical reviews, reject changed evidence and verify that
comparison leaves the store byte-identical. They need no model/runtime profile.
Set `MOONTOWN_COMPARISON_EVIDENCE` to an absolute directory to retain exact keys,
expected Markdown/JSON and the test store's root for CLI reproduction. These
synthetic fixtures are local contract evidence, not production Book outcomes.

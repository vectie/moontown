# Compare source-backed claims across Books

Use `claim_compare` to bring a small, explicitly selected set of Book claims into
one readable comparison brief. Import CSV/TSV labels and exact source quotations;
the command checks each quote against the selected local UTF-8 file and emits
Markdown or structured JSON. It reads local snapshots and never starts a worker,
fetches a URL, accepts knowledge, or changes a Book or source.

## A complete local workflow

1. Copy the source text you want to compare into a stable snapshot directory.
   Keep the Book-specific filenames/subdirectories so provenance stays readable.
2. Create a CSV or TSV with these exact headers, in this order:

   `claim_id,book_id,topic,context,value,source_path,quote`

3. Add one row per claim. Give it a unique ID, the owning Book's label, a shared
   topic and precise context (such as a date and product scope), an operator-
   supplied comparison value, a relative source path, and a literal quotation.
   Quotes must appear in the source with the same case, whitespace and newlines.
4. Run the command and review the resulting brief beside the source snapshots:

   ```sh
   claim_compare claims.csv /absolute/source-snapshots markdown > comparison.md
   claim_compare claims.csv /absolute/source-snapshots json > comparison.json
   ```

Only the named table and its selected source paths are read. `source_path` is
relative to the explicitly supplied source directory, never the current Book
catalog or table's directory. No other files are discovered. CSV/TSV supports
quoted commas, tabs, quotes and multiline cells, CR/LF/CRLF records and UTF-8 BOM.
All seven cells must be nonblank; all text, including IDs and surrounding spaces,
is otherwise preserved exactly. Use an explicit context such as `unspecified`
when necessary, understanding that those rows will be grouped together.

Redirect only to a new file, never an input or live registry. The shell truncates
an existing destination before this program runs. Success writes the full report
to stdout; failure exits 1, writes stderr and leaves stdout empty. There is no
partial report, silent missing-source skip, automatic normalization or repair.

## How to interpret the output

Groups share exactly equal `topic` and `context` values, in first-appearance order.
Every claim appears once, in its original order within the group. Different dates
or other contexts remain separate even when their values differ.

- `different_values`: at least two Book labels and more than one exact value
- `same_value`: at least two Book labels, all values textually identical
- `single_book`: one Book label, so there is no cross-Book comparison in that group

These are exact-text comparisons, not semantic contradiction detection. `Yes` and
`yes` are different; equivalent prose is not recognized. A matching quote proves
that the quoted text exists in the captured bytes, not that the operator's value
is entailed by it. Book labels are operator input, not authenticated identities.
The command does not verify source ownership, truth, age, permission or semantic
compatibility. Review those yourself before treating a candidate difference as a
contradiction. A group with two rows from one Book is still `single_book`.

All outputs explicitly remain `pending_review`. This is a bounded claim-intake and
comparison aid toward PRD UC03/R02, not the roadmap's entire reversible review,
source-update invalidation or owning-Book acceptance workflow. It does not retain
or replay a decision. Use each Book's existing review process for any actual change.

JSON retains all imported fields, group states, table SHA-256/byte count and each
unique source path's SHA-256/byte count. Markdown contains the same source-backed
claims and identities; JSON quoting makes controls and newlines visible, while
Markdown punctuation is escaped so source text cannot create active links/HTML.
Source content is not copied wholesale, only the selected exact quotes. Quotes
may contain sensitive information: inspect the report before sharing it.

Changing any captured source bytes changes its digest even if the selected quote
still matches. If a quote disappears, the whole command fails. Re-run against a
new stable snapshot to inspect a change; an old report is historical evidence and
is never silently re-labelled current. Hashes are local integrity identifiers,
not signatures or proof of a human review. The source table and source bytes are
read separately, with no live-filesystem transaction or lock. The supported use
is a stable local snapshot, not a concurrently hostile/mutating filesystem.

## Included example

The synthetic `assets/samples/claim-comparison/claims.csv` and `.tsv` compare Sales
and Engineering's October launch month, show the older September claim separately,
and show a shared Unicode region value. Source files are in the adjacent `sources/`
directory. `comparison.json` and `comparison.md` were emitted by the real command.

```sh
claim_compare assets/samples/claim-comparison/claims.csv \
  assets/samples/claim-comparison/sources markdown
```

The output contains an October `different_values` group (November vs December),
a September `single_book` group, and a `same_value` region group. These are fixture
labels and text, not observations about an actual company.

## Bounds and failure behavior

- Claim table: at most 1 MiB and 1–200 rows; each nonblank cell at most 16,384 UTF-16 code units
- Sources: at most 64 distinct paths, 256 KiB per file, 8 MiB combined
- Successful output: at most 2 MiB, otherwise fail without truncation
- Tables and sources must be regular files and valid UTF-8
- Relative paths cannot be absolute, contain empty/dot/traversal segments,
  backslashes or control characters; resolving outside the selected directory fails
- Symlinks resolving inside that directory are supported; outside symlinks fail
- Missing files, directories, FIFOs, malformed tables, duplicate IDs, unmatched
  quotes, invalid formats and all exceeded limits fail explicitly

The portable `claim_comparison.source_paths` API validates the table and returns
the selected paths. `claim_comparison.report` takes table bytes, a CSV/TSV delimiter,
an exact path-to-bytes map and `json`/`markdown` format; it does no filesystem IO.
Extra or missing source-map entries fail. Both APIs return `Result` with errors.

## Build and focused verification

Use the pinned native Town graph and unchanged real Chat R68 sibling required by
`moon.work`. With an absolute external build target and the shared native lock:

```sh
moon -C /absolute/moontown --target-dir /absolute/external-build \
  build src/cmd/claim_compare --target native --frozen --strip -j 1
moon -C /absolute/moontown --target-dir /absolute/external-build \
  test src/claim_comparison --target native --frozen --strip -j 1
python scripts/verify-claim-comparison.py /absolute/claim_compare.exe /absolute/new-test-output
```

The delivery BUILD.md gives the exact environment, lock, space check, dependencies
and executable path. The black-box tests exercise grouping, literal identities,
source changes, quoting/UTF-8, output escaping, malformed and bounded inputs. The
Python verifier invokes the actual native executable, checks fixture output and
hashes, failure exit/stdout behavior, source boundaries and unchanged sample files.
No graphical UI, live Book/provider/daemon, full-root suite or production service
is qualified by these focused checks.

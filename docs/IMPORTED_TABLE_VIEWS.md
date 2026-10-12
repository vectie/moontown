# Column-aware imported table views

An operator reviewing a CSV/TSV evidence queue can now ask for records whose
**status column equals open**, order them by topic, omit irrelevant fields, and
export the complete result with source data-row numbers. An `open` value in an
unrelated owner or note field no longer has to be removed by hand.

This extends the existing Imported outputs table drawer. Open an included CSV
or TSV, then use **Search in column**, **Exact match**, **Sort by column**, the
ascending/descending button and **Included/Omitted** column buttons. Each header
is numbered, so duplicate and blank labels remain unambiguous. Sorting and
projection affect the preview as well as **Download matching rows (.csv)**.
Rows on other pages are included in the download. All controls reset the page;
**Reset table view** restores the full source order and all columns. Refresh,
close, changing Book/output or selecting a file again clears the entire view.

## Semantics and provenance

- Contains and exact comparisons use ASCII-only case folding: `A/a` match, but
  non-ASCII case variants such as `é/É` remain distinct. Whitespace is significant;
  `open` and ` open` are different exact matches. An empty contains query means
  all rows; an empty exact query finds blank cells in the selected column (or any
  column when All columns is chosen).
- Sorting is lexicographic UTF-16 code-unit order after ASCII-only case folding.
  It is not numeric, date or locale-aware sorting. For example `10` precedes `2`.
  Equal keys retain their original row order in both directions. Blank values
  sort first ascending and last descending. `E/e` are stable ties; `É` sorts
  before `é` ascending regardless of their source order.
- UI output columns retain source order. The CLI additionally accepts an explicit
  ordered projection such as `6,1,2`. Filtering can use an omitted column.
- Every derived download is `table-view.csv`, beginning with a generated
  `source_data_row` column. Its values are 1-based data-row positions after the
  header, not filtered positions or physical line numbers. The remaining labels
  are the original source headers, even if one also says `source_data_row`.
- Values stay strings. Derived CSV quotes every field, uses CRLF, doubles quotes
  and applies the existing apostrophe neutralization to formula-leading values.
  Spreadsheet programs may infer types; import as text to retain leading zeros.
  The exact file download and the verified original text remain unchanged.
- No columns selected disables download with an explanation. No rows matching
  produces a valid header-only export, retaining selected column names.

Source limits remain 1 MiB, 128 columns, 10,000 data rows and 100,000 cells. The
pure export contract validates positions, rejects duplicates and malformed table
shapes, and rejects output above 4 MiB without returning a partial CSV. Its added
provenance column means an export can have one more column than its input.
This is a transient local view, not a saved query, table editor, typed spreadsheet
or acceptance of Book truth. No network request or source mutation is introduced.

## CLI and synthetic example

The native package is `src/cmd/table_view`:

```
table_view <input.csv|input.tsv> <all|filter-column> <contains|exact> <query> <source|sort-column> <asc|desc> <all|1,2,...>
```

Columns use 1-based positions. Read-only local file input; stdout is CSV and
errors go to stderr with exit 1 before any CSV is written. Unsupported filename
extensions, malformed input, invalid column positions, duplicate projections
and invalid modes fail atomically.

With `assets/samples/table-views/research-queue.csv`:

```
table_view research-queue.csv 3 exact open 2 asc 1,2,6
table_view research-queue.csv 3 exact "" source asc all
```

The first returns source data rows 3, 4, 6, 1 in that order. Row 2 is excluded
despite its owner being `open`; equal budget topics retain source order. Unicode,
multiline notes and leading-zero IDs survive; the formula note is neutralized.
The second isolates the blank-status row 5. Actual generated outputs ship beside
the synthetic input. Nothing here is live customer data or a provider result.

`ascii-case.csv` makes the folding limit explicit: exact `é` returns only source
row 1, not `É` in row 2. Sorting column 1 ascending returns source rows 3, 4, 2,
1: ASCII `E/e` remain tied in source order, while `É/é` are distinct. The actual
`ascii-case-filter.csv` and `ascii-case-sort.csv` outputs retain this behavior.

Focused native/JS contracts and compiled Rabbita transition/render/export tests
exercise this workflow. They do not qualify a graphical browser session, a live
Book gateway, always-on Town operation, or the complete root aggregate.

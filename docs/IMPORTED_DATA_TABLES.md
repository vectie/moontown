# Explore imported CSV and TSV outputs

MoonTown's **Imported outputs** drawer can now explore delimited data already
included in an imported MoonBook. Open the drawer, choose a Book, an output,
then its `.csv` or `.tsv` file. The host uses the existing pinned source/package,
manifest and member digest checks before returning text. No source fetch,
provider call, Book mutation or approval workflow is added.

## Everyday workflow

1. Select an included CSV/TSV file. **Table view** opens automatically when the
   complete verified text parses successfully.
2. Search any column with ASCII-only case folding (`A/a` match; `é/É` do not).
   The count shows all
   matching rows, and **Previous rows / Next rows** browse 25 at a time.
3. **Download matching rows (.csv)** exports every matching row, including
   matches on other pages, using the current sort and included columns. The first
   column identifies the original source data row; an empty result exports
   headers only. The filename is `table-view.csv`. See
   [column filters, sorting and projections](IMPORTED_TABLE_VIEWS.md).
4. **Raw text** displays the verified original. **Download exact file** retains
   the existing fresh host revalidation and exact-byte download.

The first record is always a header. Duplicate and blank header cells are
preserved; a blank header displays as `Column N`. Row labels count data rows,
starting with 1 after the header. Values remain text: leading zeros, whitespace,
Unicode, quoted separators and embedded quoted newlines are preserved. This is
an exploration/export view, not a typed spreadsheet or a source editor.

CSV uses commas and TSV uses tabs. Both support doubled quotes in quoted fields,
CRLF, LF or CR record endings, and one leading UTF-8 BOM. An extensionless file
can use a `text/csv`, `application/csv` or `text/tab-separated-values` MIME type.
A `.txt` preview inside a CSV output stays raw text. Unclosed quotes, characters
after a closing quote, inconsistent column counts and NULs produce a clear
error rather than an incomplete or guessed table. Blank records are not silently
discarded. Files without a header need a header added before import.

## Derived export and limits

The derived CSV quotes every cell, doubles embedded quotes, and uses CRLF record
endings. Formula-leading cell values (including headers) are prefixed with an
apostrophe for spreadsheet safety: `=`, `+`, `-` or `@` after leading whitespace,
and leading tab/CR/LF. This intentionally changes those derived cells, including
negative-number text. Use **Download exact file** when original bytes are needed.
Spreadsheet programs can still infer types such as numbers; import as text when
preserving leading zeros matters.

Table view accepts at most 1 MiB of UTF-8 content, 128 columns, 10,000 data rows
and 100,000 cells including the header. These are complete-table limits; it never
silently truncates a table or exports a partial result. The existing raw-text
limit is 4 MiB and exact-download member limit is 16 MiB. Oversized or malformed
tables keep the existing raw/exact-download routes. The drawer is ephemeral;
closing, refreshing or changing the selected file clears the table/search/page.
Cells are rendered as escaped text, with no formula, HTML or script execution.

## Samples and validation

`assets/samples/imported-tables/river-research.csv` and `river-research.tsv` show
Unicode, quoted separators, quoted newlines and leading-zero IDs. Include them
as ordinary output members using MoonBook's existing portable output/import
workflow, then explore them here. Search `river` and export to select the two
river records. Samples are synthetic, contain no personal data, and make no
claim about a live public source.

Focused checks cover the parser, the existing native filesystem discovery and
verified-response path, the compiled Rabbita view/state, search/paging, escaped
cells, all-pages export, raw fallback and reset behavior. These do not claim a
live graphical browser or macOS validation. Town still requires the shipped
paired MoonChat sibling described in `COLLABORATION_COMPOSER.md`; no MoonChat
source change is required for this feature.

## Tables with place coordinates

For CSV/TSV with latitude and longitude columns, the drawer also offers
**Explore table as places** with explicit name/category mapping, the existing
coordinate schematic and selected GeoJSON/original-column CSV exports. See
[the places intake guide](IMPORTED_TABLE_PLACES.md).

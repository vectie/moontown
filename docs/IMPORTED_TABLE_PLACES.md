# Explore imported CSV/TSV as places

Open **Imported outputs**, choose a Book output and its included CSV or TSV,
then use **Explore table as places** below the table/raw controls.

1. Choose separate **Latitude**, **Longitude**, **Name** and **Category** columns.
   Choices show their 1-based position as well as the header, so duplicate or
   empty headers are unambiguous. Nothing is guessed from a column name.
2. Click **Explore places**. Every data row becomes a Point in the existing
   coordinate schematic. This uses the whole table, independent of table search.
3. Search names/categories, select individual places or **Select all matching**,
   then download selected GeoJSON or CSV. Selection persists across filters and
   includes all matching pages. Use **Clear selection** to start over.
4. Table/raw views and **Download exact file** remain available. Changing a
   column or clicking Explore again clears the old place filters and selection.
   Choosing another file/book, refresh or closing clears the mapping too.

## What is kept

Each generated GeoJSON feature has a stable `table-row-N` ID, mapped `name` and
`category`, and WGS84 `[longitude, latitude]` coordinates. Its
`properties.source_table` has `data_row` (1-based, header excluded), `headers`
and `cells`. These ordered arrays preserve every original column, including
duplicate labels, empty labels, leading zeros, coordinate spelling and multiline
text. Header names cannot overwrite the mapped fields. No values become HTML or
links, and no source bytes or Book/Town records are changed.

Selected CSV keeps all original headers/columns and source row order. It uses
the existing spreadsheet-safe export: formula-leading cells are prefixed with
an apostrophe, including negative coordinate strings. For exact bytes use the
original download; for reimportable geometry use GeoJSON. CSV safety prefixes
must be removed deliberately before such a CSV can be mapped back to numbers.

## Supported inputs and limits

- Existing bounded UTF-8 CSV/TSV parser: header first; quoted separators,
  escaped quotes and quoted newlines; CRLF/LF/CR and BOM supported.
- Four distinct explicit columns; blank names/categories are retained as empty
  text. Coordinates are finite WGS84 decimal degrees. Surrounding coordinate
  whitespace and scientific notation are accepted; latitude is -90 to 90,
  longitude -180 to 180. Zero is valid. Decimal commas, DMS and projected/local
  coordinates are unsupported. The operator is responsible for the coordinate
  system; ranges cannot detect a plausible but wrong mapping.
- At most 1 MiB source text, 128 columns, 100,000 cells, 2,000 places and 1 MiB
  derived GeoJSON. Repeated header preservation can reach the derived limit
  before the source limit. A malformed row or coordinate rejects the complete
  intake and reports its data-row number. There is no partial-row import.
- The schematic is the existing local view, at most 100 whole features and
  2,000 positions. All accepted places remain searchable/selectable/exportable.
  North is up, axes scale independently; no basemap, geocoding, routing, external
  map service or live location. For a separate Polygon boundary file, use the local
  [table-to-zone join command](TABLE_ZONE_JOIN.md) to export all assignments,
  overlaps and unmatched places. The drawer itself remains a one-file view.
- Native CLI reads the local file before parser size validation. No streaming
  intake, persistent mapping recipe, provider or graphical-browser qualification.

## Native CLI

Build `src/cmd/places_export` for native. It writes the same filtered exports to
stdout, using explicit **1-based** column positions:

```text
places_export INPUT csv|tsv LAT LON NAME CATEGORY geojson|csv QUERY
places_export assets/samples/table-places/venues.csv csv 2 3 1 4 geojson reception
places_export assets/samples/table-places/venues.csv csv 2 3 1 4 csv reception
places_export assets/samples/table-places/landmarks.tsv tsv 2 3 1 4 geojson ""
```

An empty query includes all rows; filtering is case-insensitive name/category
substring matching. Invalid mappings, malformed inputs and unreadable files fail
without an export on stdout. `--help` describes the interface.

Synthetic inputs and actual native outputs are under
`assets/samples/table-places/`: the reception query returns Welcome Pavilion and
West Gate, retaining the duplicate Note columns, leading-zero contact IDs and
multiline value. The TSV example includes negative coordinates and the origin.

# Assign table places to a separate zones file

A venue list and district boundaries often arrive as different Book outputs.
`table_zones` connects the existing CSV/TSV places intake to the existing Polygon
membership contract, without requiring you to combine both into one GeoJSON file.
It writes a complete portable assignment report, including places outside every
zone and places belonging to more than one zone.

This is a local command and reusable API. The Imported outputs drawer still
explores one file at a time; no new UI control is claimed. Download the two exact
included files from the existing drawer, or use equivalent local supplied files.
The command records their exact byte digests but does not independently establish
Book/package authenticity, freshness, survey accuracy or accepted knowledge.

## Run it

Build native `src/cmd/table_zones` with the existing paired Town/Chat root graph.
The command is:

```sh
table_zones TABLE.csv|TABLE.tsv ZONES.geojson LAT LON NAME CATEGORY geojson|csv
```

The four mappings are distinct 1-based table column positions. Nothing is guessed
from a header, and duplicate/blank headers are allowed. The table's filename
selects CSV or TSV. The second file must contain a supported GeoJSON
FeatureCollection with at least one Polygon. Its filename is not interpreted.
Point and LineString features in that collection are ignored for membership;
GeoJSON output records their count. Unsupported geometry such as MultiPolygon
fails the whole intake, using the existing parser.

For the synthetic supplied examples:

```sh
table_zones assets/samples/table-zones/venues.csv assets/samples/table-zones/districts.geojson 2 3 1 4 geojson > assigned-places.geojson
table_zones assets/samples/table-zones/venues.tsv assets/samples/table-zones/districts.geojson 2 3 1 4 csv > assignments.csv
```

Both examples yield eight places: four matched, four unmatched, two of the
matched places overlapping both zones, and six total memberships. CSV has ten
data rows because overlapping places appear twice. The zone source includes one
ignored reference Point. Duplicate zone IDs deliberately demonstrate why exact
source feature positions, rather than IDs alone, identify zones.

Inputs are read once and never written. Output goes to stdout after the complete
result succeeds; errors go to stderr with exit 1 and no partial stdout. Shell
redirection itself may create an empty file on failure. Never redirect output to
an input path: the shell truncates the file before the command can read it.
The command reads local files fully before enforcing the input size limit.

## Read the report

GeoJSON emits one Point per original data row, in original order. Properties
retain mapped `name` and `category`, and `source_table` with the 1-based data row,
all ordered headers, and every original cell string. The added
`zone_memberships` array contains each matching zone's 1-based source feature,
original JSON ID (null if absent), name and category, in zone source order.
Unmatched points have an empty membership array. No first-match winner is chosen.

Collection-level `moontown_zone_join` metadata includes the contract version,
exact SHA-256 digest and byte count for each source, the four column mappings,
counts and the membership policy. Digests refer to original UTF-8 bytes, including
BOMs and line endings. Source positions are local to those exact files, not
persistent IDs across source revisions. Polygon geometries and collection-level
source metadata are not copied into the derived file; keep the two source files
when the report must be independently reproduced. The GeoJSON can be opened by
the existing explorer if it fits that explorer's 1 MiB input limit.

CSV emits one row per matching place/zone pair. An unmatched place still emits
one row, with a zero membership count and blank zone fields. The first eight
columns are:

1. `source_table_digest`
2. `source_zones_digest`
3. `source_data_row`
4. `zone_membership_count`
5. `zone_source_feature`
6. `zone_id_json`
7. `zone_name`
8. `zone_category`

Every original table column follows, preserving its label and source order even
if it duplicates a generated name. `zone_id_json` is a JSON literal: a string ID
has quotes, a numeric ID does not, and an absent ID is `null`; unmatched rows
have a blank field. Row ordering is table source order, then zone source order.
CSV is a flat membership view. Use GeoJSON for mapping/summary metadata and for
source identities when the table contains only headers (CSV then has no rows).

CSV quotes every cell, doubles embedded quotes and uses CRLF record endings.
Like existing derived exports, it prefixes formula-leading cells with an
apostrophe, including negative coordinate text and formula-looking headers.
GeoJSON retains the original strings and numeric geometry. Neither export
executes cell values or turns them into links. Review private source values before
sharing. This command performs no upload, network query, geocoding, routing,
subscription, Book write or review transition.

## Geometry and bounds

The existing zone semantics apply: straight segments in WGS84 longitude/latitude,
exterior edges/vertices included, holes and hole edges/vertices excluded. Altitude
is irrelevant to membership. Either winding is accepted. There is no geodesic
projection or fuzzy-edge tolerance; floating-point precision applies near edges.
Inputs must contain valid simple polygons and disjoint interior holes. Structural
validation checks range, closure, nonzero area and dateline jumps, but does not
prove topology, repair self-crossings or validate hole containment. Split
antimeridian-crossing polygons and prepare valid topology in a GIS tool first.
This is unsuitable as cadastral, regulatory, safety or navigation authority.

Existing limits remain: 1 MiB UTF-8 per input, 128 table columns, 100,000 table
cells, 2,000 place rows, 2,000 zone-source features and 20,000 zone-source positions.
The existing table-to-places intermediate must also fit its 1 MiB derived GeoJSON
limit. The join adds a 20-million bound on places multiplied by polygon positions,
10,000 associations including one per unmatched place, and 4 MiB final UTF-8
output. All failures are atomic; no truncation or partial assignments are returned.
A header-only table is valid and reports zero places; no-Polygon sources fail
rather than pretending the source defined zero zones.

## API and checks

`imported_output_contract.table_zones_export` accepts the exact table and zone
Bytes, delimiter, zero-based mapping parameters and output format. It uses the
same complete parsers, source-preserving place mapping and polygon-membership
functions as the existing explorer. It returns `Result[String, String]`.

Focused portable contract tests cover holes/edges, overlap, duplicate zone IDs,
source rows/values, CSV/TSV, empty tables, malformed inputs, mapping errors,
spreadsheet safety, deterministic output and amplification bounds. The native
CLI verifier checks actual file reads, source SHA-256 values, both exports,
nonzero failures with empty stdout, and byte-identical inputs:

```sh
python3 scripts/verify-table-zones.py /absolute/path/table_zones.exe /absolute/path/to/source /absolute/evidence-directory
```

This extends the existing Wenyu district/physical-space exploration (Wenyu PRD
§3.1/§3.9) and source-bounded operator-view context of authored MOONTOWN-UC05/B05.
It does not complete civic coordination, a recurring watch, semantic synthesis,
frontend integration, authenticated Book intake, a production service or a live
customer/provider workflow.

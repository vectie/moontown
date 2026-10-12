# Imported places and routes

Open the existing **Imported outputs** drawer, select an included output, then
select its `.geojson` file. Files declared `application/geo+json` also qualify.
The existing content endpoint verifies the catalog-pinned digest before the
explorer receives text. Ordinary `.json` with `application/json` remains raw JSON.

The explorer shows a local coordinate schematic and cards for GeoJSON Point,
LineString and Polygon features. Search names/categories, filter places, routes or zones, and
select individual features or all matching features. Cards paginate at 25.
Selections survive search/filter/page changes; their count includes hidden
selections. Selecting all matching replaces the selection. Clear removes it.

Download selected features as GeoJSON to hand off to a GIS application, or CSV
to inspect every coordinate/route vertex in a spreadsheet. GeoJSON retains each
selected source feature, including IDs, arbitrary properties and optional third
coordinates. It creates a new FeatureCollection in source order; collection-level
foreign members and stale bounding boxes are not copied. CSV is one row per
vertex in source order, with formula-leading fields apostrophe-prefixed. No
route optimization or new connecting route is generated. Original exact-file
download and raw source remain available.

For district boundaries, courtyard holes and finding places within a zone, see
[Imported zone queries](IMPORTED_GEOJSON_ZONES.md). Polygon exports add ring and
ring_vertex CSV columns; existing Point/LineString-only CSV keeps its six columns.

## Offline command

Build `src/cmd/geo_export` with the native target, then run its executable:

```
geo_export valley-tour.geojson geojson reception all > selected-reception.geojson
geo_export valley-tour.geojson csv reception all > selected-reception.csv
geo_export valley-tour.geojson geojson "" Point > all-places.geojson
```

Arguments are input path, output format (`geojson` or `csv`), case-insensitive
name/category substring, and kind (`Point`, `LineString`, `Polygon`, or `all`). The
optional `--within <1-based Polygon source feature number>` finds Point places
inside that zone, combined with the search. Output goes
only to stdout. Redirect to a different file from the input, because shell
redirection can truncate a file before the program reads it. Bad arguments,
unreadable input and invalid/unsupported collections fail without a report.

`assets/samples/imported-places/valley-tour.geojson` is synthetic district data.
The adjacent `selected-reception.geojson` and `.csv` are actual CLI outputs,
showing two reception places and the supplied walking route.

## Scope and limits

- UTF-8 GeoJSON FeatureCollection, WGS84 longitude/latitude positions in standard
  bounds, 2 or 3 numeric coordinates; Point, LineString and bounded Polygon.
  See the zone guide for simple-ring and planar-query limits.
- Maximum 1 MiB, 2,000 features and 20,000 positions. Unsupported geometry,
  invalid positions or a legacy CRS declaration rejects the whole explorer
  view with a reason; the raw source and exact original download remain.
- Missing names fall back to `title`, then a source feature number. Search uses
  names and string categories only. Arbitrary properties stay inert.
- Schematic draws at most 100 complete matching features / 2,000 positions.
  Long lines are omitted rather than partially drawn; coverage is labeled.
  All matching cards/exports remain available. Axes scale independently,
  north is up, and dateline wrapping is not modeled. This is not a basemap,
  distance measurement, navigation, road routing, or on-site accessibility check.
- No external map requests, device geolocation, uploads, bookings, automatic
  route generation, source mutation or persistent Town memory updates.

This supports PRD §3.6 reception-route exploration and §3.9 physical-space
signals as a portable, read-only data workflow. It does not claim the larger
venue booking, talent graph or civic acceptance criteria are completed.

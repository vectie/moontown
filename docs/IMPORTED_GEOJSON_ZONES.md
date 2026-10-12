# Find places inside an imported zone

Use this when a Book output already contains a district, venue or site boundary
and you need the places within it as a portable handoff. This is an offline
exploration workflow over supplied data, not a map service or boundary survey.

## In the Town drawer

1. Open **Imported outputs** and choose the included `.geojson` file (or a file
   with `application/geo+json`). Existing digest verification still applies.
2. The explorer now draws Polygon exteriors and courtyard holes alongside
   Point places and LineString routes. Select **Zones (Polygon)** to inspect
   boundaries and their unchanged properties.
3. Under **Find places in a zone**, choose the numbered source zone. The list
   now contains only Point places inside it. Search name/category to narrow it
   further. The schematic includes the chosen zone outline when it fits the
   existing display limit, and shows holes unfilled.
4. Click **Select all matching**, then download the selected GeoJSON or CSV.
   Changing a filter keeps the old selection until you replace or clear it.
   The zone filter itself does not select/export the zone. To export its
   boundary, change geometry kind to Polygon and select that feature.

Choosing All locations or changing geometry kind clears the zone constraint.
Changing the imported file, refreshing, or closing the drawer resets it. A
zone with no matching places gives an explicit empty result. Original exact
file download and verified raw JSON remain available, including on parse error.

## Command line and included example

Build the native `src/cmd/geo_export` command. From the repository root:

```sh
geo_export assets/samples/imported-zones/district-places.geojson geojson reception Point --within 1 > reception-in-zone.geojson
geo_export assets/samples/imported-zones/district-places.geojson csv reception Point --within 1 > reception-in-zone.csv
geo_export assets/samples/imported-zones/district-places.geojson geojson "" Polygon > zone-boundaries.geojson
geo_export assets/samples/imported-zones/district-places.geojson csv "" Polygon > zone-vertices.csv
```

`1` means source feature number 1, the North reception zone. It is not a GeoJSON
ID and does not change with filters. Invalid or non-Polygon feature numbers
fail. `--within` accepts Point or all kinds; routes and other polygons are not
point locations. Search and zone membership are intersected.

The synthetic input has a district with one courtyard hole, two reception
places inside/on its edge, one reception point in the hole, one outside, a
culture place inside, and a walking route. The reception query returns exactly
**Welcome Pavilion** and **West Gate**. The adjacent output files are actual
native CLI results, not hand-authored approximations. Do not redirect stdout
to the input path: the shell would truncate that file before the command reads it.

## Output contract

- GeoJSON retains the complete selected source features, including IDs,
  arbitrary properties, hole rings, winding and altitude coordinates. It
  creates a new FeatureCollection and does not copy collection-level metadata.
- CSV emits every source vertex in order. If any selected feature is a Polygon,
  it adds `ring` and `ring_vertex` after the original six columns. Both are
  1-based: ring 1 is exterior, later rings are holes, and the repeated closing
  vertex is retained. These two cells are blank for non-Polygon features.
  Point/LineString-only exports retain the existing six-column schema.
- CSV fields remain formula-neutralized. CSV is a spreadsheet view, not a
  lossless geometry format; use GeoJSON to preserve properties and altitude.
- No source file, Book catalog, or Town memory is changed.

## Supported geometry and interpretation

Supply a valid simple Polygon: exterior first, zero or more disjoint interior
holes, each fully inside the exterior. Rings need at least four positions,
identical first/last coordinates (including altitude if given), nonzero signed
area and valid WGS84 coordinates. Either winding direction works. A ring edge
jumping more than 180° longitude is rejected; split dateline-crossing zones
before importing. MultiPolygon/GeometryCollection remain unsupported.

Membership uses straight segments in longitude/latitude coordinates and a
ray-crossing query. Exterior edges/vertices belong to the zone; a hole and its
edges/vertices are excluded. Altitude does not affect membership. There is no
geodesic projection, area/distance measurement or fuzzy boundary tolerance.
Numerically near an edge, floating-point precision applies. Use suitable local
zones; this is not cadastral, regulatory, safety or navigation authority.

The importer checks the stated structural bounds, closure, coordinate range,
zero area and dateline jumps. It does not repair or fully validate polygon
topology: self-crossings, overlapping/nested holes, or holes outside the exterior
are invalid inputs. Prepare valid simple rings in a GIS editor first.

Existing caps apply: 1 MiB, 2,000 features, 20,000 positions per collection.
The schematic shows at most 100 whole features and 2,000 positions with explicit
coverage. A large omitted polygon remains queryable/exportable in full. No
external basemap, geolocation, online requests, uploads or route generation.

This extends Wenyu PRD §3.1 district exploration and §3.9 physical-space inputs.
It does not claim completed civic coordination, venue booking, field mapping,
provider integration or deployment.

## Separate table and zone sources

Use [table-to-zone join](TABLE_ZONE_JOIN.md) when place coordinates arrive as a
CSV/TSV file and zone boundaries as a separate GeoJSON file. The native command
exports every membership, including overlaps and explicitly unmatched places.

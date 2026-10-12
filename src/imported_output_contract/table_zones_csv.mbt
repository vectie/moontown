///|
/// One row per membership; unmatched places receive one row with blank zone
/// fields. Generated provenance columns precede every original table column.
fn table_zones_csv(
  table : DataTable,
  zones : Array[GeoFeature],
  memberships : Array[Array[Int]],
  table_digest : String,
  zone_digest : String,
) -> Result[String, String] {
  let headers = [
      "source_table_digest", "source_zones_digest", "source_data_row", "zone_membership_count",
      "zone_source_feature", "zone_id_json", "zone_name", "zone_category",
    ] +
    table.headers
  let lines = [headers.map(csv_cell).join(",")]
  let mut bytes = @utf8.encode(lines[0]).length() + 2
  for p, row in table.rows {
    let matches = memberships[p]
    let indices = if matches.is_empty() { [-1] } else { matches }
    for z in indices {
      let zone_cells = if z < 0 {
        ["", "", "", ""]
      } else {
        [
          (z + 1).to_string(),
          geo_field(zones[z].source, "id").stringify(),
          zones[z].name,
          zones[z].category,
        ]
      }
      let cells = [
          table_digest,
          zone_digest,
          (p + 1).to_string(),
          matches.length().to_string(),
        ] +
        zone_cells +
        row
      let line = cells.map(csv_cell).join(",")
      bytes += @utf8.encode(line).length() + 2
      if bytes > 4 * 1048576 {
        return Err("Joined output exceeds 4 MiB; narrow the sources")
      }
      lines.push(line)
    }
  }
  if bytes > 4 * 1048576 {
    return Err("Joined output exceeds 4 MiB; narrow the sources")
  }
  Ok(lines.join("\r\n") + "\r\n")
}

///|
/// Interpret explicitly selected, zero-based table columns as WGS84 places.
/// Every row must be valid. Original column labels, order and cell strings are
/// retained in properties.source_table, including duplicate/empty labels.
pub fn DataTable::places(
  self : DataTable,
  latitude~ : Int,
  longitude~ : Int,
  name~ : Int,
  category~ : Int,
) -> Result[Array[GeoFeature], String] {
  let columns = [latitude, longitude, name, category]
  for i, column in columns {
    if column < 0 || column >= self.headers.length() {
      return Err("Choose a column for latitude, longitude, name and category")
    }
    for j = 0; j < i; j = j + 1 {
      if columns[j] == column {
        return Err(
          "Latitude, longitude, name and category need distinct columns",
        )
      }
    }
  }
  if self.rows.length() > 2000 || self.headers.length() > 128 {
    return Err("Places intake supports at most 2,000 rows and 128 columns")
  }
  let features : Array[GeoFeature] = []
  let mut payload_bytes = 0
  for index, row in self.rows {
    let prefix = "Data row " + (index + 1).to_string() + ": "
    if row.length() != self.headers.length() {
      return Err(prefix + "column count differs from the header")
    }
    let lat = match (try? @string.parse_double(row[latitude].trim())) {
      Ok(value) if value >= -90.0 && value <= 90.0 => value
      _ => return Err(prefix + "latitude must be a number from -90 to 90")
    }
    let lon = match (try? @string.parse_double(row[longitude].trim())) {
      Ok(value) if value >= -180.0 && value <= 180.0 => value
      _ => return Err(prefix + "longitude must be a number from -180 to 180")
    }
    let source : Json = {
      "type": "Feature",
      "id": "table-row-" + (index + 1).to_string(),
      "geometry": { "type": "Point", "coordinates": [lon, lat] },
      "properties": {
        "name": row[name],
        "category": row[category],
        "source_table": {
          "data_row": index + 1,
          "headers": self.headers,
          "cells": row,
        },
      },
    }
    // Repeated headers must not amplify a bounded table into a huge collection
    // before the final pretty-printed output size check.
    payload_bytes += @utf8.encode(source.stringify()).length()
    if payload_bytes > 1048576 {
      return Err(
        "Derived places exceed the 1 MiB GeoJSON limit; use a smaller table",
      )
    }
    features.push({
      name: row[name],
      category: row[category],
      kind: "Point",
      points: [{ longitude: lon, latitude: lat, }],
      source,
    })
  }
  // Keep derived collections usable by the existing bounded GeoJSON intake.
  if @utf8.encode(geojson_selection(features, features.mapi((i, _) => i))).length() >
    1048576 {
    return Err(
      "Derived places exceed the 1 MiB GeoJSON limit; use a smaller table",
    )
  }
  Ok(features)
}

///|
/// Export selected original rows in source order, with original column labels
/// and order. CSV escaping and formula neutralization match the table explorer.
pub fn DataTable::selection_csv(
  self : DataTable,
  selected : Array[Int],
) -> String {
  let lines = [self.headers.map(csv_cell).join(",")]
  for index, row in self.rows {
    if selected.contains(index) {
      lines.push(row.map(csv_cell).join(","))
    }
  }
  lines.join("\r\n") + "\r\n"
}

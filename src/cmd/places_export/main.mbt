///|
async fn run() -> Unit {
  let usage = "Usage: places_export <input> <csv|tsv> <latitude-column> <longitude-column> <name-column> <category-column> <geojson|csv> <query>\nColumns are distinct 1-based positions. Reads a bounded local UTF-8 table, validates every row as WGS84 decimal degrees, and writes name/category matches to stdout. GeoJSON keeps original columns in properties.source_table; CSV keeps original columns with spreadsheet-safe escaping. Use an empty query for all places."
  match @env.args()[1:] {
    ["--help"] | ["-h"] => println(usage)
    [path, delimiter, lat, lon, name, category, format, query] => {
      guard (delimiter == "csv" || delimiter == "tsv") &&
        (format == "geojson" || format == "csv") else {
        fail(usage)
      }
      let table = match
        @places.parse_data_table(
          @fs.read_file(path).text(),
          if delimiter == "csv" {
            ','
          } else {
            '\t'
          },
        ) {
        Ok(table) => table
        Err(reason) => fail(reason)
      }
      let columns = [lat, lon, name, category].map(value => {
        let mut found = -1
        for i, _ in table.headers {
          if (i + 1).to_string() == value {
            found = i
          }
        }
        found
      })
      let features = match
        table.places(
          latitude=columns[0],
          longitude=columns[1],
          name=columns[2],
          category=columns[3],
        ) {
        Ok(features) => features
        Err(reason) => fail(reason)
      }
      let selected = @places.geo_matches(features, query, "Point")
      @stdio.stdout.write(
        if format == "geojson" {
          @places.geojson_selection(features, selected)
        } else {
          table.selection_csv(selected)
        },
      )
    }
    _ => fail(usage)
  }
}

///|
async fn main {
  run() catch {
    error => {
      @stdio.stderr.write("places_export: \{error}\n")
      @sys.exit(1)
    }
  }
}

///|
fn column(value : String) -> Int raise {
  let index = @string.parse_int(value) catch { _ => 0 }
  if index < 1 || index > 128 {
    fail("Columns must be 1-based positions from 1 to 128")
  }
  index - 1
}

///|
async fn run() -> Unit {
  let usage = "Usage: table_zones TABLE.csv|TABLE.tsv ZONES.geojson LAT LON NAME CATEGORY geojson|csv\nColumns are distinct 1-based positions. Joins all table places against all Polygon features in the separate zones file, retaining unmatched places and every overlap. Output includes exact input SHA-256 digests and source row/feature numbers. Geometry uses the existing planar WGS84 outer-boundary/hole policy, not geodesic or regulatory boundaries. Inputs remain unchanged; never redirect output over an input."
  match @env.args()[1:] {
    ["--help"] | ["-h"] => println(usage)
    [table_path, zones_path, lat, lon, name, category, format] => {
      let delimiter = match @table.table_delimiter(table_path, "") {
        Some(value) => value
        None => fail("Table filename must end in .csv or .tsv")
      }
      let latitude = column(lat)
      let longitude = column(lon)
      let name = column(name)
      let category = column(category)
      let table = @fs.read_file(table_path).binary()
      let zones = @fs.read_file(zones_path).binary()
      match
        @table.table_zones_export(
          table,
          zones,
          delimiter,
          latitude~,
          longitude~,
          name~,
          category~,
          format~,
        ) {
        Ok(output) => @stdio.stdout.write(output)
        Err(error) => fail(error)
      }
    }
    _ => fail(usage)
  }
}

///|
async fn main {
  run() catch {
    error => {
      @stdio.stderr.write("table_zones: \{error}\n")
      @sys.exit(1)
    }
  }
}

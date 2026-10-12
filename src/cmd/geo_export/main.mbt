///|
async fn main {
  let usage = "Usage: geo_export <input.geojson> <geojson|csv> <query> <Point|LineString|Polygon|all> [--within <zone-feature-number>]\nReads a local WGS84 FeatureCollection and writes matching features to stdout. --within selects Point places inside the 1-based source Polygon feature; exterior edges included, holes excluded."
  match @env.args()[1:] {
    ["--help"] | ["-h"] => println(usage)
    [path, format, query, kind, .. options] => {
      guard format == "geojson" || format == "csv" else { fail(usage) }
      guard kind == "Point" ||
        kind == "LineString" ||
        kind == "Polygon" ||
        kind == "all" else {
        fail(usage)
      }
      let features = match @geo.parse_geojson(@fs.read_file(path).text()) {
        Ok(features) => features
        Err(reason) => fail(reason)
      }
      let mut selected = @geo.geo_matches(
        features,
        query,
        if kind == "all" {
          ""
        } else {
          kind
        },
      )
      match options {
        [] => ()
        ["--within", number] => {
          guard kind == "Point" || kind == "all" else {
            fail(
              "--within supports Point or all; routes and zones are not point locations",
            )
          }
          let zones : Array[Int] = []
          for i, feature in features {
            if (i + 1).to_string() == number && feature.kind == "Polygon" {
              zones.push(i)
            }
          }
          guard zones is [zone] else {
            fail("--within requires a 1-based Polygon source feature number")
          }
          let contained = @geo.geo_places_in_zone(features, zone)
          selected = selected.filter(i => contained.contains(i))
        }
        _ => fail(usage)
      }
      println(
        if format == "geojson" {
          @geo.geojson_selection(features, selected)
        } else {
          @geo.geo_csv(features, selected)
        },
      )
    }
    _ => fail(usage)
  }
}

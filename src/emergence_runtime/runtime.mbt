///|
pub async fn evaluate_file(input_path : String, output_path : String) -> String {
  let input = @fs.read_file(input_path).text() catch {
    error =>
      return (
        { "accepted": false, "error": "cannot read civic round: \{error}" } :
        Json).stringify(indent=2)
  }
  let round : @emergence.AutonomousCivicRound = @json.from_json(
    @json.parse(input),
  ) catch {
    error =>
      return (
        { "accepted": false, "error": "invalid civic round: \{error}" } : Json).stringify(
        indent=2,
      )
  }
  match @emergence.evaluate_autonomous_civic_round(round) {
    Err(error) =>
      ({ "accepted": false, "error": error } : Json).stringify(indent=2)
    Ok(result) => {
      let rendered = result.to_json().stringify(indent=2) + "\n"
      if @fs.exists(output_path) {
        let existing = @fs.read_file(output_path).text()
        if existing != rendered {
          return (
            {
              "accepted": false,
              "error": "civic round identity already exists with different content",
            } : Json).stringify(indent=2)
        }
      } else {
        @fs.write_file(
          output_path,
          @encoding/utf8.encode(rendered),
          create_mode=CreateNew,
          permission=0o644,
        )
      }
      rendered
    }
  }
}

///|
pub async fn evaluate_file(input_path : String, output_path : String) -> String {
  let input = @fs.read_file(input_path).text() catch {
    error =>
      return (
        { "accepted": false, "error": "cannot read commission: \{error}" } :
        Json).stringify(indent=2)
  }
  let commission : @commission.TownCommission = @json.from_json(
    @json.parse(input),
  ) catch {
    error =>
      return (
        { "accepted": false, "error": "invalid commission: \{error}" } : Json).stringify(
        indent=2,
      )
  }
  match @commission.evaluate_commission(commission) {
    Err(error) =>
      ({ "accepted": false, "error": error } : Json).stringify(indent=2)
    Ok(promotion) => {
      let rendered = promotion.to_json().stringify(indent=2) + "\n"
      @fs.write_file(
        output_path,
        @encoding/utf8.encode(rendered),
        create=0o644,
        truncate=true,
      ) catch {
        error =>
          return (
            { "accepted": false, "error": "cannot write promotion: \{error}" } :
            Json).stringify(indent=2)
      }
      rendered
    }
  }
}

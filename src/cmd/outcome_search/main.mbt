///|
async fn run() -> Unit {
  let usage = "Usage: outcome_search <collaboration-store-root> <query.json> <markdown|json>\nQuery fields: text, case_sensitive, book_id, review_status, selections. Empty strings disable filters. Empty selections searches every source revision with its indexed latest retained review; explicit OutcomeKeys search historical reviews. Book filtering restricts matches to Book-attributed fields. Reads only verified retained evidence. See docs/RETAINED_OUTCOME_SEARCH.md."
  match @env.args()[1:] {
    ["--help"] | ["-h"] => println(usage)
    [root, path, format] => {
      guard format == "markdown" || format == "json" else { fail(usage) }
      let file = @fs.open(path, mode=ReadOnly)
      defer file.close()
      let size = file.size()
      guard file.kind() == Regular && size >= 0L && size <= 131072L else {
        fail("Search query must be a regular file of at most 128 KiB")
      }
      let bytes = file.read_exactly_at(size.to_int(), position=0L)
      let query : @contract.OutcomeSearchQuery = @json.from_json(
        @json.parse(@utf8.decode(bytes)),
      )
      let store : @authoring.Store = { root, catalog_path: "", }
      let result = store.search_outcomes(query)
      let output = if format == "markdown" {
        result.markdown()
      } else {
        result.json_text()
      }
      @stdio.stdout.write(output)
    }
    _ => fail(usage)
  }
}

///|
async fn main {
  run() catch {
    error => {
      @stdio.stderr.write("outcome_search: \{error}\n")
      @sys.exit(1)
    }
  }
}

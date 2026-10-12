///|
async fn read_key(path : String) -> @contract.OutcomeKey {
  let file = @fs.open(path, mode=ReadOnly)
  defer file.close()
  let size = file.size()
  guard file.kind() == Regular && size >= 0L && size <= 16384L else {
    fail("Outcome key must be a regular file of at most 16 KiB")
  }
  let bytes = file.read_exactly_at(size.to_int(), position=0L)
  @json.from_json(@json.parse(@utf8.decode(bytes)))
}

///|
async fn run() -> Unit {
  let usage = "Usage: outcome_compare <collaboration-store-root> list\n       outcome_compare <collaboration-store-root> <before-key.json> <after-key.json> <markdown|json>\nUse list to find exact retained OutcomeKey fields. The root is the existing collaboration-authoring store, not a suite or Book root. Reads only retained evidence; never collects work, launches participants, schedules, or changes Book knowledge. Before/after order is explicit, not inferred."
  match @env.args()[1:] {
    ["--help"] | ["-h"] => println(usage)
    [root, "list"] => {
      let store : @authoring.Store = { root, catalog_path: "", }
      let entries = store.list_outcomes()
      @stdio.stdout.write(entries.to_json().stringify(indent=2) + "\n")
    }
    [root, before, after, format] => {
      guard format == "markdown" || format == "json" else { fail(usage) }
      let left = read_key(before)
      let right = read_key(after)
      let store : @authoring.Store = { root, catalog_path: "", }
      let comparison = store.compare_outcomes(left, right)
      let output = if format == "markdown" {
        comparison.markdown()
      } else {
        comparison.to_json().stringify(indent=2) + "\n"
      }
      guard output.length() <= 4194304 else {
        fail("Comparison output exceeds 4 Mi UTF-16 code units")
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
      @stdio.stderr.write("outcome_compare: \{error}\n")
      @sys.exit(1)
    }
  }
}

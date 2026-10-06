///|
/// Additive parser for explicit per-launch completion permission. The existing
/// four-value parser keeps its original contract and rejects unknown options.
pub fn parse_options(
  args : Array[String],
) -> (String?, String, String, String, Bool) raise {
  let filtered : Array[String] = []
  let mut literal = false
  let mut allow_no_change = false
  let mut index = 0
  while index < args.length() {
    let arg = args[index]
    if !literal &&
      ["--book", "--wenyu-execution", "--wenyu-model"].contains(arg) {
      filtered.push(arg)
      if args.get(index + 1) is Some(value) {
        filtered.push(value)
      }
      index += 2
      continue
    }
    if !literal && arg == "--wenyu-allow-no-change" {
      allow_no_change = true
    } else {
      filtered.push(arg)
      if arg == "--" {
        literal = true
      }
    }
    index += 1
  }
  let (book, execution, model, goal) = parse(filtered)
  guard !allow_no_change || execution == "native" else {
    fail("--wenyu-allow-no-change requires native execution")
  }
  (book, execution, model, goal, allow_no_change)
}

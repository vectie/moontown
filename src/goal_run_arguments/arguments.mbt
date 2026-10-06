///|
/// Parse a new goal's explicit Wenyu route without interpreting flags as goal
/// text. Saved executions keep their separately frozen selection.
///
/// ```mbt check
/// test {
///   assert_eq(
///     @goal_run_arguments.parse(["Build", "Wenyu"]),
///     (None, "native", "", "Build Wenyu"),
///   )
/// }
/// ```
pub fn parse(args : Array[String]) -> (String?, String, String, String) raise {
  let mut book : String? = None
  let mut execution = "native"
  let mut model = ""
  let words : Array[String] = []
  let mut index = 0
  let mut literal = false
  while index < args.length() {
    let arg = args[index]
    if !literal && arg == "--" {
      literal = true
      index += 1
      continue
    }
    if !literal &&
      ["--book", "--wenyu-execution", "--wenyu-model"].contains(arg) {
      guard args.get(index + 1) is Some(value) && value != "" else {
        fail("Missing value for " + arg)
      }
      match arg {
        "--book" => book = Some(value)
        "--wenyu-execution" => execution = value
        _ => model = value
      }
      index += 2
      continue
    }
    if !literal && arg.has_prefix("--") {
      fail("Unknown run option: " + arg)
    }
    words.push(arg)
    index += 1
  }
  guard ["native", "acp"].contains(execution) && !words.is_empty() else {
    fail("Run requires a goal and native/acp Wenyu selection")
  }
  guard execution != "acp" || model == "" else {
    fail("--wenyu-model requires native execution")
  }
  (book, execution, model, words.join(" "))
}

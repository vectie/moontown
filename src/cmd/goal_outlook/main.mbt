///|
async fn read_source(path : String) -> Bytes {
  guard @fs.kind(path) == Regular else { fail("Input must be a regular file") }
  let file = @fs.open(path, mode=ReadOnly)
  defer file.close()
  let size = file.size()
  guard file.kind() == Regular && size >= 0L && size <= 1048576L else {
    fail("Input must be a regular file of at most 1 MiB")
  }
  file.read_exactly_at(size.to_int(), position=0L)
}

///|
fn tick(text : String) -> Int raise {
  guard !text.is_empty() && text.iter().all(c => c >= '0' && c <= '9') else {
    fail("Ticks must be nonnegative signed 32-bit decimal integers")
  }
  @string.parse_int(text)
}

///|
async fn run() -> Unit {
  let usage = "Usage: goal_outlook preview GOALS.json START END json|csv\n       goal_outlook compare BEFORE.json AFTER.json START END json|csv\n       goal_outlook stagger GOALS.json SELECTED_IDS.json START SPACING\nExplore a bounded [START,END) scheduler-tick window from explicit saved StandingGoal snapshots. Cadence-only, assuming immediate successful dispatch; not wall time or actual runtime prediction. Stagger assigns enabled selected goals successive next due ticks in selection order, retaining all other fields. Compare candidates by exact goal ID without installing them. No daemon, worker, Book or provider action. Redirect only to a NEW file, never an input or a live registry. See docs/GOAL_OUTLOOK.md."
  let result = match @env.args()[1:] {
    ["--help"] | ["-h"] => {
      println(usage)
      return
    }
    ["preview", path, start, end, format] =>
      @outlook.report(read_source(path), tick(start), tick(end), format~)
    ["compare", before, after, start, end, format] =>
      @outlook.compare(
        read_source(before),
        read_source(after),
        tick(start),
        tick(end),
        format~,
      )
    ["stagger", path, selection, start, spacing] =>
      @outlook.stagger(
        read_source(path),
        read_source(selection),
        tick(start),
        tick(spacing),
      )
    _ => fail(usage)
  }
  match result {
    Ok(output) => @stdio.stdout.write(output)
    Err(error) => fail(error)
  }
}

///|
async fn main {
  run() catch {
    error => {
      @stdio.stderr.write("goal_outlook: \{error}\n")
      @sys.exit(1)
    }
  }
}

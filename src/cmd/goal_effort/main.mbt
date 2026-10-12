///|
async fn read_source(path : String) -> Bytes {
  let file = @fs.open(path, mode=ReadOnly)
  defer file.close()
  let size = file.size()
  guard file.kind() == Regular && size >= 0L && size <= 1048576L else {
    fail("Inputs must be regular files of at most 1 MiB")
  }
  file.read_exactly_at(size.to_int(), position=0L)
}

///|
async fn run() -> Unit {
  let usage = "Usage: goal_effort STANDING-GOALS.json DIARY.csv|DIARY.tsv json|csv\nRead-only measured human-effort comparison against actual saved StandingGoals. Diary columns: goal_id,period_start,period_end,outcome,manual_period_start,manual_period_end,manual_minutes,review_minutes,supervision_minutes,followup_minutes,note. Dates are YYYY-MM-DD, start-inclusive/end-exclusive. Town periods and manual periods must each be nonoverlapping per goal and paired periods must have equal day counts. Minutes are whole numbers 0..100000, blank means unknown. Manual and Town effort must concern the same named outcome; measured manual minutes require explicit manual dates. JSON retains periods and per-goal totals; CSV summarizes each goal. Differences are reported effort, never inferred productivity. Never redirect output over either input. See docs/GOAL_EFFORT_REPORT.md."
  match @env.args()[1:] {
    ["--help"] | ["-h"] => println(usage)
    [goals_path, diary_path, format] => {
      guard format == "json" || format == "csv" else { fail(usage) }
      let delimiter = match @table.table_delimiter(diary_path, "") {
        Some(d) => d
        None => fail("Diary filename must end in .csv or .tsv")
      }
      let goals = read_source(goals_path)
      let diary = read_source(diary_path)
      match @effort.report(goals, diary, delimiter, format~) {
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
      @stdio.stderr.write("goal_effort: \{error}\n")
      @sys.exit(1)
    }
  }
}

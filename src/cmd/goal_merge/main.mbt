///|
async fn read_source(path : String) -> Bytes {
  let file = @fs.open(path, mode=ReadOnly)
  defer file.close()
  let size = file.size()
  guard file.kind() == Regular && size >= 0L && size <= 1048576L else {
    fail("Input must be a regular file of at most 1 MiB")
  }
  file.read_exactly_at(size.to_int(), position=0L)
}

///|
async fn run() -> Unit {
  let usage = "Usage: goal_merge merge|inspect BASE.json EDITED.json CURRENT.json\nMerge offline edits onto an explicit fresh snapshot. All three inputs are whole StandingGoal arrays, not partial updates. merge emits a complete candidate only without conflicts; inspect emits JSON with exact conflicts and merged_goals:null on conflict. Current order is retained, then edited-only additions. No live write, locking, scheduling, provider or Book action. Use stable copies and redirect only to NEW files. See docs/GOAL_MERGE.md."
  let result = match @env.args()[1:] {
    ["--help"] | ["-h"] => {
      println(usage)
      return
    }
    [operation, base, edited, current] => {
      guard operation == "merge" || operation == "inspect" else { fail(usage) }
      let baseline = read_source(base)
      let changes = read_source(edited)
      let latest = read_source(current)
      if operation == "merge" {
        @merge.merge_snapshots(baseline, changes, latest)
      } else {
        @merge.inspect_snapshots(baseline, changes, latest)
      }
    }
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
      @stdio.stderr.write("goal_merge: \{error}\n")
      @sys.exit(1)
    }
  }
}

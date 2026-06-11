///|
async fn latest_live_autonomy_journal_tick(snapshot_path : String) -> Int {
  let mut latest = 0
  let journal_path = default_town_journal_path(snapshot_path~)
  if @fs.exists(journal_path) {
    for line in @fs.read_file(journal_path).text().split("\n") {
      let trimmed = line.trim()
      if trimmed == "" {
        continue
      }
      let parsed = @json.parse(trimmed) catch { _ => continue }
      let spine : LiveAutonomyJournalTick = @json.from_json(parsed) catch {
        _ => continue
      }
      if spine.tick > latest {
        latest = spine.tick
      }
    }
  }
  let live_path = default_live_autonomy_path(snapshot_path~)
  if @fs.exists(live_path) {
    let parsed = @json.parse(@fs.read_file(live_path).text()) catch {
      _ => return latest
    }
    let spine : LiveAutonomyJournalTick = @json.from_json(parsed) catch {
      _ => return latest
    }
    if spine.tick > latest {
      latest = spine.tick
    }
  }
  latest
}

///|
async fn append_live_autonomy_journal(
  path : String,
  spine : LiveAutonomySpine,
) -> Unit {
  let existing = read_text_or_empty(path)
  let line = spine.to_json().stringify()
  let content = if existing == "" {
    "\{line}\n"
  } else {
    "\{existing.trim_end()}\n\{line}\n"
  }
  write_text_file(path, content)
}

///|
async fn prior_live_autonomy_stable_waiting_observation_streak(
  snapshot_path : String,
  current_tick : Int,
) -> Int {
  let journal_path = default_town_journal_path(snapshot_path~)
  if !@fs.exists(journal_path) {
    return 0
  }
  let mut streak = 0
  let mut last_tick = -1
  for line in @fs.read_file(journal_path).text().split("\n") {
    let trimmed = line.trim()
    if trimmed == "" {
      continue
    }
    let parsed = @json.parse(trimmed) catch { _ => continue }
    let probe : LiveAutonomyStabilityProbe = @json.from_json(parsed) catch {
      _ => continue
    }
    if probe.tick >= current_tick {
      continue
    }
    if probe.tick == last_tick {
      if !@live_autonomy_policy.live_autonomy_stability_probe_is_stable(probe) {
        streak = 0
      }
      continue
    }
    last_tick = probe.tick
    if @live_autonomy_policy.live_autonomy_stability_probe_is_stable(probe) {
      streak += 1
    } else {
      streak = 0
    }
  }
  streak
}

///|
async fn load_live_autonomy_watcher_records(
  snapshot_path : String,
  goals : Array[@core.StandingGoal],
) -> Array[@core.WatcherRunRecord] {
  let records : Array[@core.WatcherRunRecord] = []
  let ledger_dir = "\{@live_autonomy_policy.live_autonomy_base_dir_for_snapshot(snapshot_path)}/watchers"
  for goal in goals {
    for record in @storage.load_watcher_run_records(goal.id, dir=ledger_dir) {
      records.push(record)
    }
  }
  records
}

///|
fn changed(before : GoalView?, after : GoalView?) -> Change {
  match (before, after) {
    (Some(a), Some(b)) => {
      let settings_changed = a.goal != b.goal
      let outlook_changed = a.occurrence_ticks != b.occurrence_ticks ||
        a.state != b.state
      {
        goal_id: a.goal.id,
        state: if settings_changed {
          "changed"
        } else {
          "unchanged"
        },
        settings_changed,
        outlook_changed,
        occurrence_delta: b.occurrence_count - a.occurrence_count,
        before,
        after,
      }
    }
    (Some(a), None) =>
      {
        goal_id: a.goal.id,
        state: "removed",
        settings_changed: true,
        outlook_changed: true,
        occurrence_delta: -a.occurrence_count,
        before,
        after,
      }
    (None, Some(b)) =>
      {
        goal_id: b.goal.id,
        state: "added",
        settings_changed: true,
        outlook_changed: true,
        occurrence_delta: b.occurrence_count,
        before,
        after,
      }
    (None, None) => abort("comparison requires a goal")
  }
}

///|
/// Compare the same cadence window for two explicit snapshots by exact goal ID.
/// Includes added, removed, unchanged and edited goals. Reordering is reflected
/// in source positions, not reported as a settings edit. Nothing is installed.
pub fn compare(
  before : Bytes,
  after : Bytes,
  start : Int,
  end : Int,
  format~ : String,
) -> Result[String, String] {
  try {
    guard format == "json" || format == "csv" else {
      fail("Choose json or csv")
    }
    let a = project(before, start, end)
    let b = project(after, start, end)
    let old : Map[String, GoalView] = {}
    let next : Map[String, GoalView] = {}
    for goal in a.goals {
      old[goal.goal.id] = goal
    }
    for goal in b.goals {
      next[goal.goal.id] = goal
    }
    let changes : Array[Change] = []
    for goal in a.goals {
      changes.push(changed(Some(goal), next.get(goal.goal.id)))
    }
    for goal in b.goals {
      if !old.contains(goal.goal.id) {
        changes.push(changed(None, Some(goal)))
      }
    }
    let comparison : Comparison = {
      contract: "moontown.goal-outlook-comparison.v1",
      policy: policy(),
      start_tick: start,
      end_tick_exclusive: end,
      before_digest: a.source_digest,
      after_digest: b.source_digest,
      before_size_bytes: before.length(),
      after_size_bytes: after.length(),
      before_occurrences: a.occurrence_count,
      after_occurrences: b.occurrence_count,
      occurrence_delta: b.occurrence_count - a.occurrence_count,
      before_shared_ticks: a.shared_tick_count,
      after_shared_ticks: b.shared_tick_count,
      before_peak_goals: a.peak_goals_at_tick,
      after_peak_goals: b.peak_goals_at_tick,
      changes,
    }
    bounded(
      if format == "json" {
        comparison.to_json().stringify() + "\n"
      } else {
        comparison_csv(comparison)
      },
    )
  } catch {
    error => Err("\{error}")
  } noraise {
    output => Ok(output)
  }
}

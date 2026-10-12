///|
priv struct MergePlan {
  goals : Array[@core.StandingGoal]
  conflicts : Array[Json]
}

///|
fn decode(bytes : Bytes, label : String) -> Array[@core.StandingGoal] raise {
  match @goal_table.decode_snapshot(bytes) {
    Ok(goals) => goals
    Err(error) => fail(label + ": " + error)
  }
}

///|
fn index(goals : Array[@core.StandingGoal]) -> Map[String, @core.StandingGoal] {
  let result : Map[String, @core.StandingGoal] = Map([])
  for goal in goals {
    result[goal.id] = goal
  }
  result
}

///|
fn conflict(
  id : String,
  field : String,
  kind : String,
  base : Json,
  edited : Json,
  current : Json,
) -> Json {
  {
    "goal_id": id,
    "field": field,
    "kind": kind,
    "base_value": base,
    "edited_value": edited,
    "current_value": current,
  }
}

///|
fn[T : Eq + ToJson] choose(
  base : T,
  edited : T,
  current : T,
  id : String,
  field : String,
  conflicts : Array[Json],
) -> T {
  if edited == base || edited == current {
    current
  } else if current == base {
    edited
  } else {
    conflicts.push(
      conflict(
        id,
        field,
        "different_edits",
        ToJson::to_json(base),
        ToJson::to_json(edited),
        ToJson::to_json(current),
      ),
    )
    // This temporary value never escapes a conflicting plan as a snapshot.
    current
  }
}

///|
fn[T : ToJson] optional_value(value : T?) -> Json {
  match value {
    Some(present) => ToJson::to_json(present)
    None => Json::null()
  }
}

///|
fn[T : Eq + ToJson] choose_optional(
  base : T?,
  edited : T?,
  current : T?,
  id : String,
  field : String,
  conflicts : Array[Json],
) -> T? {
  if edited == base || edited == current {
    current
  } else if current == base {
    edited
  } else {
    conflicts.push(
      conflict(
        id,
        field,
        "different_edits",
        optional_value(base),
        optional_value(edited),
        optional_value(current),
      ),
    )
    current
  }
}

///|
fn merge_goal(
  base : @core.StandingGoal,
  edited : @core.StandingGoal,
  current : @core.StandingGoal,
  conflicts : Array[Json],
) -> @core.StandingGoal {
  let id = current.id
  @core.StandingGoal::new(
    id~,
    title=choose(
      base.title,
      edited.title,
      current.title,
      id,
      "title",
      conflicts,
    ),
    prompt=choose(
      base.prompt,
      edited.prompt,
      current.prompt,
      id,
      "prompt",
      conflicts,
    ),
    target_book_id=choose_optional(
      base.target_book_id,
      edited.target_book_id,
      current.target_book_id,
      id,
      "target_book_id",
      conflicts,
    ),
    cadence_ticks=choose(
      base.cadence_ticks,
      edited.cadence_ticks,
      current.cadence_ticks,
      id,
      "cadence_ticks",
      conflicts,
    ),
    next_due_tick=choose(
      base.next_due_tick,
      edited.next_due_tick,
      current.next_due_tick,
      id,
      "next_due_tick",
      conflicts,
    ),
    last_run_tick=choose_optional(
      base.last_run_tick,
      edited.last_run_tick,
      current.last_run_tick,
      id,
      "last_run_tick",
      conflicts,
    ),
    enabled=choose(
      base.enabled,
      edited.enabled,
      current.enabled,
      id,
      "enabled",
      conflicts,
    ),
    source_policy=choose(
      base.source_policy,
      edited.source_policy,
      current.source_policy,
      id,
      "source_policy",
      conflicts,
    ),
    quality_threshold=choose(
      base.quality_threshold,
      edited.quality_threshold,
      current.quality_threshold,
      id,
      "quality_threshold",
      conflicts,
    ),
  )
}

///|
fn plan(
  base_bytes : Bytes,
  edited_bytes : Bytes,
  current_bytes : Bytes,
) -> MergePlan raise {
  let base = index(decode(base_bytes, "BASE"))
  let edited_goals = decode(edited_bytes, "EDITED")
  let edited = index(edited_goals)
  let current_goals = decode(current_bytes, "CURRENT")
  let current = index(current_goals)
  let goals : Array[@core.StandingGoal] = []
  let conflicts : Array[Json] = []
  for now in current_goals {
    match (base.get(now.id), edited.get(now.id)) {
      (Some(before), Some(after)) =>
        goals.push(merge_goal(before, after, now, conflicts))
      (Some(before), None) =>
        if now != before {
          conflicts.push(
            conflict(
              now.id,
              "$goal",
              "deleted_modified",
              before.to_json(),
              Json::null(),
              now.to_json(),
            ),
          )
        }
      (None, Some(after)) =>
        if now == after {
          goals.push(now)
        } else {
          conflicts.push(
            conflict(
              now.id,
              "$goal",
              "added_differently",
              Json::null(),
              after.to_json(),
              now.to_json(),
            ),
          )
        }
      (None, None) => goals.push(now)
    }
  }
  for after in edited_goals {
    if !current.contains(after.id) {
      match base.get(after.id) {
        None => goals.push(after)
        Some(before) =>
          if after != before {
            conflicts.push(
              conflict(
                after.id,
                "$goal",
                "modified_deleted",
                before.to_json(),
                after.to_json(),
                Json::null(),
              ),
            )
          }
      }
    }
  }
  guard goals.length() <= 2000 else {
    fail("Merged snapshot exceeds 2,000 goals; narrow the inputs")
  }
  { goals, conflicts, }
}

///|
fn bounded(text : String, limit : Int) -> String raise {
  guard @utf8.encode(text).length() <= limit else {
    fail("Output exceeds " + limit.to_string() + " bytes; narrow the inputs")
  }
  text
}

///|
/// Three-way merge explicit snapshots by exact goal ID and typed field value.
/// A conflicting plan returns an error, never a partial candidate. Current row
/// order is retained; edited-only additions follow in edited order. Inputs and
/// the canonical output are limited to 1 MiB and 2,000 goals. No IO is performed.
pub fn merge_snapshots(
  base : Bytes,
  edited : Bytes,
  current : Bytes,
) -> Result[String, String] {
  try {
    let result = plan(base, edited, current)
    guard result.conflicts.is_empty() else {
      fail(
        "Merge has " +
        result.conflicts.length().to_string() +
        " conflict(s); run inspect with the same inputs for exact goal IDs, fields and values",
      )
    }
    bounded(result.goals.to_json().stringify() + "\n", 1048576)
  } catch {
    error => Err("\{error}")
  } noraise {
    output => Ok(output)
  }
}

///|
/// Inspect a three-way merge as JSON, including all exact field/record conflicts.
/// A conflict has status "conflict" and merged_goals:null, never a candidate.
/// Inspection output is limited to 2 MiB; malformed snapshots still fail.
pub fn inspect_snapshots(
  base : Bytes,
  edited : Bytes,
  current : Bytes,
) -> Result[String, String] {
  try {
    let result = plan(base, edited, current)
    let clean = result.conflicts.is_empty()
    let merged : Json = if clean {
      // A successful inspect must offer a candidate that also fits merge output.
      ignore(bounded(result.goals.to_json().stringify() + "\n", 1048576))
      result.goals.to_json()
    } else {
      Json::null()
    }
    let report : Json = {
      "schema": "moontown.goal-merge.v1",
      "status": if clean {
        "merged"
      } else {
        "conflict"
      },
      "conflict_count": result.conflicts.length(),
      "conflicts": result.conflicts,
      "merged_goals": merged,
    }
    bounded(report.stringify() + "\n", 2097152)
  } catch {
    error => Err("\{error}")
  } noraise {
    output => Ok(output)
  }
}

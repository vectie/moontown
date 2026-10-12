///|
fn known_sum(
  periods : Array[EffortPeriod],
  field : (EffortPeriod) -> Int?,
) -> Int? {
  if periods.is_empty() {
    return None
  }
  let mut sum = 0
  for p in periods {
    guard field(p) is Some(value) else { return None }
    sum += value
  }
  Some(sum)
}

///|
fn totals(periods : Array[EffortPeriod]) -> EffortTotals {
  {
    period_count: periods.length(),
    complete_town_periods: periods
    .filter(p => p.town_minutes is Some(_))
    .length(),
    paired_periods: periods
    .filter(p => p.manual_minus_town_minutes is Some(_))
    .length(),
    manual_minutes: known_sum(periods, p => p.manual_minutes),
    review_minutes: known_sum(periods, p => p.review_minutes),
    supervision_minutes: known_sum(periods, p => p.supervision_minutes),
    followup_minutes: known_sum(periods, p => p.followup_minutes),
    town_minutes: known_sum(periods, p => p.town_minutes),
    manual_minus_town_minutes: known_sum(periods, p => {
      p.manual_minus_town_minutes
    }),
  }
}

///|
fn source(bytes : Bytes) -> EffortSource {
  {
    digest: "sha256:" + @crypto.bytes_to_hex_string(@crypto.sha256(bytes)),
    size_bytes: bytes.length(),
  }
}

///|
/// Compare explicitly measured manual and Town-supported human effort for saved
/// StandingGoals. Diary rows name disjoint equal-length date period pairs and a common
/// outcome. Blank measurements stay unknown, including totals with missing values.
/// No worker/runtime duration is used and no goal is changed. JSON retains every
/// measured period; CSV gives one summary per saved goal. Inputs are exact UTF-8
/// bytes (at most 1 MiB each); CSV/TSV diary headers are a fixed documented schema.
pub fn report(
  goal_bytes : Bytes,
  diary_bytes : Bytes,
  delimiter : Char,
  format~ : String,
) -> Result[String, String] {
  try {
    guard format == "json" || format == "csv" else {
      fail("Choose json or csv")
    }
    let goals = parse_goals(goal_bytes)
    let periods = parse_diary(diary_bytes, delimiter, goals)
    let report : EffortReport = {
      contract: "moontown.goal-effort-report.v1",
      goal_source: source(goal_bytes),
      diary_source: source(diary_bytes),
      measurement_policy: "Operator-supplied human minutes for the same named outcome in explicit equal-length half-open date periods; blank is unknown. Town effort is review + supervision + follow-up. Manual minus Town is a reported difference, not causal time savings. No runtime activity is measured. Totals require complete measurements across all supplied periods; unmeasured goals stay unknown.",
      goals: goals.mapi((i, goal) => {
        source_goal: i + 1,
        goal_id: goal.id,
        title: goal.title,
        target_book_id: goal.target_book_id,
        enabled: goal.enabled,
        periods: periods[i],
        totals: totals(periods[i]),
      }),
    }
    let output = if format == "json" {
      report.to_json().stringify() + "\n"
    } else {
      report_csv(report)
    }
    guard @utf8.encode(output).length() <= 4 * 1048576 else {
      fail("Effort report exceeds 4 MiB; narrow the inputs")
    }
    output
  } catch {
    error => Err("\{error}")
  } noraise {
    output => Ok(output)
  }
}

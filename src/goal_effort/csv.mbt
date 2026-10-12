///|
fn csv_cell(value : String) -> String {
  let trimmed = value.trim_start()
  let safe = if trimmed.has_prefix("=") ||
    trimmed.has_prefix("+") ||
    trimmed.has_prefix("-") ||
    trimmed.has_prefix("@") ||
    value.has_prefix("\t") ||
    value.has_prefix("\r") ||
    value.has_prefix("\n") {
    "'" + value
  } else {
    value
  }
  "\"" + safe.replace_all(old="\"", new="\"\"") + "\""
}

///|
fn optional_minutes(value : Int?) -> String {
  match value {
    Some(n) => n.to_string()
    None => ""
  }
}

///|
fn report_csv(report : EffortReport) -> String {
  let lines = [
    [
      "goal_source_digest", "diary_source_digest", "source_goal", "goal_id", "title",
      "target_book_id", "enabled", "source_data_rows", "period_count", "complete_town_periods",
      "paired_periods", "manual_minutes", "review_minutes", "supervision_minutes",
      "followup_minutes", "town_minutes", "manual_minus_town_minutes", "period_pairs_json",
    ]
    .map(csv_cell)
    .join(","),
  ]
  for goal in report.goals {
    let t = goal.totals
    let fields = [
      report.goal_source.digest,
      report.diary_source.digest,
      goal.source_goal.to_string(),
      goal.goal_id,
      goal.title,
      goal.target_book_id.unwrap_or(""),
      goal.enabled.to_string(),
      goal.periods.map(p => p.source_data_row.to_string()).join(";"),
      t.period_count.to_string(),
      t.complete_town_periods.to_string(),
      t.paired_periods.to_string(),
      optional_minutes(t.manual_minutes),
      optional_minutes(t.review_minutes),
      optional_minutes(t.supervision_minutes),
      optional_minutes(t.followup_minutes),
      optional_minutes(t.town_minutes),
      optional_minutes(t.manual_minus_town_minutes),
      goal.periods
      .map(p => {
        (
          {
            "source_data_row": p.source_data_row,
            "period_start": p.period_start,
            "period_end": p.period_end,
            "manual_period_start": optional_text_json(p.manual_period_start),
            "manual_period_end": optional_text_json(p.manual_period_end),
            "outcome": p.outcome,
          } : Json)
      })
      .to_json()
      .stringify(),
    ]
    lines.push(fields.map(csv_cell).join(","))
  }
  lines.join("\r\n") + "\r\n"
}

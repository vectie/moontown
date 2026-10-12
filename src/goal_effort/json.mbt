///|
fn optional_int_json(value : Int?) -> Json {
  match value {
    Some(n) => n.to_json()
    None => Json::null()
  }
}

///|
fn optional_text_json(value : String?) -> Json {
  match value {
    Some(text) => text.to_json()
    None => Json::null()
  }
}

///|
// Explicit optional fields preserve unknown/null in the wire contract. The
// default struct ToJson derivation omits None fields, which would hide coverage.
impl ToJson for EffortPeriod with fn to_json(self) {
  {
    "source_data_row": self.source_data_row,
    "period_start": self.period_start,
    "period_end": self.period_end,
    "outcome": self.outcome,
    "manual_period_start": optional_text_json(self.manual_period_start),
    "manual_period_end": optional_text_json(self.manual_period_end),
    "manual_minutes": optional_int_json(self.manual_minutes),
    "review_minutes": optional_int_json(self.review_minutes),
    "supervision_minutes": optional_int_json(self.supervision_minutes),
    "followup_minutes": optional_int_json(self.followup_minutes),
    "town_minutes": optional_int_json(self.town_minutes),
    "manual_minus_town_minutes": optional_int_json(
      self.manual_minus_town_minutes,
    ),
    "note": self.note,
  }
}

///|
impl ToJson for EffortTotals with fn to_json(self) {
  {
    "period_count": self.period_count,
    "complete_town_periods": self.complete_town_periods,
    "paired_periods": self.paired_periods,
    "manual_minutes": optional_int_json(self.manual_minutes),
    "review_minutes": optional_int_json(self.review_minutes),
    "supervision_minutes": optional_int_json(self.supervision_minutes),
    "followup_minutes": optional_int_json(self.followup_minutes),
    "town_minutes": optional_int_json(self.town_minutes),
    "manual_minus_town_minutes": optional_int_json(
      self.manual_minus_town_minutes,
    ),
  }
}

///|
impl ToJson for GoalEffort with fn to_json(self) {
  {
    "source_goal": self.source_goal,
    "goal_id": self.goal_id,
    "title": self.title,
    "target_book_id": optional_text_json(self.target_book_id),
    "enabled": self.enabled,
    "periods": self.periods,
    "totals": self.totals,
  }
}

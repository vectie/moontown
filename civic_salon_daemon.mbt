///|
pub struct CivicSalonSchedule {
  id : String
  title : String
  building_id : String
  topic : String
  interval_ms : UInt64
  participant_book_ids : Array[String]
  enabled : Bool
  last_run_ms : UInt64
  next_due_ms : UInt64
  round_count : Int
  latest_round_id : String
  latest_summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct CivicSalonRoundRecord {
  id : String
  salon_id : String
  building_id : String
  tick : Int
  round_number : Int
  started_ms : UInt64
  finished_ms : UInt64
  participant_count : Int
  idea_count : Int
  research_question_count : Int
  participant_idea_links : Int
  idea_return_home_count : Int
  structural_effectiveness_score : Int
  decision : String
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn CivicSalonSchedule::new(
  id~ : String,
  title~ : String,
  building_id~ : String,
  topic~ : String,
  interval_ms? : UInt64 = 1_800_000UL,
  participant_book_ids? : Array[String] = [],
  enabled? : Bool = true,
  last_run_ms? : UInt64 = 0UL,
  next_due_ms? : UInt64 = 0UL,
  round_count? : Int = 0,
  latest_round_id? : String = "",
  latest_summary? : String = "",
) -> CivicSalonSchedule {
  {
    id,
    title,
    building_id,
    topic,
    interval_ms,
    participant_book_ids,
    enabled,
    last_run_ms,
    next_due_ms,
    round_count,
    latest_round_id,
    latest_summary,
  }
}

///|
pub fn default_civic_salon_schedule_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{civic_salon_base_dir(snapshot_path)}/salons.json"
}

///|
pub fn default_civic_salon_run_ledger_path(
  salon_id : String,
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{civic_salon_base_dir(snapshot_path)}/salon-runs/\{safe_salon_id(salon_id)}.jsonl"
}

///|
fn civic_salon_base_dir(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    ".moontown/civic"
  } else {
    "\{base}/civic"
  }
}

///|
fn safe_salon_id(id : String) -> String {
  let builder = StringBuilder::new()
  for ch in id {
    if (ch >= 'a' && ch <= 'z') ||
      (ch >= 'A' && ch <= 'Z') ||
      (ch >= '0' && ch <= '9') ||
      ch == '-' ||
      ch == '_' {
      builder.write_char(ch)
    } else {
      builder.write_char('-')
    }
  }
  builder.to_string()
}

///|
pub fn default_civic_salon_schedules() -> Array[CivicSalonSchedule] {
  [
    CivicSalonSchedule::new(
      id="embodied-robotics-social-square",
      title="Embodied Robotics Social Square Salon",
      building_id="social-square",
      topic="embodied robotics cross-area exchange",
      interval_ms=1_800_000UL,
      participant_book_ids=embodied_robotics_participant_book_ids(
        embodied_robotics_participant_books(),
      ),
    ),
  ]
}

///|
pub fn civic_salon_is_due(
  schedule : CivicSalonSchedule,
  now_ms : UInt64,
) -> Bool {
  schedule.enabled && now_ms >= schedule.next_due_ms
}

///|
fn complete_civic_salon_schedule(
  schedule : CivicSalonSchedule,
  now_ms : UInt64,
  round_id : String,
  summary : String,
) -> CivicSalonSchedule {
  let interval = if schedule.interval_ms < 1UL {
    1_800_000UL
  } else {
    schedule.interval_ms
  }
  {
    ..schedule,
    last_run_ms: now_ms,
    next_due_ms: now_ms + interval,
    round_count: schedule.round_count + 1,
    latest_round_id: round_id,
    latest_summary: summary,
  }
}

///|
fn civic_salon_round_id(schedule : CivicSalonSchedule) -> String {
  "\{schedule.id}-round-\{schedule.round_count + 1}"
}

///|
fn civic_salon_round_record(
  schedule : CivicSalonSchedule,
  round_id : String,
  tick : Int,
  started_ms : UInt64,
  finished_ms : UInt64,
  metrics : EmbodiedRoboticsSalonMetric,
  decision : String,
  summary : String,
) -> CivicSalonRoundRecord {
  {
    id: round_id,
    salon_id: schedule.id,
    building_id: schedule.building_id,
    tick,
    round_number: schedule.round_count + 1,
    started_ms,
    finished_ms,
    participant_count: metrics.participant_count,
    idea_count: metrics.idea_count,
    research_question_count: metrics.research_question_count,
    participant_idea_links: metrics.participant_idea_links,
    idea_return_home_count: metrics.idea_return_home_count,
    structural_effectiveness_score: metrics.structural_effectiveness_score,
    decision,
    summary,
  }
}

///|
pub async fn load_or_create_civic_salon_schedules(
  path? : String = default_civic_salon_schedule_path(),
) -> Array[CivicSalonSchedule] {
  if @fs.exists(path) {
    let text = @fs.read_file(path).text() catch { _ => "" }
    if !text.trim().is_empty() {
      let parsed = @json.parse(text) catch { _ => Json::array([]) }
      let schedules : Array[CivicSalonSchedule] = @json.from_json(parsed) catch {
        _ => []
      }
      if schedules.length() > 0 {
        return schedules
      }
    }
  }
  let schedules = default_civic_salon_schedules()
  save_civic_salon_schedules(path, schedules)
  schedules
}

///|
pub async fn save_civic_salon_schedules(
  path : String,
  schedules : Array[CivicSalonSchedule],
) -> Unit {
  write_text_file(path, schedules.to_json().stringify(indent=2))
}

///|
async fn append_civic_salon_round_record(
  path : String,
  record : CivicSalonRoundRecord,
) -> Unit {
  let previous = if @fs.exists(path) {
    @fs.read_file(path).text() catch {
      _ => ""
    }
  } else {
    ""
  }
  let prefix = if previous.is_empty() || previous.has_suffix("\n") {
    previous
  } else {
    "\{previous}\n"
  }
  write_text_file(path, "\{prefix}\{record.to_json().stringify()}\n")
}

///|
pub async fn run_due_civic_salons(
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  tick? : Int = 0,
  now_ms? : UInt64 = @env.now(),
) -> String {
  let schedule_path = default_civic_salon_schedule_path(snapshot_path~)
  let schedules = load_or_create_civic_salon_schedules(path=schedule_path)
  let updated : Array[CivicSalonSchedule] = []
  let summaries : Array[String] = []
  let refreshes : Array[String] = []
  for schedule in schedules {
    if civic_salon_is_due(schedule, now_ms) {
      let (next, summary) = run_due_civic_salon_round(
        schedule, snapshot_path, book_catalog_path, tick, now_ms,
      )
      updated.push(next)
      summaries.push(summary)
    } else {
      match
        refresh_civic_salon_projection_if_stale(
          schedule, snapshot_path, book_catalog_path,
        ) {
        Some(summary) => refreshes.push(summary)
        None => ()
      }
      updated.push(schedule)
    }
  }
  save_civic_salon_schedules(schedule_path, updated)
  if summaries.length() == 0 && refreshes.length() == 0 {
    "No civic salons due at now_ms=\{now_ms}."
  } else if summaries.length() == 0 {
    "Refreshed \{refreshes.length()} civic salon projection(s): \{refreshes.join("; ")}"
  } else if refreshes.length() == 0 {
    "Ran \{summaries.length()} civic salon(s): \{summaries.join("; ")}"
  } else {
    "Ran \{summaries.length()} civic salon(s): \{summaries.join("; ")}; refreshed \{refreshes.length()} stale projection(s): \{refreshes.join("; ")}"
  }
}

///|
async fn refresh_civic_salon_projection_if_stale(
  schedule : CivicSalonSchedule,
  snapshot_path : String,
  book_catalog_path : String,
) -> String? {
  if !schedule.enabled ||
    schedule.round_count <= 0 ||
    schedule.latest_round_id.is_empty() {
    return None
  }
  match schedule.id {
    "embodied-robotics-social-square" => {
      let projection_path = civic_salon_projection_path(schedule, snapshot_path)
      let text = read_text_or_empty(projection_path)
      let projection_current = text.contains(schedule.latest_round_id) &&
        text.contains("round \{schedule.round_count}")
      let protocol_ledgers_current = civic_salon_protocol_ledgers_current(
        schedule,
      )
      if projection_current && protocol_ledgers_current {
        None
      } else {
        let summary = bootstrap_embodied_robotics_salon(
          book_catalog_path~,
          round_id=schedule.latest_round_id,
          round_number=schedule.round_count,
          workspace_base=civic_salon_workspace_base(snapshot_path),
        )
        Some(
          "\{schedule.id}: refreshed projection for \{schedule.latest_round_id}; \{summary}",
        )
      }
    }
    _ => None
  }
}

///|
async fn civic_salon_protocol_ledgers_current(
  schedule : CivicSalonSchedule,
) -> Bool {
  for
    ledger in [
      "inbox", "contributions", "reductions", "outbox", "home_returns", "reviews",
    ] {
    let text = read_text_or_empty(
      civic_salon_protocol_ledger_path(schedule.building_id, ledger),
    )
    if text.trim().is_empty() || !text.contains(schedule.latest_round_id) {
      return false
    }
  }
  true
}

///|
fn civic_salon_protocol_ledger_path(
  building_id : String,
  ledger : String,
) -> String {
  ".moontown/civic/protocols/\{building_id}/\{ledger}.jsonl"
}

///|
fn civic_salon_projection_path(
  schedule : CivicSalonSchedule,
  snapshot_path : String,
) -> String {
  let book_id = match
    @civic.wenyu_building_protocol_for_building_id(schedule.building_id) {
    Some(protocol) => protocol.book_id
    None => schedule.building_id
  }
  "\{civic_salon_workspace_base(snapshot_path)}/books/\{book_id}/book/moonbook-ui-state.json"
}

///|
fn civic_salon_workspace_base(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    ".moontown"
  } else {
    base
  }
}

///|
async fn run_due_civic_salon_round(
  schedule : CivicSalonSchedule,
  snapshot_path : String,
  book_catalog_path : String,
  tick : Int,
  now_ms : UInt64,
) -> (CivicSalonSchedule, String) {
  match schedule.id {
    "embodied-robotics-social-square" => {
      let participants = embodied_robotics_participant_books()
      let ideas = embodied_robotics_salon_ideas()
      let metrics = embodied_robotics_salon_metrics(participants, ideas)
      let round_id = civic_salon_round_id(schedule)
      let summary = bootstrap_embodied_robotics_salon(
        book_catalog_path~,
        round_id~,
        round_number=schedule.round_count + 1,
        workspace_base=civic_salon_workspace_base(snapshot_path),
      )
      let finished_ms = @env.now()
      let record = civic_salon_round_record(
        schedule, round_id, tick, now_ms, finished_ms, metrics, "review", summary,
      )
      append_civic_salon_round_record(
        default_civic_salon_run_ledger_path(schedule.id, snapshot_path~),
        record,
      )
      (
        complete_civic_salon_schedule(schedule, now_ms, round_id, summary),
        "\{round_id}: \{summary}",
      )
    }
    _ => {
      let summary = "Unsupported civic salon schedule `\{schedule.id}`; no round executed."
      let round_id = civic_salon_round_id(schedule)
      (
        {
          ..schedule,
          latest_round_id: round_id,
          latest_summary: summary,
          next_due_ms: now_ms + 300_000UL,
        },
        summary,
      )
    }
  }
}

///|
pub async fn render_civic_salon_schedule_status(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  let schedules = load_or_create_civic_salon_schedules(
    path=default_civic_salon_schedule_path(snapshot_path~),
  )
  let now_ms = @env.now()
  let builder = StringBuilder::new()
  builder.write_string("# Civic Salon Schedule Status\n\n")
  builder.write_string(
    "| Salon | Building | Enabled | Due | Interval min | Rounds | Latest |\n",
  )
  builder.write_string("| --- | --- | ---:| ---:| ---:| ---:| --- |\n")
  for schedule in schedules {
    builder.write_string(
      "|\{schedule.title}|\{schedule.building_id}|\{schedule.enabled}|\{civic_salon_is_due(schedule, now_ms)}|\{schedule.interval_ms / 60_000UL}|\{schedule.round_count}|\{schedule.latest_round_id}|\n",
    )
  }
  builder.to_string()
}

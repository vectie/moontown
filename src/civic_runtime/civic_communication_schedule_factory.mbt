///|
fn civic_salon_schedule_for_scenario(
  scenario : CivicCommunicationScenario,
  existing? : CivicCommunicationSchedule? = None,
  now_ms? : UInt64 = @env.now(),
) -> CivicCommunicationSchedule {
  match existing {
    Some(schedule) =>
      {
        ..schedule,
        title: scenario.title,
        building_id: scenario.building_id,
        topic: scenario.topic,
        participant_book_ids: scenario.participants.map(fn(item) {
          item.book_id
        }),
      }
    None =>
      CivicCommunicationSchedule::new(
        id=scenario.id,
        title=scenario.title,
        building_id=scenario.building_id,
        topic=scenario.topic,
        interval_ms=civic_salon_scenario_interval_ms(scenario),
        next_due_ms=now_ms,
        participant_book_ids=scenario.participants.map(fn(item) { item.book_id }),
      )
  }
}

///|
fn civic_salon_scenario_interval_ms(
  scenario : CivicCommunicationScenario,
) -> UInt64 {
  match scenario.interval_ms {
    Some(value) if value > 0UL => value
    _ => 1_800_000UL
  }
}

///|
pub async fn upsert_civic_communication_schedule_for_scenario(
  scenario : CivicCommunicationScenario,
  path? : String = default_civic_communication_schedule_path(),
  now_ms? : UInt64 = @env.now(),
) -> CivicCommunicationSchedule {
  let schedules = load_or_create_civic_communication_schedules(path~)
  let updated : Array[CivicCommunicationSchedule] = []
  let mut installed = false
  let mut installed_schedule = civic_salon_schedule_for_scenario(
    scenario,
    now_ms~,
  )
  for schedule in schedules {
    if schedule.id == scenario.id {
      installed = true
      installed_schedule = civic_salon_schedule_for_scenario(
        scenario,
        existing=Some(schedule),
        now_ms~,
      )
      updated.push(installed_schedule)
    } else {
      updated.push(schedule)
    }
  }
  if !installed {
    updated.push(installed_schedule)
  }
  save_civic_communication_schedules(path, updated)
  installed_schedule
}

///|
async fn upsert_civic_salon_schedule_for_scenario(
  scenario : CivicCommunicationScenario,
  path? : String = default_civic_communication_schedule_path(),
  now_ms? : UInt64 = @env.now(),
) -> CivicCommunicationSchedule {
  upsert_civic_communication_schedule_for_scenario(scenario, path~, now_ms~)
}

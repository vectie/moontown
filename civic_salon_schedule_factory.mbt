///|
fn civic_salon_schedule_for_scenario(
  scenario : CivicSalonScenario,
  existing? : CivicSalonSchedule? = None,
  now_ms? : UInt64 = @env.now(),
) -> CivicSalonSchedule {
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
      CivicSalonSchedule::new(
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
fn civic_salon_scenario_interval_ms(scenario : CivicSalonScenario) -> UInt64 {
  match scenario.interval_ms {
    Some(value) if value > 0UL => value
    _ => 1_800_000UL
  }
}

///|
pub async fn upsert_civic_salon_schedule_for_scenario(
  scenario : CivicSalonScenario,
  path? : String = default_civic_salon_schedule_path(),
  now_ms? : UInt64 = @env.now(),
) -> CivicSalonSchedule {
  let schedules = load_or_create_civic_salon_schedules(path~)
  let updated : Array[CivicSalonSchedule] = []
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
  save_civic_salon_schedules(path, updated)
  installed_schedule
}

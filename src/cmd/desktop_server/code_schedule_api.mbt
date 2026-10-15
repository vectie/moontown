///|
fn code_schedule_api_string(fields : Map[String, Json], key : String) -> String {
  match fields.get(key) {
    Some(String(value)) => value.trim().to_owned()
    _ => ""
  }
}

///|
fn code_schedule_api_error_response(error : String) -> (Int, String) {
  if error.contains("identity already exists") {
    (409, "A Code schedule with this ID already exists.")
  } else if error.contains("Code schedule is running") {
    (
      409, "This task is running. You can edit or remove its schedule after it finishes.",
    )
  } else if error.contains("invalid Code schedule") ||
    error.contains("cadence is required") ||
    error.contains("invalid Code schedule request") {
    (400, "Enter a valid schedule ID, Code task, model, and cadence.")
  } else if error.contains("select a registered MoonBook") {
    (409, "Select a registered MoonBook with an available workspace.")
  } else if error.contains("Code schedule ID was not found") {
    (404, "This Code schedule is no longer available. Refresh the list.")
  } else if error.contains("unsupported Code schedule action") {
    (400, "This Code schedule action is not supported.")
  } else {
    (
      503, "MoonTown could not save this Code schedule. Retry after checking its service.",
    )
  }
}

///|
async fn code_schedule_api_action(body : String) -> Json {
  guard @json.parse(body) is Object(fields) else {
    fail("invalid Code schedule request")
  }
  let now = (@env.now() / 1000UL).reinterpret_as_int64()
  let id = code_schedule_api_string(fields, "id")
  match code_schedule_api_string(fields, "action") {
    "create" => {
      let book_id = code_schedule_api_string(fields, "book_id")
      let catalog = @moonbook.load_or_create_catalog(
        path=@moonbook.default_catalog_path(),
      )
      guard @code_schedules.find_code_schedule_book(catalog, book_id)
        is Some(book) &&
        @fs.kind(book.workspace_root, follow_symlink=false) is Directory &&
        @fs.realpath(book.workspace_root) == book.workspace_root else {
        fail("select a registered MoonBook with a canonical workspace")
      }
      guard fields.get("interval_seconds") is Some(Number(interval, ..)) else {
        fail("Code schedule cadence is required")
      }
      let schedule = match
        @code_schedules.CodeSchedule::new(
          id~,
          book_id~,
          book_root=book.workspace_root,
          session_id="code-schedule-\{id}",
          prompt=code_schedule_api_string(fields, "prompt"),
          model=code_schedule_api_string(fields, "model"),
          interval_seconds=interval.to_int(),
          now~,
        ) {
        Ok(value) => value
        Err(error) => fail(error)
      }
      let schedule = if fields.contains("next_due_at") ||
        fields.contains("repeat") ||
        fields.contains("title") {
        match
          schedule.reschedule(
            prompt=schedule.prompt,
            model=schedule.model,
            title=code_schedule_api_string(fields, "title"),
            interval_seconds=schedule.interval_seconds,
            next_due_at=code_schedule_api_due(fields, schedule.next_due_at),
            repeat=code_schedule_api_repeat(fields),
          ) {
          Ok(value) => value
          Err(error) => fail(error)
        }
      } else {
        schedule
      }
      let schedule = schedule.with_calendar(
        code_schedule_api_string(fields, "recurrence"),
        code_schedule_api_string(fields, "timezone"),
      )
      @code_schedules.create_code_schedule(schedule).to_json()
    }
    "update" => {
      guard fields.get("interval_seconds") is Some(Number(interval, ..)) else {
        fail("Code schedule cadence is required")
      }
      @code_schedules.edit_code_schedule(
        id,
        prompt=code_schedule_api_string(fields, "prompt"),
        model=code_schedule_api_string(fields, "model"),
        title=code_schedule_api_string(fields, "title"),
        interval_seconds=interval.to_int(),
        next_due_at=code_schedule_api_due(fields, now + interval.to_int64()),
        repeat=code_schedule_api_repeat(fields),
        recurrence=code_schedule_api_string(fields, "recurrence"),
        timezone=code_schedule_api_string(fields, "timezone"),
      ).to_json()
    }
    "run-now" => @code_schedules.run_code_schedule_now(id, now).to_json()
    "delete" => @code_schedules.delete_code_schedule(id).to_json()
    "pause" | "resume" => {
      let enabled = code_schedule_api_string(fields, "action") == "resume"
      guard @code_schedules.set_code_schedule_enabled(id, enabled, now) else {
        fail("Code schedule ID was not found")
      }
      @code_schedules.load_code_schedule_state().to_json()
    }
    _ => fail("unsupported Code schedule action")
  }
}

///|
fn code_schedule_api_due(fields : Map[String, Json], fallback : Int64) -> Int64 {
  match fields.get("next_due_at") {
    Some(Number(value, ..)) => value.to_int64()
    _ => fallback
  }
}

///|
fn code_schedule_api_repeat(fields : Map[String, Json]) -> Bool {
  match fields.get("repeat") {
    Some(False) => false
    _ => true
  }
}

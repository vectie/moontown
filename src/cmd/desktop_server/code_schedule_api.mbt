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
      guard @moonbook.find_catalog_entry(catalog, book_id) is Some(book) &&
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
      @code_schedules.create_code_schedule(schedule).to_json()
    }
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

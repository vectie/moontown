///|
fn native_work_api_valid_id(id : String) -> Bool {
  id.length() == 42 &&
  id.has_prefix("town-work-") &&
  id[10:].iter().all(ch => (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f'))
}

///|
fn native_work_api_route(path : String) -> (String, String)? {
  let base = @town_contract.desktop_native_work_path()
  if path == base {
    return Some(("", "list"))
  }
  if !path.has_prefix(base + "/") {
    return None
  }
  let parts = path[base.length() + 1:].split("/").to_array()
  match parts {
    [id] if native_work_api_valid_id(id.to_owned()) =>
      Some((id.to_owned(), "show"))
    [id, action] if native_work_api_valid_id(id.to_owned()) &&
      ["refresh", "cancel", "sync"].contains(action.to_owned()) =>
      Some((id.to_owned(), action.to_owned()))
    _ => None
  }
}

///|
fn native_work_api_revision(body : String) -> Int raise {
  guard @utf8.encode(body).length() <= 4096 else {
    fail("native_work_body_too_large")
  }
  let parsed = @json.parse(body) catch {
    _ => fail("native_work_request_invalid")
  }
  guard !body.contains(",") else { fail("native_work_request_invalid") }
  guard parsed is Object(fields) &&
    fields.length() == 1 &&
    fields.get("expected_revision") is Some(Number(number, ..)) &&
    number >= 0 &&
    number <= 2147483647.0 &&
    number == number.to_int().to_double() else {
    fail("native_work_request_invalid")
  }
  number.to_int()
}

///|
fn native_work_api_error(error : String) -> (Int, String) {
  if error.contains("native_work_revision_conflict") {
    (409, "Native work changed. Reload saved status before trying again.")
  } else if error.contains("native_work_not_found") {
    (404, "This native work is no longer available. Reload saved status.")
  } else if error.contains("native_work_body_too_large") {
    (413, "Native work control body must be at most 4096 bytes.")
  } else if error.contains("native_work_request_invalid") ||
    error.contains("native_work_action_invalid") {
    (
      400, "Use a saved work ID and a nonnegative expected_revision for this control.",
    )
  } else {
    (
      503, "MoonTown could not read or update its saved native work. Check the Town owner service and retry.",
    )
  }
}

///|
fn native_work_api_projection(
  state : @native_work.State,
  id : String,
) -> Json raise {
  if id == "" {
    return {
      "schema": @town_contract.native_work_status_schema(),
      "revision": state.revision,
      "items": state.work.map(work => @native_work.status(work).to_json()),
    }
  }
  for work in state.work {
    if work.id == id {
      return {
        "schema": @town_contract.native_work_status_schema(),
        "revision": state.revision,
        "item": @native_work.status(work).to_json(),
      }
    }
  }
  fail("native_work_not_found")
}

///|
/// Saved reads deliberately never call refresh or sync. The owner load only
/// takes its normal state lock; it cannot reserve, dispatch or apply a result.
async fn native_work_api_read(
  id : String,
  path? : String = @native_work.default_path(),
) -> Json {
  native_work_api_projection(@native_work.load(path~), id)
}

///|
async fn native_work_api_action(
  id : String,
  action : String,
  body : String,
  now : UInt64,
  path? : String = @native_work.default_path(),
) -> Json {
  guard native_work_api_valid_id(id) else {
    fail("native_work_request_invalid")
  }
  let expected_revision = native_work_api_revision(body)
  match action {
    "refresh" => ignore(@native_work.refresh(id, expected_revision, now, path~))
    "cancel" => ignore(@native_work.cancel(id, expected_revision, now, path~))
    "sync" => {
      let work = @native_work.sync(
        id,
        now,
        path~,
        force=true,
        expected_revision~,
      )
      @build_pipeline_runtime.apply_wenyu_native_work_result(
        work,
        native_path=path,
      )
    }
    _ => fail("native_work_action_invalid")
  }
  // Reload both items and revision together. Another owner operation may have
  // completed since this action, so never combine its Work with a later revision.
  native_work_api_read("", path~)
}

///|
async fn handle_native_work_api(
  request : @http.Request,
  body : &@io.Reader,
  conn : @http.ServerConnection,
  path : String,
) -> Unit {
  guard native_work_api_route(path) is Some((id, action)) else {
    send_json(conn, 404, {
      "ok": false,
      "error": "Native work route not found.",
    })
    return
  }
  if action == "list" || action == "show" {
    guard request.meth is Get else {
      send_json(conn, 405, { "ok": false, "error": "GET required" })
      return
    }
    let response = native_work_api_read(id) catch {
      error => {
        let (code, message) = native_work_api_error("\{error}")
        send_json(conn, code, { "ok": false, "error": message })
        return
      }
    }
    send_json(conn, 200, response)
    return
  }
  if reject_unsafe_operator_write(request, conn) {
    return
  }
  let input = bounded_identity_text(body, 4096) catch {
    _ => {
      send_json(conn, 400, {
        "ok": false,
        "error": "Invalid native work control body.",
      })
      return
    }
  }
  guard input is Some(input) else {
    send_json(conn, 413, {
      "ok": false,
      "error": "Native work control body must be at most 4096 bytes.",
    })
    return
  }
  let response = native_work_api_action(id, action, input, @env.now()) catch {
    error => {
      let (code, message) = native_work_api_error("\{error}")
      send_json(conn, code, { "ok": false, "error": message })
      return
    }
  }
  send_json(conn, 200, response)
}

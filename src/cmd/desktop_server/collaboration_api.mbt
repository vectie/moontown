///|
/// Keep the collaboration boundary before supervisor/runtime initialization.
async fn handle_collaboration_api(
  request : @http.Request,
  body : &@io.Reader,
  conn : @http.ServerConnection,
) -> Unit {
  if reject_unsafe_operator_write(request, conn) {
    return
  }
  let input = @collaboration_authoring.decode_request(body.read_all().text()) catch {
    error => {
      send_json(conn, 400, {
        "ok": false,
        "error": @collaboration_authoring.error_message(error),
      })
      return
    }
  }
  let store : @collaboration_authoring.Store = {
    root: state_root() + "/collaboration-authoring",
    catalog_path: @moonbook.default_catalog_path(),
  }
  if input.action == "export" ||
    input.action == "download" ||
    input.action == "outcome-export" {
    let bytes = try {
      if input.action == "outcome-export" {
        store.export_outcome(
          @collaboration_authoring.outcome_request_key(input),
        )
      } else if input.action == "export" {
        store.export_tar(input.draft_id, input.revision)
      } else {
        store.artifact(input.draft_id, input.revision, input.artifact_path)
      }
    } catch {
      error => {
        send_json(conn, 409, {
          "ok": false,
          "error": @collaboration_authoring.error_message(error),
        })
        return
      }
    }
    conn.send_response(200, "OK", extra_headers={
      "Content-Type": if input.action != "download" {
        "application/x-tar"
      } else {
        "application/octet-stream"
      },
      "Content-Length": bytes.length().to_string(),
      "Content-Disposition": "attachment; filename=collaboration-" +
      input.draft_id +
      "." +
      (if input.action != "download" { "tar" } else { "bin" }),
      "Cache-Control": "no-store",
      "X-Content-Type-Options": "nosniff",
      "X-Artifact-Digest": "sha256:" +
      @crypto.bytes_to_hex_string(@crypto.sha256(bytes)),
    })
    conn.write(bytes)
    conn.end_response()
    return
  }
  let timestamp = iso_timestamp(@env.now())[:19].to_owned() + "Z"
  if input.action.has_prefix("oneoff-") {
    let runtime : @collaboration_authoring.OneoffRuntime? = try {
      match env_value("MOONTOWN_COLLABORATION_RUNTIME_JSON") {
        Some(path) =>
          Some(@json.from_json(@json.parse(@fs.read_file(path).text())))
        None => None
      }
    } catch {
      _ => None
    }
    // Reuse the existing operator identity service. A local request or a typed
    // reviewer name is not an authenticated named-human decision.
    let actor = match public_identity(request_header(request, "cookie")) {
      Some(identity) if identity.is_operator => Some(identity.account_id)
      _ => None
    }
    let result = store.request_oneoff(
      input,
      runtime,
      actor,
      timestamp,
      (@env.now() / 1000UL).to_int(),
    )
    send_json(conn, if result.ok { 200 } else { 409 }, result.to_json())
    return
  }
  let result = store.request(input, timestamp)
  send_json(conn, if result.ok { 200 } else { 409 }, result.to_json())
}

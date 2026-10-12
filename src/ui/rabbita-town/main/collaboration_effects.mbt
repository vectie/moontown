///|
extern "js" fn collaboration_generation(value : Int) -> Unit =
  #| value => { globalThis.__townCollaborationGeneration = value; }

///|
extern "js" fn collaboration_fetch(
  endpoint : String,
  request : String,
) -> @js.Promise =
  #| async (endpoint, request) => {
  #|   try {
  #|     const response = await fetch(endpoint, {method: "POST", headers: {"Content-Type":"application/json"}, body: request});
  #|     return await response.text();
  #|   } catch (_) { return ""; }
  #| }

///|
extern "js" fn collaboration_fetch_download(
  endpoint : String,
  request : String,
  generation : Int,
  filename : String,
  expected_digest : String,
  expected_size : Int,
) -> @js.Promise =
  #| async (endpoint, request, generation, filename, expectedDigest, expectedSize) => {
  #|   try {
  #|     const response = await fetch(endpoint, {method: "POST", headers: {"Content-Type":"application/json"}, body: request});
  #|     if (!response.ok) {
  #|       const body = await response.json().catch(() => ({}));
  #|       return body.error || `Download failed (HTTP ${response.status}). Prepare again to verify the artifacts.`;
  #|     }
  #|     const digest = response.headers.get("X-Artifact-Digest") || "";
  #|     const length = response.headers.get("Content-Length") || "";
  #|     const size = Number(length);
  #|     if (!/^sha256:[0-9a-f]{64}$/.test(digest) || !/^\d+$/.test(length) || !Number.isSafeInteger(size) || size < 0 || size > 40 * 1024 * 1024 || (expectedDigest && (digest !== expectedDigest || size !== expectedSize))) return "Download identity did not match the prepared artifact";
  #|     const bytes = await response.arrayBuffer();
  #|     if (bytes.byteLength !== size || !globalThis.crypto?.subtle) return "Download bytes could not be verified";
  #|     const observed = "sha256:" + [...new Uint8Array(await crypto.subtle.digest("SHA-256", bytes))].map(b => b.toString(16).padStart(2, "0")).join("");
  #|     if (observed !== digest) return "Download content digest did not match the captured artifact";
  #|     const blob = new Blob([bytes], {type: "application/octet-stream"});
  #|     if (globalThis.__townCollaborationGeneration !== generation) return "Download cancelled after the selection changed";
  #|     const url = URL.createObjectURL(blob);
  #|     const anchor = document.createElement("a");
  #|     anchor.href = url;
  #|     anchor.download = String(filename).replace(/[\\/]/g, "-");
  #|     document.body.appendChild(anchor); anchor.click(); anchor.remove();
  #|     setTimeout(() => URL.revokeObjectURL(url), 1000);
  #|     return "Download prepared from verified saved bytes";
  #|   } catch (_) { return "Download interrupted. Retry the same saved revision."; }
  #| }

///|
async fn collaboration_wait(promise : @js.Promise) -> String noraise {
  promise.wait().cast() catch {
    _ => ""
  }
}

///|
fn collaboration_replace(
  model : Model,
  state : @collaboration.Client,
) -> (Cmd, Model) {
  (
    @cmd.custom_cmd(_ => collaboration_generation(state.generation)),
    { ..model, collaboration: state, },
  )
}

///|
fn collaboration_payload(
  state : @collaboration.Client,
  action : String,
  id : String,
  revision : String,
  path : String,
) -> String {
  let value : Json = {
    "contract_version": "moontown.collaboration.request.v1",
    "request_id": state.generation.to_string(),
    "action": action,
    "draft_id": id,
    "revision": revision,
    "new_draft_id": state.new_draft_id,
    "artifact_path": path,
    "payload": if action == "source-list" {
      { "book_id": state.source_book }
    } else if action == "outcome-inspect" || action == "outcome-export" {
      match state.outcome_key {
        Some(key) => key.to_json()
        None => Json::null()
      }
    } else {
      collaboration_work_payload(state)
    },
    "draft": if action == "save" {
      state.draft.to_json()
    } else {
      Json::null()
    },
  }
  value.stringify()
}

///|
fn collaboration_outcome_download(
  dispatch : Dispatch[Msg],
  model : Model,
) -> (Cmd, Model) {
  guard model.collaboration.outcome is Some(outcome) else {
    return collaboration_replace(model, {
      ..model.collaboration,
      notice: "Inspect an exact retained result and review before downloading",
    })
  }
  let state = model.collaboration.begin("outcome-export", outcome.key.draft_id)
  if model.collaboration.busy() || !state.busy() {
    return collaboration_replace(model, state)
  }
  let command = @rabbita.perform(
    message => dispatch(CollaborationDownloaded(state.generation, message)),
    async fn() noraise {
      collaboration_wait(
        collaboration_fetch_download(
          moontown_product_api_path("api/collaboration"),
          collaboration_payload(
            state,
            "outcome-export",
            outcome.key.draft_id,
            outcome.key.revision,
            "",
          ),
          state.generation,
          outcome.key.draft_id +
          "-" +
          outcome.key.revision +
          "-review-" +
          outcome.key.review_version.to_string() +
          ".tar",
          outcome.archive_digest,
          outcome.archive_size_bytes,
        ),
      )
    },
  )
  (
    @rabbita.batch([
      @cmd.custom_cmd(_ => collaboration_generation(state.generation)),
      command,
    ]),
    { ..model, collaboration: state, },
  )
}

///|
fn collaboration_work_payload(state : @collaboration.Client) -> Json {
  let fields : Map[String, Json] = Map([])
  for key, value in state.work_fields {
    fields[key["work_".length():].to_owned()] = value.to_json()
  }
  if state.work is Some(work) {
    fields["result_digest"] = work.result_digest.to_json()
    fields["review_version"] = work.review_version.to_json()
  }
  Json::object(fields)
}

///|
fn collaboration_action(
  dispatch : Dispatch[Msg],
  model : Model,
  action : String,
  id : String,
  revision : String,
) -> (Cmd, Model) {
  let state = model.collaboration.begin(action, id)
  if model.collaboration.busy() || !state.busy() {
    return collaboration_replace(model, state)
  }
  let command = @rabbita.perform(
    raw => dispatch(CollaborationReply(state.generation, action, raw)),
    async fn() noraise {
      collaboration_wait(
        collaboration_fetch(
          moontown_product_api_path("api/collaboration"),
          collaboration_payload(state, action, id, revision, ""),
        ),
      )
    },
  )
  (
    @rabbita.batch([
      @cmd.custom_cmd(_ => collaboration_generation(state.generation)),
      command,
    ]),
    { ..model, collaboration: state, },
  )
}

///|
fn collaboration_download(
  dispatch : Dispatch[Msg],
  model : Model,
  path : String,
) -> (Cmd, Model) {
  let action = if path.is_empty() { "export" } else { "download" }
  let state = model.collaboration.begin(
    action,
    model.collaboration.draft.draft_id,
  )
  if model.collaboration.busy() || !state.busy() || state.prepared is None {
    return collaboration_replace(model, {
      ..state,
      pending_action: "",
      notice: "Prepare this saved revision before downloading",
    })
  }
  let filename = if path.is_empty() {
    state.draft.draft_id + "-" + state.revision + ".tar"
  } else {
    path.split("/").last().unwrap_or("artifact").to_owned()
  }
  let selected = state.prepared.unwrap().artifacts.filter(a => a.path == path)
  if !path.is_empty() && selected.length() != 1 {
    return collaboration_replace(model, {
      ..state,
      pending_action: "",
      notice: "Artifact is not in this prepared revision",
    })
  }
  let expected_digest = if path.is_empty() { "" } else { selected[0].digest }
  let expected_size = if path.is_empty() { 0 } else { selected[0].size_bytes }
  let command = @rabbita.perform(
    message => dispatch(CollaborationDownloaded(state.generation, message)),
    async fn() noraise {
      collaboration_wait(
        collaboration_fetch_download(
          moontown_product_api_path("api/collaboration"),
          collaboration_payload(
            state,
            action,
            state.draft.draft_id,
            state.revision,
            path,
          ),
          state.generation,
          filename,
          expected_digest,
          expected_size,
        ),
      )
    },
  )
  (
    @rabbita.batch([
      @cmd.custom_cmd(_ => collaboration_generation(state.generation)),
      command,
    ]),
    { ..model, collaboration: state, },
  )
}

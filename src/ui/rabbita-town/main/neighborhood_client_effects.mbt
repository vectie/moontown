///|
/// Transport only. Identity is supplied by the verified same-origin server
/// session. The expected actor is only a stale-form fence, never an identity
/// credential; this browser cannot assign the server actor or hosting role.
extern "js" fn fetch_neighborhood_json(
  endpoint : String,
  method : String,
  body : String,
) -> @js.Promise =
  #| async (endpoint, method, body) => {
  #|   try {
  #|     const response = await fetch(endpoint, {
  #|       method, credentials: "same-origin", cache: "no-store",
  #|       headers: { Accept: "application/json", ...(method === "POST" ? { "Content-Type": "application/json" } : {}) },
  #|       ...(method === "POST" ? { body } : {}),
  #|       signal: AbortSignal.timeout(15000)
  #|     });
  #|     if (!response.body) return JSON.stringify({ status: response.status, body: "" });
  #|     const reader = response.body.getReader(), chunks = [];
  #|     let size = 0;
  #|     while (true) {
  #|       const { value, done } = await reader.read();
  #|       if (done) break;
  #|       size += value.byteLength;
  #|       if (size > 2097152) { await reader.cancel(); return JSON.stringify({ status: 0, body: "" }); }
  #|       chunks.push(value);
  #|     }
  #|     const bytes = new Uint8Array(size); let offset = 0;
  #|     for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.byteLength; }
  #|     return JSON.stringify({ status: response.status, body: new TextDecoder("utf-8", { fatal: true }).decode(bytes) });
  #|   } catch (_) { return JSON.stringify({ status: 0, body: "" }); }
  #| }

///|
async fn wait_neighborhood_json(promise : @js.Promise) -> String noraise {
  promise.wait().cast() catch {
    _ => ""
  }
}

///|
fn neighborhood_read_cmd(
  dispatch : Dispatch[Msg],
  generation : Int32,
  route : String,
) -> Cmd {
  @rabbita.perform(
    raw => dispatch(NeighborhoodEvent(Loaded(generation, route, raw))),
    async fn() noraise {
      wait_neighborhood_json(
        fetch_neighborhood_json(
          neighborhood_api_path(current_browser_pathname(), route),
          "GET",
          "",
        ),
      )
    },
  )
}

///|
fn neighborhood_cmd(
  dispatch : Dispatch[Msg],
  request : NeighborhoodRequest?,
) -> Cmd {
  match request {
    None => @rabbita.none
    Some(PublicLoad(generation)) =>
      neighborhood_read_cmd(dispatch, generation, "public")
    Some(Load(generation)) =>
      @rabbita.batch([
        neighborhood_read_cmd(dispatch, generation, "public"),
        neighborhood_read_cmd(dispatch, generation, "mine"),
      ])
    Some(Submit(generation, expected_actor_id, action, payload)) => {
      let body : Json = {
        "action": action,
        "payload": payload,
        "expected_actor_id": expected_actor_id,
      }
      @rabbita.perform(
        raw => dispatch(NeighborhoodEvent(Loaded(generation, "action", raw))),
        async fn() noraise {
          wait_neighborhood_json(
            fetch_neighborhood_json(
              neighborhood_api_path(current_browser_pathname(), "actions"),
              "POST",
              body.stringify(),
            ),
          )
        },
      )
    }
  }
}

///|
/// The neighborhood belongs to the shared town, not each user's workspace.
/// platform-base.js exempts this precise API family from workspace rewriting.
fn neighborhood_api_path(pathname : String, route : String) -> String {
  let base = if pathname == "/moontown" || pathname.has_prefix("/moontown/") {
    "/moontown"
  } else {
    ""
  }
  base + "/api/neighborhood/" + route
}

///|
fn update_neighborhood(
  dispatch : Dispatch[Msg],
  model : Model,
  event : NeighborhoodMsg,
) -> (Cmd, Model) {
  let (state, request) = neighborhood_transition(model.neighborhood, event)
  let base = if event is Open {
    {
      ..close_town_transient_surfaces(model),
      selection: Overview,
      map_lab_open: false,
      energy_intro_open: false,
    }
  } else {
    model
  }
  let changed_identity = state.actor_id != model.neighborhood.actor_id
  let managed = if changed_identity {
    initial_neighborhood_manage_state()
  } else if event is Loaded(_, _, _) {
    let reconciled = neighborhood_manage_reconcile(
      model.neighborhood_manage,
      state.mine,
    )
    if state.needs_refresh {
      neighborhood_manage_revoke_consent(reconciled)
    } else {
      reconciled
    }
  } else {
    model.neighborhood_manage
  }
  let next = { ..base, neighborhood: state, neighborhood_manage: managed, }
  let route_cmd = match event {
    Open =>
      @cmd.custom_cmd(_ => {
        replace_browser_query_param("layer", "")
        replace_browser_query_param("request", "")
        replace_browser_query_param("area", "")
        replace_browser_query_param("panel", "")
        replace_browser_query_param("community", "1")
      })
    Close => @cmd.custom_cmd(_ => replace_browser_query_param("community", "0"))
    _ => @rabbita.none
  }
  (@rabbita.batch([route_cmd, neighborhood_cmd(dispatch, request)]), next)
}

///|
extern "js" fn neighborhood_date_label(raw : String) -> String =
  #| raw => {
  #|   try {
  #|     const value = JSON.parse(raw);
  #|     if (typeof value !== "number" || value <= 0) return "时间待确认";
  #|     const date = new Date(value);
  #|     if (!Number.isFinite(date.getTime())) return "时间待确认";
  #|     return date.toLocaleString("zh-CN", { timeZone: "Asia/Shanghai", month: "numeric", day: "numeric", hour: "2-digit", minute: "2-digit", hour12: false });
  #|   } catch (_) { return "时间待确认"; }
  #| }

///|
fn neighborhood_event_time(event : Json) -> String {
  neighborhood_date_label(
    neighborhood_field(event, "starts_ms").unwrap_or(Json::null()).stringify(),
  ) +
  " – " +
  neighborhood_date_label(
    neighborhood_field(event, "ends_ms").unwrap_or(Json::null()).stringify(),
  )
}

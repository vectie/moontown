///|
/// Private projections live only in this in-memory state, never local storage.
struct NeighborhoodState {
  open : Bool
  snapshot : Json?
  mine : Json?
  actor_id : String
  generation : Int32
  loading : Bool
  mine_loading : Bool
  busy : Bool
  needs_refresh : Bool
  error : String
  mine_error : String
  notice : String
  section : String
  selected_id : String
  display_name : String
  contact : String
  followup_message : String
  followup_consent : Bool
} derive(Debug)

///|
enum NeighborhoodMsg {
  Preview
  Open
  Close
  Refresh
  SelectSection(String)
  SelectStory(String)
  SelectEvent(String)
  Back
  Edit(String, String)
  SetFollowupConsent(Bool)
  Action(String, Json)
  Loaded(Int32, String, String)
} derive(Debug)

///|
enum NeighborhoodRequest {
  PublicLoad(Int32)
  Load(Int32)
  Submit(Int32, String, String, Json)
} derive(Debug)

///|
fn initial_neighborhood_state() -> NeighborhoodState {
  {
    open: false,
    snapshot: None,
    mine: None,
    actor_id: "",
    generation: 0,
    loading: false,
    mine_loading: false,
    busy: false,
    needs_refresh: false,
    error: "",
    mine_error: "",
    notice: "",
    section: "events",
    selected_id: "",
    display_name: "",
    contact: "",
    followup_message: "",
    followup_consent: false,
  }
}

///|
fn neighborhood_field(value : Json, key : String) -> Json? {
  match value {
    Object(fields) => fields.get(key)
    _ => None
  }
}

///|
fn neighborhood_text(value : Json, key : String) -> String {
  match neighborhood_field(value, key) {
    Some(String(text)) => text
    _ => ""
  }
}

///|
fn neighborhood_items(value : Json, key : String) -> Array[Json] {
  match neighborhood_field(value, key) {
    Some(Array(items)) => items
    _ => []
  }
}

///|
fn neighborhood_flag(value : Json, key : String) -> Bool {
  neighborhood_field(value, key) is Some(True)
}

///|
fn neighborhood_number(value : Json, key : String) -> Int32 {
  match neighborhood_field(value, key) {
    Some(Number(number)) => number.to_int()
    _ => 0
  }
}

///|
fn neighborhood_snapshot(model : Model) -> Json? {
  model.neighborhood.snapshot
}

///|
fn neighborhood_mine(model : Model) -> Json? {
  model.neighborhood.mine
}

///|
fn neighborhood_can_host(model : Model) -> Bool {
  model.neighborhood.mine
  .map(mine => neighborhood_flag(mine, "can_host"))
  .unwrap_or(false)
}

///|
fn neighborhood_busy(model : Model) -> Bool {
  model.neighborhood.busy ||
  model.neighborhood.mine_loading ||
  model.neighborhood.needs_refresh
}

///|
fn neighborhood_clear_identity(state : NeighborhoodState) -> NeighborhoodState {
  {
    ..state,
    mine: None,
    actor_id: "",
    display_name: "",
    contact: "",
    followup_message: "",
    followup_consent: false,
    needs_refresh: false,
  }
}

///|
fn close_neighborhood(state : NeighborhoodState) -> NeighborhoodState {
  { ..state, open: false, }
}

///|
fn neighborhood_error_label(status : Int32, code : String) -> String {
  if status == 401 || code == "unauthenticated" {
    "登录已失效，请重新登录后刷新。"
  } else if status == 403 || code == "forbidden" {
    "当前账户不能执行此操作。"
  } else if status == 404 || code == "not_found" {
    "内容已不可用，请刷新查看。"
  } else if status == 409 || code == "conflict" {
    "状态已变化，请刷新后再操作。"
  } else if status == 400 || code == "invalid_request" {
    "请检查所填内容及确认选项。"
  } else {
    "暂时无法连接街区，请稍后刷新。"
  }
}

///|
/// Only accept a real server snapshot. An empty feed is not demo content.
fn neighborhood_decode_snapshot(body : Json) -> Json? {
  match body {
    { "ok": True, "payload": payload, .. } =>
      match payload {
        {
          "schema": String("moontown.neighborhood.v1"),
          "revision": Number(_),
          "stories": Array(_),
          "events": Array(_),
          "mine": _,
          ..
        } => Some(payload)
        _ => None
      }
    _ => None
  }
}

///|
fn neighborhood_loaded(
  state : NeighborhoodState,
  route : String,
  raw : String,
) -> NeighborhoodState {
  let wire = @json.parse(raw) catch { _ => Json::null() }
  let status = neighborhood_number(wire, "status")
  let body = @json.parse(neighborhood_text(wire, "body")) catch {
    _ => Json::null()
  }
  let completed = if route == "public" {
    { ..state, loading: false, }
  } else {
    { ..state, mine_loading: false, busy: false, }
  }
  if route != "public" && neighborhood_text(body, "error") == "identity_changed" {
    return {
      ..neighborhood_clear_identity(completed),
      mine_error: "账户已切换，已清除旧账户草稿；请刷新后继续。",
    }
  }
  if status == 401 && route != "public" {
    return {
      ..neighborhood_clear_identity(completed),
      mine_error: if route == "mine" {
        ""
      } else {
        neighborhood_error_label(status, "")
      },
    }
  }
  guard status >= 200 &&
    status < 300 &&
    neighborhood_decode_snapshot(body) is Some(snapshot) else {
    let message = if route == "action" && status == 0 {
      "提交结果尚未确认，请先刷新查看，勿重复提交。"
    } else {
      neighborhood_error_label(status, neighborhood_text(body, "error"))
    }
    return if route == "public" {
      { ..completed, error: message, }
    } else if route == "action" {
      { ..completed, mine_error: message, needs_refresh: status != 400, }
    } else {
      { ..completed, mine: None, mine_error: message, }
    }
  }
  // Public and authenticated reads may arrive in either order. Never let the
  // older public response overwrite a newer publication or registration.
  let visible_snapshot = match state.snapshot {
    Some(previous) if neighborhood_number(previous, "revision") >
      neighborhood_number(snapshot, "revision") => previous
    _ => snapshot
  }
  // Public data may not install a private projection even if a host misroutes it.
  let safe_snapshot = match visible_snapshot {
    Object(fields) => {
      let safe = fields.copy()
      safe["mine"] = Json::null()
      Json::object(safe)
    }
    _ => visible_snapshot
  }
  if route == "public" {
    return { ..completed, snapshot: Some(safe_snapshot), error: "", }
  }
  guard neighborhood_field(snapshot, "mine") is Some(mine) &&
    !neighborhood_text(mine, "actor_id").is_empty() else {
    return {
      ..neighborhood_clear_identity(completed),
      snapshot: Some(safe_snapshot),
      mine_error: "请登录后刷新，查看自己的报名。",
    }
  }
  let actor = neighborhood_text(mine, "actor_id")
  let same_actor = actor == state.actor_id || state.actor_id.is_empty()
  let next = if same_actor {
    completed
  } else {
    neighborhood_clear_identity(completed)
  }
  {
    ..next,
    snapshot: Some(safe_snapshot),
    mine: Some(mine),
    actor_id: actor,
    error: "",
    mine_error: "",
    needs_refresh: false,
    notice: if route == "action" {
      "已保存"
    } else {
      ""
    },
    // Consent applies to one explicit request, not the next event.
    followup_consent: if route == "action" {
      false
    } else {
      next.followup_consent
    },
    followup_message: if route == "action" {
      ""
    } else {
      next.followup_message
    },
  }
}

///|
fn neighborhood_transition(
  state : NeighborhoodState,
  message : NeighborhoodMsg,
) -> (NeighborhoodState, NeighborhoodRequest?) {
  match message {
    Preview => {
      if state.loading || state.mine_loading || state.busy {
        return (state, None)
      }
      let generation = state.generation + 1
      (
        { ..state, generation, loading: true, error: "", },
        Some(PublicLoad(generation)),
      )
    }
    Open | Refresh => {
      if state.busy {
        return (
          if message is Open {
            { ..state, open: true, }
          } else {
            state
          },
          None,
        )
      }
      let generation = state.generation + 1
      (
        {
          ..state,
          open: true,
          generation,
          loading: true,
          mine_loading: true,
          mine: None,
          error: "",
          mine_error: "",
          notice: "",
          needs_refresh: false,
        },
        Some(Load(generation)),
      )
    }
    Close => (close_neighborhood(state), None)
    SelectSection(section) =>
      if ["events", "stories", "mine"].contains(section) {
        ({ ..state, section, selected_id: "", notice: "", }, None)
      } else {
        (state, None)
      }
    SelectStory(id) =>
      ({ ..state, section: "stories", selected_id: id, notice: "", }, None)
    SelectEvent(id) =>
      (
        {
          ..state,
          section: "events",
          selected_id: id,
          notice: "",
          followup_message: "",
          followup_consent: false,
        },
        None,
      )
    Back => ({ ..state, selected_id: "", notice: "", }, None)
    Edit(field, value) => {
      let next = match field {
        "name" => { ..state, display_name: value, }
        "contact" => { ..state, contact: value, }
        "followup" => { ..state, followup_message: value, }
        _ => state
      }
      (next, None)
    }
    SetFollowupConsent(value) => ({ ..state, followup_consent: value, }, None)
    Action(action, payload) => {
      guard state.open &&
        !state.busy &&
        !state.mine_loading &&
        !state.needs_refresh else {
        return (state, None)
      }
      guard state.mine is Some(_) else {
        return (
          { ..state, mine_error: "请先登录，再刷新报名状态。", },
          None,
        )
      }
      if action == "register" &&
        neighborhood_text(payload, "display_name").trim().is_empty() {
        return ({ ..state, mine_error: "请填写报名姓名。", }, None)
      }
      if action == "request-follow-up" &&
        (
          !state.followup_consent ||
          neighborhood_text(payload, "message").trim().is_empty()
        ) {
        return (
          {
            ..state,
            mine_error: "请填写需求，并确认愿意让主办方跟进。",
          },
          None,
        )
      }
      let generation = state.generation + 1
      (
        {
          ..state,
          generation,
          busy: true,
          loading: false,
          error: "",
          mine_error: "",
          notice: "",
        },
        Some(Submit(generation, state.actor_id, action, payload)),
      )
    }
    Loaded(generation, route, raw) =>
      if generation != state.generation {
        (state, None)
      } else {
        (neighborhood_loaded(state, route, raw), None)
      }
  }
}

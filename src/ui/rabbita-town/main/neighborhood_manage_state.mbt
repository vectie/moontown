///|
enum NeighborhoodManageSection {
  ManageStories
  ManageEvents
  ManageFollowups
} derive(Debug, Eq)

///|
struct NeighborhoodStoryForm {
  id : String
  title : String
  author_name : String
  body : String
  consent : Bool
  consent_revision : Int32
} derive(Debug, Eq)

///|
struct NeighborhoodEventForm {
  id : String
  title : String
  description : String
  location : String
  starts : String
  ends : String
  capacity : String
} derive(Debug, Eq)

///|
/// Only local, editable intent lives here. All authority and saved state come
/// from the current account's /mine response, never from this form.
struct NeighborhoodManageState {
  section : NeighborhoodManageSection
  story : NeighborhoodStoryForm?
  event : NeighborhoodEventForm?
  followup_fields : Map[String, String]
  confirmation : (String, String)?
  notice : String
  work_context : String
  roster_page : Int32
} derive(Debug, Eq)

///|
enum NeighborhoodManageMsg {
  Section(NeighborhoodManageSection)
  NewStory
  EditStory(String)
  StoryField(String, String)
  StoryConsent(Bool)
  SaveStory
  PublishStory
  NewEvent
  EditEvent(String)
  EventField(String, String)
  SaveEvent
  PublishEvent
  Confirm(String, String)
  CancelConfirmation
  CommitConfirmation
  CheckIn(String)
  RosterPage(Int32)
  FollowupField(String, String, String)
  ResolveFollowup(String)
  ContinueWork(String)
  ClearWorkContext
} derive(Debug, Eq)

///|
fn initial_neighborhood_manage_state() -> NeighborhoodManageState {
  {
    section: ManageStories,
    story: None,
    event: None,
    followup_fields: Map([]),
    confirmation: None,
    notice: "",
    work_context: "",
    roster_page: 0,
  }
}

///|
fn neighborhood_manage_revoke_consent(
  state : NeighborhoodManageState,
) -> NeighborhoodManageState {
  {
    ..state,
    story: state.story.map(form => {
      ..form,
      consent: false,
      consent_revision: 0,
    }),
  }
}

///|
fn neighborhood_manage_reconcile(
  state : NeighborhoodManageState,
  mine : Json?,
) -> NeighborhoodManageState {
  guard mine is Some(mine) && state.story is Some(form) && form.consent else {
    return state
  }
  let observed_revision = neighborhood_manage_find(mine, "stories", form.id)
    .map(story => neighborhood_number(story, "content_revision"))
    .unwrap_or(0)
  if observed_revision <= 0 || observed_revision != form.consent_revision {
    {
      ..neighborhood_manage_revoke_consent(state),
      notice: "故事版本已变化，请核对当前保存的内容后重新确认公开。",
    }
  } else {
    state
  }
}

///|
/// Browser primitives only: formatting and converting datetime-local values
/// uses the visitor's local timezone. Validation and workflow stay in MoonBit.
extern "js" fn neighborhood_manage_local_time(ms : Double) -> String =
  #| ms => {
  #|   const date = new Date(ms);
  #|   if (!Number.isFinite(date.getTime())) return "";
  #|   const pad = n => String(n).padStart(2, "0");
  #|   return `${date.getFullYear()}-${pad(date.getMonth()+1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`;
  #| }

///|
extern "js" fn neighborhood_manage_new_id(prefix : String) -> String =
  #| prefix => prefix + "-" + (globalThis.crypto?.randomUUID?.().replaceAll("-", "") || `${Date.now().toString(36)}-${Math.random().toString(36).slice(2)}`)

///|
fn neighborhood_manage_number(value : Json, key : String) -> Double {
  match neighborhood_field(value, key) {
    Some(Number(number)) => number
    _ => -1.0
  }
}

///|
fn neighborhood_manage_find(
  mine : Json,
  collection : String,
  id : String,
) -> Json? {
  neighborhood_items(mine, collection)
  .iter()
  .find_first(item => neighborhood_text(item, "id") == id)
}

///|
fn neighborhood_manage_followup(mine : Json, id : String) -> (Json, Json)? {
  for event in neighborhood_items(mine, "events") {
    for followup in neighborhood_items(event, "followups") {
      if neighborhood_text(followup, "id") == id {
        return Some((event, followup))
      }
    }
  }
  None
}

///|
fn neighborhood_manage_story_saved(
  form : NeighborhoodStoryForm,
  mine : Json,
) -> Bool {
  match neighborhood_manage_find(mine, "stories", form.id) {
    Some(story) =>
      neighborhood_text(story, "title") == form.title.trim().to_owned() &&
      neighborhood_text(story, "author_name") ==
      form.author_name.trim().to_owned() &&
      neighborhood_text(story, "body") == form.body.trim().to_owned()
    None => false
  }
}

///|
fn neighborhood_manage_event_saved(
  form : NeighborhoodEventForm,
  mine : Json,
) -> Bool {
  let capacity = @string.parse_int(form.capacity.trim().to_owned()) catch {
    _ => -1
  }
  match neighborhood_manage_find(mine, "events", form.id) {
    Some(event) =>
      neighborhood_text(event, "title") == form.title.trim().to_owned() &&
      neighborhood_text(event, "description") ==
      form.description.trim().to_owned() &&
      neighborhood_text(event, "location") == form.location.trim().to_owned() &&
      neighborhood_manage_number(event, "starts_ms") ==
      browser_timestamp_ms(form.starts) &&
      neighborhood_manage_number(event, "ends_ms") ==
      browser_timestamp_ms(form.ends) &&
      neighborhood_manage_number(event, "capacity").to_int() == capacity
    None => false
  }
}

///|
fn neighborhood_manage_story_dirty(
  form : NeighborhoodStoryForm,
  mine : Json,
) -> Bool {
  (
    neighborhood_manage_find(mine, "stories", form.id) is Some(_) ||
    !form.title.is_blank() ||
    !form.author_name.is_blank() ||
    !form.body.is_blank()
  ) &&
  !neighborhood_manage_story_saved(form, mine)
}

///|
fn neighborhood_manage_event_dirty(
  form : NeighborhoodEventForm,
  mine : Json,
) -> Bool {
  (
    neighborhood_manage_find(mine, "events", form.id) is Some(_) ||
    !form.title.is_blank() ||
    !form.description.is_blank() ||
    !form.location.is_blank() ||
    !form.starts.is_blank() ||
    !form.ends.is_blank() ||
    form.capacity != "20"
  ) &&
  !neighborhood_manage_event_saved(form, mine)
}

///|
fn neighborhood_manage_story_error(form : NeighborhoodStoryForm) -> String {
  if form.title.is_blank() || form.title.trim().length() > 160 {
    "请填写故事标题，不超过 160 字。"
  } else if form.author_name.trim().length() > 100 {
    "公开署名不超过 100 字。"
  } else if form.body.is_blank() || form.body.trim().length() > 20000 {
    "请填写故事正文，不超过 20000 字。"
  } else {
    ""
  }
}

///|
fn neighborhood_manage_event_error(
  form : NeighborhoodEventForm,
  now_ms : Double,
) -> String {
  if form.title.is_blank() || form.title.trim().length() > 160 {
    return "请填写活动名称，不超过 160 字。"
  }
  if form.description.is_blank() || form.description.trim().length() > 10000 {
    return "请填写活动说明，不超过 10000 字。"
  }
  if form.location.is_blank() || form.location.trim().length() > 500 {
    return "请填写活动地点，不超过 500 字。"
  }
  let starts = browser_timestamp_ms(form.starts)
  let ends = browser_timestamp_ms(form.ends)
  if starts <= now_ms || ends <= starts {
    return "请选择未来的开始时间，结束时间应晚于开始时间。"
  }
  let capacity = @string.parse_int(form.capacity.trim().to_owned()) catch {
    _ => 0
  }
  if capacity < 1 || capacity > 10000 {
    "人数需为 1–10000 之间的整数。"
  } else {
    ""
  }
}

///|
fn neighborhood_manage_can_check_in(
  event : Json,
  registration : Json,
  now_ms : Double,
) -> Bool {
  neighborhood_text(event, "state") == "published" &&
  neighborhood_text(registration, "state") == "confirmed" &&
  now_ms >= neighborhood_manage_number(event, "starts_ms") &&
  now_ms <= neighborhood_manage_number(event, "ends_ms")
}

///|
fn neighborhood_manage_status(value : String) -> String {
  match value {
    "draft" => "仅自己可见 · 草稿"
    "published" => "已公开"
    "withdrawn" => "已撤下"
    "cancelled" => "已取消"
    "ended" => "已结束"
    "confirmed" => "已报名"
    "waitlisted" => "候补中"
    "checked_in" => "已签到"
    "event_cancelled" => "活动已取消"
    "open" => "待回复"
    "resolved" => "已记录下一步"
    _ => "状态待确认"
  }
}

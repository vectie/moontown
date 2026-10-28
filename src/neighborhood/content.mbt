///|
fn save_story(
  state : State,
  payload : Json,
  actor : String,
  now_ms : UInt64,
) -> State raise NeighborhoodError {
  let id = object_id(payload, "id", fallback=fresh_id(state, "story"))
  let previous = state.stories.iter().find_first(s => s.id == id)
  if previous is Some(story) {
    owner(actor, story.owner_id)
    guard story.state != "published" else {
      raise Conflict("withdraw the story before editing")
    }
  }
  let story : Story = {
    id,
    owner_id: actor,
    author_name: Some(text_field(payload, "author_name", 100, optional=true)),
    content_revision: Some(state.revision + 1),
    title: text_field(payload, "title", 160),
    body: text_field(payload, "body", 20000),
    state: "draft",
    created_ms: previous.map(s => s.created_ms).unwrap_or(now_ms),
    updated_ms: now_ms,
    published_ms: None,
  }
  let stories = state.stories.filter(s => s.id != id)
  stories.push(story)
  { ..state, stories, }
}

///|
fn transition_story(
  state : State,
  payload : Json,
  actor : String,
  now_ms : UInt64,
  publish : Bool,
) -> State raise NeighborhoodError {
  let id = object_id(payload, "story_id")
  let story = state.stories
    .iter()
    .find_first(s => s.id == id)
    .unwrap_or_else(() => raise NotFound)
  owner(actor, story.owner_id)
  if publish {
    consent(payload)
    require_content_revision(payload, story.content_revision)
    guard story.state != "published" else {
      raise Conflict("story is already published")
    }
  } else {
    guard story.state == "published" else {
      raise Conflict("only a published story can be withdrawn")
    }
  }
  {
    ..state,
    stories: state.stories.map(s => {
      if s.id == id {
        {
          ..s,
          state: if publish {
            "published"
          } else {
            "withdrawn"
          },
          updated_ms: now_ms,
          published_ms: if publish {
            Some(now_ms)
          } else {
            s.published_ms
          },
        }
      } else {
        s
      }
    }),
  }
}

///|
fn save_event(
  state : State,
  payload : Json,
  actor : String,
  now_ms : UInt64,
  can_host : Bool,
) -> State raise NeighborhoodError {
  let id = object_id(payload, "id", fallback=fresh_id(state, "event"))
  let previous = state.events.iter().find_first(e => e.id == id)
  match previous {
    Some(event) => {
      owner(actor, event.owner_id)
      guard event.state == "draft" else {
        raise Conflict("only a draft event can be edited")
      }
    }
    None => {
      guard can_host else { raise Forbidden }
    }
  }
  let starts_ms = timestamp_field(payload, "starts_ms")
  let ends_ms = timestamp_field(payload, "ends_ms")
  let capacity : Int32 = number_field(payload, "capacity")
  guard starts_ms > now_ms && ends_ms > starts_ms else {
    raise InvalidRequest("event start must be in the future and before its end")
  }
  guard capacity >= 1 && capacity <= 10000 else {
    raise InvalidRequest("capacity must be between 1 and 10000")
  }
  let event : Event = {
    id,
    owner_id: actor,
    content_revision: Some(state.revision + 1),
    title: text_field(payload, "title", 160),
    description: text_field(payload, "description", 10000),
    location: text_field(payload, "location", 500),
    starts_ms,
    ends_ms,
    capacity,
    state: "draft",
    created_ms: previous.map(e => e.created_ms).unwrap_or(now_ms),
    updated_ms: now_ms,
    published_ms: None,
  }
  let events = state.events.filter(e => e.id != id)
  events.push(event)
  { ..state, events, }
}

///|
fn transition_event(
  state : State,
  payload : Json,
  actor : String,
  now_ms : UInt64,
  operation : String,
) -> State raise NeighborhoodError {
  let id = object_id(payload, "event_id")
  let event = event_by_id(state, id)
  owner(actor, event.owner_id)
  let next_state = match operation {
    "publish-event" => {
      consent(payload)
      require_content_revision(payload, event.content_revision)
      guard event.state == "draft" && event.starts_ms > now_ms else {
        raise Conflict("only a future draft event can be published")
      }
      "published"
    }
    "cancel-event" => {
      guard event.state == "draft" || event.state == "published" else {
        raise Conflict("event is already closed")
      }
      "cancelled"
    }
    "end-event" => {
      guard event.state == "published" && now_ms >= event.starts_ms else {
        raise Conflict("only a started published event can end")
      }
      "ended"
    }
    _ => raise InvalidRequest("unsupported event operation")
  }
  let next = change_event(state, {
    ..event,
    state: next_state,
    updated_ms: now_ms,
    published_ms: if next_state == "published" {
      Some(now_ms)
    } else {
      event.published_ms
    },
  })
  if next_state == "cancelled" {
    {
      ..next,
      registrations: next.registrations.map(r => {
        if r.event_id == id && (occupied(r) || r.state == "waitlisted") {
          { ..r, state: "event_cancelled", updated_ms: now_ms, }
        } else {
          r
        }
      }),
    }
  } else {
    next
  }
}

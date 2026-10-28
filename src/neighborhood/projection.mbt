///|
fn timestamp(value : UInt64) -> Json {
  value.to_double().to_json()
}

///|
fn optional_timestamp(value : UInt64?) -> Json {
  value.map(timestamp).unwrap_or(Json::null())
}

///|
fn public_story(story : Story) -> Json {
  {
    "id": story.id,
    "author_name": story.author_name.unwrap_or(""),
    "content_revision": story.content_revision.unwrap_or(0),
    "title": story.title,
    "body": story.body,
    "state": story.state,
    "created_ms": timestamp(story.created_ms),
    "updated_ms": timestamp(story.updated_ms),
    "published_ms": optional_timestamp(story.published_ms),
  }
}

///|
fn public_event(state : State, event : Event) -> Json {
  {
    "id": event.id,
    "content_revision": event.content_revision.unwrap_or(0),
    "title": event.title,
    "description": event.description,
    "location": event.location,
    "starts_ms": timestamp(event.starts_ms),
    "ends_ms": timestamp(event.ends_ms),
    "capacity": event.capacity,
    "state": event.state,
    "confirmed_count": event_occupancy(state, event.id),
    "waitlisted_count": state.registrations
    .filter(r => r.event_id == event.id && r.state == "waitlisted")
    .length(),
    "created_ms": timestamp(event.created_ms),
    "updated_ms": timestamp(event.updated_ms),
    "published_ms": optional_timestamp(event.published_ms),
  }
}

///|
fn owned_event(state : State, event : Event) -> Json {
  guard public_event(state, event) is Object(fields) else {
    return Json::null()
  }
  fields["registrations"] = state.registrations
    .filter(r => r.event_id == event.id)
    .map(private_registration)
    .to_json()
  fields["followups"] = state.followups
    .filter(f => f.event_id == event.id)
    .map(private_followup)
    .to_json()
  Json::object(fields)
}

///|
fn snapshot(state : State, actor : String?, can_host : Bool) -> Json {
  let mine : Json = match actor {
    Some(actor) =>
      {
        "actor_id": actor,
        "can_host": can_host,
        "stories": state.stories
        .filter(s => s.owner_id == actor)
        .map(public_story)
        .to_json(),
        "events": state.events
        .filter(e => e.owner_id == actor)
        .map(e => owned_event(state, e))
        .to_json(),
        "registrations": state.registrations
        .filter(r => r.participant_id == actor)
        .map(private_registration)
        .to_json(),
        "followups": state.followups
        .filter(f => f.participant_id == actor)
        .map(private_followup)
        .to_json(),
      }
    None => Json::null()
  }
  {
    "schema": "moontown.neighborhood.v1",
    "revision": state.revision,
    "stories": state.stories
    .filter(s => s.state == "published")
    .map(public_story)
    .to_json(),
    // Cancellation/end notices remain public only if publication was authorized.
    // A cancelled private draft must never become a public announcement.
    "events": state.events
    .filter(e => e.published_ms is Some(_))
    .map(e => public_event(state, e))
    .to_json(),
    "mine": mine,
  }
}

///|
fn private_registration(registration : Registration) -> Json {
  {
    "id": registration.id,
    "event_id": registration.event_id,
    "participant_id": registration.participant_id,
    "display_name": registration.display_name,
    "contact": registration.contact,
    "state": registration.state,
    "created_ms": timestamp(registration.created_ms),
    "updated_ms": timestamp(registration.updated_ms),
    "checked_in_ms": optional_timestamp(registration.checked_in_ms),
  }
}

///|
fn private_followup(followup : Followup) -> Json {
  {
    "id": followup.id,
    "event_id": followup.event_id,
    "participant_id": followup.participant_id,
    "message": followup.message,
    "contact": followup.contact,
    "state": followup.state,
    "next_step": followup.next_step,
    "outcome": followup.outcome,
    "created_ms": timestamp(followup.created_ms),
    "updated_ms": timestamp(followup.updated_ms),
    "resolved_ms": optional_timestamp(followup.resolved_ms),
  }
}

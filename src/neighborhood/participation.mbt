///|
fn register(
  state : State,
  payload : Json,
  actor : String,
  now_ms : UInt64,
) -> State raise NeighborhoodError {
  let event_id = object_id(payload, "event_id")
  let event = event_by_id(state, event_id)
  guard event.state == "published" && now_ms < event.ends_ms else {
    raise Conflict("event registration is closed")
  }
  guard !state.registrations.any(r => {
    r.event_id == event_id &&
    r.participant_id == actor &&
    r.state != "cancelled"
  }) else {
    raise Conflict("already registered for this event")
  }
  let registration : Registration = {
    id: fresh_id(state, "registration"),
    event_id,
    participant_id: actor,
    display_name: text_field(payload, "display_name", 100),
    contact: text_field(payload, "contact", 500, optional=true),
    state: if event_occupancy(state, event_id) < event.capacity {
      "confirmed"
    } else {
      "waitlisted"
    },
    created_ms: now_ms,
    updated_ms: now_ms,
    checked_in_ms: None,
  }
  let registrations = state.registrations.copy()
  registrations.push(registration)
  { ..state, registrations, }
}

///|
fn change_registration(
  state : State,
  payload : Json,
  actor : String,
  now_ms : UInt64,
  check_in : Bool,
) -> State raise NeighborhoodError {
  let id = object_id(payload, "registration_id")
  let registration = state.registrations
    .iter()
    .find_first(r => r.id == id)
    .unwrap_or_else(() => raise NotFound)
  let event = event_by_id(state, registration.event_id)
  if check_in {
    owner(actor, event.owner_id)
    guard event.state == "published" &&
      now_ms >= event.starts_ms &&
      now_ms <= event.ends_ms &&
      registration.state == "confirmed" else {
      raise Conflict(
        "check-in requires a confirmed registration during the event",
      )
    }
  } else {
    owner(actor, registration.participant_id)
    guard event.state == "published" &&
      now_ms < event.ends_ms &&
      (registration.state == "confirmed" || registration.state == "waitlisted") else {
      raise Conflict("this registration cannot be cancelled")
    }
  }
  let registrations = state.registrations.map(r => {
    if r.id == id {
      {
        ..r,
        state: if check_in {
          "checked_in"
        } else {
          "cancelled"
        },
        updated_ms: now_ms,
        checked_in_ms: if check_in {
          Some(now_ms)
        } else {
          r.checked_in_ms
        },
      }
    } else {
      r
    }
  })
  // Store order is admission order, including re-registration after a cancel.
  // Promotion and release are persisted as one locked transaction.
  if !check_in && occupied(registration) {
    for i, waiting in registrations {
      if waiting.event_id == event.id && waiting.state == "waitlisted" {
        registrations[i] = {
          ..waiting,
          state: "confirmed",
          updated_ms: now_ms,
        }
        break
      }
    }
  }
  { ..state, registrations, }
}

///|
fn request_followup(
  state : State,
  payload : Json,
  actor : String,
  now_ms : UInt64,
) -> State raise NeighborhoodError {
  let event_id = object_id(payload, "event_id")
  let event = event_by_id(state, event_id)
  consent(payload)
  guard event.state == "ended" else {
    raise Conflict("follow-up requests open after the event ends")
  }
  guard state.registrations.any(r => {
    r.event_id == event_id && r.participant_id == actor && occupied(r)
  }) else {
    raise Forbidden
  }
  guard !state.followups.any(f => {
    f.event_id == event_id && f.participant_id == actor
  }) else {
    raise Conflict("a follow-up request already exists")
  }
  let followup : Followup = {
    id: fresh_id(state, "followup"),
    event_id,
    participant_id: actor,
    message: text_field(payload, "message", 5000),
    contact: text_field(payload, "contact", 500, optional=true),
    state: "open",
    next_step: "",
    outcome: "",
    created_ms: now_ms,
    updated_ms: now_ms,
    resolved_ms: None,
  }
  let followups = state.followups.copy()
  followups.push(followup)
  { ..state, followups, }
}

///|
fn resolve_followup(
  state : State,
  payload : Json,
  actor : String,
  now_ms : UInt64,
) -> State raise NeighborhoodError {
  let id = object_id(payload, "followup_id")
  let followup = state.followups
    .iter()
    .find_first(f => f.id == id)
    .unwrap_or_else(() => raise NotFound)
  let event = event_by_id(state, followup.event_id)
  owner(actor, event.owner_id)
  guard followup.state == "open" else {
    raise Conflict("follow-up has already been resolved")
  }
  let next_step = text_field(payload, "next_step", 5000)
  let outcome = text_field(payload, "outcome", 5000, optional=true)
  {
    ..state,
    followups: state.followups.map(f => {
      if f.id == id {
        {
          ..f,
          state: "resolved",
          next_step,
          outcome,
          updated_ms: now_ms,
          resolved_ms: Some(now_ms),
        }
      } else {
        f
      }
    }),
  }
}

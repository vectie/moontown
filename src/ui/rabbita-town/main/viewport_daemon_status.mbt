///|
fn daemon_tick_count(model : Model) -> Int {
  match model.daemon_snapshot {
    Some(snapshot) => snapshot.tick_sequence
    None => 0
  }
}

///|
fn daemon_tick_label(model : Model) -> String {
  match model.daemon_snapshot {
    Some(snapshot) => "Town check \{snapshot.tick_sequence}"
    None => "Town check waiting"
  }
}

///|
fn daemon_heartbeat_label(model : Model) -> String {
  match model.daemon_snapshot {
    Some(snapshot) => "Heartbeat events \{snapshot.last_heartbeat_event_count}"
    None => "Heartbeat waiting"
  }
}

///|
fn daemon_cadence_label(model : Model) -> String {
  match model.daemon_snapshot {
    Some(snapshot) => {
      let mut cadence = 30
      let mut kind = "standing-goal"
      for job in snapshot.jobs {
        if job.id == "dispatch-standing-goals" {
          cadence = job.interval_seconds
          kind = job.kind
        }
      }
      ignore(kind)
      "Watch cadence \{cadence}s"
    }
    None => "Watch cadence waiting"
  }
}

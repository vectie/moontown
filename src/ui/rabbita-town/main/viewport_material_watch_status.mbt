///|
fn material_watch_latest_record(
  model : Model,
  goal_id : String,
) -> WatcherRunRecordSnapshot? {
  let mut latest : WatcherRunRecordSnapshot? = None
  for record in model.watcher_records {
    if record.goal_id == goal_id {
      match latest {
        Some(previous) if previous.tick > record.tick => ()
        _ => latest = Some(record)
      }
    }
  }
  latest
}

///|
fn material_watch_baseline_status(model : Model, goal_id : String) -> String {
  let mut baseline_tick : Int? = None
  let mut later_baseline_evidence = false
  for record in model.watcher_records {
    if record.goal_id != goal_id {
      continue
    }
    if record.decision == "NoChange" &&
      record.detail.has_prefix("Material watch baseline saved") {
      match baseline_tick {
        Some(tick) if tick <= record.tick => ()
        _ => baseline_tick = Some(record.tick)
      }
    }
    if (
        record.decision == "NoChange" &&
        record.detail.has_prefix("Material watch unchanged:")
      ) ||
      (
        (
          record.decision == "Update" ||
          record.decision == "NeedsReview" ||
          record.decision == "NoChange"
        ) &&
        material_watch_source_bound_record(record)
      ) {
      later_baseline_evidence = true
    }
  }
  match baseline_tick {
    Some(tick) => "First baseline: saved at tick \{tick}; no review requested"
    None if later_baseline_evidence =>
      "First baseline: established; its original tick is outside the available history"
    None => "First baseline: awaiting a confirmed baseline record"
  }
}

///|
fn material_watch_source_bound_record(
  record : WatcherRunRecordSnapshot,
) -> Bool {
  record.task_id is Some(_) &&
  record.detail
  .split("\n")
  .any(line => line.has_prefix("material_watch_input: ")) &&
  record.detail
  .split("\n")
  .any(line => line.has_prefix("material_watch_input_sha256: "))
}

///|
fn material_watch_next_check_status(model : Model, goal_id : String) -> String {
  for goal in model.standing_goals {
    if goal.id == goal_id {
      return if goal.enabled {
        "Next check: tick \{goal.next_due_tick}"
      } else {
        "Watch paused; saved next due tick \{goal.next_due_tick}"
      }
    }
  }
  if material_watch_latest_record(model, goal_id) is Some(record) {
    return "Latest ledger next due tick: \{record.next_due_tick}; standing-goal snapshot unavailable"
  }
  "Next check: awaiting the standing-goal snapshot"
}

///|
fn material_watch_decision_status(record : WatcherRunRecordSnapshot) -> String {
  let outcome = if record.decision == "NoChange" &&
    record.detail.has_prefix("Material watch baseline saved") {
    "Baseline saved quietly; no task dispatched"
  } else if record.decision == "NoChange" &&
    record.detail.has_prefix("Material watch unchanged:") {
    "Quiet: sources and plan unchanged; no new task or review"
  } else {
    match watcher_decision_kind(record.decision) {
      NeedsReview => "Change awaits Book review"
      Update => "Change processed through the Book workflow"
      NoChange =>
        if material_watch_source_bound_record(record) {
          "Source change reviewed; no accepted knowledge change"
        } else {
          "Checked or reviewed; no accepted knowledge change"
        }
      Failed => "Blocked: check failed; this is not a quiet result"
      Deferred => "Waiting: the existing work or dispatch needs reconciliation"
      Other => "Outcome not yet recognized"
    }
  }
  "Latest check at tick \{record.tick}: \{outcome}"
}

///|
fn render_material_watch_saved_card(
  model : Model,
  title : String,
  goal_id : String,
  saved : MaterialWatchSnapshot,
  book_id? : String = "",
) -> @rabbita.Html {
  article(class="request-composer material-watch-saved", [
    h3(title),
    p(class="request-status", "Saved local material watch · \{goal_id}"),
    if !book_id.is_empty() {
      p(class="request-status", "Target Book: \{book_id}")
    } else {
      div(no_children())
    },
    p(class="request-last", "Intent: \{saved.intent}"),
    div(
      class="request-field",
      [
        p(class="request-label", "Saved source paths (Book-relative)"),
        ..saved.sources.map(path => p(class="request-last", path)),
      ],
    ),
    p(class="request-last", "Acceptance: \{saved.acceptance}"),
    p(class="request-last", "Next owner action: \{saved.next_action}"),
    p(class="request-last", "Saved plan: \{saved.plan_path}"),
    p(class="request-status", material_watch_baseline_status(model, goal_id)),
    p(class="request-status", material_watch_next_check_status(model, goal_id)),
    match material_watch_latest_record(model, goal_id) {
      Some(record) =>
        div([
          p(class="request-status", material_watch_decision_status(record)),
          p(class="request-last", one_line(record.detail)),
          if record.task_id is Some(task_id) {
            p(class="request-last", "Retained task: \{task_id}")
          } else {
            div(no_children())
          },
        ])
      None =>
        p(
          class="request-status",
          "No check recorded yet. Saving does not establish the first baseline.",
        )
    },
  ])
}

///|
fn render_material_watch_saved_requests(model : Model) -> @rabbita.Html {
  let cards = []
  for request in model.operator_requests {
    if request.material_watch is Some(saved) {
      cards.push(
        render_material_watch_saved_card(
          model,
          request.title,
          request.standing_goal_id,
          saved,
          book_id=request.target_book_id,
        ),
      )
    }
  }
  // A received save response is useful before asynchronous snapshot refresh.
  // After reload, the durable operator-request snapshot is authoritative.
  if model.request_material_receipt
    is Some((request_id, goal_id, book_id, saved)) &&
    !model.operator_requests.any(request => {
      request.id == request_id && request.material_watch is Some(_)
    }) {
    cards.push(
      render_material_watch_saved_card(
        model,
        "Just saved",
        goal_id,
        saved,
        book_id~,
      ),
    )
  }
  div(class="request-desk-stack", cards)
}

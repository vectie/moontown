///|
priv struct WatcherTimelineItemView {
  class_name : String
  title : String
  detail : String
  goal_label : String
  book_label : String
  new_source_label : String
  checked_label : String
  found_label : String
  accepted_label : String
  rejected_label : String
  wiki_label : String
  book_changed_label : String
  delta_label : String
  next_label : String
  task_label : String
  run_label : String
}

///|
fn watcher_timeline_item_view(
  record : WatcherRunRecordSnapshot,
) -> WatcherTimelineItemView {
  let metrics = watcher_record_metric_labels(record)
  {
    class_name: watcher_decision_class("watch-timeline-item", record.decision),
    title: "\{record.decision} at tick \{record.tick}",
    detail: one_line(record.detail),
    goal_label: "goal \{record.goal_id}",
    book_label: "book \{record.target_book_id}",
    new_source_label: "sources +\{metrics.sources}",
    checked_label: "checked \{metrics.checked}",
    found_label: "found \{metrics.found}",
    accepted_label: "accepted \{metrics.accepted}",
    rejected_label: "rejected \{metrics.rejected}",
    wiki_label: "wiki \{metrics.wiki}",
    book_changed_label: "book changed \{metrics.book_changed}",
    delta_label: "delta \{record.delta_score}",
    next_label: "next \{record.next_due_tick}",
    task_label: match record.task_id {
      Some(task_id) => "task \{task_id}"
      None => "task pending"
    },
    run_label: match record.run_id {
      Some(run_id) => "run \{run_id}"
      None => "run pending"
    },
  }
}

///|
fn render_watcher_record(record : WatcherRunRecordSnapshot) -> @rabbita.Html {
  let view = watcher_timeline_item_view(record)
  article(class=view.class_name, [
    div(class="watch-timeline-dot", no_children()),
    div(class="watch-timeline-copy", [
      h3(view.title),
      p(view.detail),
      div(class="watch-timeline-meta", [
        span(view.goal_label),
        span(view.book_label),
        span(view.new_source_label),
        span(view.checked_label),
        span(view.found_label),
        span(view.accepted_label),
        span(view.rejected_label),
        span(view.wiki_label),
        span(view.book_changed_label),
        span(view.delta_label),
        span(view.next_label),
        span(view.task_label),
        span(view.run_label),
      ]),
    ]),
  ])
}

///|
fn latest_watcher_timeline_records(
  records : Array[WatcherRunRecordSnapshot],
  limit : Int,
) -> Array[WatcherRunRecordSnapshot] {
  let items : Array[WatcherRunRecordSnapshot] = []
  let count = if records.length() < limit { records.length() } else { limit }
  for offset in 0..<count {
    items.push(records[records.length() - 1 - offset])
  }
  items
}

///|
fn render_watcher_timeline(model : Model) -> @rabbita.Html {
  let items = latest_watcher_timeline_records(model.watcher_records, 5)
    .map(render_watcher_record)
  if items.is_empty() {
    items.push(
      article(class="watch-timeline-empty", [
        h3("No watcher records yet"),
        p(
          "Start the daemon or submit a standing watch request to create a durable progress ledger.",
        ),
      ]),
    )
  }
  div(class="watch-timeline", items)
}

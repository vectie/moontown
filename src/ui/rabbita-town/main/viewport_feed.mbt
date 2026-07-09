///|
fn feed_items(
  model : Model,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
  events : Array[@core.TownEvent],
) -> Array[FeedItem] {
  let feed : Array[FeedItem] = []
  feed.push(standing_watch_feed_item(model))
  push_live_autonomy_messages(feed, model)
  push_visual_projection_messages(feed, model)
  push_recent_event_messages(feed, events)
  push_worker_alert_messages(feed, workers, standing_watch_idle_detail(model))
  push_execution_messages(feed, executions)
  push_idle_feed_message_if_needed(feed)
  feed
}

///|
fn push_optional_feed_item(feed : Array[FeedItem], item : FeedItem?) -> Bool {
  match item {
    Some(item) => {
      feed.push(item)
      true
    }
    None => false
  }
}

///|
fn push_feed_items(feed : Array[FeedItem], items : Array[FeedItem]) -> Int {
  let mut pushed = 0
  for item in items {
    feed.push(item)
    pushed += 1
  }
  pushed
}

///|
fn standing_watch_feed_item(model : Model) -> FeedItem {
  {
    title: standing_watch_connected_title(model),
    detail: standing_watch_connected_detail(model),
    tone: "calm",
  }
}

///|
fn push_idle_feed_message_if_needed(feed : Array[FeedItem]) -> Unit {
  ignore(push_optional_feed_item(feed, idle_feed_fallback_item(feed)))
}

///|
fn feed_has_only_standing_watch_message(feed : Array[FeedItem]) -> Bool {
  feed.length() == 1
}

///|
fn idle_feed_fallback_item(feed : Array[FeedItem]) -> FeedItem? {
  if feed_has_only_standing_watch_message(feed) {
    Some(no_new_town_messages_feed_item())
  } else {
    None
  }
}

///|
fn no_new_town_messages_feed_item() -> FeedItem {
  {
    title: "No new town messages",
    detail: "The town loop is between checks. Leave this page open and the professional workspace will refresh when new watch or book activity appears.",
    tone: "neutral",
  }
}

///|
fn push_visual_projection_messages(
  feed : Array[FeedItem],
  model : Model,
) -> Unit {
  ignore(
    push_optional_feed_item(feed, visual_projection_feed_item_for_model(model)),
  )
}

///|
fn visual_projection_feed_item_for_model(model : Model) -> FeedItem? {
  model.visual_projection.map(visual_projection_feed_item)
}

///|
fn visual_projection_feed_item(
  projection : VisualProjectionSnapshot,
) -> FeedItem {
  {
    title: "Visual projection tick \{projection.tick}",
    detail: visual_projection_feed_summary(projection),
    tone: "calm",
  }
}

///|
fn visual_projection_feed_summary(
  projection : VisualProjectionSnapshot,
) -> String {
  if projection.messages.is_empty() {
    "No visual projection messages in this tick."
  } else {
    projection.messages.join(" ")
  }
}

///|
fn render_feed(feed : Array[FeedItem]) -> @rabbita.Html {
  section(class="feed-panel activity-ledger-panel", [
    div(class="activity-ledger-head", [
      span(class="activity-ledger-status", ""),
      div([
        h2("Activity Ledger"),
        p("Recent watch, review, and town work signals"),
      ]),
    ]),
    div(
      class="feed-list activity-ledger-list",
      feed.map(item => render_feed_item(item)),
    ),
  ])
}

///|
fn render_feed_item(item : FeedItem) -> @rabbita.Html {
  article(class=feed_item_class(item), [
    span(class="feed-item-rail", ""),
    div(class="feed-item-copy", [h3(item.title), p(item.detail)]),
  ])
}

///|
fn feed_item_class(item : FeedItem) -> String {
  "feed-item activity-ledger-item tone-\{item.tone}"
}

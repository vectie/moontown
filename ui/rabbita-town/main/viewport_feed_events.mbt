///|
priv enum FeedEventKind {
  StandingWatch
  StandingGoal
  Execution
  Persist
  Projection
  Summary
  Review
  Daemon
  Supervision
  CivicPattern
  CivicSalon
  Other
}

///|
fn feed_event_kind(kind : String) -> FeedEventKind {
  match kind {
    "standing-watch" => StandingWatch
    "standing-goal" => StandingGoal
    "execution" => Execution
    "persist" => Persist
    "projection" => Projection
    "summary" => Summary
    "review" => Review
    "daemon" => Daemon
    "supervision" => Supervision
    "civic-pattern" => CivicPattern
    "civic-salon" => CivicSalon
    _ => Other
  }
}

///|
fn feed_event_kind_is_daemon(kind : FeedEventKind) -> Bool {
  kind is Daemon
}

///|
fn feed_event_title(event : @core.TownEvent) -> String {
  let suffix = match event.related_book_id {
    Some(book_id) => " / \{book_id}"
    None => ""
  }
  match feed_event_kind(event.kind) {
    StandingWatch => "Mayor watch update\{suffix}"
    StandingGoal => "Watcher dispatched\{suffix}"
    Execution => "Worker run changed\{suffix}"
    Persist => "Bookkeeper saved memory\{suffix}"
    Projection => "Website projection refreshed\{suffix}"
    Summary => "Book health summary\{suffix}"
    Review => "Keeper review needed\{suffix}"
    Daemon => "Daemon heartbeat"
    Supervision => "Mayor supervision"
    CivicPattern => "Civic pattern round"
    CivicSalon => "Civic pattern round"
    Other => "Town message\{suffix}"
  }
}

///|
fn feed_event_detail_is_alert(detail : String) -> Bool {
  watcher_decision_text_mentions_failed(detail) || detail.contains("not-ready")
}

///|
fn feed_event_is_quiet_standing_watch(event : @core.TownEvent) -> Bool {
  feed_event_kind(event.kind) is StandingWatch &&
  watcher_decision_text_mentions_no_change(event.detail)
}

///|
fn feed_event_kind_is_calm(kind : FeedEventKind) -> Bool {
  match kind {
    Persist | Projection => true
    _ => false
  }
}

///|
fn feed_event_kind_is_hot(kind : FeedEventKind) -> Bool {
  match kind {
    Review | Supervision | CivicPattern | CivicSalon => true
    _ => false
  }
}

///|
fn feed_event_tone(event : @core.TownEvent) -> String {
  let kind = feed_event_kind(event.kind)
  if feed_event_detail_is_alert(event.detail) {
    "alert"
  } else if feed_event_is_quiet_standing_watch(event) {
    "calm"
  } else if feed_event_kind_is_calm(kind) {
    "calm"
  } else if feed_event_kind_is_hot(kind) {
    "hot"
  } else {
    "neutral"
  }
}

///|
fn feed_event_visible(event : @core.TownEvent) -> Bool {
  !(feed_event_kind(event.kind) is Other)
}

///|
fn feed_item_for_event(event : @core.TownEvent) -> FeedItem? {
  if feed_event_visible(event) {
    Some({
      title: feed_event_title(event),
      detail: event.detail,
      tone: feed_event_tone(event),
    })
  } else {
    None
  }
}

///|
let recent_event_feed_limit = 6

///|
fn recent_event_limit_reached(pushed : Int) -> Bool {
  pushed >= recent_event_feed_limit
}

///|
fn recent_event_should_skip(
  kind : FeedEventKind,
  daemon_pushed~ : Bool,
) -> Bool {
  feed_event_kind_is_daemon(kind) && daemon_pushed
}

///|
fn recent_event_feed_items(
  events : Array[@core.TownEvent],
) -> Array[FeedItem] {
  let feed : Array[FeedItem] = []
  let mut pushed = 0
  let mut daemon_pushed = false
  for offset in 0..<events.length() {
    let event = events[events.length() - 1 - offset]
    let kind = feed_event_kind(event.kind)
    if recent_event_limit_reached(pushed) {
      break
    }
    if recent_event_should_skip(kind, daemon_pushed~) {
      continue
    }
    if push_optional_feed_item(feed, feed_item_for_event(event)) {
      pushed += 1
      if feed_event_kind_is_daemon(kind) {
        daemon_pushed = true
      }
    }
  }
  feed
}

///|
fn push_recent_event_messages(
  feed : Array[FeedItem],
  events : Array[@core.TownEvent],
) -> Unit {
  ignore(push_feed_items(feed, recent_event_feed_items(events)))
}

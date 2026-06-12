///|
fn push_live_autonomy_messages(feed : Array[FeedItem], model : Model) -> Unit {
  match model.live_autonomy {
    Some(spine) =>
      ignore(push_feed_items(feed, live_autonomy_spine_feed_items(spine)))
    None => feed.push(live_autonomy_disconnected_feed_item())
  }
}

///|
fn live_autonomy_disconnected_feed_item() -> FeedItem {
  {
    title: "Live spine not connected",
    detail: "Run `moon run src/cmd/main -- live refresh` or one daemon tick to publish `.moontown/live-autonomy.json` for the operator console.",
    tone: "alert",
  }
}

///|
fn live_autonomy_spine_feed_items(
  spine : LiveAutonomySnapshot,
) -> Array[FeedItem] {
  let feed : Array[FeedItem] = [
    live_autonomy_status_feed_item(spine),
    live_autonomy_digest_feed_item(spine),
  ]
  ignore(
    push_optional_feed_item(
      feed,
      live_autonomy_template_request_feed_item(spine),
    ),
  )
  ignore(push_feed_items(feed, live_autonomy_next_action_feed_items(spine)))
  feed
}

///|
fn live_autonomy_status_feed_item(spine : LiveAutonomySnapshot) -> FeedItem {
  {
    title: "Live spine is \{spine.status}",
    detail: spine.summary,
    tone: live_autonomy_spine_tone(spine),
  }
}

///|
fn live_autonomy_digest_feed_item(spine : LiveAutonomySnapshot) -> FeedItem {
  {
    title: "Live digest updated",
    detail: "Mayor wrote \{spine.digest_path} with current watch state, blockers, and next actions.",
    tone: "calm",
  }
}

///|
fn live_autonomy_template_request_feed_item(
  spine : LiveAutonomySnapshot,
) -> FeedItem? {
  if spine.pending_book_template_request_count > 0 ||
    spine.failed_book_template_request_count > 0 {
    Some({
      title: "Book creation inbox",
      detail: "\{spine.pending_book_template_request_count} pending, \{spine.failed_book_template_request_count} failed. \{spine.book_template_request_summary}. Latest event: \{spine.book_template_latest_event_summary}",
      tone: if spine.failed_book_template_request_count > 0 {
        "alert"
      } else {
        "book"
      },
    })
  } else {
    None
  }
}

///|
let live_autonomy_next_action_feed_limit = 2

///|
fn live_autonomy_next_action_limit_reached(pushed : Int) -> Bool {
  pushed >= live_autonomy_next_action_feed_limit
}

///|
fn live_autonomy_next_action_feed_item(
  spine : LiveAutonomySnapshot,
  action : String,
) -> FeedItem {
  {
    title: "Mayor next action",
    detail: action,
    tone: live_autonomy_next_action_tone(spine),
  }
}

///|
fn live_autonomy_next_action_feed_items(
  spine : LiveAutonomySnapshot,
) -> Array[FeedItem] {
  let feed : Array[FeedItem] = []
  let mut pushed = 0
  for action in spine.next_actions {
    if live_autonomy_next_action_limit_reached(pushed) {
      break
    }
    feed.push(live_autonomy_next_action_feed_item(spine, action))
    pushed += 1
  }
  feed
}

///|
fn live_autonomy_next_action_tone(spine : LiveAutonomySnapshot) -> String {
  if spine.status == "needs-recovery" {
    "alert"
  } else {
    "calm"
  }
}

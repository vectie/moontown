///|
fn test_visual_projection_snapshot(
  tick? : Int = 7,
  messages? : Array[String] = [],
) -> VisualProjectionSnapshot {
  { tick, agents: [], buildings: [], modules: None, messages }
}

///|
test "standing watch feed item centralizes base feed message" {
  let item = standing_watch_feed_item(init_model())
  assert_eq(item.title, "No standing watcher connected")
  assert_true(item.detail.contains("Save a standing watch"))
  assert_eq(item.tone, "calm")
}

///|
test "optional feed item push reports whether it changed the feed" {
  let feed : Array[FeedItem] = []
  assert_true(
    push_optional_feed_item(
      feed,
      Some({ title: "Town event", detail: "Worker arrived", tone: "calm" }),
    ),
  )
  assert_eq(feed.length(), 1)
  assert_eq(feed[0].title, "Town event")
  assert_true(!push_optional_feed_item(feed, None))
  assert_eq(feed.length(), 1)
}

///|
test "feed item appender returns number of appended items" {
  let feed : Array[FeedItem] = [
    { title: "Existing", detail: "base", tone: "calm" },
  ]
  let appended = push_feed_items(feed, [
    { title: "First", detail: "one", tone: "neutral" },
    { title: "Second", detail: "two", tone: "hot" },
  ])
  assert_eq(appended, 2)
  assert_eq(feed.length(), 3)
  assert_eq(feed[1].title, "First")
  assert_eq(feed[2].tone, "hot")
}

///|
test "idle feed policy only adds fallback after base message" {
  let feed : Array[FeedItem] = [standing_watch_feed_item(init_model())]
  assert_true(feed_has_only_standing_watch_message(feed))
  assert_eq(
    idle_feed_fallback_item(feed).unwrap().title,
    "No new town messages",
  )
  push_idle_feed_message_if_needed(feed)
  assert_eq(feed.length(), 2)
  assert_eq(feed[1].title, "No new town messages")
  assert_eq(feed[1].tone, "neutral")
}

///|
test "idle feed policy does not add fallback when feed has real messages" {
  let feed : Array[FeedItem] = [
    standing_watch_feed_item(init_model()),
    visual_projection_feed_item(
      test_visual_projection_snapshot(messages=["projection updated"]),
    ),
  ]
  assert_true(!feed_has_only_standing_watch_message(feed))
  assert_true(idle_feed_fallback_item(feed) is None)
  push_idle_feed_message_if_needed(feed)
  assert_eq(feed.length(), 2)
}

///|
test "visual projection feed item for model is optional" {
  assert_true(visual_projection_feed_item_for_model(init_model()) is None)
  let model = {
    ..init_model(),
    visual_projection: Some(
      test_visual_projection_snapshot(messages=["projection updated"]),
    ),
  }
  let item = visual_projection_feed_item_for_model(model)
  assert_eq(item.unwrap().title, "Visual projection tick 7")
  assert_eq(item.unwrap().detail, "projection updated")
}

///|
test "visual projection feed summary has explicit empty fallback" {
  assert_eq(
    visual_projection_feed_summary(test_visual_projection_snapshot()),
    "No visual projection messages in this tick.",
  )
}

///|
test "visual projection feed summary joins tick messages" {
  assert_eq(
    visual_projection_feed_summary(
      test_visual_projection_snapshot(messages=["agent moved", "book updated"]),
    ),
    "agent moved book updated",
  )
}

///|
test "visual projection feed item centralizes title detail and tone" {
  let item = visual_projection_feed_item(
    test_visual_projection_snapshot(tick=42, messages=["worker entered hall"]),
  )
  assert_eq(item.title, "Visual projection tick 42")
  assert_eq(item.detail, "worker entered hall")
  assert_eq(item.tone, "calm")
}

///|
test "feed item class centralizes tone styling" {
  assert_eq(
    feed_item_class({ title: "Alert", detail: "Needs action", tone: "alert" }),
    "feed-item message-bubble tone-alert",
  )
}

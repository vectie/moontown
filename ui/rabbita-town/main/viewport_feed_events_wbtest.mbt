///|
fn feed_event_test_event(kind : String, detail : String) -> @core.TownEvent {
  @core.TownEvent::new(
    id="event-\{kind}",
    kind~,
    detail~,
    related_book_id=Some("research-opc"),
  )
}

///|
test "feed event kind classifies known and unknown event kinds" {
  assert_true(feed_event_kind("standing-watch") is StandingWatch)
  assert_true(feed_event_kind("standing-goal") is StandingGoal)
  assert_true(feed_event_kind("execution") is Execution)
  assert_true(feed_event_kind("persist") is Persist)
  assert_true(feed_event_kind("projection") is Projection)
  assert_true(feed_event_kind("summary") is Summary)
  assert_true(feed_event_kind("review") is Review)
  assert_true(feed_event_kind("daemon") is Daemon)
  assert_true(feed_event_kind("supervision") is Supervision)
  assert_true(feed_event_kind("civic-pattern") is CivicPattern)
  assert_true(feed_event_kind("civic-salon") is CivicSalon)
  assert_true(feed_event_kind("internal-debug") is Other)
}

///|
test "feed event kind helpers classify tone groups and daemon events" {
  assert_true(feed_event_kind_is_daemon(feed_event_kind("daemon")))
  assert_true(!feed_event_kind_is_daemon(feed_event_kind("summary")))
  assert_true(feed_event_kind_is_calm(feed_event_kind("persist")))
  assert_true(feed_event_kind_is_calm(feed_event_kind("projection")))
  assert_true(!feed_event_kind_is_calm(feed_event_kind("review")))
  assert_true(feed_event_kind_is_hot(feed_event_kind("review")))
  assert_true(feed_event_kind_is_hot(feed_event_kind("supervision")))
  assert_true(feed_event_kind_is_hot(feed_event_kind("civic-salon")))
  assert_true(!feed_event_kind_is_hot(feed_event_kind("summary")))
}

///|
test "feed event title preserves suffix policy by event kind" {
  assert_eq(
    feed_event_title(feed_event_test_event("standing-watch", "Update")),
    "Mayor watch update / research-opc",
  )
  assert_eq(
    feed_event_title(feed_event_test_event("review", "NeedsReview")),
    "Keeper review needed / research-opc",
  )
  assert_eq(
    feed_event_title(feed_event_test_event("daemon", "heartbeat")),
    "Daemon heartbeat",
  )
  assert_eq(
    feed_event_title(feed_event_test_event("civic-pattern", "round")),
    "Civic pattern round",
  )
  assert_eq(
    feed_event_title(feed_event_test_event("unknown-kind", "message")),
    "Town message / research-opc",
  )
}

///|
test "feed event tone prioritizes alert details" {
  assert_eq(feed_event_tone(feed_event_test_event("standing-watch", "Failed")), "alert")
  assert_eq(
    feed_event_tone(feed_event_test_event("standing-watch", "worker failed")),
    "alert",
  )
  assert_eq(
    feed_event_tone(feed_event_test_event("projection", "not-ready")),
    "alert",
  )
}

///|
test "feed event tone classifies calm hot and neutral events" {
  assert_eq(
    feed_event_tone(feed_event_test_event("standing-watch", "NoChange")),
    "calm",
  )
  assert_eq(feed_event_tone(feed_event_test_event("persist", "saved")), "calm")
  assert_eq(feed_event_tone(feed_event_test_event("projection", "built")), "calm")
  assert_eq(feed_event_tone(feed_event_test_event("review", "needs review")), "hot")
  assert_eq(
    feed_event_tone(feed_event_test_event("supervision", "mayor check")),
    "hot",
  )
  assert_eq(
    feed_event_tone(feed_event_test_event("civic-pattern", "round")),
    "hot",
  )
  assert_eq(feed_event_tone(feed_event_test_event("summary", "healthy")), "neutral")
}

///|
test "feed event visibility accepts known feed kinds only" {
  assert_true(feed_event_visible(feed_event_test_event("standing-watch", "Update")))
  assert_true(feed_event_visible(feed_event_test_event("daemon", "heartbeat")))
  assert_true(feed_event_visible(feed_event_test_event("civic-salon", "round")))
  assert_true(!feed_event_visible(feed_event_test_event("internal-debug", "hidden")))
}

///|
test "feed item for event projects visible events and skips hidden events" {
  let item = feed_item_for_event(feed_event_test_event("standing-watch", "NoChange"))
  assert_true(
    item is Some({
      title: "Mayor watch update / research-opc",
      detail: "NoChange",
      tone: "calm",
    }),
  )
  assert_true(feed_item_for_event(feed_event_test_event("internal-debug", "hidden")) is None)
}

///|
test "recent event feed policy owns limit and daemon dedupe" {
  assert_eq(recent_event_feed_limit, 6)
  assert_true(!recent_event_limit_reached(5))
  assert_true(recent_event_limit_reached(6))
  assert_true(
    recent_event_should_skip(feed_event_kind("daemon"), daemon_pushed=true),
  )
  assert_true(
    !recent_event_should_skip(feed_event_kind("daemon"), daemon_pushed=false),
  )
  assert_true(
    !recent_event_should_skip(feed_event_kind("summary"), daemon_pushed=true),
  )
}

///|
fn recent_event_projection_test_events() -> Array[@core.TownEvent] {
  [
    feed_event_test_event("standing-watch", "oldest"),
    feed_event_test_event("daemon", "old daemon"),
    feed_event_test_event("internal-debug", "hidden"),
    feed_event_test_event("projection", "projection built"),
    feed_event_test_event("daemon", "new daemon"),
    feed_event_test_event("review", "review now"),
    feed_event_test_event("summary", "summary now"),
    feed_event_test_event("persist", "persist now"),
    feed_event_test_event("execution", "execution now"),
  ]
}

///|
test "recent event feed items keeps newest visible events and dedupes daemon" {
  let feed = recent_event_feed_items(recent_event_projection_test_events())
  assert_eq(feed.length(), 6)
  assert_eq(feed[0].title, "Worker run changed / research-opc")
  assert_eq(feed[1].title, "Bookkeeper saved memory / research-opc")
  assert_eq(feed[2].title, "Book health summary / research-opc")
  assert_eq(feed[3].title, "Keeper review needed / research-opc")
  assert_eq(feed[4].title, "Daemon heartbeat")
  assert_eq(feed[4].detail, "new daemon")
  assert_eq(feed[5].title, "Website projection refreshed / research-opc")
}

///|
test "push recent event messages delegates to event feed projection" {
  let feed : Array[FeedItem] = [
    { title: "Existing", detail: "base", tone: "calm" },
  ]
  push_recent_event_messages(feed, recent_event_projection_test_events())
  assert_eq(feed.length(), 7)
  assert_eq(feed[0].title, "Existing")
  assert_eq(feed[1].title, "Worker run changed / research-opc")
  assert_eq(feed[6].title, "Website projection refreshed / research-opc")
}

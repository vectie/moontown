///|
test "desktop projection resolves runtime books onto Energy Valley buildings" {
  assert_eq(building_module_key("research-opc"), "research-opc")
  assert_eq(
    building_module_key("research-how-llms-are-trained-in-very-detail"),
    "research-llm-training",
  )
  assert_eq(
    building_module_key("research-agent-work-projection"),
    "research-ai-agents",
  )
  assert_eq(building_module_key("coding"), "ai-garden")
  assert_eq(building_module_key("finance"), "valley-market")
  assert_eq(building_module_key("wenyu-policy-hall"), "policy-hall")
  assert_eq(building_module_key("wenyu-broadcast-tower"), "story-radar")
  assert_eq(building_module_key("wenyu-physical-bridge"), "town-shell")
}

///|
test "desktop projection treats uncertain watcher outcomes conservatively" {
  assert_eq(
    watcher_task_status({ "decision": "NeedsReview" }),
    Some("waiting_review"),
  )
  assert_eq(watcher_task_status({ "decision": "Deferred" }), Some("blocked"))
  assert_eq(
    watcher_task_status({ "decision": "unexpected-value" }),
    Some("blocked"),
  )
  assert_eq(watcher_task_status(Map([])), None)
}

///|
test "desktop projection reads detailed watcher progress markers" {
  let watcher : Map[String, Json] = {
    "new_source_count": 8,
    "detail": "checked_sources_count: 9\naccepted_facts_count: 4\nrejected_facts_count: 2\nwiki_pages_changed_count: 7\nbook_changed: yes",
  }
  assert_eq(watcher_non_negative_int(watcher, "new_source_count"), Some(8))
  assert_eq(watcher_non_negative_int(watcher, "checked_sources_count"), Some(9))
  assert_eq(watcher_non_negative_int(watcher, "accepted_facts_count"), Some(4))
  assert_eq(watcher_non_negative_int(watcher, "rejected_facts_count"), Some(2))
  assert_eq(
    watcher_non_negative_int(watcher, "wiki_pages_changed_count"),
    Some(7),
  )
  assert_eq(watcher_detail_value(watcher, "book_changed"), Some("yes"))
}

///|
test "desktop collaboration does not mislabel pending work as running" {
  assert_eq(collaboration_participant_status("Running"), "running")
  assert_eq(collaboration_participant_status("Queued"), "queued")
  assert_eq(collaboration_participant_status("Pending"), "assigned")
  assert_eq(collaboration_participant_status("Succeeded"), "completed")
  assert_eq(collaboration_participant_status("unrecognized"), "unknown")
}

///|
test "desktop server exposes every Rabbita runtime snapshot path" {
  for
    path in [
      "/town.json", "/visual-projection.json", "/module-projections.json", "/moondesk-bridge.json",
      "/civic-status.json", "/daemon.json", "/live-autonomy.json", "/editor-pipeline.json",
      "/standing-goals.json", "/book-template-requests.json",
    ] {
    assert_true(runtime_snapshot_source(path) is Some(_), msg=path)
  }
  assert_true(runtime_snapshot_source("/not-a-runtime-file.json") is None)
}

///|
test "desktop book-template request accepts newline and comma website lists" {
  let newline : Map[String, Json] = {
    "websites": "https://example.org/a\nhttps://example.org/b",
  }
  assert_eq(json_string_list_field(newline, "websites").length(), 2)
  let comma : Map[String, Json] = {
    "websites": "https://example.org/a, https://example.org/b",
  }
  assert_eq(json_string_list_field(comma, "websites").length(), 2)
}

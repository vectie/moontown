///|
async test "desktop operator policy uses the source-tree template in development" {
  assert_eq(
    resolved_operator_policy_path(None, None),
    "assets/templates/operator-request-policy.json",
  )
  let policy_text = @support.read_text_or_empty(
    resolved_operator_policy_path(None, None),
  )
  guard @json.parse(policy_text) is Object(fields) else {
    fail("expected the development operator policy to be a JSON object")
  }
  assert_eq(
    @support.json_object_string(fields, "standing_goal_source_policy"),
    Some("web-first"),
  )
}

///|
async test "development policy accepts a long multilingual standing watch" {
  let prompt_builder = StringBuilder::new()
  for _ in 0..<300 {
    prompt_builder.write_string(
      "能源谷居民协作研究：核验代理、任务、运行编号与证据链。",
    )
  }
  let prompt = prompt_builder.to_string()
  let state_root = "/tmp/moontown-desktop-policy-{@env.now()}"
  let application = @town_application.request_application(
    state_root,
    resolved_operator_policy_path(None, None),
  )
  let request : Json = {
    "title": "能源谷 UI 协作研究",
    "prompt": prompt,
    "target_book_id": "research-agent-work-projection",
    "cadence_ticks": "1000000",
    "quality_threshold": "85",
  }
  let result = application.submit_standing_watch(request.stringify())
  assert_eq(@support.json_string_field(result, "status"), Some("accepted"))
  let goals = @support.read_optional_json_file(
    state_root + "/standing-goals.json",
  )
  guard goals is Some(Array([Object(goal), ..])) else {
    fail("expected the multilingual standing watch to persist")
  }
  assert_eq(@support.json_object_string(goal, "prompt"), Some(prompt))
}

///|
test "desktop operator policy uses the bundled resource in a packaged app" {
  assert_eq(
    resolved_operator_policy_path(
      None,
      Some("/Applications/MoonTown/Resources"),
    ),
    "/Applications/MoonTown/Resources/operator-policy.json",
  )
}

///|
test "desktop operator policy honors an explicit override in every mode" {
  assert_eq(
    resolved_operator_policy_path(
      Some("/srv/moontown/operator-policy.json"),
      Some("/Applications/MoonTown/Resources"),
    ),
    "/srv/moontown/operator-policy.json",
  )
}

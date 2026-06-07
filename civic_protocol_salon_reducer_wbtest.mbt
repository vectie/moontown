///|
async test "MoonClaw reducer workspace excludes template seed ideas" {
  let root = cleaned_civic_protocol_test_root(
    "/tmp/moontown-civic-salon-reducer-input",
  )
  let scenario = test_civic_salon_scenario()
  write_civic_salon_reducer_workspace(
    scenario, root, "future-energy-round-2", 2,
  )
  let input = @fs.read_file(
    "\{root}/raw/bootstrap/civic-salon-reducer-input.md",
  ).text()
  let participants = @fs.read_file(
    "\{root}/raw/bootstrap/civic-salon-participants.json",
  ).text()
  let skill = @fs.read_file("\{root}/skills/future-energy-salon/SKILL.md").text()
  assert_true(!input.contains("storage-grid-control-contract"))
  assert_true(!participants.contains("storage-grid-control-contract"))
  assert_true(skill.contains("CivicSalonIdea"))
  assert_true(@fs.exists("\{root}/moonclaw.jobs.json"))
}

///|
async test "civic salon reducer profile preserves existing civic service worker profile" {
  let root = cleaned_civic_protocol_test_root(
    "/tmp/moontown-civic-salon-profile-merge",
  )
  write_text_file(
    "\{root}/moonclaw.jobs.json",
    "{ \"jobs\": { \"profiles\": { \"wenyu_civic_service_worker\": { \"family\": \"wenyu_civic_service_worker\", \"steps\": [{\"id\":\"execute_civic_service\"},{\"id\":\"review_civic_service\"}] } } } }",
  )
  write_civic_salon_reducer_workspace(
    test_civic_salon_scenario(),
    root,
    "future-energy-round-3",
    3,
  )
  let merged = @fs.read_file("\{root}/moonclaw.jobs.json").text()
  assert_true(merged.contains("\"wenyu_civic_service_worker\""))
  assert_true(merged.contains("\"execute_civic_service\""))
  assert_true(merged.contains("\"review_civic_service\""))
  assert_true(merged.contains("\"civic_salon_reducer_worker\""))
  assert_true(merged.contains("\"reduce_civic_pattern_outputs\""))
}

///|
async test "civic salon reducer parses object ideas contract" {
  let root = cleaned_civic_protocol_test_root(
    "/tmp/moontown-civic-salon-reducer-contract",
  )
  let scenario = test_civic_salon_scenario()
  let path = civic_salon_reducer_output_path_in_workspace(root)
  write_text_file(
    path,
    Json::object({ "ideas": scenario.ideas.to_json() }).stringify(indent=2),
  )
  match load_civic_salon_ideas_file(path) {
    Some(ideas) => {
      assert_eq(ideas.length(), 1)
      assert_eq(ideas.get(0).unwrap().id, "storage-grid-control-contract")
    }
    None => fail("expected reducer ideas JSON")
  }
  assert_eq(
    civic_salon_reducer_output_path(scenario, "/tmp/moontown"),
    "/tmp/moontown/books/wenyu-social-square/raw/bootstrap/civic-salon-ideas.json",
  )
}

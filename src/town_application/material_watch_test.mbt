///|
async fn setup_fixture() -> (String, @town_application.RequestApplication) {
  let root = @fs.tmpdir(prefix="town-material-setup-")
  let entry = @moonbook.BookCatalogEntry::new(
    id="research-material",
    name="Material",
    purpose="Changes",
    workspace_root=root + "/book",
  )
  @support.write_text_file(root + "/book/sources/customer.txt", "October\n")
  @support.write_text_file(root + "/book/sources/market.txt", "Steady\n")
  @moonbook.save_catalog_file(root + "/moonbooks.json", [entry])
  @support.write_text_file(
    root + "/operator-policy.json",
    "{\"standing_goal_source_policy\":\"web-first\"}",
  )
  (
    root,
    @town_application.request_application(root, root + "/operator-policy.json"),
  )
}

///|
fn setup_body(
  sources? : Json = "sources/customer.txt\nsources/market.txt",
  book? : String = "research-material",
  goal? : String = "",
) -> String {
  let body : Json = {
    "watch_mode": "local-material",
    "title": "Customer assumption",
    "prompt": "Keep launch current",
    "target_book_id": book,
    "cadence_ticks": "10",
    "quality_threshold": "85",
    "goal_id": goal,
    "material_sources": sources,
    "material_acceptance": "Show exact changed source",
    "material_next_action": "Founder reviews the date",
  }
  body.stringify()
}

///|
async test "material setup rejects invalid unavailable duplicate escaped and binary sources without enabling a goal" {
  let (root, app) = setup_fixture()
  @fs.write_file(
    root + "/book/sources/binary.bin",
    b"\xff\xfe",
    create_mode=CreateOrTruncate,
  )
  @support.write_text_file(root + "/outside.txt", "outside")
  @fs.symlink(target=root + "/outside.txt", root + "/book/sources/escape.txt")
  let bad : Array[Json] = [
    "../outside.txt",
    "/etc/hosts",
    "sources/missing.txt",
    "sources/binary.bin",
    "sources/escape.txt",
    "sources/customer.txt\nsources/customer.txt",
    [("sources/customer.txt" : Json), (4 : Json)].to_json(),
  ]
  for source in bad {
    try app.submit_standing_watch(setup_body(sources=source)) catch {
      _ => ()
    } noraise {
      _ => fail("Invalid material source accepted")
    }
    assert_true(!@fs.exists(root + "/standing-goals.json"))
    assert_true(!@fs.exists(root + "/operator-requests/requests.jsonl"))
  }
  try app.submit_standing_watch(setup_body(book="missing-book")) catch {
    _ => ()
  } noraise {
    _ => fail("Unknown Book accepted")
  }
  assert_true(!@fs.exists(root + "/standing-goals.json"))
}

///|
async test "material setup same request is idempotent across restart and preserves source filenames" {
  let (root, app) = setup_fixture()
  @support.write_text_file(
    root + "/book/sources/customer,notes.txt",
    "Comma filename",
  )
  let body = setup_body(sources="sources/customer,notes.txt")
  let first = app.submit_standing_watch(body)
  let second = @town_application.request_application(
    root,
    root + "/operator-policy.json",
  ).submit_standing_watch(body)
  assert_eq(first, second)
  assert_eq(
    @storage.load_standing_goals_file(root + "/standing-goals.json")
    .unwrap()
    .length(),
    1,
  )
  assert_eq(
    @support.read_text_or_empty(root + "/operator-requests/requests.jsonl")
    .split("\n")
    .filter(line => !line.is_empty())
    .length(),
    1,
  )
  let id = @support.json_string_field(first, "request_id").unwrap()
  let request = @support.read_optional_json_file(
    root + "/operator-requests/" + id + ".json",
  ).unwrap()
  guard request is Object(fields) &&
    fields.get("material_watch") is Some(Object(material)) else {
    fail("Missing saved readback")
  }
  assert_eq(
    material.get("sources"),
    Some((["sources/customer,notes.txt"] : Array[String]).to_json()),
  )
  assert_eq(
    material.get("baseline_status"),
    Some(("pending_first_check" : Json)),
  )
}

///|
async test "material setup plan write failure never publishes a goal and can be retried" {
  let (root, app) = setup_fixture()
  @support.write_text_file(root + "/book/.moontown", "occupied file")
  try app.submit_standing_watch(setup_body()) catch {
    _ => ()
  } noraise {
    _ => fail("Expected plan-directory failure")
  }
  assert_true(!@fs.exists(root + "/standing-goals.json"))
  assert_true(!@fs.exists(root + "/operator-requests/requests.jsonl"))
  @fs.remove(root + "/book/.moontown")
  assert_eq(
    @support.json_string_field(
      app.submit_standing_watch(setup_body()),
      "status",
    ),
    Some("accepted"),
  )
}

///|
async test "material setup receipt failure repairs identical durable goal after restart" {
  let (root, app) = setup_fixture()
  @fs.mkdir(root + "/operator-requests", recursive=true)
  @fs.mkdir(root + "/operator-requests/requests.jsonl")
  let body = setup_body()
  try app.submit_standing_watch(body) catch {
    _ => ()
  } noraise {
    _ => fail("Expected ledger failure")
  }
  let saved = @storage.load_standing_goals_file(root + "/standing-goals.json").unwrap()
  assert_eq(saved.length(), 1)
  @fs.rmdir(root + "/operator-requests/requests.jsonl")
  let recovered = @town_application.request_application(
    root,
    root + "/operator-policy.json",
  ).submit_standing_watch(body)
  assert_eq(@support.json_string_field(recovered, "status"), Some("accepted"))
  assert_eq(
    @storage.load_standing_goals_file(root + "/standing-goals.json").unwrap(),
    saved,
  )
  assert_eq(
    @support.read_text_or_empty(root + "/operator-requests/requests.jsonl")
    .split("\n")
    .filter(line => !line.is_empty())
    .length(),
    1,
  )
}

///|
async test "material setup conflicts retain prior plan and legacy cadence still uses operator policy" {
  let (root, app) = setup_fixture()
  ignore(app.submit_standing_watch(setup_body(goal="watch-explicit")))
  let goals_before = @fs.read_file(root + "/standing-goals.json").text()
  try
    app.submit_standing_watch(
      setup_body(sources="sources/customer.txt", goal="watch-explicit"),
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("Conflicting saved plan overwritten")
  }
  assert_eq(@fs.read_file(root + "/standing-goals.json").text(), goals_before)
  let legacy : Json = {
    "title": "Ordinary",
    "prompt": "Web check",
    "target_book_id": "Research Legacy",
    "cadence_ticks": "17",
    "quality_threshold": "91",
  }
  ignore(app.submit_standing_watch(legacy.stringify()))
  let goals = @storage.load_standing_goals_file(root + "/standing-goals.json").unwrap()
  assert_eq(goals.length(), 2)
  assert_eq(goals[1].source_policy, "web-first")
  assert_eq(goals[1].target_book_id, Some("research-legacy"))
  assert_eq(goals[1].cadence_ticks, 17)
}

///|
async test "material setup concurrent repeated saves retain one watch beside an ordinary cadence save" {
  let (root, app) = setup_fixture()
  let responses : Array[Json] = []
  let legacy : Json = {
    "title": "Ordinary",
    "prompt": "Web check",
    "goal_id": "ordinary-watch",
  }
  @async.with_task_group(group => {
    for _ in 0..<3 {
      group.spawn_bg(() => {
        responses.push(app.submit_standing_watch(setup_body()))
      })
    }
    group.spawn_bg(() => ignore(app.submit_standing_watch(legacy.stringify())))
  })
  assert_eq(responses.length(), 3)
  assert_eq(responses[0], responses[1])
  assert_eq(responses[1], responses[2])
  let goals = @storage.load_standing_goals_file(root + "/standing-goals.json").unwrap()
  assert_eq(goals.length(), 2)
  assert_eq(
    goals
    .filter(goal => goal.source_policy.has_prefix("local-material:"))
    .length(),
    1,
  )
  assert_eq(goals.filter(goal => goal.source_policy == "web-first").length(), 1)
  assert_eq(
    @support.read_text_or_empty(root + "/operator-requests/requests.jsonl")
    .split("\n")
    .filter(line => !line.is_empty())
    .length(),
    2,
  )
}

///|
async test "material setup requires explicit known mode and complete plan fields" {
  let (root, app) = setup_fixture()
  for
    body in [
      "{\"watch_mode\":\"local-material\",\"title\":\"Incomplete\",\"prompt\":\"Intent\",\"target_book_id\":\"research-material\"}",
      "{\"watch_mode\":\"material\",\"title\":\"Typo\",\"prompt\":\"Intent\"}", "{\"watch_mode\":true,\"title\":\"Malformed\",\"prompt\":\"Intent\"}",
    ] {
    try app.submit_standing_watch(body) catch {
      _ => ()
    } noraise {
      _ => fail("Unknown or incomplete material mode accepted")
    }
  }
  assert_true(!@fs.exists(root + "/standing-goals.json"))
  assert_true(!@fs.exists(root + "/operator-requests/requests.jsonl"))
}

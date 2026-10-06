///|
async fn native_work_api_fixture(name : String) -> (String, @native_work.Work) {
  let root = "/tmp/town-work-api-" + name + "-" + @env.now().to_string()
  @fs.mkdir(root, recursive=true)
  let prompt = "private native prompt never projected"
  let request : @native_work.Request = {
    kind: "planbook_repair",
    work_key: "api-fixture:" + name,
    generation: 0,
    owner_workspace: root + "/private-owner",
    book_id: "book-visible",
    book_root: root + "/private-book",
    book_type: "planbook",
    catalog_path: root + "/private-catalog.json",
    execution_root: root + "/private-source",
    source_binding: { "private": "baseline" },
    criterion_id: "criterion-visible",
    model_request: "private-model",
    prompt,
    input_blocker: "",
    input_digest: @native_work.digest(prompt),
    output_contract: "planbook.repair.native_patch_receipt.v1",
    result_path: root + "/must-not-apply.md",
    acceptance_policy: Json::null(),
    created_at_ms: 1UL,
  }
  let path = root + "/state.json"
  (path, @native_work.enqueue(request, path~))
}

///|
test "native work HTTP accepts only fixed work identities and exact revision bodies" {
  let id = "town-work-0123456789abcdef0123456789abcdef"
  assert_eq(native_work_api_route("/api/native-work"), Some(("", "list")))
  assert_eq(native_work_api_route("/api/native-work/" + id), Some((id, "show")))
  for action in ["refresh", "cancel", "sync"] {
    assert_eq(
      native_work_api_route("/api/native-work/" + id + "/" + action),
      Some((id, action)),
    )
  }
  for
    path in [
      "/api/native-work/../cancel",
      "/api/native-work/%2e%2e/cancel",
      "/api/native-work/" + id + "/pause",
      "/api/native-work/" + id + "/cancel/extra",
    ] {
    assert_eq(native_work_api_route(path), None)
  }
  assert_eq(native_work_api_revision("{\"expected_revision\":0}"), 0)
  for
    text in [
      "{}", "[]", "not json", "{\"expected_revision\":-1}", "{\"expected_revision\":1.5}",
      "{\"expected_revision\":2147483648}", "{\"expected_revision\":\"1\"}", "{\"expected_revision\":1,\"book_root\":\"/other\"}",
    ] {
    try native_work_api_revision(text) catch {
      error => assert_eq(native_work_api_error("\{error}").0, 400)
    } noraise {
      _ => fail("invalid revision body accepted: " + text)
    }
  }
  try native_work_api_revision(" ".repeat(4097)) catch {
    error => assert_eq(native_work_api_error("\{error}").0, 413)
  } noraise {
    _ => fail("oversize body accepted")
  }
}

///|
async test "native work saved list and detail preserve output without state mutation or private owner data" {
  let (path, work) = native_work_api_fixture("saved")
  let state = @native_work.load(path~)
  let updated = {
    ..work,
    state: "completed",
    output: "Native output remains intact",
    receipt: {
      "engineering_status": "applied_and_validated",
      "private_receipt": true,
    },
  }
  @fs.write_file(path, { ..state, work: [updated], }.to_json().stringify())
  let before = @fs.read_file(path).text()
  let list = native_work_api_read("", path~)
  let detail = native_work_api_read(work.id, path~)
  assert_eq(@fs.read_file(path).text(), before)
  assert_false(@fs.exists(work.request.result_path))
  for result in [list, detail] {
    let text = result.stringify()
    assert_true(text.contains("moontown.native-work.status.v1"))
    assert_true(text.contains("Native output remains intact"))
    assert_true(text.contains("applied_and_validated"))
    assert_false(text.contains("private native prompt"))
    assert_false(text.contains("private-owner"))
    assert_false(text.contains("private-source"))
    assert_false(text.contains("private-catalog"))
    assert_false(text.contains("private_receipt"))
    assert_false(text.contains("acceptance_policy"))
  }
  try
    native_work_api_read("town-work-00000000000000000000000000000000", path~)
  catch {
    error => assert_eq(native_work_api_error("\{error}").0, 404)
  } noraise {
    _ => fail("missing work found")
  }
}

///|
async test "native work HTTP cancellation persists once and rejects stale duplicate revision" {
  let (path, work) = native_work_api_fixture("cancel")
  let result = native_work_api_action(
    work.id,
    "cancel",
    "{\"expected_revision\":1}",
    20UL,
    path~,
  )
  guard result
    is { "revision": Number(revision, ..), "items": Array(items), .. } else {
    fail("missing coherent list")
  }
  assert_eq(revision, 2.0)
  assert_eq(items.length(), 1)
  assert_true(items[0] is { "state": String("cancelled"), .. })
  let before = @fs.read_file(path).text()
  for action in ["cancel", "refresh", "sync"] {
    try
      native_work_api_action(
        work.id,
        action,
        "{\"expected_revision\":1}",
        30UL,
        path~,
      )
    catch {
      error => assert_eq(native_work_api_error("\{error}").0, 409)
    } noraise {
      _ => fail("stale action accepted: " + action)
    }
    assert_eq(@fs.read_file(path).text(), before)
  }
  let replay = native_work_api_action(
    work.id,
    "cancel",
    "{\"expected_revision\":2}",
    40UL,
    path~,
  )
  assert_eq(replay, result)
  assert_eq(@fs.read_file(path).text(), before)
}

///|
async test "native work explicit refresh does not dispatch unreserved work" {
  let (path, work) = native_work_api_fixture("refresh")
  let before = @fs.read_file(path).text()
  ignore(
    native_work_api_action(
      work.id,
      "refresh",
      "{\"expected_revision\":1}",
      20UL,
      path~,
    ),
  )
  assert_eq(@fs.read_file(path).text(), before)
  assert_true(@native_work.load(path~).work[0].reservation is None)
}

///|
test "native work errors do not expose private failed control configuration" {
  let response = native_work_api_error(
    "private /owner/control/moonclaw.json token=fixture-token",
  )
  assert_eq(response.0, 503)
  assert_false(response.1.contains("fixture-token"))
  assert_false(response.1.contains("/owner/control"))
}

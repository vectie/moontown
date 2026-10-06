///|
/// A retained, already-committed synthetic repository. These are its exact
/// source/index/ref/object bytes; tests neither initialize nor commit history.
fn wenyu_retained_fixture_manifest() -> Array[(String, String)] {
  [
    (
      "moon.mod", "9dfc68c074c71227405e979fd4116c1559e809ff569a6625cf6b6b5864f31dd1",
    ),
    (
      "source.mbt", "9160d4be34c8695bd172a76c7c7966587ea5a4d991ad22c87b2b91af54aa9ebb",
    ),
    (
      "notes.txt", "a5043fcdf99dda638f5568737abe8e836922c6dd627feb3d7ce6d8d3649dae90",
    ),
    (
      ".git/HEAD", "f6f2b945f6c411b02ba3da9c7ace88dcf71b6af65ba2e0d89aa82900042b5a10",
    ),
    (
      ".git/index", "4c30968bbbcb7e580d94132cc2768ad1751551998318057c81bb7989d301ffc7",
    ),
    (
      ".git/config", "cfe7ba1238c9a78be7535d7c63bcaf5a4d5011d46b07c9b45d3bbf7d6c312dfe",
    ),
    (
      ".git/refs/heads/master", "7939fbeee137618175725f6c9d6b94f39f24647f18f7e537e8632204d3457ffd",
    ),
    (
      ".git/objects/fd/d650708bb049dd21f1b76725287dcbf9e42af4", "0906d0a54b1ce835eba7e9227c303e36f4a1e50a6f39592e250051c592658d6a",
    ),
    (
      ".git/objects/42/dea4cb1e38bc251b5a0079fb3f573c1284c0cc", "fd73ed77ae71fb77539452876214fc4340913bd982a0967a14a2532630acf000",
    ),
    (
      ".git/objects/90/be1f3056c4f471f977a28497b8d4b392c55a02", "7e2d860937eae1d919e00466505b42928c76d8d57c9847a2bef720203d99f81e",
    ),
    (
      ".git/objects/9d/8dc807d091a77c7bb23ebabe5c9c60ecc7b388", "95585323d6a06fc17d85b8e2c15203088326da8f59bfe17d2a1df12aa2e5f21e",
    ),
    (
      ".git/objects/6e/ef98d89e215127f2be8807ec168e9a59175945", "bae2ee89aae6a2c1f82ebc921b675b354413d8ee43a6dddc8c4cb5ab97b40c5c",
    ),
  ]
}

///|
async fn wenyu_copy_retained_fixture(
  from : String,
  destination : String,
) -> Unit {
  for (relative, expected) in wenyu_retained_fixture_manifest() {
    let bytes = @fs.read_file(from + "/" + relative).binary()
    assert_eq(
      @crypto.bytes_to_hex_string(@crypto.sha256(bytes)),
      expected,
      msg=relative,
    )
    let target = destination + "/" + relative
    @support.ensure_parent_directory(target)
    @fs.write_file(target, bytes, create_mode=CreateNew)
    assert_eq(@fs.read_file(target).binary(), bytes, msg=relative)
  }
}

///|
/// The transport and journal are explicitly injected. Only source bytes,
/// Git's bounded whitespace check, focused diff, and owner reconciliation are
/// real; this test does not claim compiler or live-provider execution.
async test "wenyu actual source mutation and bounded Git check reconcile through injected native sync" {
  let root = @fs.realpath(@fsx.mkdtemp("/tmp/town-wenyu-real-source-XXXXXX"))
  let retained = root + "/retained-baseline"
  wenyu_materialize_retained_fixture(retained)
  let request = wenyu_fixture_request(root~)
  @fs.mkdir(request.owner_workspace)
  @fs.mkdir(request.book_root)
  wenyu_copy_retained_fixture(retained, request.execution_root)
  @moonbook.save_catalog_file(request.catalog_path, [
    @moonbook.BookCatalogEntry::new(
      id=request.book_id,
      name="Wenyu",
      purpose="Synthetic real-source regression",
      workspace_root=request.book_root,
    ),
  ])
  let command = "git diff --check --no-ext-diff --no-textconv"
  no_change_set(
    request.acceptance_policy,
    "required_validation_commands",
    [command].to_json(),
  )
  let request = {
    ..request,
    source_binding: source_binding(Some(request.execution_root)).unwrap(),
  }
  let path = root + "/state.json"
  let queued = enqueue(request, path~)
  let posted : Array[String] = []
  let terminal_receipts : Array[Json] = []
  let journal : Array[Json] = []
  let client = fixture_client(request, async fn(method, route, body) {
    if route == "/v1/code/capabilities" {
      return Ok({ "model_workspace_contract": "mooncode.model-workspace.v1" })
    }
    if route == "/v1/moongate-route" {
      return Ok({
        "contract": "moonclaw.moongate-route.v1",
        "ready": true,
        "default_model": "moongate/fixture",
        "models": [{ "name": "moongate/fixture" }],
      })
    }
    if method == "POST" {
      posted.push(body)
      let reserved = @json.parse(body)
      return Ok({
        "accepted": true,
        "session_id": text(reserved, "session_id"),
        "command_id": text(field(reserved, "packet"), "command_id"),
        "book_root": request.execution_root,
      })
    }
    if posted.is_empty() {
      return Err("native_not_found")
    }
    let reserved = @json.parse(posted[0])
    let projection : Json = {
      "protocol": "mooncode.v1",
      "owner": "moonclaw",
      "session_id": text(reserved, "session_id"),
      "book_root": request.execution_root,
    }
    if route.contains("runtime-claim") {
      let delivered : Json = [
        {
          "command_id": text(field(reserved, "packet"), "command_id"),
          "command": reserved,
          "receipt": terminal_receipts[0],
        },
      ]
      no_change_set(projection, "delivered_commands", delivered)
    } else if route.contains("runtime-events") {
      no_change_set(projection, "events", journal.to_json())
      no_change_set(projection, "event_count", journal.length().to_json())
    }
    Ok(projection)
  })
  let running = sync(queued.id, 2UL, path~, client~)
  assert_eq(running.state, "running")
  assert_eq(
    text(running.baseline, "head"),
    "fdd650708bb049dd21f1b76725287dcbf9e42af4",
  )
  let before_index = @fs.read_file(request.execution_root + "/.git/index").binary()
  let code = "///|\npub fn fixture_answer() -> Int {\n  42\n}\n"
  @support.write_text_file(request.execution_root + "/source.mbt", code)
  let check = @integration.run("git", [
    "-C",
    request.execution_root,
    "diff",
    "--check",
    "--no-ext-diff",
    "--no-textconv",
  ])
  assert_eq(check.status, 0)
  journal.push(
    fixture_event(running, "write-1", "write", {
      "path": "source.mbt",
      "changed": true,
      "before_fingerprint": native_fingerprint(b"before\n"),
      "after_fingerprint": native_fingerprint(@utf8.encode(code)),
    }),
  )
  journal.push(
    fixture_event(
      running,
      "check-2",
      "shell",
      {
        "cmd": command,
        "cwd": ".",
        "exit_code": check.status,
        "run_id": "synthetic-check-run",
        "approval_id": "synthetic-check-approval",
        "execution_sandbox_policy": "grant-bound",
        "sandbox_evidence": {
          "command_digest": digest(command),
          "cleanup_verified": true,
          "fixture_injected": true,
          "actual_stdout": check.stdout,
        },
      },
      sequence="2",
    ),
  )
  let answer = wenyu_fixture_answer(running).stringify()
  let receipt = fixture_receipt(running, answer~)
  no_change_set(receipt, "protocol", "mooncode.v1".to_json())
  no_change_set(receipt, "command", @json.parse(posted[0]))
  terminal_receipts.push(receipt)
  let completed = sync(queued.id, 40000UL, path~, client~)
  assert_eq(completed.state, "completed")
  assert_eq(completed.output, answer)
  assert_eq(
    text(completed.receipt, "contract"),
    "wenyu.build.native_patch_receipt.v1",
  )
  assert_true(
    text(completed.receipt, "focused_diff").contains(
      "+pub fn fixture_answer() -> Int {",
    ),
  )
  assert_eq(
    text(rows(completed.receipt, "validation_commands")[0], "command"),
    command,
  )
  assert_eq(
    text(completed.receipt, "checked_source_digest"),
    text(source_snapshot(request.execution_root), "source_digest"),
  )
  assert_eq(@fs.read_file(request.execution_root + "/source.mbt").text(), code)
  assert_eq(
    @fs.read_file(request.execution_root + "/notes.txt").text(),
    "original notes\n",
  )
  assert_eq(
    @fs.read_file(request.execution_root + "/.git/index").binary(),
    before_index,
  )
  assert_eq(
    text(source_snapshot(request.execution_root), "head"),
    text(running.baseline, "head"),
  )
  assert_eq(@fs.readdir(request.book_root).length(), 0)
  assert_eq(posted.length(), 1)
  assert_eq(sync(queued.id, 80000UL, path~, client~).receipt, completed.receipt)
  assert_eq(posted.length(), 1)
  for (relative, expected) in wenyu_retained_fixture_manifest() {
    assert_eq(
      @crypto.bytes_to_hex_string(
        @crypto.sha256(@fs.read_file(retained + "/" + relative).binary()),
      ),
      expected,
      msg=relative,
    )
  }
}

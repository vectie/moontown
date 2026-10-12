///|
async test "oneoff host Start returns before work finishes and refresh reconciles after lost UI reply" {
  let (store, root, runtime) = oneoff_fixture()
  for id in ["water", "mobility"] {
    @fs.write_file(
      root + "/books/" + id + "/raw/nested/source.bin",
      "SLOW_PARTICIPANT_FIXTURE: exact local " + id + " evidence",
    )
  }
  let saved = store.save(fixture_draft(), "", "2026-10-07T04:00:00Z")
  ignore(store.prepare(saved.draft.draft_id, saved.revision))
  let request : Request = {
    contract_version: "moontown.collaboration.request.v1",
    request_id: "first",
    action: "oneoff-start",
    draft_id: saved.draft.draft_id,
    revision: saved.revision,
    new_draft_id: "",
    artifact_path: "",
    draft: None,
    payload: None,
  }
  let first = store.request_oneoff(
    request,
    Some(runtime),
    None,
    "2026-10-07T04:01:00Z",
    1791330000,
  )
  assert_true(first.ok)
  assert_eq(first.work.unwrap().status, "running")
  // Simulate losing the response and issuing Start again from a reopened UI.
  let duplicate = store.request_oneoff(
    { ..request, request_id: "retry", },
    Some(runtime),
    None,
    "2026-10-07T04:01:01Z",
    1791330001,
  )
  assert_true(duplicate.ok)
  assert_eq(
    duplicate.work.unwrap().participants.map(p => p.run_id),
    first.work.unwrap().participants.map(p => p.run_id),
  )
  let result = @async.with_timeout(5000, () => {
    let mut current = store.read_oneoff(saved.draft.draft_id, saved.revision)
    while current.status == "running" {
      @async.sleep(20)
      current = store.read_oneoff(saved.draft.draft_id, saved.revision)
    }
    current
  })
  assert_eq(result.status, "completed")
  let proposals = @json.parse(
    text_bytes(
      read_bytes(
        store.work_root(saved) +
        "/runtime/.moonsuite/products/moonclaw/jobs/job_proposals.json",
        2097152,
      ),
    ),
  )
  guard proposals is { "proposals": Array(items), .. } else {
    fail("Expected actual producer proposals")
  }
  assert_eq(items.length(), 2)
  for participant in result.participants {
    assert_true(
      items.any(item => {
        item is { "id": String(id), "last_run_id": String(run_id), .. } &&
        id == participant.proposal_id &&
        run_id == participant.run_id
      }),
    )
  }
  assert_true(
    result.participants.all(p => {
      p.output_text.contains("SLOW_PARTICIPANT_FIXTURE")
    }),
  )
  assert_eq(store.read_oneoff(saved.draft.draft_id, saved.revision), result)
  if @env.get_env_var("MOONTOWN_ONEOFF_EVIDENCE") is Some(path) {
    directory(path, true)
    write_bytes(path + "/background-root.txt", @utf8.encode(root))
    write_bytes(
      path + "/background-first.json",
      @utf8.encode(first.to_json().stringify(indent=2)),
    )
    write_bytes(
      path + "/background-completed.json",
      @utf8.encode(result.to_json().stringify(indent=2)),
    )
  }
}

///|
async test "oneoff invalid initial profile blocks before capture and corrected setup retries same question" {
  let (store, root, runtime) = oneoff_fixture()
  let original_profile = read_bytes(
    root + "/runtime/moonclaw.jobs.json",
    1048576,
  )
  @fs.write_file(
    root + "/runtime/moonclaw.jobs.json",
    "{\"jobs\":{\"profiles\":{}}}",
  )
  let saved = store.save(fixture_draft(), "", "2026-10-07T05:00:00Z")
  ignore(store.prepare(saved.draft.draft_id, saved.revision))
  let blocked = try {
    ignore(
      store.start_oneoff(
        saved.draft.draft_id,
        saved.revision,
        runtime,
        background=true,
      ),
    )
    false
  } catch {
    error => {
      assert_true(
        error_message(error).contains("retry the same prepared question"),
      )
      true
    }
  }
  assert_true(blocked)
  assert_false(@fs.exists(store.work_root(saved) + "/intent.json"))
  assert_false(@fs.exists(store.work_root(saved) + "/workspaces"))
  assert_eq(
    store.read_oneoff(saved.draft.draft_id, saved.revision).status,
    "not_started",
  )
  @fs.write_file(root + "/runtime/moonclaw.jobs.json", original_profile)
  let recovered = store.start_oneoff(
    saved.draft.draft_id,
    saved.revision,
    runtime,
  )
  assert_eq(recovered.status, "completed")
  assert_eq(recovered.revision, saved.revision)
}

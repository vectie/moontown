///|
async fn oneoff_fixture() -> (Store, String, OneoffRuntime) {
  guard @env.get_env_var("MOONTOWN_MOONCLAW_BIN") is Some(_) else {
    fail(
      "Run this crossing with the built local Claw oneoff_fixture binary; no real provider is allowed",
    )
  }
  let (store, root) = fixture()
  for id in ["water", "mobility"] {
    @fs.write_file(
      root + "/books/" + id + "/raw/nested/source.bin",
      "Captured " + id + " observation: 水\u0000exact retained source.\n",
    )
  }
  @fs.mkdir(root + "/runtime")
  @fs.write_file(
    root + "/runtime/moonclaw.jobs.json",
    (
      {
        "jobs": {
          "profiles": {
            "town_single": {
              "family": "town_single",
              "steps": [
                {
                  "id": "contribution",
                  "title": "Contribution",
                  "kind": "job.analysis",
                  "prompt_template": "${request}",
                  "metadata": {
                    "enable_tools": false,
                    "web_search": false,
                    "disable_adaptive": true,
                    "retry_max_attempts": 1,
                    "timeout_ms": 1000,
                  },
                },
              ],
            },
          },
        },
      } : Json).stringify(),
    create_mode=CreateNew,
  )
  let runtime : OneoffRuntime = {
    moonclaw_root: root,
    home: root + "/runtime",
    profile: "town_single",
    profile_config_path: None,
  }
  (store, root, runtime)
}

///|
fn decision_payload(
  work : @contract.OneoffWork,
  id : String,
  decision : String,
) -> Json {
  {
    "result_digest": work.result_digest,
    "review_version": work.review_version,
    "decision_id": id,
    "decision": decision,
    "rationale": "Synthetic local reviewer context for boundary verification; not authenticated real-human acceptance.",
  }
}

///|
async test "oneoff production Claw boundary outputs survive retry reopen and named-owner settlement" {
  let (store, root, runtime) = oneoff_fixture()
  let source_before = read_bytes(
    root + "/books/water/raw/nested/source.bin",
    1048576,
  )
  let catalog_before = read_bytes(root + "/catalog.json", 1048576)
  let saved = store.save(fixture_draft(), "", "2026-10-07T01:00:00Z")
  let prepared = store.prepare(saved.draft.draft_id, saved.revision)
  assert_false(@fs.exists(root + "/runtime/.moonsuite/products/moonclaw/jobs"))
  let original_export = store.export_tar(saved.draft.draft_id, saved.revision)
  let result = store.start_oneoff(saved.draft.draft_id, saved.revision, runtime)
  assert_eq(result.status, "completed")
  assert_eq(result.participants.length(), 2)
  assert_false(@fs.exists(root + "/runtime/.moonsuite/products/moonclaw/jobs"))
  for participant in result.participants {
    assert_eq(participant.status, "completed")
    assert_true(
      participant.output_text.contains("Deterministic local fixture output"),
    )
    assert_true(
      participant.output_text.contains("水\u0000exact retained source"),
    )
    assert_eq(
      digest(@utf8.encode(participant.output_text)),
      participant.output_digest,
    )
    assert_true(participant.run_id.has_prefix("run-oneoff-town-"))
  }
  assert_eq(
    store.start_oneoff(saved.draft.draft_id, saved.revision, runtime),
    result,
  )
  assert_eq(store.read_oneoff(saved.draft.draft_id, saved.revision), result)
  assert_eq(store.prepare(saved.draft.draft_id, saved.revision), prepared)
  assert_eq(
    store.export_tar(saved.draft.draft_id, saved.revision),
    original_export,
  )
  let missing_authority = try {
    ignore(
      store.decide_oneoff(
        saved.draft.draft_id,
        saved.revision,
        None,
        decision_payload(result, "review-result", "approve"),
        "2026-10-07T01:01:00Z",
      ),
    )
    false
  } catch {
    _ => true
  }
  assert_true(missing_authority)
  let rejected = store.decide_oneoff(
    saved.draft.draft_id,
    saved.revision,
    Some("alex"),
    decision_payload(result, "review-result", "reject"),
    "2026-10-07T01:01:00Z",
  )
  assert_eq(rejected.decisions[0].decision, "reject")
  assert_true(
    try {
      ignore(
        store.decide_oneoff(
          saved.draft.draft_id,
          saved.revision,
          Some("alex"),
          decision_payload(rejected, "resolve-objection", "approve"),
          "2026-10-07T01:02:00Z",
        ),
      )
      false
    } catch {
      _ => true
    },
  )
  let deferred = store.decide_oneoff(
    saved.draft.draft_id,
    saved.revision,
    Some("sam"),
    decision_payload(rejected, "resolve-objection", "defer"),
    "2026-10-07T01:02:00Z",
  )
  assert_eq(deferred.review_status, "pending_review")
  let objection = store.decide_oneoff(
    saved.draft.draft_id,
    saved.revision,
    Some("sam"),
    decision_payload(deferred, "resolve-objection", "approve"),
    "2026-10-07T01:03:00Z",
  )
  assert_eq(objection.review_status, "rejected")
  let settled = store.decide_oneoff(
    saved.draft.draft_id,
    saved.revision,
    Some("alex"),
    decision_payload(objection, "review-result", "approve"),
    "2026-10-07T01:04:00Z",
  )
  assert_eq(settled.review_status, "accepted")
  assert_eq(settled.review_version, 4)
  assert_true(settled.review_history_text.contains("review-result: reject"))
  assert_true(settled.review_history_text.contains("resolve-objection: defer"))
  assert_true(
    try {
      ignore(
        store.decide_oneoff(
          saved.draft.draft_id,
          saved.revision,
          Some("alex"),
          decision_payload(result, "review-result", "approve"),
          "2026-10-07T01:05:00Z",
        ),
      )
      false
    } catch {
      _ => true
    },
  )
  assert_eq(store.read_oneoff(saved.draft.draft_id, saved.revision), settled)
  let outcomes = store.list_outcomes()
  let retained = outcomes
    .iter()
    .find_first(e => e.revision == saved.revision)
    .unwrap()
  let inspected = store.inspect_outcome(retained.key())
  assert_eq(inspected.work.result_text, settled.result_text)
  assert_eq(inspected.work.participants, settled.participants)
  assert_eq(inspected.work.review_version, settled.review_version)
  assert_eq(
    digest(store.export_outcome(retained.key())),
    inspected.archive_digest,
  )
  assert_eq(read_bytes(root + "/catalog.json", 1048576), catalog_before)
  assert_eq(
    read_bytes(root + "/books/water/raw/nested/source.bin", 1048576),
    source_before,
  )
  assert_false(@fs.exists(root + "/state/schedules"))
  assert_false(@fs.exists(root + "/books/water/review"))
  let prior_bytes = read_bytes(
    store.work_root(saved) + "/review/1.json",
    2097152,
  )
  let revised = store.save(
    { ..saved.draft, question: "Revised source question", },
    saved.revision,
    "2026-10-07T01:06:00Z",
  )
  ignore(store.prepare(revised.draft.draft_id, revised.revision))
  let next = store.start_oneoff(
    revised.draft.draft_id,
    revised.revision,
    runtime,
  )
  assert_eq(next.status, "completed")
  assert_true(next.participants[0].run_id != result.participants[0].run_id)
  assert_eq(next.review_status, "pending_review")
  assert_eq(
    read_bytes(store.work_root(saved) + "/review/1.json", 2097152),
    prior_bytes,
  )
  assert_eq(store.read_oneoff(saved.draft.draft_id, saved.revision), settled)
  if @env.get_env_var("MOONTOWN_ONEOFF_EVIDENCE") is Some(path) {
    directory(path, true)
    write_bytes(path + "/completed-root.txt", @utf8.encode(root))
    write_bytes(
      path + "/completed-work.json",
      @utf8.encode(settled.to_json().stringify(indent=2)),
    )
    write_bytes(
      path + "/revised-work.json",
      @utf8.encode(next.to_json().stringify(indent=2)),
    )
  }
}

///|
async test "oneoff partial failure stays visible and frozen input substitution is rejected" {
  let (store, root, runtime) = oneoff_fixture()
  @fs.write_file(
    root + "/books/mobility/raw/nested/source.bin",
    "FAIL_PARTICIPANT_FIXTURE",
  )
  let saved = store.save(fixture_draft(), "", "2026-10-07T02:00:00Z")
  ignore(store.prepare(saved.draft.draft_id, saved.revision))
  let result = store.start_oneoff(saved.draft.draft_id, saved.revision, runtime)
  assert_eq(result.status, "partial")
  assert_eq(result.participants[0].status, "completed")
  assert_eq(result.participants[1].status, "failed")
  assert_true(result.result_text.contains("failed"))
  let retained = store.list_outcomes()[0]
  assert_eq(retained.outcome_status, "partial")
  let inspected = store.inspect_outcome(retained.key())
  assert_eq(inspected.work.participants, result.participants)
  assert_eq(
    digest(store.export_outcome(retained.key())),
    inspected.archive_digest,
  )
  assert_eq(
    store.start_oneoff(saved.draft.draft_id, saved.revision, runtime),
    result,
  )
  @fs.write_file(
    store.work_root(saved) + "/workspaces/water/input/brief.md",
    "source substitution",
  )
  assert_true(
    try {
      ignore(store.start_oneoff(saved.draft.draft_id, saved.revision, runtime))
      false
    } catch {
      _ => true
    },
  )
  if @env.get_env_var("MOONTOWN_ONEOFF_EVIDENCE") is Some(path) {
    write_bytes(path + "/partial-root.txt", @utf8.encode(root))
    write_bytes(
      path + "/partial-work.json",
      @utf8.encode(result.to_json().stringify(indent=2)),
    )
  }
}

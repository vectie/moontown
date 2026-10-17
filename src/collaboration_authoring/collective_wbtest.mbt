///|
/// Synthetic retained evidence exercises the real host action and source
/// persistence. No runtime/provider execution or authenticated review is faked.
async test "collective host saves reopens prepares a new source-bound peer-challenge round and rejects changed retries" {
  let (store, root) = fixture()
  let original = store.save(fixture_draft(), "", "2026-10-12T13:00:00Z")
  let retained = retain_outcome_fixture(store, original, false)
  let original_source = original.sources[0].digest
  // Current Book content may evolve; the next round must capture new bytes
  // while preserving the exact historical output excerpt and source identity.
  @fs.write_file(
    root + "/books/water/raw/nested/source.bin",
    "Current water source",
  )
  let fields : Json = {
    "review_version": retained.review_version,
    "collective_new_id": "shared-experiment",
    "collective_result_digest": retained.result_digest,
    "collective_title": "Compare observation contexts",
    "collective_hypothesis": "Both domains share a confounding observation context.",
    "collective_experiment": "Compare source dates and contexts before proposing a pilot.",
    "collective_falsifier": "No shared context is present in the two source sets.",
    "collective_dissent": "The original period comparability concern remains open.",
    "collective_assumptions": "The source dates may be incomplete.",
    "collective_quote_water": "Exact contribution 水 café 🚲",
    "collective_quote_mobility": "No consensus inferred <script>.",
    "collective_connection_water": "Water supplies the first context.",
    "collective_connection_mobility": "Mobility supplies the cross-domain challenge.",
    "collective_challenge_water": "Check dates against the water sources.",
    "collective_challenge_mobility": "Look for a counterexample in the mobility sources.",
  }
  let request : Request = {
    contract_version: "moontown.collaboration.request.v1",
    request_id: "followup",
    action: "oneoff-followup",
    draft_id: original.draft.draft_id,
    revision: original.revision,
    new_draft_id: "unused-untrusted-id",
    artifact_path: "",
    draft: None,
    payload: Some(fields),
  }
  let reply = store.request_oneoff(
    request,
    None,
    None,
    "2026-10-12T13:01:00Z",
    1791800000,
  )
  assert_true(reply.ok, msg=reply.error)
  let saved = reply.saved.unwrap()
  assert_eq(saved.draft.draft_id, "shared-experiment")
  assert_eq(saved.previous_revision, "")
  assert_true(saved.draft.question.contains(original_source))
  assert_true(
    saved.draft.question.contains(retained.participants[0].output_digest),
  )
  assert_true(saved.sources[0].digest != original_source)
  assert_eq(store.load(saved.draft.draft_id), saved)
  assert_false(@fs.exists(store.work_root(saved) + "/intent.json"))
  assert_false(@fs.exists(store.work_root(saved) + "/review"))
  let retry = store.request_oneoff(
    request,
    None,
    None,
    "2026-10-12T13:02:00Z",
    1791800060,
  )
  assert_eq(retry.saved, Some(saved))
  let prepared = store.prepare(saved.draft.draft_id, saved.revision)
  assert_eq(prepared.review_status, "pending_review")
  let brief = text_bytes(
    store.artifact(
      saved.draft.draft_id,
      saved.revision,
      revision_prefix(saved) + "briefs/water.md",
    ),
  )
  assert_true(brief.contains("Check dates against the water sources."))
  assert_true(brief.contains("No shared context is present"))
  assert_eq(
    store.read_oneoff(saved.draft.draft_id, saved.revision).status,
    "not_started",
  )
  assert_eq(
    store.load(original.draft.draft_id, revision=original.revision),
    original,
  )
  assert_eq(store.retained_work(original).result_digest, retained.result_digest)
  @fs.write_file(
    root + "/books/water/raw/nested/source.bin",
    "Newer source after save",
  )
  let stale = store.request_oneoff(
    request,
    None,
    None,
    "2026-10-12T13:03:00Z",
    1791800120,
  )
  assert_false(stale.ok)
  assert_eq(store.load(saved.draft.draft_id), saved)
  @fs.write_file(
    store.work_root(original) + "/produced/water/report.md",
    "Tampered original output",
  )
  let tampered = store.request_oneoff(
    request,
    None,
    None,
    "2026-10-12T13:04:00Z",
    1791800180,
  )
  assert_false(tampered.ok)
}

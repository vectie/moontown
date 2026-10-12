///|
async test "retained comparison reads exact source revisions and failures without mutating the store" {
  let (store, root) = fixture()
  let first = store.save(fixture_draft(), "", "2026-10-10T01:00:00Z")
  ignore(retain_outcome_fixture(store, first, false))
  let before_key = store.list_outcomes()[0].key()
  @fs.write_file(
    root + "/books/water/raw/nested/source.bin",
    b"new exact source\x00\xff\n",
  )
  let second = store.save(
    { ..first.draft, question: "Which new observations need review?", },
    first.revision,
    "2026-10-10T02:00:00Z",
  )
  ignore(retain_outcome_fixture(store, second, true))
  let after_key = store
    .list_outcomes()
    .iter()
    .find_first(e => e.revision == second.revision)
    .unwrap()
    .key()
  let before_tree = outcome_tree(root)
  let comparison = store.compare_outcomes(before_key, after_key)
  assert_eq(comparison.before, before_key)
  assert_eq(comparison.after, after_key)
  assert_eq(comparison.sources.map(row => row.change), ["changed", "unchanged"])
  assert_eq(comparison.contributions.map(row => row.change), [
    "unchanged", "changed",
  ])
  assert_eq(comparison.contributions[1].after.unwrap().status, "failed")
  assert_true(comparison.markdown().contains("Attributed fixture failure"))
  assert_true(
    comparison.fields.any(row => {
      row.identity == "question" && row.change == "changed"
    }),
  )
  assert_eq(outcome_tree(root), before_tree)
  assert_eq(store.compare_outcomes(before_key, after_key), comparison)
  let same = store.compare_outcomes(before_key, before_key)
  assert_true(same.sources.all(row => row.change == "unchanged"))
  assert_true(same.contributions.all(row => row.change == "unchanged"))
  if @env.get_env_var("MOONTOWN_COMPARISON_EVIDENCE") is Some(path) {
    directory(path, true)
    write_bytes(path + "/store-root.txt", @utf8.encode(store.root))
    write_bytes(
      path + "/before-key.json",
      @utf8.encode(before_key.to_json().stringify(indent=2)),
    )
    write_bytes(
      path + "/after-key.json",
      @utf8.encode(after_key.to_json().stringify(indent=2)),
    )
    write_bytes(
      path + "/expected.json",
      @utf8.encode(comparison.to_json().stringify(indent=2) + "\n"),
    )
    write_bytes(path + "/expected.md", @utf8.encode(comparison.markdown()))
  }
}

///|
async test "retained comparison pins historical review and leaves corrupt or absent evidence unchanged" {
  let (store, root) = fixture()
  let saved = store.save(fixture_draft(), "", "2026-10-10T01:00:00Z")
  let work = retain_outcome_fixture(store, saved, false)
  let old = store.list_outcomes()[0].key()
  ignore(
    outcome_fixture_decision(
      store,
      saved,
      work,
      result_bundle(saved, work),
      1,
      "review-result",
      "defer",
    ),
  )
  let current = store.list_outcomes()[0].key()
  let before = outcome_tree(root)
  let comparison = store.compare_outcomes(old, current)
  assert_eq(comparison.before.review_version, 0)
  assert_eq(comparison.after.review_version, 1)
  assert_eq(comparison.decisions[0].change, "changed")
  assert_eq(comparison.decisions[0].before.unwrap().decision, "pending")
  assert_eq(comparison.decisions[0].after.unwrap().decision, "defer")
  assert_eq(outcome_tree(root), before)
  assert_true(
    (try? store.compare_outcomes(old, {
      ..current,
      review_digest: "sha256:wrong",
    }))
    is Err(_),
  )
  assert_eq(outcome_tree(root), before)
  @fs.write_file(
    store.work_root(saved) + "/produced/water/report.md",
    "substituted",
  )
  let corrupt = outcome_tree(root)
  assert_true((try? store.compare_outcomes(old, current)) is Err(_))
  assert_eq(outcome_tree(root), corrupt)
}

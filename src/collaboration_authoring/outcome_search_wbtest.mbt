///|
fn outcome_search_query(text : String) -> @contract.OutcomeSearchQuery {
  {
    text,
    case_sensitive: false,
    book_id: "",
    review_status: "",
    selections: [],
  }
}

///|
async test "retained search scans old source revisions and pins current or explicit historical reviews without writes" {
  let (store, root) = fixture()
  let first = store.save(fixture_draft(), "", "2026-10-10T06:00:00Z")
  let work = retain_outcome_fixture(store, first, false)
  let old_key = store.list_outcomes()[0].key()
  ignore(
    outcome_fixture_decision(
      store,
      first,
      work,
      result_bundle(first, work),
      1,
      "review-result",
      "defer",
    ),
  )
  let second = store.save(
    { ..first.draft, question: "Which observation changed?", },
    first.revision,
    "2026-10-10T06:01:00Z",
  )
  ignore(retain_outcome_fixture(store, second, true))
  ignore(
    store.save(
      { ..fixture_draft(), draft_id: "not-yet-retained", },
      "",
      "2026-10-10T06:02:00Z",
    ),
  )
  let before = outcome_tree(root)
  let query = outcome_search_query("exact contribution")
  let result = store.search_outcomes(query)
  assert_eq(result.candidate_count, 3)
  assert_eq(result.searched_count, 2)
  assert_eq(result.excluded_count, 0)
  assert_eq(result.hits.length(), 2)
  assert_eq(result.gaps.length(), 1)
  assert_eq(result.gaps[0].status, "not_retained")
  let first_hit = result.hits
    .iter()
    .find_first(h => h.key.revision == first.revision)
    .unwrap()
  assert_eq(first_hit.key.review_version, 1)
  assert_eq(first_hit.review_status, "deferred")
  let history_query = {
    ..query,
    text: "Historical local fixture decision",
    selections: [old_key],
  }
  let historic = store.search_outcomes(history_query)
  assert_eq(historic.review_selection, "explicit_pinned_reviews")
  assert_eq(historic.hits.length(), 0)
  assert_eq(historic.searched_count, 1)
  let latest = store.search_outcomes({ ..history_query, selections: [], })
  assert_eq(latest.hits.length(), 1)
  assert_eq(latest.hits[0].key.review_version, 1)
  let pinned = store.search_outcomes({ ..query, selections: [old_key], })
  assert_eq(pinned.hits[0].key, old_key)
  assert_eq(pinned.hits[0].review_status, "pending_review")
  let filtered = store.search_outcomes({
    ..query,
    book_id: "mobility",
    review_status: "deferred",
  })
  assert_eq(filtered.hits.length(), 1)
  assert_eq(filtered.excluded_count, 1)
  assert_eq(filtered.hits[0].matches.length(), 1)
  assert_eq(filtered.hits[0].matches[0].book_id, "mobility")
  let failure = store.search_outcomes(
    outcome_search_query("incomplete observations"),
  )
  assert_eq(failure.hits.length(), 1)
  assert_eq(failure.hits[0].outcome_status, "partial")
  assert_eq(failure.hits[0].matches[0].field, "participant.detail")
  assert_eq(outcome_tree(root), before)
  assert_eq(store.search_outcomes(query), result)
  if @env.get_env_var("MOONTOWN_SEARCH_EVIDENCE") is Some(path) {
    directory(path, true)
    write_bytes(path + "/store-root.txt", @utf8.encode(store.root))
    write_bytes(
      path + "/query.json",
      @utf8.encode(query.to_json().stringify(indent=2)),
    )
    write_bytes(
      path + "/historic-query.json",
      @utf8.encode(
        { ..query, selections: [old_key], }.to_json().stringify(indent=2),
      ),
    )
    write_bytes(path + "/expected.json", @utf8.encode(result.json_text()))
    write_bytes(path + "/expected.md", @utf8.encode(result.markdown()))
  }
}

///|
async test "retained search reports corruption missing pins and empty stores without repair or fabricated absence" {
  let (store, root) = fixture()
  let saved = store.save(fixture_draft(), "", "2026-10-10T06:03:00Z")
  ignore(retain_outcome_fixture(store, saved, false))
  let key = store.list_outcomes()[0].key()
  let wrong = { ..key, review_digest: "sha256:wrong", }
  let query = outcome_search_query("contribution")
  let before = outcome_tree(root)
  let missing = store.search_outcomes({ ..query, selections: [wrong], })
  assert_eq(missing.hits.length(), 0)
  assert_eq(missing.gaps[0].status, "unavailable")
  assert_eq(missing.searched_count, 0)
  assert_eq(outcome_tree(root), before)
  @fs.write_file(
    store.work_root(saved) + "/produced/water/report.md",
    "changed report",
  )
  let corrupt = outcome_tree(root)
  let broken = store.search_outcomes(query)
  assert_eq(broken.candidate_count, 1)
  assert_eq(broken.gaps[0].status, "unavailable")
  assert_eq(broken.hits.length(), 0)
  assert_eq(outcome_tree(root), corrupt)
  let empty : Store = { root: root + "/absent-search-store", catalog_path: "", }
  assert_eq(empty.search_outcomes(query).candidate_count, 0)
  assert_eq(kind(empty.root), None)
  assert_eq(
    empty.search_outcomes({ ..query, selections: [key], }).gaps[0].status,
    "unavailable",
  )
  assert_eq(kind(empty.root), None)
}

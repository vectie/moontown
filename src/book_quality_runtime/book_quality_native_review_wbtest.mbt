///|
async test "scheduled native semantic producer never seeds ACP and keeps one pending review" {
  let root = cleaned_book_quality_test_root(
    @fs.realpath("/tmp") + "/moontown-native-semantic-producer-wbtest",
  )
  let book_root = root + "/imported"
  @support.write_text_file(book_root + "/wiki/index.md", "Fixture Book\n")
  let catalog = root + "/catalog.json"
  @moonbook.save_catalog_file(catalog, [
    book_quality_catalog_entry(
      id="native-book",
      name="Native Book",
      purpose="Fixture semantic review",
      workspace_root=book_root,
      tags=["research"],
    ),
  ])
  let snapshot = root + "/snapshot.json"
  let review_dir = root + "/book-quality/ai-review-packets"
  let result_dir = root + "/book-quality/ai-review-results"
  let run_path = root + "/book-quality/ai-review-runs.json"
  let calls : Array[String] = []
  let client = @native_code_control.Client::new(
    owner_workspace=@storage.moontown_active_workspace_root(),
    instance_id="fixture",
    config_path="/fixture/control/execution-sandbox/moonclaw.json",
    request=async fn(method, path, _) {
      calls.push(method + " " + path)
      Ok({ "model_workspace_contract": "mooncode.model-workspace.v1" })
    },
  )
  let summary = dispatch_next_native_book_quality_review(
    catalog,
    snapshot,
    review_dir,
    result_dir,
    run_path,
    client~,
  )
  assert_true(summary.contains("read_only_execution_unavailable"))
  let state_path = @native_work.path_for_snapshot(snapshot)
  let first = @native_work.load(path=state_path)
  assert_eq(first.work.length(), 1)
  ignore(
    dispatch_next_native_book_quality_review(
      catalog,
      snapshot,
      review_dir,
      result_dir,
      run_path,
      client~,
    ),
  )
  assert_eq(@native_work.load(path=state_path).work.length(), 1)
  assert_false(
    @fs.exists(@book_quality.review_root(review_dir) + "/moonclaw.jobs.json"),
  )
  assert_false(@fs.exists(@book_quality.moonclaw_config_path(review_dir)))
  assert_eq(calls.length(), 1)
  assert_eq(
    @fs.read_file(book_root + "/wiki/index.md").text(),
    "Fixture Book\n",
  )
}

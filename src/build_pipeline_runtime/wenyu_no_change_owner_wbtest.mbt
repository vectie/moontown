///|
fn wenyu_test_restore_envs(keys : Array[String], old : Array[String?]) -> Unit {
  for index, key in keys {
    wenyu_test_restore_env(key, old[index])
  }
}

///|
// Normal repository runs use the existing owner callback fixture. The bounded
// audit invocation explicitly supplies a tiny Book CLI bridge; that mode runs
// the actual Town adapter and actual Book transaction against isolated files.
// It does not claim Book's full CLI parser or live native check execution.
async fn wenyu_journey_persist(
  launch : WenyuLaunch,
  work : @native_work.Work,
  result : @moonbook.BookResult,
) -> @moonbook.PersistResultOutcome {
  guard @env.get_env_var("WENYU_TEST_BOOK_BIN") is Some(binary) else {
    return wenyu_owner_outcome(result)
  }
  let root = launch.native_path[:launch.native_path.length() -
  "/native.json".length()].to_owned()
  let cli_root = root + "/book-cli-home"
  if !@fs.exists(cli_root) {
    @fs.mkdir(cli_root)
  }
  let keys = [
    "HOME", "MOONTOWN_SUITE_ROOT", "MOONSUITE_ROOT", "MOONTOWN_MOONBOOK_ROOT", "MOONTOWN_MOONBOOK_BIN",
  ]
  let old = keys.map(key => @env.get_env_var(key))
  defer wenyu_test_restore_envs(keys, old)
  @env.set_env_var("HOME", root + "/home")
  @env.set_env_var("MOONTOWN_SUITE_ROOT", root + "/suite")
  @env.set_env_var("MOONSUITE_ROOT", root + "/suite")
  @env.set_env_var("MOONTOWN_MOONBOOK_ROOT", cli_root)
  @env.set_env_var("MOONTOWN_MOONBOOK_BIN", binary)
  if !@fs.exists(launch.entry.workspace_root + "/wiki/index.md") {
    @support.write_text_file(
      launch.entry.workspace_root + "/wiki/index.md",
      "# Synthetic Book\n",
    )
  }
  if !@fs.exists(launch.entry.workspace_root + "/moonclaw.jobs.json") {
    @support.write_text_file(
      launch.entry.workspace_root + "/moonclaw.jobs.json",
      "{}",
    )
  }
  @moonbook.persist_native_wenyu_result(
    launch.entry,
    result,
    work.id,
    work.request_digest,
    moonbook_root=cli_root,
  )
}

///|
async test "Wenyu no change actual source sync and owner pages survive every persistence boundary" {
  for stop in ["package", "code-page", "test-page", "book-commit"] {
    let launch = wenyu_launch_fixture()
    let work = wenyu_journey_completed(launch)
    let root = launch.entry.workspace_root
    let blockers = root + "/build/CODE_BLOCKERS.md"
    @support.write_text_file(blockers, "Unrelated older blocker stays\n")
    let package = wenyu_output_package(launch, work)
    assert_eq(package.pages.length(), 2)
    assert_true(package.result.memory_candidates.is_empty())
    assert_true(package.result.requires_review && package.result.notify_town)
    let directory = root + "/raw/build/native/" + work.id
    if stop == "package" {
      @support.write_text_file(
        directory + "/output-package.json",
        package.to_json().stringify(indent=2),
      )
    }
    let calls = [0]
    let persist = async fn(result : @moonbook.BookResult) {
      calls[0] += 1
      let outcome = wenyu_journey_persist(launch, work, result)
      if stop == "book-commit" && calls[0] == 1 {
        fail("injected_after_book_commit")
      }
      outcome
    }
    if stop != "package" {
      try {
        ignore(
          import_wenyu_native_result(launch, work, persist~, after_page=async fn(
            page,
          ) {
            if (stop == "code-page" && page == "build/CODE_PATCH.md") ||
              (stop == "test-page" && page == "build/TEST_RESULTS.md") {
              fail("injected_after_page")
            }
          }),
        )
        fail("expected injected interruption")
      } catch {
        error => assert_true(error.to_string().contains("injected_after_"))
      }
      assert_false(@fs.exists(directory + "/application-receipt.json"))
    }
    let immutable = @fs.read_file(directory + "/output-package.json").text()
    let outcome = import_wenyu_native_result(launch, work, persist~)
    assert_true(outcome.review_queued && outcome.notify_town)
    assert_false(outcome.executable_event.accepted)
    let application = @fs.read_file(directory + "/application-receipt.json").text()
    let count = calls[0]
    assert_eq(
      import_wenyu_native_result(launch, work, persist~).to_json(),
      outcome.to_json(),
    )
    assert_eq(calls[0], count)
    assert_eq(
      @fs.read_file(directory + "/output-package.json").text(),
      immutable,
    )
    assert_eq(
      @fs.read_file(directory + "/application-receipt.json").text(),
      application,
    )
    let code = @fs.read_file(root + "/build/CODE_PATCH.md").text()
    assert_true(code.has_prefix("# Wenyu Code Validation"))
    assert_true(
      code.contains(
        "No net source change; required checks passed; human review required; original-task acceptance unevaluated",
      ),
    )
    assert_true(code.contains("existing_answer already returns 42"))
    assert_true(
      @fs.read_file(root + "/build/TEST_RESULTS.md")
      .text()
      .contains("moon -C src/ui/rabbita-town build --target js --release"),
    )
    assert_eq(@fs.read_file(blockers).text(), "Unrelated older blocker stays\n")
    assert_eq(
      wenyu_native_execution_record(launch, work, 1).status,
      AwaitingPersistence,
    )
    let record = wenyu_native_execution_record(launch, work, 2, imported=true)
    assert_eq(record.status, ReviewQueued)
    assert_true(record.summary.contains("No net source change"))
    if @env.get_env_var("WENYU_TEST_BOOK_BIN") is Some(_) {
      let review_path = root + "/wiki/reviews/pending.md"
      let evidence = @fs.read_file(root + "/wiki/synthesis/evidence.md").text()
      assert_true(evidence.contains("pending-review"))
      assert_true(
        @fs.read_file(review_path)
        .text()
        .contains("native Wenyu result requires human product review"),
      )
      @support.write_text_file(review_path, "Human review remains final\n")
      let latest = root + "/events/latest.json"
      @support.write_text_file(latest, "{\"newer-human-event\":true}")
      ignore(import_wenyu_native_result(launch, work, persist~))
      assert_eq(
        @fs.read_file(review_path).text(),
        "Human review remains final\n",
      )
      assert_eq(@fs.read_file(latest).text(), "{\"newer-human-event\":true}")
      assert_eq(calls[0], count)
      let event = outcome.executable_event.to_json()
      assert_eq(native_json_text(event, "event_type"), "review_required")
      assert_eq(wenyu_test_field(event, "accepted"), false.to_json())
      assert_eq(wenyu_test_field(event, "lifecycle_proof"), Json::null())
      println("WENYU_REAL_BOOK_ADAPTER_PROOF " + stop + " " + work.id)
    }
  }
}

///|
async test "Wenyu no change owner rejects edited receipt human outputs and symlinks" {
  let launch = wenyu_launch_fixture()
  let work = wenyu_journey_completed(launch)
  for
    key in [
      "engineering_status", "result_decision", "completion_outcome", "contract",
      "request_digest", "output_digest", "source_root", "task_id", "goal_id", "model",
      "request_body_digest", "acceptance_scope", "original_task_acceptance", "changed_files",
      "final_observation", "native_completion_verdict",
    ] {
    let changed : @native_work.Work = @json.from_json(
      @json.parse(work.to_json().stringify()),
    )
    wenyu_test_set(changed.receipt, key, Json::null())
    try {
      ignore(
        import_wenyu_native_result(launch, changed, persist=async fn(result) {
          wenyu_owner_outcome(result)
        }),
      )
      fail("accepted invalid receipt")
    } catch {
      error => assert_true(error.to_string().contains("wenyu_result_"), msg=key)
    }
  }
  for state in ["running", "dispatch_uncertain", "superseded"] {
    try {
      ignore(
        import_wenyu_native_result(launch, { ..work, state, }, persist=async fn(
          result,
        ) {
          wenyu_owner_outcome(result)
        }),
      )
      fail("accepted nonterminal result")
    } catch {
      error =>
        assert_true(error.to_string().contains("wenyu_result_binding_mismatch"))
    }
  }
  let page = launch.entry.workspace_root + "/build/CODE_PATCH.md"
  @support.write_text_file(page, "Human output\n")
  try {
    ignore(
      import_wenyu_native_result(launch, work, persist=async fn(result) {
        wenyu_owner_outcome(result)
      }),
    )
    fail("replaced human result")
  } catch {
    error =>
      assert_true(
        error
        .to_string()
        .contains("wenyu_output_changed_by_human_or_newer_work"),
      )
  }
  assert_eq(@fs.read_file(page).text(), "Human output\n")
  let symlink_launch = wenyu_launch_fixture()
  let symlink_work = wenyu_journey_completed(symlink_launch)
  @fs.mkdir(symlink_launch.entry.workspace_root + "/build")
  @fs.symlink(
    target=symlink_launch.entry.workspace_root + "/outside.md",
    symlink_launch.entry.workspace_root + "/build/CODE_PATCH.md",
  )
  try {
    ignore(
      import_wenyu_native_result(symlink_launch, symlink_work, persist=async fn(
        result,
      ) {
        wenyu_owner_outcome(result)
      }),
    )
    fail("followed symlink")
  } catch {
    error =>
      assert_true(error.to_string().contains("wenyu_book_path_not_canonical"))
  }
}

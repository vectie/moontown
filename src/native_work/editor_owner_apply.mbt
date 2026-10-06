///|
/// Engineering completion stays terminal. Explicit sync retries only the fixed
/// owner package; observation-only refresh never calls this seam.
async fn apply_editor_owner_result(
  work : Work,
  after_step? : async (String) -> Unit,
) -> Work {
  if work.state != "completed" {
    return work
  }
  try {
    let receipt = match after_step {
      Some(after_step) => apply_editor_owner_package(work, after_step~)
      None => apply_editor_owner_package(work)
    }
    editor_with_application(work, "applied", "", receipt)
  } catch {
    error =>
      editor_with_application(work, "blocked", error.to_string(), Json::null())
  }
}

///|
async fn apply_editor_owner_package(
  work : Work,
  after_step? : async (String) -> Unit,
) -> Json {
  guard editor_spec(work.request) is Some(spec) && editor_evidence_bound(work) else {
    fail("editor_owner_evidence_binding_invalid")
  }
  guard validate_book(work.request) else {
    fail("editor_owner_book_binding_unavailable")
  }
  let root = work.request.book_root
  let directory = editor_owner_directory(work.id)
  let package_path = editor_owner_file(root, directory + "/output-package.json")
  let receipt_path = editor_owner_file(
    root,
    directory + "/application-receipt.json",
  )
  let lock_path = editor_owner_file(
    root, "raw/editor-pipeline/native/application.lock",
  )
  @support.ensure_parent_directory(lock_path)
  let lock = @fs.open(
    lock_path,
    mode=ReadWrite,
    create_mode=OpenOrCreate,
    permission=0o600,
  )
  defer lock.close()
  lock.lock(Exclusive)
  defer lock.unlock()
  let expected = editor_owner_package(work, spec)
  let package = if @fs.exists(package_path) {
    guard @fs.kind(package_path, follow_symlink=false) is Regular else {
      fail("editor_output_package_not_regular")
    }
    let saved : EditorOutputPackage = @json.from_json(
      @json.parse(@fs.read_file(package_path).text()),
    )
    guard saved.to_json() == expected.to_json() else {
      fail("editor_output_package_conflict")
    }
    saved
  } else {
    // Never freeze/apply source evidence after a different source state won.
    guard source_still_bound(work.request.source_binding, strict_digest=false) &&
      verify_final_source_freshness(work, work.last_attempt_at_ms).state ==
      "completed" else {
      fail("editor_owner_source_changed")
    }
    @support.ensure_parent_directory(package_path)
    @fs.write_file(
      package_path,
      expected.to_json().stringify(indent=2),
      create_mode=CreateNew,
      permission=0o600,
      sync=Full,
    )
    sync_state_directories(package_path)
    expected
  }
  let expected_receipt = editor_application_receipt(package)
  if @fs.exists(receipt_path) {
    guard @fs.kind(receipt_path, follow_symlink=false) is Regular &&
      @json.parse(@fs.read_file(receipt_path).text()) == expected_receipt else {
      fail("editor_application_receipt_invalid")
    }
    // Durable completed replay never overwrites a later human/newer-work edit.
    return expected_receipt
  }
  if after_step is Some(after_step) {
    after_step("package")
  }
  if spec.selection_digest != "" {
    if editor_owner_fingerprint(root, "raw/editor-pipeline/next-feature.json") !=
      spec.selection_digest {
      fail("editor_selection_changed")
    }
  }
  guard source_still_bound(work.request.source_binding, strict_digest=false) &&
    verify_final_source_freshness(work, work.last_attempt_at_ms).state ==
    "completed" else {
    fail("editor_owner_source_changed")
  }
  // Validate all destinations before writing any one. The package is owner
  // generated and must contain only the fixed criterion-specific destination set.
  for relative, content in package.pages {
    guard spec.output_before.contains(relative) &&
      [
        "raw/repair/repair-result.md",
        "raw/repair/repair-result.md.native-receipt.json",
        "raw/editor-pipeline/selected-feature-implementation.md",
        editor_owner_plan_relative(),
      ].contains(relative) else {
      fail("editor_owner_output_path_not_allowed")
    }
    let current = editor_owner_fingerprint(root, relative)
    guard Some(current) == package.before.get(relative) ||
      current == digest(content) else {
      fail("editor_owner_output_changed_by_human_or_newer_work: " + relative)
    }
  }
  for relative, content in package.pages {
    let desired = digest(content)
    let current = editor_owner_fingerprint(root, relative)
    if current == desired {
      continue
    }
    guard Some(current) == package.before.get(relative) else {
      fail("editor_owner_output_changed_by_human_or_newer_work: " + relative)
    }
    let path = editor_owner_file(root, relative)
    let next = editor_owner_file(root, relative + "." + work.id + ".next")
    @support.ensure_parent_directory(path)
    @fs.write_file(next, content, create_mode=CreateOrTruncate, sync=Full)
    let before_replace = editor_owner_fingerprint(root, relative)
    if before_replace == desired {
      continue
    }
    guard Some(before_replace) == package.before.get(relative) else {
      fail("editor_owner_output_changed_by_human_or_newer_work: " + relative)
    }
    if spec.selection_digest != "" &&
      editor_owner_fingerprint(root, "raw/editor-pipeline/next-feature.json") !=
      spec.selection_digest {
      fail("editor_selection_changed")
    }
    @fs.rename(next, path, replace=true)
    sync_state_directories(path)
    if after_step is Some(after_step) {
      after_step(relative)
    }
  }
  if after_step is Some(after_step) {
    after_step("before_receipt")
  }
  // Receipt last, after checking the exact written documents once more.
  for relative, content in package.pages {
    guard editor_owner_fingerprint(root, relative) == digest(content) else {
      fail("editor_owner_output_changed_before_receipt: " + relative)
    }
  }
  if spec.selection_digest != "" &&
    editor_owner_fingerprint(root, "raw/editor-pipeline/next-feature.json") !=
    spec.selection_digest {
    fail("editor_selection_changed")
  }
  @fs.write_file(
    receipt_path,
    expected_receipt.stringify(indent=2),
    create_mode=CreateNew,
    permission=0o600,
    sync=Full,
  )
  sync_state_directories(receipt_path)
  if after_step is Some(after_step) {
    after_step("receipt")
  }
  expected_receipt
}

///|
pub(all) struct WenyuLaunch {
  schema : String
  execution : String
  native_path : String
  entry : @moonbook.BookCatalogEntry
  task : @moonbook.BookTask
  request : @native_work.Request
  output_before : Map[String, String]
} derive(ToJson, FromJson)

///|
pub fn wenyu_native_task_kind(kind : String) -> Bool {
  ["code-patch", "projection-schema", "test-fix"].contains(kind)
}

///|
pub fn wenyu_objective_task(
  task : @moonbook.BookTask,
  objective : String,
) -> @moonbook.BookTask {
  @moonbook.BookTask::new(
    id=task.id + "-goal-" + @native_work.digest(objective)[:16].to_owned(),
    goal=task.goal,
    title=task.title,
    kind=task.kind,
    prompt=task.prompt,
    priority=task.priority,
    requires_review=task.requires_review,
    target_pages=task.target_pages,
    required_role=task.required_role,
  )
}

///|
pub fn wenyu_launch_path(native_path : String, task_id : String) -> String {
  native_path + ".wenyu-launches/" + @native_work.digest(task_id) + ".json"
}

///|
/// A corrected launch is new only after the operator explicitly superseded the
/// prior native generation. Existing manifests and requests remain immutable.
pub async fn wenyu_task_after_explicit_supersession(
  task : @moonbook.BookTask,
  native_path : String,
) -> @moonbook.BookTask {
  if !@fs.exists(native_path) {
    return task
  }
  let state = @native_work.load(path=native_path)
  let mut selected = task
  for generation in 1..<100 {
    let path = wenyu_launch_path(native_path, selected.id)
    if !@fs.exists(path) {
      return selected
    }
    let launch = load_wenyu_launch(path)
    if launch.execution != "native" {
      return selected
    }
    let mut superseded = false
    for work in state.work {
      if work.request.work_key == launch.request.work_key {
        if work.state != "superseded" {
          return selected
        }
        superseded = true
      }
    }
    if !superseded {
      return selected
    }
    selected = @moonbook.BookTask::new(
      id=task.id + "-generation-" + (generation + 1).to_string(),
      goal=task.goal,
      title=task.title,
      kind=task.kind,
      prompt=task.prompt,
      priority=task.priority,
      requires_review=task.requires_review,
      target_pages=task.target_pages,
      required_role=task.required_role,
    )
  }
  fail("wenyu_generation_limit_requires_attention")
}

///|
fn native_json_text(value : Json, key : String) -> String {
  match value {
    Object(fields) =>
      match fields.get(key) {
        Some(String(text)) => text
        _ => ""
      }
    _ => ""
  }
}

///|
async fn native_book_file(root : String, relative : String) -> String {
  guard relative != "" &&
    !relative.has_prefix("/") &&
    !relative.split("/").any(part => part == ".." || part == "." || part == "") else {
    fail("wenyu_book_path_invalid")
  }
  guard @fs.kind(root, follow_symlink=false) is Directory &&
    @fs.realpath(root) == root else {
    fail("wenyu_book_root_not_canonical")
  }
  let mut path = root
  for part in relative.split("/") {
    path += "/" + part.to_owned()
    let kind = Some(@fs.kind(path, follow_symlink=false)) catch { _ => None }
    if kind is Some(SymLink) {
      fail("wenyu_book_path_not_canonical")
    }
    if kind is Some(_) && @fs.realpath(path) != path {
      fail("wenyu_book_path_not_canonical")
    }
  }
  path
}

///|
async fn native_output_fingerprint(root : String, relative : String) -> String {
  let path = native_book_file(root, relative)
  if !@fs.exists(path) {
    return "absent"
  }
  guard @fs.kind(path, follow_symlink=false) is Regular else {
    fail("wenyu_output_not_regular")
  }
  @native_work.digest(@fs.read_file(path).text())
}

///|
#cfg(not(platform="windows"))
async fn wenyu_sync_ancestors(path : String) -> Unit {
  let parts = path.split("/").map(part => part.to_owned()).to_array()
  for count = parts.length() - 1; count > 0; count = count - 1 {
    let parent = if count == 1 { "/" } else { parts[:count].join("/") }
    let directory = @fs.open(parent, mode=ReadOnly)
    defer directory.close()
    directory.sync()
  }
}

///|
#cfg(platform="windows")
async fn wenyu_sync_ancestors(path : String) -> Unit {
  // File contents are flushed; POSIX directory fsync is unavailable here.
  ignore(path)
}

///|
fn wenyu_validation_commands() -> Array[String] {
  [
    "moon fmt", "moon info", "moon check --no-render", "moon test src/build_pipeline src/build_pipeline_runtime src/town_runtime --no-render",
    "moon -C src/ui/rabbita-town build --target js --release", "git diff --check",
  ]
}

///|
pub async fn freeze_wenyu_launch(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  goal_id : String,
  objective : String,
  execution? : String = "native",
  model? : String = "",
  allow_no_change? : Bool = false,
  native_path? : String = @native_work.default_path(),
  catalog_path? : String = @moonbook.default_catalog_path(),
) -> WenyuLaunch {
  guard ["native", "acp"].contains(execution) && goal_id != "" else {
    fail("wenyu_launch_selection_invalid")
  }
  let path = wenyu_launch_path(native_path, task.id)
  if @fs.exists(path) {
    let saved = load_wenyu_launch(path)
    guard saved.entry.id == entry.id &&
      saved.entry.workspace_root == entry.workspace_root &&
      saved.task.id == task.id &&
      saved.native_path == native_path else {
      fail("wenyu_saved_launch_binding_mismatch")
    }
    return saved
  }
  guard !allow_no_change || execution == "native" else {
    fail("wenyu_no_change_requires_native")
  }
  let (binding, source_blocker) = match
    @native_work.source_binding(@env.get_env_var("MOONTOWN_WORKSPACE_ROOT")) {
    Ok(binding) => (binding, "")
    Err(reason) => (Json::null(), reason)
  }
  let mut blocker = source_blocker
  if task.kind != "code-patch" {
    blocker = "wenyu_task_output_contract_not_supported: " + task.kind
  }
  let policy : Json = {
    "contract": "wenyu.build.native-policy.v1",
    "goal_id": goal_id,
    "objective": objective,
    "task_id": task.id,
    "task_kind": task.kind,
    "frozen_task": task,
    "commit_requirement": "not_requested",
    "required_validation_commands": wenyu_validation_commands(),
    "preserve_preexisting_unrelated_dirty_files": true,
    "push_requested": false,
    "output_pages": [
      "build/CODE_PATCH.md", "build/TEST_RESULTS.md", "build/CODE_BLOCKERS.md",
    ],
  }
  let no_change = allow_no_change &&
    execution == "native" &&
    task.kind == "code-patch"
  if no_change && policy is Object(fields) {
    fields["completion_policy"] = @native_work.wenyu_completion_policy(
      wenyu_validation_commands(),
    )
  }
  let context : Array[String] = [
    "Original accepted Wenyu task (authoritative implementation instruction):\n" +
    task.prompt,
    "Frozen task identity and validation policy:\n" + policy.stringify(indent=2),
    "Execute only in the explicitly bound source root: " +
    @native_work.source_root(binding) +
    ". The Book root is context/output storage only: " +
    entry.workspace_root +
    ". Owner/model workspace: " +
    @storage.moontown_active_workspace_root() +
    ".",
    if no_change {
      "Use checkpoint in the first batch, then read/read_skill/moon_ide to inspect the requested behavior. Preserve unrelated dirty/index/HEAD state. No commit or push was requested. Do not mutate Git history/index. Run every frozen validation command as a separate native shell call from cwd '.' after the final mutation or failed tool; formatting/interface generation themselves may mutate source, so rerun the entire command set after final source changes. The frozen UI build remains required. This request explicitly permits the frozen already_satisfied no_change alternative for the implementation milestone only. Preserve all original milestones and typed evidence requirements. Finish only after an accepted all-done checkpoint and attested mutation/checks or accepted identical no_change checkpoint/finish proposals with source evidence, nonempty observation and every required check reference. Never create a fake edit. No net source change and engineering checks do not establish product acceptance; original-task acceptance remains unevaluated and requires human review. If blocked, preserve the actual partial work and report the blocker; never claim successful completion from prose."
    } else {
      "Use checkpoint in the first batch, then read/read_skill/moon_ide and the smallest relevant source patch. Preserve unrelated dirty/index/HEAD state. No commit or push was requested. Do not mutate Git history/index. Run every frozen validation command as a separate native shell call from cwd '.' after the final mutation; formatting/interface generation themselves may mutate source, so rerun the entire command set after final source changes. The frozen UI build is required because this slice may change UI. Finish only after an accepted all-done checkpoint and attested source mutation/checks. No-change is not enabled. If blocked, preserve the actual partial work and report the blocker for native human continuation or cancellation; never claim successful completion from prose."
    },
    if no_change {
      "Do not write Book pages from the source worker. Return only wenyu.build.native-result.v1 JSON with the exact identity supplied in the reserved command, outcome implemented for an attested mutation or no_change for verified already-satisfied work, summary, behavior and residual_risks. The answer outcome must agree with the native completion evidence. MoonTown validates evidence and owns Book output application; original-task acceptance remains unevaluated. Target pages and repo:this-moontown-checkout are outputs/symbolic scope, never required input paths."
    } else {
      "Do not write Book pages from the source worker. Return only wenyu.build.native-result.v1 JSON with the exact identity supplied in the reserved command, outcome implemented, summary, behavior and residual_risks. MoonTown validates evidence and owns Book output application. Target pages and repo:this-moontown-checkout are outputs/symbolic scope, never required input paths."
    },
  ]
  for
    relative in [
      "raw/bootstrap/WENYU_VALLEY_PRD.md", "raw/bootstrap/deep-report.md", "raw/bootstrap/evidence-matrix.md",
      "build/IMPLEMENTATION_BACKLOG.md", "build/ACCEPTANCE_TESTS.md", "skills/wenyu-code-patch/SKILL.md",
    ] {
    let file = native_book_file(entry.workspace_root, relative)
    if !@fs.exists(file) {
      if relative.has_prefix("raw/bootstrap/") && blocker == "" {
        blocker = "wenyu_context_missing: " + relative
      }
      continue
    }
    guard @fs.kind(file, follow_symlink=false) is Regular else {
      fail("wenyu_context_not_regular")
    }
    let content = @fs.read_file(file).text()
    context.push(
      "Context " +
      relative +
      " sha256=" +
      @native_work.digest(content) +
      "\n" +
      content,
    )
  }
  let prompt = context.join("\n\n")
  let before : Map[String, String] = Map([])
  for
    relative in [
      "build/CODE_PATCH.md", "build/TEST_RESULTS.md", "build/CODE_BLOCKERS.md",
    ] {
    before[relative] = native_output_fingerprint(entry.workspace_root, relative)
  }
  let launch : WenyuLaunch = {
    schema: "moontown.wenyu.launch.v1",
    execution,
    native_path,
    entry,
    task,
    output_before: before,
    request: {
      kind: "wenyu_build",
      work_key: "wenyu_build:" +
      entry.id +
      ":" +
      @native_work.digest(objective) +
      ":" +
      task.id,
      generation: 0,
      owner_workspace: @storage.moontown_active_workspace_root(),
      book_id: entry.id,
      book_root: entry.workspace_root,
      book_type: "wenyu",
      catalog_path,
      execution_root: @native_work.source_root(binding),
      source_binding: binding,
      criterion_id: task.id,
      model_request: model,
      prompt,
      input_blocker: blocker,
      input_digest: @native_work.digest(prompt),
      output_contract: "wenyu.build.native-result.v1",
      result_path: entry.workspace_root + "/build/CODE_PATCH.md",
      acceptance_policy: policy,
      created_at_ms: @env.now(),
    },
  }
  @support.ensure_parent_directory(path)
  @fs.write_file(
    path,
    launch.to_json().stringify(indent=2),
    create_mode=CreateNew,
    permission=0o600,
    sync=Full,
  )
  wenyu_sync_ancestors(path)
  launch
}

///|
pub async fn load_wenyu_launch(path : String) -> WenyuLaunch {
  guard @fs.kind(path, follow_symlink=false) is Regular &&
    @fs.realpath(path) == path else {
    fail("wenyu_launch_not_canonical")
  }
  let launch : WenyuLaunch = @json.from_json(
    @json.parse(@fs.read_file(path).text()),
  )
  guard launch.schema == "moontown.wenyu.launch.v1" &&
    ["native", "acp"].contains(launch.execution) &&
    launch.entry.id == launch.request.book_id &&
    launch.entry.workspace_root == launch.request.book_root &&
    launch.task.id == launch.request.criterion_id &&
    launch.request.input_digest == @native_work.digest(launch.request.prompt) &&
    path == wenyu_launch_path(launch.native_path, launch.task.id) else {
    fail("wenyu_launch_identity_invalid")
  }
  launch
}

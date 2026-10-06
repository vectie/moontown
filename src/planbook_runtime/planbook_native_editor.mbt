///|
/// Capture only owner-selected Book inputs. This never grants the native
/// source worker filesystem access to the course or PlanBook roots.
async fn prepare_native_editor_owner(
  criterion_id : String,
  workspace_root : String,
  catalog_path : String,
) -> @native_work.EditorOwnerSpec {
  let catalog = @moonbook.load_or_create_catalog(path=catalog_path)
  let course_id = @course_book.default_wenyu_course_book_id()
  let course = match @moonbook.find_catalog_entry(catalog, course_id) {
    Some(entry) => entry
    None => fail("editor_course_binding_missing")
  }
  let inputs : Array[@native_work.EditorCapturedInput] = []
  let course_pages = if criterion_id == "editor-selected-feature-implementation" {
    [
      "wiki/course/beginner-course.md", "wiki/course/exercises.md", "wiki/course/progress-rubric.md",
    ]
  } else {
    ["wiki/course/beginner-course.md"]
  }
  for relative in course_pages {
    let path = @native_work.editor_owner_file(course.workspace_root, relative)
    if !@fs.exists(path) {
      fail("editor_course_input_missing: " + relative)
    }
    if @fs.kind(path, follow_symlink=false) != Regular {
      fail("editor_course_input_not_regular: " + relative)
    }
    let content = @fs.read_file(path).text()
    if content.trim() == "" {
      fail("editor_course_input_empty: " + relative)
    }
    inputs.push({
      book_id: course.id,
      root: course.workspace_root,
      relative,
      content,
      content_digest: @native_work.digest(content),
    })
  }
  let plan_relative = @native_work.editor_owner_plan_relative()
  let plan_path = @native_work.editor_owner_file(workspace_root, plan_relative)
  let plan_exists = @fs.exists(plan_path)
  if plan_exists {
    if @fs.kind(plan_path, follow_symlink=false) != Regular {
      fail("editor_plan_input_not_regular")
    }
    let content = @fs.read_file(plan_path).text()
    if content.trim() == "" {
      fail("editor_plan_input_empty")
    }
    inputs.push({
      book_id: default_planbook_book_id(),
      root: workspace_root,
      relative: plan_relative,
      content,
      content_digest: @native_work.digest(content),
    })
  }
  let before : Map[String, String] = Map([])
  for
    relative in [
      "raw/repair/repair-result.md", "raw/repair/repair-result.md.native-receipt.json",
    ] {
    before[relative] = @native_work.editor_owner_fingerprint(
      workspace_root, relative,
    )
  }
  let selection_content = if criterion_id ==
    "editor-selected-feature-implementation" {
    let relative = "raw/editor-pipeline/next-feature.json"
    let path = @native_work.editor_owner_file(workspace_root, relative)
    if !@fs.exists(path) {
      fail("editor_selection_missing")
    }
    if @fs.kind(path, follow_symlink=false) != Regular {
      fail("editor_selection_not_regular")
    }
    before["raw/editor-pipeline/selected-feature-implementation.md"] = @native_work.editor_owner_fingerprint(
      workspace_root, "raw/editor-pipeline/selected-feature-implementation.md",
    )
    @fs.read_file(path).text()
  } else {
    ""
  }
  let selection = if criterion_id == "editor-selected-feature-implementation" {
    match @editor_pipeline.parse_native_selection(selection_content) {
      Some(selection) => Some(selection)
      None => fail("editor_selection_invalid")
    }
  } else {
    None
  }
  let missing_plan_template = if criterion_id == "editor-mode-real-pipeline" &&
    !plan_exists {
    before[plan_relative] = "absent"
    @planbook.editor_pipeline_plan_markdown()
  } else {
    ""
  }
  {
    contract: "planbook.editor.owner-output.v1",
    criterion_id,
    plan_id: "2026-05-31-editor-mode-real-pipeline",
    selection_content,
    selection_digest: if selection is Some(_) {
      @native_work.digest(selection_content)
    } else {
      ""
    },
    selected_feature: selection.map(item => item.selected_feature).unwrap_or(""),
    title: selection.map(item => item.title).unwrap_or(""),
    implementation_hint: selection
    .map(item => item.implementation_hint)
    .unwrap_or(""),
    acceptance: selection.map(item => item.acceptance).unwrap_or([]),
    captured_inputs: inputs,
    output_before: before,
    missing_plan_template,
  }
}

///|
fn native_editor_policy(
  policy : Json,
  spec : @native_work.EditorOwnerSpec,
) -> Json {
  if policy is Object(fields) {
    fields["editor_owner_output"] = spec.to_json()
    // Both native editor criteria inspect UI source. Freeze its separate module
    // build along with focused owner/consumer tests before enqueue/reservation.
    let commands : Array[String] = [
      "moon fmt", "moon info", "moon check --no-render", "moon test src/planbook_runtime/planbook_autonomy_wbtest.mbt src/live_autonomy_runtime/live_autonomy_wbtest.mbt --no-render",
      "moon test src/editor_pipeline src/editor_runtime src/native_work --no-render",
      "moon test --no-render", "moon -C src/ui/rabbita-town build --target js --release",
      "git diff --check",
    ]
    fields["required_validation_commands"] = commands.to_json()
    if fields.get("completion_policy") is Some(Object(completion)) {
      completion["required_checks"] = commands
        .mapi((index, command) => {
          (
            {
              "id": "check-" + (index + 1).to_string(),
              "tool": "shell",
              "command": command,
              "cwd": ".",
              "exit_code": 0,
            } : Json)
        })
        .to_json()
    }
  }
  policy
}

///|
fn native_editor_context(spec : @native_work.EditorOwnerSpec) -> String {
  let lines = [
    "Editor owner handoff: all Book pages below are captured read-only inputs, not additional readable/writable native roots. Work only in the frozen source execution root. Never write the course, selection JSON, PlanBook plan or result pages; MoonTown applies the fixed owner outputs after evidence validation.",
    "Owner criterion: " + spec.criterion_id,
    "Selected feature: " +
    spec.selected_feature +
    " selection_sha256=" +
    spec.selection_digest,
  ]
  for input in spec.captured_inputs {
    lines.push(
      "Captured Book " +
      input.book_id +
      " path=" +
      input.relative +
      " sha256=" +
      input.content_digest +
      "\n" +
      input.content,
    )
  }
  if spec.selection_content != "" {
    lines.push("Captured complete selection JSON:\n" + spec.selection_content)
  }
  if spec.missing_plan_template != "" {
    lines.push(
      "MoonTown will create the missing editor plan from this frozen template after verified engineering settlement:\n" +
      spec.missing_plan_template,
    )
  }
  lines.join("\n\n")
}

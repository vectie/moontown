///|
/// Owner-captured, read-only Book content. Roots are provenance, never native
/// execution roots or extra writable scopes.
pub(all) struct EditorCapturedInput {
  book_id : String
  root : String
  relative : String
  content : String
  content_digest : String
} derive(ToJson, FromJson)

///|
pub(all) struct EditorOwnerSpec {
  contract : String
  criterion_id : String
  plan_id : String
  selection_content : String
  selection_digest : String
  selected_feature : String
  title : String
  implementation_hint : String
  acceptance : Array[String]
  captured_inputs : Array[EditorCapturedInput]
  output_before : Map[String, String]
  missing_plan_template : String
} derive(ToJson, FromJson)

///|
pub fn editor_owner_plan_relative() -> String {
  "plans/2026-05-31-editor-mode-real-pipeline/plan.md"
}

///|
pub fn editor_owner_enabled(criterion : String) -> Bool {
  ["editor-mode-real-pipeline", "editor-selected-feature-implementation"].contains(
    criterion,
  )
}

///|
fn editor_owner_opted_in(request : Request) -> Bool {
  field(request.acceptance_policy, "editor_owner_output") != Json::null()
}

///|
fn editor_spec(request : Request) -> EditorOwnerSpec? {
  if request.kind != "planbook_repair" ||
    request.output_contract != "planbook.editor.native-result.v1" {
    return None
  }
  let spec : EditorOwnerSpec = @json.from_json(
    field(request.acceptance_policy, "editor_owner_output"),
  ) catch {
    _ => return None
  }
  if spec.contract != "planbook.editor.owner-output.v1" ||
    !editor_owner_enabled(spec.criterion_id) ||
    spec.criterion_id != request.criterion_id ||
    spec.plan_id != "2026-05-31-editor-mode-real-pipeline" ||
    spec.captured_inputs.is_empty() {
    return None
  }
  for input in spec.captured_inputs {
    if input.book_id == "" ||
      input.root == "" ||
      input.relative == "" ||
      input.content_digest != digest(input.content) ||
      input.content.trim() == "" {
      return None
    }
  }
  let required = [
    "raw/repair/repair-result.md", "raw/repair/repair-result.md.native-receipt.json",
  ]
  for relative in required {
    if !spec.output_before.contains(relative) {
      return None
    }
  }
  if spec.criterion_id == "editor-selected-feature-implementation" {
    guard @editor_pipeline.parse_native_selection(spec.selection_content)
      is Some(selection) &&
      spec.selection_digest == digest(spec.selection_content) &&
      spec.selected_feature == selection.selected_feature &&
      spec.title == selection.title &&
      spec.implementation_hint == selection.implementation_hint &&
      spec.acceptance == selection.acceptance &&
      spec.missing_plan_template == "" &&
      spec.output_before.length() == 3 &&
      spec.output_before.contains(
        "raw/editor-pipeline/selected-feature-implementation.md",
      ) else {
      return None
    }
  } else {
    if spec.selection_content != "" ||
      spec.selection_digest != "" ||
      spec.selected_feature != "" ||
      !spec.acceptance.is_empty() {
      return None
    }
    if spec.missing_plan_template != "" {
      if spec.output_before.length() != 3 ||
        spec.output_before.get(editor_owner_plan_relative()) != Some("absent") {
        return None
      }
    } else if spec.output_before.length() != 2 {
      return None
    }
  }
  Some(spec)
}

///|
fn editor_finish_schema(work : Work) -> Json {
  let spec = editor_spec(work.request).unwrap()
  {
    "contract": "planbook.editor.native-result.v1",
    "work_id": work.id,
    "book_id": work.request.book_id,
    "criterion_id": spec.criterion_id,
    "selected_feature": spec.selected_feature,
    "selection_digest": spec.selection_digest,
    "outcome": "implemented",
    "summary": "Describe the validated engineering implementation",
    "acceptance_evidence": spec.acceptance.map(item => {
      (
        {
          "acceptance": item,
          "explanation": "Explain the observed behavior and limitations; owner verifies native check evidence separately",
        } : Json)
    }),
    "residual_risks": [],
  }
}

///|
fn editor_reserved_prompt(work : Work) -> String {
  work.request.prompt +
  "\n\nReturn exactly this owner-issued finish JSON schema with your summary, acceptance explanations and residual risks. No extra keys, Markdown fences or worker-chosen output paths:\n" +
  editor_finish_schema(work).stringify() +
  "\nUse outcome implemented only for an attested source mutation. When the frozen completion_policy permits verified no_change, use outcome no_change and preserve its structured checkpoint/finish completion evidence; original-task acceptance stays unevaluated. Never create a mutation merely to finish. MoonTown applies owner documents, never the worker.\n"
}

///|
fn editor_result_satisfies_contract(
  work : Work,
  answer : String,
  no_change : Bool,
) -> Bool {
  let spec = match editor_spec(work.request) {
    Some(spec) => spec
    None => return false
  }
  if answer.length() > 1_000_000 {
    return false
  }
  let result = @json.parse(answer, max_nesting_depth=5) catch {
    _ => return false
  }
  guard result is Object(fields) && fields.length() == 10 else { return false }
  // Reject duplicate root fields rather than relying on last-member-wins JSON.
  let mut depth = 0
  let mut quoted = false
  let mut escaped = false
  let mut members = 0
  for character in answer {
    if quoted {
      if escaped {
        escaped = false
      } else if character == '\\' {
        escaped = true
      } else if character == '"' {
        quoted = false
      }
    } else if character == '"' {
      quoted = true
    } else if character == '{' || character == '[' {
      depth += 1
    } else if character == '}' || character == ']' {
      depth -= 1
    } else if character == ':' && depth == 1 {
      members += 1
    }
  }
  if members != 10 ||
    text(result, "contract") != work.request.output_contract ||
    text(result, "work_id") != work.id ||
    text(result, "book_id") != work.request.book_id ||
    text(result, "criterion_id") != spec.criterion_id ||
    text(result, "selected_feature") != spec.selected_feature ||
    text(result, "selection_digest") != spec.selection_digest ||
    text(result, "outcome") !=
    (if no_change { "no_change" } else { "implemented" }) ||
    text(result, "summary").trim() == "" {
    return false
  }
  guard field(result, "acceptance_evidence") is Array(evidence) &&
    field(result, "residual_risks") is Array(risks) &&
    evidence.length() == spec.acceptance.length() &&
    risks.all(item => item is String(_)) else {
    return false
  }
  for index, item in evidence {
    guard item is Object(fields) &&
      fields.length() == 2 &&
      text(item, "acceptance") == spec.acceptance[index] &&
      text(item, "explanation").trim() != "" else {
      return false
    }
  }
  true
}

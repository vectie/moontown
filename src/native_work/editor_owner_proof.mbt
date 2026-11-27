///|
/// Frozen artifacts from one validated applied package. Archive callers use
/// these bytes rather than rereading mutable selection/proof files after I/O.
#derive(Debug, Eq)
pub(all) struct EditorAppliedFeature {
  selected_feature : String
  selection_content : String
  implementation_content : String
}

///|
/// Read-only proof consumer shared by editor readiness, lifecycle and archival.
/// Invalid native proof returns None and must not fall back to manual/ACP text.
pub async fn editor_applied_feature(book_root : String) -> String? {
  editor_applied_feature_artifacts(book_root).map(item => item.selected_feature)
}

///|
pub async fn editor_applied_feature_artifacts(
  book_root : String,
) -> EditorAppliedFeature? {
  read_editor_applied_feature(book_root) catch {
    _ => None
  }
}

///|
#warnings("-reserved_keyword")
async fn read_editor_applied_feature(root : String) -> EditorAppliedFeature? {
  let proof_relative = "raw/editor-pipeline/selected-feature-implementation.md"
  let proof_path = editor_owner_file(root, proof_relative)
  guard @fs.kind(proof_path, follow_symlink=false) is Regular else {
    return None
  }
  let proof = @fs.read_file(proof_path).text()
  let fields : Map[String, String] = Map([])
  // Only the fixed header is authoritative. Prose/evidence below cannot add or
  // replace identities, and duplicate header fields are never accepted.
  for line in proof.split("\n") {
    if line == "" {
      break
    }
    let split = line.find(": ")
    guard split is Some(index) else { return None }
    let key = line[:index].to_owned()
    if fields.contains(key) {
      return None
    }
    fields[key] = line[index + 2:].to_owned()
  }
  guard fields.get("native_owner_contract") ==
    Some("planbook.editor.owner-output.v1") &&
    fields.get("contract") ==
    Some(@editor_pipeline.selected_feature_implementation_contract()) &&
    fields.get("implementation_status") == Some("accepted") &&
    fields.get("engineering_status") == Some("applied_and_validated") &&
    fields.get("owner_work_id") is Some(work_id) else {
    return None
  }
  let directory = editor_owner_directory(work_id)
  guard fields.get("application_receipt") ==
    Some(directory + "/application-receipt.json") else {
    return None
  }
  let package_path = editor_owner_file(root, directory + "/output-package.json")
  let receipt_path = editor_owner_file(
    root,
    directory + "/application-receipt.json",
  )
  guard @fs.kind(package_path, follow_symlink=false) is Regular &&
    @fs.kind(receipt_path, follow_symlink=false) is Regular else {
    return None
  }
  let pkg_val : EditorOutputPackage = @json.from_json(
    @json.parse(@fs.read_file(package_path).text()),
  )
  let work = editor_package_work(pkg_val)
  guard pkg_val.contract == "planbook.editor.output-package.v1" &&
    pkg_val.work_id == work_id &&
    pkg_val.request.book_root == root &&
    editor_spec(pkg_val.request) is Some(spec) &&
    spec.criterion_id == "editor-selected-feature-implementation" &&
    editor_evidence_bound(work) &&
    text(pkg_val.engineering_receipt, "engineering_status") ==
    "applied_and_validated" &&
    ToJson::to_json(pkg_val) ==
    ToJson::to_json(editor_owner_package(work, spec)) &&
    pkg_val.pages.get(proof_relative) == Some(proof) &&
    @json.parse(@fs.read_file(receipt_path).text()) ==
    editor_application_receipt(pkg_val) else {
    return None
  }
  // A same-ID selection with changed acceptance is a different owner input.
  if editor_owner_fingerprint(root, "raw/editor-pipeline/next-feature.json") !=
    spec.selection_digest {
    return None
  }
  Some({
    selected_feature: spec.selected_feature,
    selection_content: spec.selection_content,
    implementation_content: proof,
  })
}

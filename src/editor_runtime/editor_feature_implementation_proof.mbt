///|
/// Native owner proof must be checked against its selection, accepted package,
/// and exact application receipt. Retained native provenance also selects this
/// fail-closed path if the owner marker has been damaged or removed.
async fn editor_accepted_feature_from_proof(
  workspace_root : String,
  proof : String,
) -> String? {
  if editor_proof_has_native_provenance(proof) {
    return @native_work.editor_applied_feature(workspace_root)
  }
  if !proof.contains(
      "contract: \{@editor_pipeline.selected_feature_implementation_contract()}",
    ) ||
    !proof.contains("implementation_status: accepted") {
    return None
  }
  markdown_field_value(proof, "selected_feature")
}

///|
fn editor_proof_has_native_provenance(proof : String) -> Bool {
  [
    "native_owner_contract", "owner_work_id:", "owner_request_digest:", "native_session_id:",
    "native_command_id:", "native_request_body_digest:", "application_receipt:",
  ].any(field => proof.contains(field))
}

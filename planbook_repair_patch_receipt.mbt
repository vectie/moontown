///|
async fn planbook_latest_repair_patch_receipt_ready(
  workspace_root : String,
) -> Bool {
  planbook_repair_source_patch_receipt_text_ready(
    read_text_or_empty(
      planbook_repair_result_path_for_workspace(workspace_root),
    ),
  ) ||
  planbook_repair_source_patch_receipt_text_ready(
    read_text_or_empty(planbook_repair_superseded_result_path(workspace_root)),
  ) ||
  planbook_repair_source_patch_receipt_from_index_ready(workspace_root)
}

///|
async fn planbook_repair_source_patch_receipt_from_index_ready(
  workspace_root : String,
) -> Bool {
  let criterion_id = "planbook-source-patch-loop"
  let run_ids = planbook_repair_run_ids_for_criterion(
    workspace_root, criterion_id,
  )
  for offset in 0..<run_ids.length() {
    let run_id = run_ids[run_ids.length() - offset - 1]
    match moonclaw_run_result_payload_from_run(run_id, workspace_root) {
      Some(payload) =>
        if @planbook_policy.repair_payload_has_valid_patch_receipt(
            payload,
            criterion_id,
            planbook_repair_source_root(),
            run_id,
          ) {
          return true
        }
      _ => ()
    }
  }
  false
}

///|
fn planbook_repair_source_patch_receipt_text_ready(text : String) -> Bool {
  planbook_repair_result_has_accepted_decision(text) &&
  @planbook_policy.repair_result_records_validation_passes(text) &&
  @planbook_policy.repair_text_has_valid_patch_receipt(
    text,
    "planbook-source-patch-loop",
    planbook_repair_source_root(),
  )
}

///|
async fn planbook_repair_run_ids_for_criterion(
  workspace_root : String,
  criterion_id : String,
) -> Array[String] {
  let path = planbook_repair_job_proposals_path(workspace_root)
  if !@fs.exists(path) {
    return []
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch { _ => return [] }
  match parsed {
    Object(root) =>
      match root.get("proposals") {
        Some(Array(proposals)) => {
          let run_ids : Array[String] = []
          for item in proposals {
            match item {
              Object(proposal) => {
                let request_text = json_object_string(proposal, "request_text").unwrap_or(
                  "",
                )
                if request_text.contains("Open criterion: `\{criterion_id}`") {
                  match json_object_string(proposal, "id") {
                    Some(proposal_id) =>
                      for
                        run_id in planbook_repair_run_ids_for_proposal(
                          workspace_root, proposal_id,
                        ) {
                        if !run_ids.contains(run_id) {
                          run_ids.push(run_id)
                        }
                      }
                    None => ()
                  }
                  match json_object_string(proposal, "last_run_id") {
                    Some(run_id) if !run_ids.contains(run_id) =>
                      run_ids.push(run_id)
                    None => ()
                    _ => ()
                  }
                }
              }
              _ => ()
            }
          }
          run_ids
        }
        _ => []
      }
    _ => []
  }
}

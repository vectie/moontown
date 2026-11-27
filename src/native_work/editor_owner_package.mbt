///|
#derive(ToJson, FromJson)
struct EditorOutputPackage {
  contract : String
  work_id : String
  request_digest : String
  request : Request
  reservation : Reservation
  engineering_receipt : Json
  output : String
  pages : Map[String, String]
  before : Map[String, String]
}

///|
fn editor_owner_package(
  work : Work,
  spec : EditorOwnerSpec,
) -> EditorOutputPackage raise {
  let engineering = editor_engineering_receipt(work.receipt)
  let no_change = text(engineering, "engineering_status") == "no_change"
  let pages : Map[String, String] = Map([])
  pages["raw/repair/repair-result.md.native-receipt.json"] = engineering.stringify(
    indent=2,
  )
  pages["raw/repair/repair-result.md"] = "contract: planbook.repair.result.v1\ncriterion_id: " +
    spec.criterion_id +
    "\nrepair_decision: " +
    (if no_change { "no_change" } else { "accepted" }) +
    "\nengineering_status: " +
    text(engineering, "engineering_status") +
    "\ncommit_status: not_requested\npush_status: not_requested\npush_performed: unknown\npublication_verification: not_verified\n" +
    (if no_change {
      "native_receipt_contract: planbook.repair.native_no_change_receipt.v1\noriginal_task_acceptance: unevaluated\nacceptance_scope: engineering_only\n"
    } else {
      ""
    }) +
    "native_owner_contract: planbook.editor.owner-output.v1\nowner_work_id: " +
    work.id +
    "\n\nWorker explanation (native engineering evidence is recorded separately):\n" +
    work.output +
    "\n"
  if spec.missing_plan_template != "" {
    pages[editor_owner_plan_relative()] = spec.missing_plan_template
  }
  if spec.criterion_id == "editor-selected-feature-implementation" && !no_change {
    let reservation = work.reservation.unwrap()
    let answer = @json.parse(work.output)
    let lines = [
      "contract: " + @editor_pipeline.selected_feature_implementation_contract(),
      "native_owner_contract: planbook.editor.owner-output.v1",
      "selected_feature: " + spec.selected_feature,
      "selection_digest: " + spec.selection_digest,
      "implementation_status: accepted",
      "engineering_status: applied_and_validated",
      "acceptance_scope: engineering_implementation",
      "original_task_acceptance: unevaluated",
      "owner_work_id: " + work.id,
      "owner_request_digest: " + work.request_digest,
      "native_session_id: " + reservation.session_id,
      "native_command_id: " + reservation.command_id,
      "native_request_body_digest: " + reservation.body_digest,
      "checked_source_digest: " + text(engineering, "checked_source_digest"),
      "application_receipt: " +
      editor_owner_directory(work.id) +
      "/application-receipt.json",
      "",
      "# Selected Feature Engineering Implementation",
      "",
      spec.title,
      "",
      text(answer, "summary"),
      "",
      "## Frozen acceptance observations",
      "",
    ]
    for item in rows(answer, "acceptance_evidence") {
      lines.push(
        "- " + text(item, "acceptance") + "\n  " + text(item, "explanation"),
      )
    }
    lines.push("\n## Captured course and plan provenance\n")
    for input in spec.captured_inputs {
      lines.push(
        "- Book " +
        input.book_id +
        " / " +
        input.relative +
        " sha256=" +
        input.content_digest,
      )
    }
    lines.push(
      "\n## Verified native engineering evidence\n\n```json\n" +
      engineering.stringify(indent=2) +
      "\n```",
    )
    lines.push(
      "\n## Residual risks\n\n" +
      field(answer, "residual_risks").stringify(indent=2),
    )
    lines.push(
      "\nThis records validated engineering implementation. It does not certify customer acceptance or semantic Review.\n",
    )
    pages["raw/editor-pipeline/selected-feature-implementation.md"] = lines.join(
      "\n",
    )
  }
  {
    contract: "planbook.editor.output-package.v1",
    work_id: work.id,
    request_digest: work.request_digest,
    request: work.request,
    reservation: work.reservation.unwrap(),
    engineering_receipt: engineering,
    output: work.output,
    pages,
    before: spec.output_before,
  }
}

///|
fn editor_evidence_bound(work : Work) -> Bool {
  let engineering = editor_engineering_receipt(work.receipt)
  let status = text(engineering, "engineering_status")
  guard work.state == "completed" &&
    work.request_digest == digest(ToJson::to_json(work.request).stringify()) &&
    work.request.input_digest == digest(work.request.prompt) &&
    work.id == "town-work-" + work.request_digest[:32].to_owned() &&
    work.request.result_path ==
    work.request.book_root + "/raw/repair/repair-result.md" &&
    ["applied_and_validated", "no_change"].contains(status) &&
    editor_result_satisfies_contract(work, work.output, status == "no_change") &&
    work.reservation is Some(reservation) else {
    return false
  }
  let expected_contract = if status == "no_change" {
    "planbook.repair.native_no_change_receipt.v1"
  } else {
    "planbook.repair.native_patch_receipt.v1"
  }
  text(engineering, "contract") == expected_contract &&
  text(engineering, "request_id") == work.id &&
  text(engineering, "request_digest") == work.request_digest &&
  text(engineering, "criterion_id") == work.request.criterion_id &&
  text(engineering, "book_root") == work.request.book_root &&
  text(engineering, "source_root") == work.request.execution_root &&
  text(engineering, "output_digest") == digest(work.output) &&
  text(engineering, "session_id") == reservation.session_id &&
  text(engineering, "command_id") == reservation.command_id &&
  text(engineering, "model") == reservation.model &&
  text(engineering, "model_workspace") == reservation.model_workspace &&
  text(engineering, "request_body_digest") == reservation.body_digest &&
  reservation.session_id == work.id &&
  reservation.command_id == work.id + "-repair" &&
  reservation.body_digest == digest(reservation.request_body) &&
  reservation.execution_root == work.request.execution_root &&
  reservation.model_workspace == work.request.owner_workspace
}

///|
#warnings("-reserved_keyword")
fn editor_package_work(pkg_val : EditorOutputPackage) -> Work {
  {
    id: pkg_val.work_id,
    request: pkg_val.request,
    request_digest: pkg_val.request_digest,
    reservation: Some(pkg_val.reservation),
    state: "completed",
    blocked_reason: "",
    control: None,
    baseline: field(pkg_val.engineering_receipt, "baseline"),
    observed_instances: [],
    last_attempt_at_ms: 0UL,
    retry_after_ms: 0UL,
    output: pkg_val.output,
    receipt: pkg_val.engineering_receipt,
  }
}

///|
#warnings("-reserved_keyword")
fn editor_application_receipt(pkg_val : EditorOutputPackage) -> Json {
  let spec = editor_spec(pkg_val.request).unwrap()
  let hashes : Map[String, String] = Map([])
  for relative, content in pkg_val.pages {
    hashes[relative] = digest(content)
  }
  {
    "contract": "planbook.editor.application-receipt.v1",
    "status": "applied",
    "work_id": pkg_val.work_id,
    "request_digest": pkg_val.request_digest,
    "book_id": pkg_val.request.book_id,
    "criterion_id": pkg_val.request.criterion_id,
    "selection_digest": spec.selection_digest,
    "package_digest": digest(ToJson::to_json(pkg_val).stringify()),
    "engineering_receipt_digest": digest(
      pkg_val.engineering_receipt.stringify(),
    ),
    "engineering_status": text(
      pkg_val.engineering_receipt,
      "engineering_status",
    ),
    "session_id": pkg_val.reservation.session_id,
    "command_id": pkg_val.reservation.command_id,
    "request_body_digest": pkg_val.reservation.body_digest,
    "document_digests": hashes,
  }
}

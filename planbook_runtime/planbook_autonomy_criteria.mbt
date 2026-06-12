///|
async fn planbook_autonomy_criteria(
  snapshot_path : String,
  workspace_root : String,
  book_catalog_path : String,
) -> Array[PlanbookCriterionStatus] {
  [
    planbook_workspace_criterion(workspace_root),
    planbook_live_spine_criterion(),
    planbook_editor_pipeline_criterion(workspace_root),
    planbook_ui_operator_criterion(),
    planbook_result_contract_criterion(),
    planbook_semantic_review_criterion(snapshot_path, book_catalog_path),
    planbook_runtime_book_quality_coverage_criterion(
      snapshot_path, book_catalog_path,
    ),
    planbook_editor_feature_selection_criterion(workspace_root),
    planbook_editor_selected_feature_implementation_criterion(workspace_root),
    planbook_source_patch_loop_criterion(workspace_root),
    planbook_engineering_loop_criterion(workspace_root),
    planbook_implementation_backlog_criterion(workspace_root),
    planbook_validation_criterion(snapshot_path),
    planbook_runtime_recovery_criterion(snapshot_path),
    planbook_civic_service_reconciliation_criterion(book_catalog_path),
    planbook_moonbook_provider_criterion(),
    planbook_app_tool_book_template_criterion(),
  ]
}

///|
fn planbook_backlog_target_files_for_criterion(
  criterion_id : String,
  source_root : String,
) -> Array[String] {
  @planbook_policy.backlog_target_files_for_criterion(criterion_id, source_root)
}

///|
fn planbook_backlog_criterion_for_item(
  item : PlanbookImplementationBacklogItem,
  workspace_root : String,
) -> PlanbookCriterionStatus {
  ignore(workspace_root)
  planbook_criterion(
    @planbook_policy.backlog_criterion_id(item.id),
    item.source_plan,
    "Backlog: \{item.title}",
    item.owner,
    false,
    @planbook_policy.backlog_criterion_evidence(item),
    @planbook_policy.backlog_criterion_next_action(item),
  )
}

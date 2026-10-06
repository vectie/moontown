///|
pub async fn complete_wenyu_build_artifacts_if_needed(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  execution : @core.TaskExecutionRecord,
) -> @core.TaskExecutionRecord {
  if execution.output_contract == "wenyu.build.native-result.v1" {
    return execution
  }
  if !@build_pipeline.is_wenyu_book(entry) {
    return execution
  }
  match task.kind {
    "implementation-backlog" => {
      write_wenyu_implementation_backlog(entry, task)
      copy_execution_with(
        execution,
        status=Completed,
        output_contract="wenyu.build.local-result.v1",
        summary="MoonTown locally materialized implementation backlog and acceptance tests for \{entry.id}; implementation still requires execution and review.",
      )
    }
    "code-patch" => {
      if execution.status is Completed {
        return execution
      }
      write_wenyu_code_patch_record(entry, task, execution)
      copy_execution_with(
        execution,
        status=ReviewQueued,
        summary="MoonTown materialized a code-patch handoff and blocker record for \{entry.id}; MoonCode/MoonClaw execution did not produce a repository patch in this run.",
      )
    }
    "image-asset" => {
      let summary = write_wenyu_asset_pack_record(entry, task)
      copy_execution_with(
        execution,
        status=ReviewQueued,
        output_contract="wenyu.build.local-result.v1",
        summary~,
      )
    }
    _ => execution
  }
}

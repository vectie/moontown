///|
pub async fn complete_wenyu_build_artifacts_if_needed(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  execution : @core.TaskExecutionRecord,
) -> @core.TaskExecutionRecord {
  if !@build_pipeline.is_wenyu_book(entry) {
    return execution
  }
  match task.kind {
    "implementation-backlog" => {
      write_wenyu_implementation_backlog(entry, task)
      copy_execution_with(
        execution,
        status=Completed,
        summary="MoonTown materialized implementation backlog and acceptance tests for \{entry.id} after the Wenyu build controller returned no writable artifacts.",
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
      write_wenyu_asset_pack_record(entry, task)
      copy_execution_with(
        execution,
        status=Completed,
        summary="MoonTown materialized module-specific asset prompts and an asset manifest for \{entry.id} after the Wenyu build controller returned no writable artifacts.",
      )
    }
    _ => execution
  }
}

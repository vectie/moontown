///|
async fn write_wenyu_code_patch_record(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  execution : @core.TaskExecutionRecord,
) -> Unit {
  let root = @moonbook.workspace_root(entry)
  let module_name = wenyu_module_name(entry)
  write_wenyu_code_patch_handoff(root, task, module_name)
  write_wenyu_code_blockers(root, module_name, execution)
  write_wenyu_code_test_results(root, module_name)
}

///|
async fn write_wenyu_code_patch_handoff(
  root : String,
  task : @moonbook.BookTask,
  module_name : String,
) -> Unit {
  @support.write_text_file(
    "\{root}/build/CODE_PATCH.md",
    [
      "# \{module_name} Code Patch Handoff",
      "",
      "- Task: `\{task.id}`",
      "- Target repository: `/Users/kq/Workspace/moontown`",
      "- Status: blocked before repository patch",
      "",
      "## Intended Patch",
      "",
      "- Add or update Wenyu district projection in `ui/rabbita-town`.",
      "- Surface this module's build/readiness state in the live town dashboard.",
      "- Preserve Moontown as orchestration/UI, MoonBook as memory/wiki, and MoonClaw/OpenClaw as executor.",
      "",
      "## Validation To Run After Patch",
      "",
      "- `/Users/kq/.moon/bin/moon test`",
      "- `/Users/kq/.moon/bin/moon check`",
      "- UI build command for `ui/rabbita-town` if UI files change.",
    ].join("\n"),
  )
}

///|
async fn write_wenyu_code_blockers(
  root : String,
  module_name : String,
  execution : @core.TaskExecutionRecord,
) -> Unit {
  @support.write_text_file(
    "\{root}/build/CODE_BLOCKERS.md",
    [
      "# \{module_name} Code Execution Blockers",
      "",
      "The Wenyu build controller did not produce a repository patch in this run.",
      "",
      "## Runtime Summary",
      "",
      execution.summary,
      "",
      "## Required Fix",
      "",
      "- Configure the MoonClaw/OpenClaw Codex ACP target with write access to `/Users/kq/Workspace/moontown`.",
      "- Dispatch code-patch tasks to that ACP target instead of a read-only or book-only analysis runner.",
      "- Rerun this task after the target can edit files and run validation.",
    ].join("\n"),
  )
}

///|
async fn write_wenyu_code_test_results(
  root : String,
  module_name : String,
) -> Unit {
  @support.write_text_file(
    "\{root}/build/TEST_RESULTS.md",
    [
      "# \{module_name} Test Results",
      "",
      "- Code patch status: blocked before repository edit.",
      "- Tests run by this fallback: none.",
      "- Required next validation: run MoonBit tests/checks and UI build after Codex ACP applies the patch.",
    ].join("\n"),
  )
}

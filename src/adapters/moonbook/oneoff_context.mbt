///|
/// A caller-owned frozen workspace without Book schedules, writes or memory.
pub fn oneoff_context(
  book_id : String,
  workspace_root : String,
  task_id : String,
  prompt : String,
  context_pages : Array[String],
) -> WorkerContextBundle {
  {
    book_id,
    workspace_root,
    task_id,
    prompt,
    policy: ["Frozen source input only"],
    routines: [],
    skill_paths: ["skills/oneoff/SKILL.md"],
    context_pages,
    active_memory: [],
    user_memory: [],
    working_memory: [],
    memory_summary: "One-off collaboration; no persistent Book memory",
    output_contract: [
      "Return a source-cited UTF-8 contribution with limits and unresolved objections.",
    ],
  }
}

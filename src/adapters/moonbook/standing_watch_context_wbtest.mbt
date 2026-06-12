///|
test "standing watch context is not mistaken for research bootstrap" {
  let entry = moonbook_adapter_opc_research_entry()
  let bundle = WorkerContextBundle::{
    book_id: "research-opc",
    workspace_root: "/tmp/research-opc",
    task_id: "standing-watch-opc-news-tick-3",
    prompt: "This is a MoonBook-owned 24/7 standing-watch cycle. Research OPC, compare wiki history, wiki/sources, and raw/bootstrap baseline only as context. standing_goal_decision: update | no_change | needs_review | failed",
    policy: [],
    routines: [],
    skill_paths: ["skills/standing-watch/SKILL.md"],
    context_pages: ["history/standing-watch.md", "raw/bootstrap/"],
    active_memory: [],
    user_memory: [],
    working_memory: [],
    memory_summary: "watch baseline",
    output_contract: ["standing_goal_decision"],
  }
  let clean = enrich_worker_context_bundle(entry, bundle)
  assert_true(clean.prompt.contains("24/7 standing-watch"))
  assert_true(clean.skill_paths.contains("skills/standing-watch/SKILL.md"))
  assert_true(clean.output_contract.join("\n").contains("new_source_count"))
  assert_true(clean.output_contract.join("\n").contains("book_changed"))
  assert_true(!clean.prompt.contains("raw research bootstrap handoff"))
  assert_true(!clean.skill_paths.contains("skills/wiki-marketing/SKILL.md"))
}

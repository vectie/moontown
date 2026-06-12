///|
test "research bootstrap context is sanitized for direct MoonClaw worker" {
  let entry = moonbook_adapter_opc_research_entry()
  let bundle = WorkerContextBundle::{
    book_id: "research-opc",
    workspace_root: "/tmp/research-opc",
    task_id: "goal-research-opc-research-bootstrap-ingest",
    prompt: "Loaded skill excerpts and local source hints for moonbook /Users/kq/Workspace/moonbook",
    policy: [],
    routines: [],
    skill_paths: [
      "skills/wiki-ingest/SKILL.md", "skills/repo-source-materialize/SKILL.md",
    ],
    context_pages: ["wiki/sources", "/Users/kq/Workspace/moonbook/README.md"],
    active_memory: [],
    user_memory: [],
    working_memory: [],
    memory_summary: "dirty",
    output_contract: ["Return exactly one JSON object."],
  }
  let clean = enrich_worker_context_bundle(entry, bundle)
  assert_true(clean.prompt.contains("raw research bootstrap handoff"))
  assert_true(clean.output_contract.join("\n").contains("plain Markdown"))
  assert_true(clean.skill_paths.contains("skills/web-first-research/SKILL.md"))
  assert_true(
    !clean.skill_paths.contains("skills/repo-source-materialize/SKILL.md"),
  )
  assert_true(
    !clean.context_pages.contains("/Users/kq/Workspace/moonbook/README.md"),
  )
  assert_true(!clean.prompt.contains("/Users/kq/Workspace/moonbook"))
}

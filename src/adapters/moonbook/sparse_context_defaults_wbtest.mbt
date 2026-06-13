///|
test "sparse worker context gets keeper-safe defaults before MoonClaw import" {
  let entry = moonbook_adapter_catalog_entry(
    id="coding",
    name="Coding",
    purpose="Keep coding workspace healthy",
    workspace_root="/tmp/coding",
  )
  let task = moonbook_adapter_task(
    id="coding-synthesis",
    title="Synthesize coding memory",
    kind="synthesis",
    prompt="Review the protocol and keep harness memory healthy.",
    priority=80,
    requires_review=true,
  )
  let bundle = WorkerContextBundle::{
    book_id: "coding",
    workspace_root: "/tmp/coding",
    task_id: "coding-synthesis",
    prompt: "Review coding memory.",
    policy: [],
    routines: [],
    skill_paths: [],
    context_pages: [],
    active_memory: [],
    user_memory: [],
    working_memory: [],
    memory_summary: "empty sparse bundle",
    output_contract: [],
  }
  let clean = finalize_worker_context_bundle(entry, task, bundle)
  assert_true(
    clean.context_pages == @moonbook_contracts.default_keeper_context_pages(),
  )
  assert_true(
    clean.skill_paths == @moonbook_contracts.default_keeper_skill_paths(),
  )
}

///|
test "sparse worker context prefers book skills and task target pages" {
  let entry = moonbook_adapter_catalog_entry(
    id="finance",
    name="Finance",
    purpose="Maintain finance memory",
    workspace_root="/tmp/finance",
    skills=["skills/ledger-review/SKILL.md"],
  )
  let task = moonbook_adapter_task(
    id="finance-synthesis",
    title="Synthesize finance memory",
    kind="synthesis",
    prompt="Review the ledger workflow.",
    priority=80,
    requires_review=true,
    target_pages=["wiki/synthesis/overview.md"],
  )
  let bundle = WorkerContextBundle::{
    book_id: "finance",
    workspace_root: "/tmp/finance",
    task_id: "finance-synthesis",
    prompt: "Review finance memory.",
    policy: [],
    routines: [],
    skill_paths: ["  "],
    context_pages: [""],
    active_memory: [],
    user_memory: [],
    working_memory: [],
    memory_summary: "empty sparse bundle",
    output_contract: [],
  }
  let clean = finalize_worker_context_bundle(entry, task, bundle)
  assert_true(clean.context_pages == ["wiki/synthesis/overview.md"])
  assert_true(clean.skill_paths == ["skills/ledger-review/SKILL.md"])
}

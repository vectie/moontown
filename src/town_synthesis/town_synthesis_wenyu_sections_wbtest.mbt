///|
test "Wenyu executive summary fragments preserve lane ownership story" {
  let mayor = @roles.Mayor::new()
  let plan = mayor.plan_goal(
    @moonbook.default_catalog(),
    "Build Wenyu Valley AI Innovation Town according to docs/WENYU_VALLEY_PRD.md",
  )
  assert_true(
    wenyu_parallel_lane_summary(plan).contains("isolated civic product books"),
  )
  assert_true(wenyu_lane_input_summary().contains("Wenyu PRD"))
  assert_true(wenyu_product_build_map_summary().contains("Town Shell owns"))
  assert_true(
    wenyu_product_build_map_summary().contains("Physical Bridge owns"),
  )
}

///|
test "Wenyu synthesis routing consumes policy goal vocabulary" {
  let mayor = @roles.Mayor::new()
  let plan = mayor.plan_goal(@moonbook.default_catalog(), "ordinary town work")
  assert_true(
    is_wenyu_town_synthesis_plan(
      "Build Wenyu Valley AI Innovation Town according to docs/WENYU_VALLEY_PRD.md",
      plan,
    ),
  )
  assert_true(!is_wenyu_town_synthesis_plan("ordinary town work", plan))
  let civic_entry = @moonbook.BookCatalogEntry::new(
    id="wenyu-policy-hall",
    name="Policy Hall",
    purpose="civic protocol exchange",
    workspace_root="/tmp/wenyu-policy-hall",
  )
  let civic_plan = @roles.MayorGoalPlan::new(
    output_contract="mayor.goal.decomposition.v1",
    prompt="ordinary town work",
    parallelizable=true,
    summary="contains civic protocol lane",
    lanes=[
      @roles.MayorGoalLane::new(
        entry=civic_entry,
        objective="ordinary town work",
        rationale="policy-owned civic protocol capability",
      ),
    ],
  )
  assert_true(is_wenyu_town_synthesis_plan("ordinary town work", civic_plan))
}

///|
test "Wenyu architecture graph renders mayor to lane to operator path" {
  let mayor = @roles.Mayor::new()
  let plan = mayor.plan_goal(
    @moonbook.default_catalog(),
    "Build Wenyu Valley AI Innovation Town according to docs/WENYU_VALLEY_PRD.md",
  )
  let graph = render_wenyu_architecture_graph(plan)
  assert_true(graph.contains("```mermaid"))
  assert_true(graph.contains("Mayor claw in Moontown"))
  assert_true(graph.contains("Wenyu Valley / Town Shell"))
  assert_true(graph.contains("Town-level build synthesis"))
  assert_true(graph.contains("Operator-visible Wenyu roadmap"))
}

///|
test "Wenyu artifact and readiness rows use canonical workspace paths and counts" {
  let mayor = @roles.Mayor::new()
  let plan = mayor.plan_goal(
    @moonbook.default_catalog(),
    "Build Wenyu Valley AI Innovation Town according to docs/WENYU_VALLEY_PRD.md",
  )
  let entry = plan.lanes[0].entry
  let artifact = wenyu_artifact_matrix_row(entry)
  assert_true(artifact.contains("raw/bootstrap/deep-report.md"))
  assert_true(artifact.contains("raw/bootstrap/evidence-matrix.md"))
  assert_true(artifact.contains("wiki/Home.md"))
  let summary = @moonbook.BookStateSummary::new(
    book_id=entry.id,
    root=@moonbook.workspace_root(entry),
    page_count=9,
    source_count=5,
    verified_source_count=4,
    entity_count=3,
    concept_count=2,
    pending_review_count=0,
    keeper_memory_count=1,
    keeper_working_count=1,
    evidence_count=7,
    operational_evidence_count=2,
    substantive_coverage_ready=true,
    summary="ready",
  )
  let readiness = wenyu_readiness_row(entry.id, "complete", "ready", summary)
  assert_true(
    readiness.contains("| \{entry.id} | complete | 4 | 7 | 2 | 3 | 2 | ready |"),
  )
}

///|
test "Wenyu next build plan is numbered and keeps mayor authority boundary" {
  let steps = wenyu_next_build_steps()
  assert_eq(steps.length(), 5)
  let mayor = @roles.Mayor::new()
  let plan = mayor.plan_goal(
    @moonbook.default_catalog(),
    "Build Wenyu Valley AI Innovation Town according to docs/WENYU_VALLEY_PRD.md",
  )
  let rendered = render_wenyu_next_build_plan(plan)
  assert_true(rendered.contains("1. Promote each lane"))
  assert_true(rendered.contains("5. Keep the mayor loop responsible"))
  assert_true(rendered.contains("Lane count for next planning pass: 11."))
}

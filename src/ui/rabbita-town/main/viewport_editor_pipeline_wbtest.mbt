///|
test "editor pipeline stage status tone groups runtime states" {
  assert_true(editor_pipeline_stage_status_tone("ready") is Ready)
  assert_true(editor_pipeline_stage_status_tone("completed") is Ready)
  assert_true(editor_pipeline_stage_status_tone("running") is Review)
  assert_true(editor_pipeline_stage_status_tone("dispatched") is Review)
  assert_true(editor_pipeline_stage_status_tone("failed") is Alert)
  assert_true(editor_pipeline_stage_status_tone("stale") is Alert)
  assert_true(editor_pipeline_stage_status_tone("missing") is Alert)
  assert_true(editor_pipeline_stage_status_tone("unknown") is Neutral)
}

///|
test "editor lifecycle status tone keeps accepted as live state" {
  assert_true(editor_lifecycle_status_tone("ready-to-export") is Ready)
  assert_true(editor_lifecycle_status_tone("accepted") is Live)
  assert_true(editor_lifecycle_status_tone("running") is Review)
  assert_true(editor_lifecycle_status_tone("blocked") is Alert)
  assert_true(editor_lifecycle_status_tone("planned") is Neutral)
  assert_true(editor_lifecycle_status_tone("unknown") is Neutral)
}

///|
test "editor lifecycle labels stay concise without overstating unknown results" {
  assert_eq(editor_lifecycle_label("ready-to-export"), "待导出")
  assert_eq(editor_lifecycle_label("accepted"), "已接收")
  assert_eq(editor_lifecycle_label("running"), "进行中")
  assert_eq(editor_lifecycle_label("blocked"), "需处理")
  assert_eq(editor_lifecycle_label("planned"), "待开始")
  assert_eq(editor_lifecycle_label("succeeded-but-unrecognized"), "待确认")
}

///|
test "construction plan keeps its status visible and technical references secondary" {
  let lifecycle : EditorPipelineLifecycleSnapshot = {
    change_id: "private-change-id",
    selected_feature: "调整入口",
    title: "入口布局",
    lifecycle_status: "blocked",
    summary: "需要确认建筑入口。",
    course_ref: "private-course-ref",
    plan_ref: "private-plan-ref",
    repair_ref: "private-repair-ref",
    output_ref: "private-output-ref",
  }
  let primary = disclosure_test_html(
    render_editor_pipeline_lifecycle(lifecycle),
  )
  assert_true(primary.contains("入口布局"))
  assert_true(primary.contains("需处理"))
  assert_true(primary.contains("需要确认建筑入口"))
  assert_false(primary.contains("private-"))
  assert_false(primary.contains("已完成"))
}

///|
test "missing construction plan is not represented as ready or an executable repair" {
  let model = { ..init_model(), editor_pipeline: None, }
  let html = disclosure_test_html(render_editor_pipeline_panel(model))
  let primary = html.split("<details").to_array()[0]
  assert_true(primary.contains("建设计划"))
  assert_true(primary.contains("尚未载入"))
  assert_false(primary.contains("moon run"))
  assert_false(primary.contains("已完成"))
  assert_false(html.contains(" open"))
}

///|
test "editor status class adapters preserve css class contract" {
  assert_eq(editor_pipeline_stage_class("ready"), "artifact-status-ready")
  assert_eq(editor_pipeline_stage_class("running"), "artifact-status-review")
  assert_eq(editor_pipeline_stage_class("failed"), "artifact-status-alert")
  assert_eq(editor_pipeline_stage_class("unknown"), "artifact-status-neutral")
  assert_eq(
    editor_lifecycle_status_class("ready-to-export"),
    "artifact-status-ready",
  )
  assert_eq(editor_lifecycle_status_class("accepted"), "artifact-status-live")
  assert_eq(editor_lifecycle_status_class("blocked"), "artifact-status-alert")
}

///|
fn editor_style_candidate_fixture(
  status~ : String = "running",
  selected~ : Bool = false,
) -> EditorPipelineStyleCandidateSnapshot {
  {
    style_id: "white-tech",
    title: "White Tech Pavilion",
    status,
    evidence_ref: "docs/style.md",
    asset_ref: "assets/style.png",
    rationale: "clean civic technology",
    tradeoff: "less playful",
    selected,
  }
}

///|
test "editor style candidate class uses shared selected suffix policy" {
  assert_eq(
    editor_pipeline_style_candidate_class(
      editor_style_candidate_fixture(status="running", selected=false),
    ),
    "editor-pipeline-stage artifact-status-review",
  )
  assert_eq(
    editor_pipeline_style_candidate_class(
      editor_style_candidate_fixture(status="completed", selected=true),
    ),
    "editor-pipeline-stage artifact-status-ready is-selected-style",
  )
}

///|
test "editor style candidate status label separates selected candidates" {
  assert_eq(
    editor_pipeline_style_candidate_status(
      editor_style_candidate_fixture(status="running", selected=false),
    ),
    "running",
  )
  assert_eq(
    editor_pipeline_style_candidate_status(
      editor_style_candidate_fixture(status="completed", selected=true),
    ),
    "selected",
  )
}

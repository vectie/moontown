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

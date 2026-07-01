///|
test "feature selection contracts are stable" {
  assert_eq(
    feature_selection_result_contract(),
    "moontown.editor_feature_selection.v1",
  )
  assert_eq(
    selected_feature_implementation_contract(),
    "moontown.editor_selected_feature_implementation.v1",
  )
}

///|
test "feature selection predicate rejects weak outputs" {
  assert_true(
    feature_selection_result_satisfies_contract(
      "{\"contract\":\"moontown.editor_feature_selection.v1\",\"selected_feature\":\"road-editor\",\"score\":1,\"implementation_hint\":\"patch\",\"acceptance\":[\"visible\"]}",
    ),
  )
  assert_false(
    feature_selection_result_satisfies_contract(
      "{\"contract\":\"moontown.editor_feature_selection.v1\",\"selected_feature\":\"road-editor\"}",
    ),
  )
}

///|
test "style metadata maps known styles and labels unknown slugs" {
  assert_eq(style_title("white-tech-pavilion"), "White Tech Pavilion")
  assert_eq(
    style_asset_ref("white-tech-pavilion"),
    "ui/assets/tilemap/buildings/white-tech-pavilion/alpha",
  )
  assert_eq(style_title("custom-glass-hub"), "Custom Glass Hub")
  assert_eq(style_asset_ref("custom-glass-hub"), "ui/assets/tilemap/buildings")
}

///|
test "pipeline markdown renders canonical sections" {
  let lifecycle : EditorPipelineLifecycleRecord = {
    change_id: "change-1",
    selected_feature: "style-comparison-workbench",
    title: "Style Workbench",
    lifecycle_status: "ready-to-export",
    summary: "Validated.",
    course_ref: "course.md",
    plan_ref: "plan.md",
    repair_ref: "repair.md",
    output_ref: "viewport.html",
  }
  let selection : EditorPipelineStyleSelectionRecord = {
    target_module_id: "policy-hall",
    target_module_title: "Policy Hall",
    selected_style_id: "white-tech-pavilion",
    selected_style_title: "White Tech Pavilion",
    status: "selected",
    decision_ref: "style.md",
    critique: "Fits civic tech.",
  }
  let state : EditorPipelineState = {
    contract: "moontown.editor_pipeline.v1",
    status: "ready",
    source_course_book: "course-wenyu-game-design",
    source_course_page: "course.md",
    planbook_id: "plan-moontown-quality",
    plan_id: "plan-1",
    repair_status: "accepted",
    editor_mode_url: "editor.html",
    output_mode_url: "output.html",
    generated_at_ms: 1,
    stages: [
      {
        id: "course-source",
        title: "Course Source",
        status: "ready",
        summary: "Course exists.",
        evidence: "course.md",
      },
    ],
    lifecycle,
    movement_loops: [],
    placement_diffs: [],
    terrain_layers: [],
    terrain_reasons: [],
    style_candidates: [
      {
        style_id: "white-tech-pavilion",
        title: "White Tech Pavilion",
        status: "ready",
        evidence_ref: "style.md",
        asset_ref: "assets",
        rationale: "Modern civic style.",
        tradeoff: "Needs contrast.",
        selected: true,
      },
    ],
    style_selection: selection,
  }
  let text = render_pipeline_markdown(state)
  assert_true(text.contains("# Editor Pipeline Status"))
  assert_true(text.contains("## Lifecycle"))
  assert_true(text.contains("## Style Comparison Workbench"))
  assert_true(text.contains("White Tech Pavilion"))
}

///|
test "stage policy marks ready only when required editor proof is complete" {
  let lifecycle : EditorPipelineLifecycleRecord = {
    change_id: "change-1",
    selected_feature: "movement-loop-evidence",
    title: "Movement Loop",
    lifecycle_status: "ready-to-export",
    summary: "Ready.",
    course_ref: "course.md",
    plan_ref: "plan.md",
    repair_ref: "repair.md",
    output_ref: "viewport.html",
  }
  let inputs : EditorPipelineStageInputs = {
    course_page: "course.md",
    plan_path: "plan.md",
    feature_selection_result_path: "next-feature.json",
    repair_task_path: "repair-task.json",
    module_config_ref: "modules.json",
    placement_proposal_path: "placement.json",
    course_ready: true,
    plan_ready: true,
    command_ready: true,
    ui_ready: true,
    repair_status: "accepted",
    feature_selection_status: "ready",
    feature_selection_summary: "selection exists",
    lifecycle,
    feature_history_ready: true,
    movement_loop_ready: true,
    placement_diff_ready: true,
    terrain_label_ready: true,
    style_comparison_ready: true,
  }
  assert_eq(pipeline_status(inputs), "ready")
  let stages = pipeline_stages(inputs)
  assert_eq(stages.length(), 11)
  assert_true(
    stages.any(fn(stage) {
      stage.id == "movement-loop-evidence" &&
      stage.status == "ready" &&
      stage.evidence == "modules.json"
    }),
  )
  assert_true(
    stages.any(fn(stage) {
      stage.id == "building-protocol-history" &&
      stage.evidence.contains(
        ".moonsuite/products/moontown/civic/protocols/<building-id>/*.jsonl",
      )
    }),
  )
}

///|
test "selected feature stage policy keeps unrelated missing work idle" {
  let lifecycle : EditorPipelineLifecycleRecord = {
    change_id: "change-1",
    selected_feature: "placement-diff-preview",
    title: "Placement Diff",
    lifecycle_status: "running",
    summary: "Running.",
    course_ref: "course.md",
    plan_ref: "plan.md",
    repair_ref: "repair.md",
    output_ref: "viewport.html",
  }
  assert_eq(
    selected_feature_stage_status(false, lifecycle, "movement-loop-evidence"),
    "idle",
  )
  assert_eq(
    selected_feature_stage_status(false, lifecycle, "placement-diff-preview"),
    "missing",
  )
  assert_eq(
    selected_feature_stage_status(true, lifecycle, "placement-diff-preview"),
    "ready",
  )
}

///|
test "feature selection prompt policy is evidence-first and non-hardcoded" {
  let target_files = ["course.md", "CURRENT_UI_EVIDENCE.md"]
  let text = feature_selection_request_text("next-feature.json", target_files)
  assert_true(
    text.contains(
      "You are the AI feature rater for Moontown's Wenyu editor-mode pipeline.",
    ),
  )
  assert_true(
    text.contains("Read the absolute `skills/editor-feature-rater/SKILL.md`"),
  )
  assert_true(text.contains("Prefer `CURRENT_UI_EVIDENCE.md`"))
  assert_true(text.contains("Do not rely on a hardcoded candidate list"))
  assert_true(text.contains("FEATURE_SELECTION_CONTEXT.md"))
  assert_true(text.contains("Score each remaining candidate from 1 to 10"))
  assert_true(text.contains("Select the lowest-scoring remaining candidate"))
  assert_true(text.contains("Do not edit source code in this step."))
  assert_true(text.contains("Write JSON to `next-feature.json`"))
  assert_true(text.contains("- `course.md`"))
  assert_true(text.contains("- `CURRENT_UI_EVIDENCE.md`"))
}

///|
test "feature selection profile prompt uses the shared contract" {
  let text = feature_selection_profile_prompt_template()
  assert_true(text.contains("Read skill_paths and context_pages"))
  assert_true(text.contains(feature_selection_result_contract()))
  assert_true(text.contains("FEATURE_SELECTION_CONTEXT.md"))
  assert_true(text.contains("Do not edit source code in this step."))
}

///|
test "selection policy gates only the selected feature" {
  let lifecycle : EditorPipelineLifecycleRecord = {
    change_id: "change-1",
    selected_feature: "style-comparison-workbench",
    title: "Style Workbench",
    lifecycle_status: "running",
    summary: "Running.",
    course_ref: "course.md",
    plan_ref: "plan.md",
    repair_ref: "repair.md",
    output_ref: "viewport.html",
  }
  let selected : EditorPipelineStyleCandidateRecord = {
    style_id: "white-tech-pavilion",
    title: "White Tech Pavilion",
    status: "ready",
    evidence_ref: "style.md",
    asset_ref: "assets",
    rationale: "Fits civic tech.",
    tradeoff: "Needs contrast.",
    selected: true,
  }
  let rejected : EditorPipelineStyleCandidateRecord = {
    style_id: "cartoon-town",
    title: "Cartoon Town",
    status: "ready",
    evidence_ref: "style.md",
    asset_ref: "assets",
    rationale: "Warm.",
    tradeoff: "Too playful.",
    selected: false,
  }
  let selection : EditorPipelineStyleSelectionRecord = {
    target_module_id: "policy-hall",
    target_module_title: "Policy Hall",
    selected_style_id: "white-tech-pavilion",
    selected_style_title: "White Tech Pavilion",
    status: "selected",
    decision_ref: "style.md",
    critique: "Fits civic tech.",
  }
  assert_eq(
    selected_style_candidate([rejected, selected]).unwrap().style_id,
    "white-tech-pavilion",
  )
  assert_true(
    style_comparison_ready(lifecycle, [rejected, selected, rejected], selection),
  )
  assert_false(style_comparison_ready(lifecycle, [selected], selection))
  assert_true(movement_loop_ready(lifecycle, []))
  assert_true(placement_diff_ready(lifecycle, []))
  assert_true(terrain_label_ready(lifecycle, [], []))
}

///|
test "selected feature readiness requires matching evidence" {
  let lifecycle : EditorPipelineLifecycleRecord = {
    change_id: "change-1",
    selected_feature: "terrain-label-map",
    title: "Terrain Labels",
    lifecycle_status: "running",
    summary: "Running.",
    course_ref: "course.md",
    plan_ref: "plan.md",
    repair_ref: "repair.md",
    output_ref: "viewport.html",
  }
  let layer : EditorPipelineTerrainLayerRecord = {
    layer_id: "water",
    title: "Water",
    status: "labeled",
    evidence_ref: "reference-map",
    summary: "River and lake labels.",
  }
  let reason : EditorPipelineTerrainReasonRecord = {
    module_id: "bridge",
    module_title: "Bridge",
    terrain_layer: "roads",
    status: "labeled",
    placement_ref: "tile:1,2/3x4",
    reason: "Bridge sits on a road crossing.",
  }
  assert_false(terrain_label_ready(lifecycle, [], []))
  assert_true(terrain_label_ready(lifecycle, [layer], [reason]))
  assert_true(
    placement_diff_ready(
      { ..lifecycle, selected_feature: "placement-diff-preview" },
      [
        {
          module_id: "policy-hall",
          module_title: "Policy Hall",
          change_kind: "moved",
          status: "reviewable",
          before_ref: "tile:1,1/3x4",
          after_ref: "tile:2,2/3x4",
          entrance_ref: "tile:2,6",
          terrain_status: "reviewable:entrance-and-footprint-present",
          reason: "review placement",
        },
      ],
    ),
  )
  assert_false(
    movement_loop_ready(
      { ..lifecycle, selected_feature: "movement-loop-evidence" },
      [],
    ),
  )
}

///|
test "module policy builds movement placement and terrain records" {
  let current : EditorPipelineModulePlacement = {
    id: "policy-hall",
    enabled: true,
    title: "Policy Hall",
    book_id: "wenyu-policy-hall",
    district: "civic-core",
    building_kind: "pavilion",
    grid_x: 10,
    grid_y: 20,
    footprint_w: 3,
    footprint_h: 4,
    entrance_x: 11,
    entrance_y: 24,
    style_family: "white-tech-pavilion",
  }
  let moved : EditorPipelineModulePlacement = { ..current, grid_x: 12 }
  let loops = movement_loop_records([current])
  assert_eq(loops.length(), 1)
  assert_eq(loops[0].status, "ready")
  assert_eq(loops[0].entrance_ref, "tile:11,24")
  let diffs = placement_diff_records([current], [moved])
  assert_eq(diffs.length(), 1)
  assert_eq(diffs[0].change_kind, "moved")
  assert_eq(diffs[0].before_ref, "tile:10,20/3x4")
  assert_eq(diffs[0].after_ref, "tile:12,20/3x4")
  let layers = terrain_layers_for_modules([current])
  assert_true(layers.any(fn(layer) { layer.layer_id == "districts" }))
  let reasons = terrain_reason_records([current])
  assert_eq(reasons.length(), 1)
  assert_eq(reasons[0].terrain_layer, "districts")
  assert_eq(selected_style_family([current]), "white-tech-pavilion")
}

///|
test "module policy handles blocked and added or removed placements" {
  let blocked : EditorPipelineModulePlacement = {
    id: "future-module",
    enabled: true,
    title: "Future Module",
    book_id: "",
    district: "future",
    building_kind: "lab",
    grid_x: -1,
    grid_y: 2,
    footprint_w: 0,
    footprint_h: 4,
    entrance_x: -1,
    entrance_y: -1,
    style_family: "",
  }
  assert_eq(first_enabled_module([blocked]).unwrap().id, "future-module")
  assert_eq(selected_style_family([blocked]), "white-tech-pavilion")
  let loops = movement_loop_records([blocked])
  assert_eq(loops[0].status, "blocked")
  assert_true(loops[0].missing_reason.contains("missing book/home binding"))
  let added = placement_diff_records([], [blocked])
  assert_eq(added[0].change_kind, "added")
  assert_true(added[0].terrain_status.has_prefix("blocked"))
  let removed = placement_diff_records([blocked], [])
  assert_eq(removed[0].change_kind, "removed")
  let reasons = terrain_reason_records([blocked])
  assert_eq(reasons[0].status, "blocked")
  assert_eq(reasons[0].terrain_layer, "future-civic-module-land")
}

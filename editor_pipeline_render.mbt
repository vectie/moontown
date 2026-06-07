///|
fn render_editor_pipeline_markdown(state : EditorPipelineState) -> String {
  let lines = [
    "# Editor Pipeline Status",
    "",
    "- contract: `\{state.contract}`",
    "- status: `\{state.status}`",
    "- source_course_book: `\{state.source_course_book}`",
    "- source_course_page: `\{state.source_course_page}`",
    "- planbook_id: `\{state.planbook_id}`",
    "- plan_id: `\{state.plan_id}`",
    "- repair_status: `\{state.repair_status}`",
    "- editor_mode_url: `\{state.editor_mode_url}`",
    "- output_mode_url: `\{state.output_mode_url}`",
    "- lifecycle_status: `\{state.lifecycle.lifecycle_status}`",
    "- selected_feature: `\{state.lifecycle.selected_feature}`",
    "",
    "## Lifecycle",
    "",
    "- change_id: `\{state.lifecycle.change_id}`",
    "- title: \{state.lifecycle.title}",
    "- summary: \{state.lifecycle.summary}",
    "- course_ref: `\{state.lifecycle.course_ref}`",
    "- plan_ref: `\{state.lifecycle.plan_ref}`",
    "- repair_ref: `\{state.lifecycle.repair_ref}`",
    "- output_ref: `\{state.lifecycle.output_ref}`",
    "",
    "## Stages",
    "",
  ]
  for stage in state.stages {
    lines.push(
      "- `\{stage.id}` / `\{stage.status}`: \{stage.title} - \{stage.summary} Evidence: `\{stage.evidence}`",
    )
  }
  lines.push("")
  lines.push("## Movement Loop Evidence")
  lines.push("")
  if state.movement_loops.is_empty() {
    lines.push("- No Wenyu module movement loops are available.")
  } else {
    for loop_record in state.movement_loops {
      lines.push(
        "- `\{loop_record.module_id}` / `\{loop_record.status}`: home `\{loop_record.home_ref}` -> entrance `\{loop_record.entrance_ref}` -> output `\{loop_record.output_ref}` -> return `\{loop_record.return_ref}`. \{loop_record.missing_reason}",
      )
    }
  }
  lines.push("")
  lines.push("## Terrain Label Map")
  lines.push("")
  if state.terrain_layers.is_empty() {
    lines.push("- No terrain label layers are available.")
  } else {
    for layer_record in state.terrain_layers {
      lines.push(
        "- `\{layer_record.layer_id}` / `\{layer_record.status}`: \{layer_record.title}. \{layer_record.summary} Evidence: `\{layer_record.evidence_ref}`",
      )
    }
  }
  lines.push("")
  lines.push("### Module Terrain Reasons")
  lines.push("")
  if state.terrain_reasons.is_empty() {
    lines.push("- No module terrain reasons are available.")
  } else {
    for reason_record in state.terrain_reasons {
      lines.push(
        "- `\{reason_record.module_id}` / `\{reason_record.status}`: layer `\{reason_record.terrain_layer}` at `\{reason_record.placement_ref}`. \{reason_record.reason}",
      )
    }
  }
  lines.push("")
  lines.push("## Style Comparison Workbench")
  lines.push("")
  lines.push(
    "- target_module: `\{state.style_selection.target_module_id}` / \{state.style_selection.target_module_title}",
  )
  lines.push(
    "- selected_style: `\{state.style_selection.selected_style_id}` / \{state.style_selection.selected_style_title}",
  )
  lines.push("- status: `\{state.style_selection.status}`")
  lines.push("- critique: \{state.style_selection.critique}")
  lines.push("")
  if state.style_candidates.is_empty() {
    lines.push("- No style candidates are available.")
  } else {
    for candidate in state.style_candidates {
      lines.push(
        "- `\{candidate.style_id}` / `\{candidate.status}` / selected=`\{candidate.selected}`: \{candidate.title}. \{candidate.rationale} Tradeoff: \{candidate.tradeoff} Evidence: `\{candidate.evidence_ref}` Asset: `\{candidate.asset_ref}`",
      )
    }
  }
  lines.push("")
  lines.push("## Placement Diff Preview")
  lines.push("")
  if state.placement_diffs.is_empty() {
    lines.push("- No placement diff records are available.")
  } else {
    for diff_record in state.placement_diffs {
      lines.push(
        "- `\{diff_record.module_id}` / `\{diff_record.change_kind}` / `\{diff_record.status}`: before `\{diff_record.before_ref}` -> after `\{diff_record.after_ref}`; entrance `\{diff_record.entrance_ref}`; terrain `\{diff_record.terrain_status}`. \{diff_record.reason}",
      )
    }
  }
  lines.join("\n")
}

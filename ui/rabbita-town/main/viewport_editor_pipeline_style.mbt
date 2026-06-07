///|
fn render_editor_pipeline_style_candidate(
  record : EditorPipelineStyleCandidateSnapshot,
) -> @rabbita.Html {
  article(
    class=editor_pipeline_style_candidate_class(record),
    [
      div(class="handoff-artifact-heading", [
        span(class="handoff-kind", record.style_id),
        span(class="handoff-status", editor_pipeline_style_candidate_status(record)),
      ]),
      h3(record.title),
      p(record.rationale),
      p(record.tradeoff),
      div(class="viewport-output-links", [
        span("Evidence / \{record.evidence_ref}"),
        span("Assets / \{record.asset_ref}"),
      ]),
    ],
  )
}

///|
fn editor_pipeline_style_candidate_class(
  record : EditorPipelineStyleCandidateSnapshot,
) -> String {
  "editor-pipeline-stage \{editor_pipeline_stage_class(record.status)}" +
  class_suffix_when(record.selected, " is-selected-style")
}

///|
fn editor_pipeline_style_candidate_status(
  record : EditorPipelineStyleCandidateSnapshot,
) -> String {
  if record.selected {
    "selected"
  } else {
    record.status
  }
}

///|
fn render_editor_pipeline_style_comparison(
  pipeline : EditorPipelineSnapshot,
) -> @rabbita.Html {
  let candidates : Array[@rabbita.Html] = []
  for record in pipeline.style_candidates {
    candidates.push(render_editor_pipeline_style_candidate(record))
  }
  section(class="editor-pipeline-panel", [
    div(class="viewport-panel-heading", [
      p(class="eyebrow", "Style Comparison Workbench"),
      h2("Compare Building Visual Systems"),
      p(
        "The editor pipeline records at least three visual systems, critiques the tradeoffs, and makes the selected style visible before output export.",
      ),
    ]),
    div(class="viewport-editor-stats", [
      render_module_detail(
        "Target",
        "\{pipeline.style_selection.target_module_title} / \{pipeline.style_selection.target_module_id}",
      ),
      render_module_detail(
        "Selected",
        pipeline.style_selection.selected_style_title,
      ),
      render_module_detail("Status", pipeline.style_selection.status),
      render_module_detail("Decision", pipeline.style_selection.decision_ref),
    ]),
    article(
      class="editor-pipeline-stage \{editor_pipeline_stage_class(pipeline.style_selection.status)}",
      [
        div(class="handoff-artifact-heading", [
          span(class="handoff-kind", pipeline.style_selection.selected_style_id),
          span(class="handoff-status", pipeline.style_selection.status),
        ]),
        h3(pipeline.style_selection.selected_style_title),
        p(pipeline.style_selection.critique),
      ],
    ),
    render_artifact_grid_or_empty(
      candidates, "No Style Candidates", "No style comparison candidates were available from current runtime data.",
    ),
  ])
}

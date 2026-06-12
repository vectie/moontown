///|
fn render_editor_pipeline_placement_diff(
  record : EditorPipelinePlacementDiffSnapshot,
) -> @rabbita.Html {
  article(
    class="editor-pipeline-stage \{editor_pipeline_stage_class(record.status)}",
    [
      div(class="handoff-artifact-heading", [
        span(
          class="handoff-kind",
          "\{record.change_kind} / \{record.module_id}",
        ),
        span(class="handoff-status", record.status),
      ]),
      h3(record.module_title),
      p(record.reason),
      div(class="viewport-output-links", [
        span("Before / \{record.before_ref}"),
        span("After / \{record.after_ref}"),
        span("Entrance / \{record.entrance_ref}"),
        span("Terrain / \{record.terrain_status}"),
      ]),
    ],
  )
}

///|
fn render_editor_pipeline_placement_diffs(
  pipeline : EditorPipelineSnapshot,
) -> @rabbita.Html {
  let diffs : Array[@rabbita.Html] = []
  for record in pipeline.placement_diffs {
    diffs.push(render_editor_pipeline_placement_diff(record))
  }
  section(class="editor-pipeline-panel", [
    div(class="viewport-panel-heading", [
      p(class="eyebrow", "Placement Diff Preview"),
      h2("Review Module Placement Before Export"),
      p(
        "The editor pipeline compares current and proposed building placements, including coordinates, footprint, entrance tile, and terrain readiness.",
      ),
    ]),
    render_artifact_grid_or_empty(
      diffs, "No Placement Diff", "No placement proposal or current module records were available for review.",
    ),
  ])
}

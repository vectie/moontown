///|
fn render_editor_pipeline_movement_loop(
  record : EditorPipelineMovementLoopSnapshot,
) -> @rabbita.Html {
  article(
    class="editor-pipeline-stage \{editor_pipeline_stage_class(record.status)}",
    [
      div(class="handoff-artifact-heading", [
        span(class="handoff-kind", record.module_id),
        span(class="handoff-status", record.status),
      ]),
      h3(record.module_title),
      p(record.missing_reason),
      div(class="viewport-output-links", [
        span("Book / \{record.book_id}"),
        span("Home / \{record.home_ref}"),
        span("Entrance / \{record.entrance_ref}"),
        span("Output / \{record.output_ref}"),
        span("Return / \{record.return_ref}"),
      ]),
    ],
  )
}

///|
fn render_editor_pipeline_movement_loops(
  pipeline : EditorPipelineSnapshot,
) -> @rabbita.Html {
  let loops : Array[@rabbita.Html] = []
  for record in pipeline.movement_loops {
    loops.push(render_editor_pipeline_movement_loop(record))
  }
  section(class="editor-pipeline-panel", [
    div(class="viewport-panel-heading", [
      p(class="eyebrow", "Movement Loop Evidence"),
      h2("Home to Building to Output to Home"),
      p(
        "The editor pipeline publishes route proof from module configuration: book home, building entrance, output surface, and return-home binding.",
      ),
    ]),
    render_artifact_grid_or_empty(
      loops, "No Movement Loops", "No enabled Wenyu modules were available for movement-loop proof.",
    ),
  ])
}

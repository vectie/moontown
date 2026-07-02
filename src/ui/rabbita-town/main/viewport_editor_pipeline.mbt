///|
fn editor_pipeline_stage_class(status : String) -> String {
  artifact_status_tone_class(editor_pipeline_stage_status_tone(status))
}

///|
fn editor_pipeline_stage_status_tone(status : String) -> ArtifactStatusTone {
  match status {
    "ready" | "completed" => Ready
    "running" | "dispatched" => Review
    "failed" | "stale" | "missing" => Alert
    _ => Neutral
  }
}

///|
fn editor_lifecycle_status_class(status : String) -> String {
  artifact_status_tone_class(editor_lifecycle_status_tone(status))
}

///|
fn editor_lifecycle_status_tone(status : String) -> ArtifactStatusTone {
  match status {
    "ready-to-export" => Ready
    "accepted" => Live
    "running" => Review
    "blocked" => Alert
    "planned" => Neutral
    _ => Neutral
  }
}

///|
fn render_editor_pipeline_lifecycle(
  lifecycle : EditorPipelineLifecycleSnapshot,
) -> @rabbita.Html {
  article(
    class="editor-pipeline-stage \{editor_lifecycle_status_class(lifecycle.lifecycle_status)}",
    [
      div(class="handoff-artifact-heading", [
        span(class="handoff-kind", "lifecycle"),
        span(class="handoff-status", lifecycle.lifecycle_status),
      ]),
      h3(lifecycle.title),
      p(lifecycle.summary),
      div(class="viewport-output-links", [
        span("Change / \{lifecycle.change_id}"),
        span("Course / \{lifecycle.course_ref}"),
        span("Plan / \{lifecycle.plan_ref}"),
        span("Repair / \{lifecycle.repair_ref}"),
        span("Output / \{lifecycle.output_ref}"),
      ]),
    ],
  )
}

///|
fn render_editor_pipeline_stage(
  stage : EditorPipelineStageSnapshot,
) -> @rabbita.Html {
  article(
    class="editor-pipeline-stage \{editor_pipeline_stage_class(stage.status)}",
    [
      div(class="handoff-artifact-heading", [
        span(class="handoff-kind", stage.id),
        span(class="handoff-status", stage.status),
      ]),
      h3(stage.title),
      p(stage.summary),
      p(class="handoff-scope", stage.evidence),
    ],
  )
}

///|
fn render_editor_pipeline_panel(model : Model) -> @rabbita.Html {
  match model.editor_pipeline {
    Some(pipeline) => {
      let stages = pipeline.stages.map(render_editor_pipeline_stage)
      section(class="editor-pipeline-panel", [
        div(class="viewport-panel-heading", [
          p(class="eyebrow", "Editor Pipeline"),
          h2("PlanBook to MoonClaw Implementation Loop"),
          p(
            "Editor mode is connected to a runtime contract instead of static prose. The pipeline links the Wenyu course, PlanBook plan, repair status, and final output surface.",
          ),
        ]),
        div(class="viewport-editor-stats", [
          render_module_detail("Contract", pipeline.contract),
          render_module_detail("Status", pipeline.status),
          render_module_detail("Repair", pipeline.repair_status),
          render_module_detail("Plan", pipeline.plan_id),
          render_module_detail("PlanBook", pipeline.planbook_id),
          render_module_detail("Course Book", pipeline.source_course_book),
          render_module_detail("Course Page", pipeline.source_course_page),
          render_module_detail("Lifecycle", pipeline.lifecycle.lifecycle_status),
          render_module_detail("Feature", pipeline.lifecycle.selected_feature),
        ]),
        render_editor_pipeline_lifecycle(pipeline.lifecycle),
        render_editor_pipeline_movement_loops(pipeline),
        render_editor_pipeline_terrain_labels(pipeline),
        render_editor_pipeline_style_comparison(pipeline),
        render_editor_pipeline_placement_diffs(pipeline),
        div(class="handoff-link-row", [
          a(
            href="./editor-pipeline.json",
            class="module-book-link module-book-link-config",
            "Open Pipeline JSON",
          ),
          a(
            href=pipeline.editor_mode_url,
            class="module-book-link module-book-link-config",
            "Editor Mode",
          ),
          a(
            href=pipeline.output_mode_url,
            class="module-book-link module-book-link-config",
            "Final Output",
          ),
        ]),
        div(class="handoff-artifact-grid", stages),
      ])
    }
    None =>
      section(class="editor-pipeline-panel", [
        div(class="viewport-panel-heading", [
          p(class="eyebrow", "Editor Pipeline"),
          h2("Pipeline State Missing"),
          p(
            "Run `moon run src/cmd/main -- editor-pipeline refresh` to publish \{moontown_product_display_artifact_code("editor-pipeline.json")} for editor mode.",
          ),
        ]),
      ])
  }
}

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
fn editor_lifecycle_label(status : String) -> String {
  match status {
    "ready-to-export" => "待导出"
    "accepted" => "已接收"
    "running" => "进行中"
    "blocked" => "需处理"
    "planned" => "待开始"
    _ => "待确认"
  }
}

///|
fn render_editor_pipeline_lifecycle(
  lifecycle : EditorPipelineLifecycleSnapshot,
) -> @rabbita.Html {
  article(
    class="editor-pipeline-stage handoff-artifact-card \{editor_lifecycle_status_class(lifecycle.lifecycle_status)}",
    [
      div(class="handoff-artifact-heading", [
        span(class="handoff-kind", "当前计划"),
        span(
          class="handoff-status",
          editor_lifecycle_label(lifecycle.lifecycle_status),
        ),
      ]),
      h3(lifecycle.title),
      p(
        if lifecycle.lifecycle_status == "blocked" {
          lifecycle.summary
        } else {
          compact_single_line(lifecycle.summary, limit=180)
        },
      ),
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
      section(class="editor-pipeline-panel viewport-editor-boundary", [
        div(class="viewport-panel-heading", [h2("建设计划")]),
        render_editor_pipeline_lifecycle(pipeline.lifecycle),
        div(class="handoff-link-row", [
          a(
            href=pipeline.output_mode_url,
            class="module-book-link module-book-link-config",
            "预览",
          ),
        ]),
        render_advanced_details("建设与执行记录", [
          p(pipeline.lifecycle.summary),
          div(class="viewport-editor-stats", [
            render_module_detail("状态", pipeline.status),
            render_module_detail("修复", pipeline.repair_status),
            render_module_detail("功能", pipeline.lifecycle.selected_feature),
            render_module_detail("协议", pipeline.contract),
            render_module_detail("计划", pipeline.plan_id),
            render_module_detail("PlanBook", pipeline.planbook_id),
            render_module_detail("课程", pipeline.source_course_book),
            render_module_detail("课程页", pipeline.source_course_page),
          ]),
          div(class="viewport-output-links", [
            span("Change / \{pipeline.lifecycle.change_id}"),
            span("Plan / \{pipeline.lifecycle.plan_ref}"),
            span("Repair / \{pipeline.lifecycle.repair_ref}"),
            span("Output / \{pipeline.lifecycle.output_ref}"),
            span("Course / \{pipeline.lifecycle.course_ref}"),
          ]),
          div(class="handoff-artifact-grid", stages),
          render_editor_pipeline_movement_loops(pipeline),
          render_editor_pipeline_terrain_labels(pipeline),
          render_editor_pipeline_style_comparison(pipeline),
          render_editor_pipeline_placement_diffs(pipeline),
          div(class="handoff-link-row", [
            a(
              href=pipeline.editor_mode_url,
              class="module-book-link module-book-link-config",
              "编辑场景",
            ),
            a(
              href="./editor-pipeline.json",
              class="module-book-link module-book-link-config",
              "原始记录",
            ),
          ]),
        ]),
      ])
    }
    None =>
      section(class="editor-pipeline-panel viewport-editor-boundary", [
        div(class="viewport-panel-heading", [
          h2("建设计划"),
          p("尚未载入计划记录。"),
        ]),
        render_advanced_details("计划连接详情", [
          p(
            "建设服务尚未提供计划。请管理员检查服务后重新载入；此处不会自动运行修复。",
          ),
        ]),
      ])
  }
}

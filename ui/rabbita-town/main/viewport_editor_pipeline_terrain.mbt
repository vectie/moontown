///|
fn render_editor_pipeline_terrain_layer(
  record : EditorPipelineTerrainLayerSnapshot,
) -> @rabbita.Html {
  article(
    class="editor-pipeline-stage \{editor_pipeline_stage_class(record.status)}",
    [
      div(class="handoff-artifact-heading", [
        span(class="handoff-kind", record.layer_id),
        span(class="handoff-status", record.status),
      ]),
      h3(record.title),
      p(record.summary),
      p(class="handoff-scope", record.evidence_ref),
    ],
  )
}

///|
fn render_editor_pipeline_terrain_reason(
  record : EditorPipelineTerrainReasonSnapshot,
) -> @rabbita.Html {
  article(
    class="editor-pipeline-stage \{editor_pipeline_stage_class(record.status)}",
    [
      div(class="handoff-artifact-heading", [
        span(
          class="handoff-kind",
          "\{record.terrain_layer} / \{record.module_id}",
        ),
        span(class="handoff-status", record.status),
      ]),
      h3(record.module_title),
      p(record.reason),
      div(class="viewport-output-links", [
        span("Layer / \{record.terrain_layer}"),
        span("Placement / \{record.placement_ref}"),
      ]),
    ],
  )
}

///|
fn render_editor_pipeline_terrain_labels(
  pipeline : EditorPipelineSnapshot,
) -> @rabbita.Html {
  let layers : Array[@rabbita.Html] = []
  for record in pipeline.terrain_layers {
    layers.push(render_editor_pipeline_terrain_layer(record))
  }
  let reasons : Array[@rabbita.Html] = []
  for record in pipeline.terrain_reasons {
    reasons.push(render_editor_pipeline_terrain_reason(record))
  }
  section(class="editor-pipeline-panel", [
    div(class="viewport-panel-heading", [
      p(class="eyebrow", "Terrain Label Map"),
      h2("Map Semantics Before Export"),
      p(
        "The editor pipeline publishes terrain labels and per-building placement reasons so map edits are reviewed against water, roads, districts, farms, forests, and future civic land.",
      ),
    ]),
    render_artifact_grid_or_empty(
      layers, "No Terrain Layers", "No terrain label layers were available from current map/module data.",
    ),
    render_artifact_grid_or_empty(
      reasons, "No Module Terrain Reasons", "No module placement reasons were available for terrain review.",
    ),
  ])
}

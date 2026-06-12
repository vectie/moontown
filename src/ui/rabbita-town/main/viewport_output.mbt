///|
fn render_final_output_book_card(
  projection : BookProjectionFragment,
) -> @rabbita.Html {
  article(class="viewport-output-book-card", [
    div(class="module-book-heading", [
      div([p(class="eyebrow", "MoonBook Output"), h2(projection.title)]),
      span(class="module-book-id", projection.book_id),
    ]),
    p(class="module-book-summary", projection.summary),
    render_projection_chips(projection),
    render_projection_metrics(projection),
    div(class="viewport-output-book-grid", [
      render_projection_item_group(
        "Readiness",
        "No readiness summary was published yet.",
        "readiness",
        projection.readiness,
      ),
      render_projection_item_group(
        "Review Queue",
        "No review queue was published yet.",
        "review",
        projection.review_queue,
      ),
      render_projection_item_group(
        "Page Families",
        "No page-family summary was published yet.",
        "pages",
        projection.page_families,
      ),
      render_projection_links(projection),
    ]),
    render_projection_journey(projection),
  ])
}

///|
fn render_final_output_empty_state() -> @rabbita.Html {
  article(class="viewport-output-empty", [
    h2("No MoonBook Outputs Connected"),
    p(
      "The final-output mode is working, but the browser bridge did not load any `moonbook-ui-state.json` fragments yet.",
    ),
    p(
      "Run a book projection or publish generated MoonBook UI state under `.moontown/books/<book>/book/` to populate this page.",
    ),
  ])
}

///|
fn render_output_lifecycle_panel(model : Model) -> @rabbita.Html {
  match model.editor_pipeline {
    Some(pipeline) =>
      section(class="editor-pipeline-panel", [
        div(class="viewport-panel-heading", [
          p(class="eyebrow", "Output Readiness"),
          h2("Current Change Lifecycle"),
          p(
            "Output mode mirrors the same editor-pipeline lifecycle so operators can see whether a visible artifact is still planned, running, accepted, blocked, or ready to export.",
          ),
        ]),
        div(class="viewport-editor-stats", [
          render_module_detail("Lifecycle", pipeline.lifecycle.lifecycle_status),
          render_module_detail("Feature", pipeline.lifecycle.selected_feature),
          render_module_detail("Repair", pipeline.repair_status),
          render_module_detail("Output", pipeline.lifecycle.output_ref),
        ]),
        render_editor_pipeline_lifecycle(pipeline.lifecycle),
        render_editor_pipeline_movement_loops(pipeline),
        render_editor_pipeline_terrain_labels(pipeline),
        render_editor_pipeline_style_comparison(pipeline),
        render_editor_pipeline_placement_diffs(pipeline),
      ])
    None =>
      section(class="editor-pipeline-panel", [
        div(class="viewport-panel-heading", [
          p(class="eyebrow", "Output Readiness"),
          h2("No Editor-Pipeline Change Yet"),
          p(
            "No editor-pipeline change has been started yet. Publish `editor-pipeline.json` before treating output mode as proof of a completed implementation loop.",
          ),
        ]),
      ])
  }
}

///|
fn render_viewport_output_body(model : Model) -> @rabbita.Html {
  let cards : Array[@rabbita.Html] = []
  for projection in model.module_projections {
    cards.push(render_final_output_book_card(projection))
  }
  section(class="viewport-output-panel", [
    div(class="viewport-panel-heading", [
      p(class="eyebrow", "Final Output Mode"),
      h2("Generated Book Outputs"),
      p(viewport_mode_summary(ViewportMode::OutputMode)),
    ]),
    div(class="viewport-output-stats", [
      render_module_detail(
        "Book Fragments",
        "\{model.module_projections.length()}",
      ),
      render_module_detail(
        "Bound Modules",
        "\{module_projection_count_for_configured_modules(model)}",
      ),
      render_module_detail("Daemon Tick", daemon_tick_label(model)),
      render_module_detail("Civic", civic_status_summary(model)),
      render_module_detail("Local Time", real_time_label()),
    ]),
    render_output_lifecycle_panel(model),
    div(
      class="viewport-output-grid",
      if cards.is_empty() {
        [render_final_output_empty_state()]
      } else {
        cards
      },
    ),
    render_moondesk_handoff_panel(model),
    render_moondesk_bridge_panel(model),
  ])
}

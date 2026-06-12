///|
fn render_town_editor_boundary_panel(model : Model) -> @rabbita.Html {
  section(class="viewport-editor-boundary", [
    div(class="viewport-panel-heading", [
      p(class="eyebrow", "Town-Level Editor"),
      h2("Moontown / Moondesk Boundary"),
      p(
        "Moontown composes modules, books, worker lanes, resource envelopes, and output surfaces. Detailed file, prompt, skill, memory, and single-agent work stays in Moondesk and returns as portable artifacts.",
      ),
    ]),
    div(class="viewport-editor-stats", [
      render_module_detail("Edit Scope", "multi-agent town"),
      render_module_detail("Simple Agent Edit", "role, cadence, capacity"),
      render_module_detail("Deep Agent Edit", "Moondesk"),
      render_module_detail("Bridge", moondesk_root_status_label(model)),
    ]),
    div(class="handoff-link-row", [
      a(
        href="./tilemap/modules/wenyu-town-modules.json",
        class="module-book-link module-book-link-config",
        "Open Module Registry",
      ),
      a(
        href="./tilemap/modules/moondesk-handoff.json",
        class="module-book-link module-book-link-config",
        "Open Handoff Manifest",
      ),
      a(
        href="./moondesk-bridge.json",
        class="module-book-link module-book-link-config",
        "Open Bridge Ledger",
      ),
    ]),
  ])
}

///|
fn render_handoff_contract_items(
  artifact : MoondeskHandoffArtifact,
) -> @rabbita.Html {
  let items : Array[@rabbita.Html] = []
  for contract in artifact.import_contract {
    items.push(span(class="handoff-contract-item", contract))
  }
  if items.is_empty() {
    items.push(
      span(class="handoff-contract-item", "No import contract declared."),
    )
  }
  div(class="handoff-contract-list", items)
}

///|
fn render_handoff_artifact_card(
  artifact : MoondeskHandoffArtifact,
) -> @rabbita.Html {
  article(
    class="handoff-artifact-card \{artifact_status_class(artifact.status)}",
    [
      div(class="handoff-artifact-heading", [
        span(class="handoff-kind", artifact.kind),
        span(class="handoff-status", artifact.status),
      ]),
      h3(artifact.title),
      p(artifact.summary),
      div(class="handoff-path-grid", [
        render_module_detail("Artifact", artifact.id),
        render_module_detail("Source", artifact.source_path),
        render_module_detail("Target", artifact.target_path),
      ]),
      p(class="handoff-scope", artifact.scope),
      render_handoff_contract_items(artifact),
    ],
  )
}

///|
fn render_moondesk_handoff_panel(model : Model) -> @rabbita.Html {
  let artifacts : Array[@rabbita.Html] = []
  for artifact in model.moondesk_handoff_artifacts {
    artifacts.push(render_handoff_artifact_card(artifact))
  }
  section(class="moondesk-handoff-panel", [
    div(class="viewport-panel-heading", [
      p(class="eyebrow", "MoonDesk Import Contract"),
      h2("Portable Artifact Lanes"),
      p(
        "These are the data/config lanes MoonDesk can export into MoonTown. Adding new capability should add or update this manifest before changing viewport code.",
      ),
    ]),
    div(
      class="handoff-artifact-grid",
      if artifacts.is_empty() {
        [
          article(class="viewport-output-empty", [
            h2("No Handoff Artifacts"),
            p("`tilemap/modules/moondesk-handoff.json` did not load."),
          ]),
        ]
      } else {
        artifacts
      },
    ),
  ])
}

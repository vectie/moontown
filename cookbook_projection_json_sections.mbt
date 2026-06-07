///|
fn cookbook_status_chips_json() -> Array[String] {
  [
    cookbook_chip_json("cookbook", "healthy"),
    cookbook_chip_json("moonbook generated", "info"),
    cookbook_chip_json("moondesk managed", "info"),
    cookbook_chip_json("moontown consumed", "review"),
  ]
}

///|
fn cookbook_metrics_json(
  docs_value : String,
  definitions_value : String,
  runtime_value : String,
  missing_value : String,
) -> Array[String] {
  [
    cookbook_metric_json("Docs", docs_value, "canonical documents", "healthy"),
    cookbook_metric_json(
      "Definitions", definitions_value, "machine-readable registries", "healthy",
    ),
    cookbook_metric_json(
      "Runtime state", runtime_value, "restart-readable state files", "info",
    ),
    cookbook_metric_json(
      "Missing required", missing_value, "drift to repair", "review",
    ),
  ]
}

///|
fn cookbook_readiness_json(manifest_path_value : String) -> Array[String] {
  [
    cookbook_item_json(
      "Stable-state manifest",
      manifest_path_value,
      "Generated",
      detail_is_json=true,
    ),
    cookbook_item_json(
      "Cookbook contract", "raw/bootstrap/COOKBOOK_CONTRACT.md", "Ready",
    ),
    cookbook_item_json(
      "Ownership map", "wiki/definitions/ownership.md", "Ready",
    ),
    cookbook_item_json(
      "Doctor procedure", "wiki/operating-procedures/doctor.md", "Ready",
    ),
  ]
}

///|
fn cookbook_review_queue_json() -> Array[String] {
  [
    cookbook_item_json(
      "Stable-state drift", "wiki/definitions/stable-state.md", "Review when required_missing > 0",
    ),
    cookbook_item_json(
      "Describer coverage", "wiki/describer/feature-guide.md", "Review when a feature lacks internals, AI behavior, or evidence flow",
    ),
  ]
}

///|
fn cookbook_page_families_json() -> Array[String] {
  [
    cookbook_item_json(
      "Stable State", "wiki/definitions/stable-state.md", "Definitions",
    ),
    cookbook_item_json(
      "Ownership", "wiki/definitions/ownership.md", "Boundaries",
    ),
    cookbook_item_json(
      "Doctor", "wiki/operating-procedures/doctor.md", "Procedure",
    ),
    cookbook_item_json(
      "Describer", "wiki/describer/feature-guide.md", "Feature internals",
    ),
    cookbook_item_json(
      "Content Rules", "wiki/describer/content-rules.md", "AI summarization policy",
    ),
  ]
}

///|
fn cookbook_journey_json(
  entry : @moonbook.BookCatalogEntry,
  manifest : MoontownCookbookManifest,
) -> Array[String] {
  [
    cookbook_journey_item_json(
      "Cookbook bootstrap",
      "generated",
      "review",
      "MoonBook generated a stable-state cookbook workspace and manifest for Moontown.",
      [
        "Manifest: \{manifest.manifest_path}",
        "Workspace: \{entry.workspace_root}",
        "Moondesk can curate this book as the human desktop surface.",
        "Feature guide: wiki/describer/feature-guide.md",
      ],
    ),
    cookbook_journey_item_json(
      "Describer upgrade",
      "generated",
      "ready",
      "The cookbook now explains Moontown by feature, protocol, runtime state, and AI role instead of only listing artifacts.",
      [
        "Overview: wiki/describer/overview.md", "Feature internals: wiki/describer/feature-guide.md",
        "Content rules: wiki/describer/content-rules.md",
      ],
    ),
  ]
}

///|
fn cookbook_links_json() -> Array[String] {
  [
    cookbook_link_json(
      "Stable state", "wiki", "wiki/definitions/stable-state.md",
    ),
    cookbook_link_json("Ownership", "wiki", "wiki/definitions/ownership.md"),
    cookbook_link_json(
      "Describer overview", "wiki", "wiki/describer/overview.md",
    ),
    cookbook_link_json(
      "Feature guide", "wiki", "wiki/describer/feature-guide.md",
    ),
    cookbook_link_json(
      "Content rules", "wiki", "wiki/describer/content-rules.md",
    ),
    cookbook_link_json("Doctor", "wiki", "wiki/operating-procedures/doctor.md"),
  ]
}

///|
pub fn cookbook_status_chips_json() -> Array[String] {
  [
    cookbook_chip_json("cookbook", "healthy"),
    cookbook_chip_json("moonbook generated", "info"),
    cookbook_chip_json("moondesk managed", "info"),
    cookbook_chip_json("moontown consumed", "review"),
  ]
}

///|
pub fn cookbook_metrics_json(
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
pub fn cookbook_readiness_json(manifest_path_value : String) -> Array[String] {
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
      "Codebase algorithms", "wiki/describer/algorithms.md", "Ready",
    ),
    cookbook_item_json(
      "Cookbook skill", "skills/cookbook-generation/SKILL.md", "Ready",
    ),
    cookbook_item_json(
      "Doctor procedure", "wiki/operating-procedures/doctor.md", "Ready",
    ),
  ]
}

///|
pub fn cookbook_review_queue_json() -> Array[String] {
  [
    cookbook_item_json(
      "Stable-state drift", "wiki/definitions/stable-state.md", "Review when required_missing > 0",
    ),
    cookbook_item_json(
      "Describer coverage", "wiki/describer/core-features.md", "Review when a feature lacks algorithms, data structures, data flow, AI boundaries, or evidence files",
    ),
  ]
}

///|
pub fn cookbook_page_families_json() -> Array[String] {
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
      "Algorithms", "wiki/describer/algorithms.md", "Code behavior",
    ),
    cookbook_item_json(
      "Data Structures", "wiki/describer/data-structures.md", "Record contracts",
    ),
    cookbook_item_json(
      "Data Flow", "wiki/describer/data-flow.md", "Runtime movement",
    ),
    cookbook_item_json(
      "Core Features", "wiki/describer/core-features.md", "Implementation guide",
    ),
    cookbook_item_json(
      "Content Rules", "wiki/describer/content-rules.md", "AI summarization policy",
    ),
  ]
}

///|
pub fn cookbook_journey_json(
  entry : @moonbook.BookCatalogEntry,
  manifest : MoontownCookbookManifest,
) -> Array[String] {
  [
    cookbook_journey_item_json(
      "Cookbook bootstrap",
      "generated",
      "review",
      "MoonBook generated a stable-state cookbook workspace and manifest for MoonTown.",
      [
        "Manifest: \{manifest.manifest_path}",
        "Workspace: \{entry.workspace_root}",
        "MoonDesk can curate this book as the human desktop surface.",
        "Algorithms: wiki/describer/algorithms.md",
        "Data flow: wiki/describer/data-flow.md",
        "Cookbook skill: skills/cookbook-generation/SKILL.md",
      ],
    ),
    cookbook_journey_item_json(
      "Codebase describer upgrade",
      "generated",
      "ready",
      "The cookbook now explains MoonTown by algorithm, data structure, data flow, feature implementation, AI boundary, and evidence file instead of only listing artifacts.",
      [
        "Overview: wiki/describer/overview.md", "Algorithms: wiki/describer/algorithms.md",
        "Data structures: wiki/describer/data-structures.md", "Data flow: wiki/describer/data-flow.md",
        "Core features: wiki/describer/core-features.md", "Content rules: wiki/describer/content-rules.md",
      ],
    ),
  ]
}

///|
pub fn cookbook_links_json() -> Array[String] {
  [
    cookbook_link_json(
      "Stable state", "wiki", "wiki/definitions/stable-state.md",
    ),
    cookbook_link_json("Ownership", "wiki", "wiki/definitions/ownership.md"),
    cookbook_link_json(
      "Describer overview", "wiki", "wiki/describer/overview.md",
    ),
    cookbook_link_json("Algorithms", "wiki", "wiki/describer/algorithms.md"),
    cookbook_link_json(
      "Data structures", "wiki", "wiki/describer/data-structures.md",
    ),
    cookbook_link_json("Data flow", "wiki", "wiki/describer/data-flow.md"),
    cookbook_link_json(
      "Core features", "wiki", "wiki/describer/core-features.md",
    ),
    cookbook_link_json(
      "Feature guide", "wiki", "wiki/describer/feature-guide.md",
    ),
    cookbook_link_json(
      "Content rules", "wiki", "wiki/describer/content-rules.md",
    ),
    cookbook_link_json(
      "Cookbook skill", "skill", "skills/cookbook-generation/SKILL.md",
    ),
    cookbook_link_json("Doctor", "wiki", "wiki/operating-procedures/doctor.md"),
  ]
}

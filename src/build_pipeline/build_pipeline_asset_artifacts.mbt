///|
async fn write_wenyu_asset_pack_record(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
) -> Unit {
  let root = @moonbook.workspace_root(entry)
  let module_name = wenyu_module_name(entry)
  write_wenyu_asset_prompts(root, task, module_name)
  write_wenyu_asset_manifest(root, entry, module_name)
}

///|
async fn write_wenyu_asset_prompts(
  root : String,
  task : @moonbook.BookTask,
  module_name : String,
) -> Unit {
  @support.write_text_file(
    "\{root}/build/ASSET_PROMPTS.md",
    [
      "# \{module_name} Asset Prompts",
      "",
      "- Task: `\{task.id}`",
      "",
      "## District Tile",
      "",
      "A warm civic AI innovation district for \{module_name}, Wenyu Valley town map style, clay-and-glass miniature architecture, visible tiny AI workers, public-service dashboard lights, approachable student innovation atmosphere, no generic neon cyberpunk, 16:9.",
      "",
      "## Icon",
      "",
      "Simple readable icon for \{module_name}, civic innovation town visual language, rounded geometry, warm daylight palette, transparent background.",
      "",
      "## Resident Or Worker Sprite",
      "",
      "Small friendly AI worker sprite for \{module_name}, isometric town dashboard style, clear silhouette, visible task tool, transparent background.",
      "",
      "## Background Vignette",
      "",
      "Soft Wenyu Valley background vignette for \{module_name}, town district atmosphere, layered paper-map depth, gentle motion-ready shapes.",
    ].join("\n"),
  )
}

///|
async fn write_wenyu_asset_manifest(
  root : String,
  entry : @moonbook.BookCatalogEntry,
  module_name : String,
) -> Unit {
  @support.write_text_file(
    "\{root}/build/ASSET_MANIFEST.md",
    [
      "# \{module_name} Asset Manifest",
      "",
      "| Asset | Intended Path | Size | Usage | Alt Text | Status |",
      "| --- | --- | --- | --- | --- | --- |",
      "| District tile | `src/ui/rabbita-town/assets/\{entry.id}-tile.png` | 1536x864 | town district card | \{module_name} district with visible AI workers | prompt-ready |",
      "| Icon | `src/ui/rabbita-town/assets/\{entry.id}-icon.png` | 512x512 | map marker and panel heading | \{module_name} icon | prompt-ready |",
      "| Worker sprite | `src/ui/rabbita-town/assets/\{entry.id}-worker.png` | 768x768 | live worker layer | AI worker for \{module_name} | prompt-ready |",
      "| Background vignette | `src/ui/rabbita-town/assets/\{entry.id}-vignette.png` | 1536x864 | district background | Wenyu Valley \{module_name} background | prompt-ready |",
    ].join("\n"),
  )
}

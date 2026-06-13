///|
pub async fn bootstrap_moontown_cookbook(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  workspace_root? : String = @cookbook.default_cookbook_workspace_root(),
  manifest_path? : String = @cookbook.default_cookbook_manifest_path(),
) -> String {
  let entry = @cookbook.book_entry(workspace_root)
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  @moonbook.save_catalog_file(
    book_catalog_path,
    @cookbook.merge_catalog(catalog, entry),
  )
  let manifest = observe_moontown_cookbook_manifest(
    workspace_root, manifest_path,
  )
  @support.write_text_file(
    manifest_path,
    manifest.to_json().stringify(indent=2),
  )
  write_moontown_cookbook_workspace(entry, manifest)
  let status = inspect_moontown_cookbook(workspace_root~, manifest_path~)
  "Bootstrapped MoonBook cookbook `\{entry.id}` at \{workspace_root}; wrote \{manifest_path}; required_missing=\{status.required_missing_count}."
}

///|
pub async fn inspect_moontown_cookbook(
  workspace_root? : String = @cookbook.default_cookbook_workspace_root(),
  manifest_path? : String = @cookbook.default_cookbook_manifest_path(),
) -> @cookbook.MoontownCookbookStatus {
  let manifest = observe_moontown_cookbook_manifest(
    workspace_root, manifest_path,
  )
  @cookbook.cookbook_status_from_manifest(
    workspace_root,
    manifest_path,
    manifest,
    cookbook_workspace_ready(workspace_root),
    @fs.exists(manifest_path),
  )
}

///|
pub async fn render_moontown_cookbook_status(
  workspace_root? : String = @cookbook.default_cookbook_workspace_root(),
  manifest_path? : String = @cookbook.default_cookbook_manifest_path(),
) -> String {
  @cookbook.status_markdown(
    inspect_moontown_cookbook(workspace_root~, manifest_path~),
  )
}

///|
async fn observe_moontown_cookbook_manifest(
  workspace_root : String,
  manifest_path : String,
) -> @cookbook.MoontownCookbookManifest {
  let base = @cookbook.manifest(workspace_root, manifest_path)
  let observed : Array[@cookbook.CookbookArtifact] = []
  for artifact in base.artifacts {
    observed.push(
      @cookbook.cookbook_artifact_with_exists(
        artifact,
        @fs.exists(artifact.path),
      ),
    )
  }
  @cookbook.cookbook_manifest_with_artifacts(base, observed)
}

///|
async fn cookbook_workspace_ready(workspace_root : String) -> Bool {
  @fs.exists("\{workspace_root}/wiki/index.md") &&
  @fs.exists("\{workspace_root}/book/moonbook-ui-state.json")
}

///|
pub(all) struct LocalProjectionOutcome {
  contract : String
  generated_artifacts : Array[String]
  preserved_artifacts : Array[String]
  missing_artifacts : Array[String]
} derive(Debug, ToJson, FromJson)

///|
/// Ask MoonBook to fill missing local projection outputs, preserving authored
/// files and returning the provenance of each path. No provider is invoked.
///
/// ```mbt check
/// test {
///   let ensure = async fn(entry : @moonbook.BookCatalogEntry) {
///     @moonbook.ensure_local_projection(entry)
///   }
///   ignore(ensure)
/// }
/// ```
pub async fn ensure_local_projection(
  entry : BookCatalogEntry,
  moonbook_root? : String = default_moonbook_root(),
) -> LocalProjectionOutcome {
  let root = resolved_workspace_root(entry.workspace_root)
  let (command, args) = moonbook_runtime_invocation(["wiki", "projection", root])
  let json = @integration.run_json(
    command,
    args,
    cwd=Some(resolved_root_path(moonbook_root)),
  )
  let outcome : LocalProjectionOutcome = @json.from_json(json)
  guard outcome.contract == "moonbook.local_projection.v1" else {
    fail("MoonBook returned an unsupported local projection contract")
  }
  outcome
}

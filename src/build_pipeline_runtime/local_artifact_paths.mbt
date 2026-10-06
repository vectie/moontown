///|
/// Return only existing regular local outputs from a local Wenyu materializer.
/// Declared future images and provider run identifiers are never synthesized.
///
/// ```mbt check
/// test {
///   ignore(@build_pipeline_runtime.local_wenyu_result_artifacts)
/// }
/// ```
pub async fn local_wenyu_result_artifacts(
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
) -> Array[String] {
  if execution.output_contract != "wenyu.build.local-result.v1" {
    return []
  }
  let root = @fs.realpath(@moonbook.workspace_root(entry))
  let artifacts : Array[String] = []
  for relative in execution.context_pages {
    if relative.has_prefix("/") ||
      relative.contains("\\") ||
      relative.contains(":") ||
      relative.split("/").any(part => part == ".." || part == "." || part == "") {
      continue
    }
    let path = root + "/" + relative
    let valid = try
      @fs.kind(path, follow_symlink=false) is Regular &&
      @fs.realpath(path) == path
    catch {
      _ => false
    }
    if valid && !artifacts.contains(relative) {
      artifacts.push(relative)
    }
  }
  artifacts
}

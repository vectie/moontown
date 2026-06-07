///|
struct CookbookArtifactSummary {
  docs_count : Int
  definition_count : Int
  runtime_state_count : Int
  required_missing_paths : Array[String]
} derive(Debug, Eq)

///|
fn CookbookArtifactSummary::from_artifacts(
  artifacts : Array[CookbookArtifact],
) -> CookbookArtifactSummary {
  let required_missing_paths : Array[String] = []
  let mut docs_count = 0
  let mut definition_count = 0
  let mut runtime_state_count = 0
  for artifact in artifacts {
    match artifact.kind {
      "doc" => docs_count += 1
      "definition" => definition_count += 1
      "runtime-state" => runtime_state_count += 1
      _ => ()
    }
    if artifact.required && !artifact.exists {
      required_missing_paths.push(artifact.path)
    }
  }
  { docs_count, definition_count, runtime_state_count, required_missing_paths }
}

///|
fn CookbookArtifactSummary::required_missing_count(
  self : CookbookArtifactSummary,
) -> Int {
  self.required_missing_paths.length()
}

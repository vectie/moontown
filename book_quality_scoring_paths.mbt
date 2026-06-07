///|
async fn base_workspace_score(
  root : String,
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  let mut score = 0
  if @fs.exists(root) {
    score += 12
    strengths.push("workspace exists")
  } else {
    gaps.push("workspace directory is missing")
  }
  if @fs.exists(
      book_quality_workspace_path(root, book_quality_wiki_index_path()),
    ) {
    score += 8
    strengths.push("wiki index exists")
  } else {
    gaps.push("missing \{book_quality_wiki_index_path()}")
  }
  if @fs.exists(
      book_quality_workspace_path(root, book_quality_projection_state_path()),
    ) {
    score += 8
    strengths.push("MoonBook projection state exists")
  } else {
    gaps.push("missing \{book_quality_projection_state_path()}")
  }
  score
}

///|
fn book_quality_workspace_path(root : String, relative : String) -> String {
  "\{root}/\{relative}"
}

///|
fn book_quality_wiki_index_path() -> String {
  "wiki/index.md"
}

///|
fn book_quality_projection_state_path() -> String {
  "book/moonbook-ui-state.json"
}

///|
fn book_quality_generated_site_path() -> String {
  "book/site/generated/index.html"
}

///|
async fn path_score(
  root : String,
  relative : String,
  points : Int,
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  if @fs.exists(book_quality_workspace_path(root, relative)) {
    strengths.push("has `\{relative}`")
    points
  } else {
    gaps.push("missing `\{relative}`")
    0
  }
}

///|
priv struct BookQualityRequiredPath {
  relative : String
  points : Int
}

///|
fn book_quality_required_path(
  relative : String,
  points : Int,
) -> BookQualityRequiredPath {
  { relative, points }
}

///|
async fn required_paths_score(
  root : String,
  paths : Array[BookQualityRequiredPath],
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  let mut score = 0
  for path in paths {
    score += path_score(root, path.relative, path.points, strengths, gaps)
  }
  score
}

///|
async fn paths_score(
  root : String,
  relatives : Array[String],
  points : Int,
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  if relatives.is_empty() {
    return points
  }
  let missing = workspace_missing_relative_paths(root, relatives)
  if missing.is_empty() {
    strengths.push("all \{relatives.length()} expected typed pages exist")
    points
  } else {
    let joined = missing.join(", ")
    gaps.push("missing typed pages: \{joined}")
    points * (relatives.length() - missing.length()) / relatives.length()
  }
}

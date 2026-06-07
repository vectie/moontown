///|
fn civic_skill_frontmatter(name : String, description : String) -> String {
  ["---", "name: \{name}", "description: \{description}", "---"].join("\n")
}

///|
fn civic_skill_section(title : String, body : String) -> String {
  "\n## \{title}\n\n\{body}"
}

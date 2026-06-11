///|
fn planbook_markdown_page(
  header : Array[String],
  sections : Array[Array[String]],
) -> String {
  let lines = header.copy()
  for section in sections {
    for line in section {
      lines.push(line)
    }
  }
  lines.join("\n")
}

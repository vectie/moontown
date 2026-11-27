///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct MaterialContextMatch {
  match_line : MaterialMatch
  first_line : Int32
  last_line : Int32
  text : String
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct MaterialContextSearch {
  search : MaterialSearch
  context_lines : Int32
  windows : Array[MaterialContextMatch]
}

///|
/// Inspect a literal match with neighboring source lines before selecting a
/// passage. Line ranges can be passed to select_lines; context is not selected
/// automatically. CRLF bytes are retained just as in select_lines.
pub fn MaterialNotebook::find_context(
  self : MaterialNotebook,
  query : String,
  context_lines : Int32,
) -> MaterialContextSearch raise {
  guard context_lines >= 0 && context_lines <= 10 else {
    fail("Choose 0–10 neighboring lines on each side")
  }
  let search = self.find(query)
  let windows = search.matches.map(hit => {
    let page = self.pages.filter(page => {
        page.book_id == hit.book_id && page.source_path == hit.source_path
      })[0]
    let lines = page.text.split("\n").to_array()
    let first_line = Int32::max(1, hit.line_number - context_lines)
    let last_line = Int32::min(lines.length(), hit.line_number + context_lines)
    {
      match_line: hit,
      first_line,
      last_line,
      text: lines[first_line - 1:last_line]
      .map(line => line.to_owned())
      .join("\n"),
    }
  })
  { search, context_lines, windows, }
}

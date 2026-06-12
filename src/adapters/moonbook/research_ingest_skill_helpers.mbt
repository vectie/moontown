///|
fn research_ingest_push(lines : Array[String], section : Array[String]) -> Unit {
  for line in section {
    lines.push(line)
  }
}

///|
fn research_ingest_text(parts : Array[String]) -> String {
  parts.join(" ")
}

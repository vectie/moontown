///|
fn web_first_push(lines : Array[String], section : Array[String]) -> Unit {
  for line in section {
    lines.push(line)
  }
}

///|
fn web_first_text(parts : Array[String]) -> String {
  parts.join(" ")
}

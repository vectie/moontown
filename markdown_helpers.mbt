///|
fn markdown_inline(text : String) -> String {
  text.replace(old="\n", new=" ").replace(old="|", new="\\|")
}

///|
fn markdown_bullets(values : Array[String]) -> String {
  let builder = StringBuilder::new()
  for value in values {
    builder.write_string("- ")
    builder.write_string(value)
    builder.write_char('\n')
  }
  builder.to_string().trim().to_owned()
}

///|
fn remove_first_markdown_title(report : String) -> String {
  let builder = StringBuilder::new()
  let mut skipped = false
  for line in report.split("\n") {
    let trimmed = line.trim().to_owned()
    if !skipped && trimmed.has_prefix("# ") {
      skipped = true
      continue
    }
    builder.write_string(line.to_owned())
    builder.write_string("\n")
  }
  builder.to_string().trim().to_owned()
}

///|
fn demote_markdown_headings(markdown : String) -> String {
  let builder = StringBuilder::new()
  for line in markdown.split("\n") {
    if line.has_prefix("####") {
      builder.write_string("#\{line}\n")
    } else if line.has_prefix("###") {
      builder.write_string("#\{line}\n")
    } else if line.has_prefix("##") {
      builder.write_string("#\{line}\n")
    } else {
      builder.write_string(line.to_owned())
      builder.write_string("\n")
    }
  }
  builder.to_string()
}

///|
fn section_body(report : String, heading : String) -> String {
  let builder = StringBuilder::new()
  let mut in_section = false
  for line in report.split("\n") {
    let trimmed = line.trim().to_owned()
    if trimmed == heading {
      in_section = true
      continue
    }
    if in_section && trimmed.has_prefix("## ") {
      break
    }
    if in_section {
      builder.write_string(line.to_owned())
      builder.write_string("\n")
    }
  }
  builder.to_string().trim().to_owned()
}

///|
fn first_non_heading_paragraph(markdown : String) -> String {
  let builder = StringBuilder::new()
  let mut emitted = false
  let mut in_code_block = false
  for line in markdown.split("\n") {
    let trimmed = line.trim().to_owned()
    if trimmed.has_prefix("```") {
      in_code_block = !in_code_block
      continue
    }
    if in_code_block {
      continue
    }
    if trimmed.is_blank() {
      if emitted {
        break
      }
      continue
    }
    if trimmed.has_prefix("#") || trimmed.has_prefix("|") {
      continue
    }
    builder.write_string(trimmed)
    builder.write_string(" ")
    emitted = true
  }
  builder.to_string().trim().to_owned()
}

///|
fn markdown_excerpt(text : String, limit : Int) -> String {
  let trimmed = text.trim()
  if limit <= 0 {
    return "..."
  }
  if trimmed.length() <= limit {
    return trimmed.to_owned()
  }
  let builder = StringBuilder::new()
  let mut emitted = 0
  for char in trimmed {
    if emitted >= limit {
      break
    }
    builder.write_char(char)
    emitted += 1
  }
  "\{builder.to_string()}\n\n..."
}

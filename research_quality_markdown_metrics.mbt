///|
fn count_text_lines(text : String) -> Int {
  if text.is_empty() {
    return 0
  }
  let mut count = 0
  for _ in text.split("\n") {
    count += 1
  }
  count
}

///|
fn normalized_markdown_line(raw : StringView) -> String {
  raw.trim().to_owned().to_lower()
}

///|
fn line_is_section_heading(line : String) -> Bool {
  line.has_prefix("## ")
}

///|
fn count_english_word_tokens(text : String) -> Int {
  let mut count = 0
  let mut in_word = false
  for char in text {
    if is_english_alnum(char) {
      if !in_word {
        count += 1
      }
      in_word = true
    } else {
      in_word = false
    }
  }
  count
}

///|
fn is_english_alnum(char : Char) -> Bool {
  (char >= 'a' && char <= 'z') ||
  (char >= 'A' && char <= 'Z') ||
  (char >= '0' && char <= '9')
}

///|
fn count_markdown_sections(markdown : String) -> Int {
  let mut count = 0
  for line in markdown.split("\n") {
    let trimmed = line.trim().to_owned()
    if trimmed.has_prefix("## ") {
      count += 1
    }
  }
  count
}

///|
fn markdown_has_table(markdown : String) -> Bool {
  for line in markdown.split("\n") {
    let trimmed = line.trim().to_owned()
    if trimmed.has_prefix("|") && trimmed.contains("---") {
      return true
    }
  }
  false
}

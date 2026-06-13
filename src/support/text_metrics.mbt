///|
pub fn count_english_word_tokens(text : String) -> Int {
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

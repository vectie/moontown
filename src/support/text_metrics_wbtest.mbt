///|
test "english word token count treats ascii runs as words" {
  assert_eq(count_english_word_tokens("One-person company, v2.0"), 5)
  assert_eq(count_english_word_tokens("中文 plus English-words"), 3)
  assert_eq(count_english_word_tokens(""), 0)
}

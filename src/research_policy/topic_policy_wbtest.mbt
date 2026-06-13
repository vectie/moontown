///|
test "research policy owns topic normalization and display" {
  assert_eq(normalize_topic_id("LLM Training Detail"), "llm-training-detail")
  assert_eq(strip_research_attempt_suffix("llm-training-v4"), "llm-training")
  assert_eq(strip_research_attempt_suffix("llm-training"), "llm-training")
  assert_eq(display_topic_name("opc"), "One Person Company (OPC)")
  assert_true(is_local_project_topic("moonclaw"))
  assert_true(is_external_domain_topic("euv-lithography"))
}

///|
test "research policy owns topic route hints" {
  assert_true(
    mode_text("euv").contains("Local repository inspection is not part"),
  )
  assert_true(question_text("opc", "OPC").contains("One Person Company"))
  assert_true(followup_query("opc", "OPC").contains("AI solo founder"))
  assert_true(risk_query("moonclaw", "MoonClaw").contains("site:github.com"))
  assert_true(web_queries("moonclaw").contains("vectie moonclaw"))
  assert_true(
    reference_urls("moonclaw").contains("https://github.com/vectie/moonclaw"),
  )
  assert_true(local_paths("euv-lithography").is_empty())
}

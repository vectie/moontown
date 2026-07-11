///|
pub fn normalize_topic_id(topic : String) -> String {
  let normalized = topic.to_lower().trim().to_owned()
  match normalized {
    "moontown" => "moontown"
    "moonbook" => "moonbook"
    "moonclaw" => "moonclaw"
    "finance" => "finance"
    "coding" => "coding"
    _ => compact_topic_segment(normalized)
  }
}

///|
pub fn strip_research_attempt_suffix(topic : String) -> String {
  let cleaned = topic.to_lower().trim().to_owned()
  let parts = cleaned.split("-").to_array()
  if parts.length() < 2 {
    return cleaned
  }
  let last = parts[parts.length() - 1].to_owned()
  if !(last.length() > 1 &&
    last[0] == 'v' &&
    string_is_digits(last[1:].to_owned())) {
    return cleaned
  }
  let builder = StringBuilder::new()
  for index in 0..<(parts.length() - 1) {
    if index > 0 {
      builder.write_char('-')
    }
    builder.write_string(parts[index].to_owned())
  }
  builder.to_string()
}

///|
fn string_is_digits(text : String) -> Bool {
  if text.is_empty() {
    return false
  }
  for char in text {
    if char < '0' || char > '9' {
      return false
    }
  }
  true
}

///|
fn compact_topic_segment(text : String) -> String {
  let builder = StringBuilder::new()
  let mut last_dash = false
  for char in text.to_lower() {
    if (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') {
      builder.write_char(char)
      last_dash = false
    } else if !last_dash {
      builder.write_char('-')
      last_dash = true
    }
  }
  builder.to_string().trim(chars="-").to_owned()
}

///|
pub fn display_topic_name(topic : String) -> String {
  match topic {
    "moontown" => "MoonTown"
    "moonbook" => "MoonBook"
    "moonclaw" => "MoonClaw"
    "finance" => "Finance"
    "coding" => "Coding"
    "opc" => "One Person Company (OPC)"
    _ => topic_id_to_words(topic)
  }
}

///|
fn topic_id_to_words(topic : String) -> String {
  let builder = StringBuilder::new()
  for char in topic {
    if char == '-' {
      builder.write_char(' ')
    } else {
      builder.write_char(char)
    }
  }
  builder.to_string()
}

///|
pub fn is_local_project_topic(topic : String) -> Bool {
  match topic {
    "moontown" | "moonbook" | "moonclaw" => true
    _ => false
  }
}

///|
pub fn is_external_domain_topic(topic : String) -> Bool {
  !is_local_project_topic(topic)
}

///|
pub fn mode_text(topic : String) -> String {
  if is_external_domain_topic(topic) {
    "web discovery first, source screening second, evidence extraction third, source triangulation fourth, MoonClaw raw handoff fifth, and MoonBook wiki materialization last. Local repository inspection is not part of the default path."
  } else {
    "web discovery first, source screening second, evidence extraction third, local repository inspection fourth, MoonClaw raw handoff fifth, and MoonBook wiki materialization last."
  }
}

///|
pub fn question_text(topic : String, display : String) -> String {
  match topic {
    "opc" =>
      "What is the One Person Company model, what current news and evidence show about its business reality, how AI tools and agentic workflows change its feasibility, what examples and risks matter, and what remains uncertain?"
    _ if is_external_domain_topic(topic) =>
      "What is \{display}, what new advantages or supplements are emerging, what evidence shows their technical and market significance, what routes or alternatives should be compared, what bottlenecks remain, and what should be watched next?"
    _ =>
      "What is \{display}, what problem does it solve, how is it implemented or operated, what evidence supports those claims, and what remains uncertain?"
  }
}

///|
pub fn followup_query(topic : String, display : String) -> String {
  match topic {
    "opc" => "AI solo founder one person company trend"
    _ if is_external_domain_topic(topic) =>
      "\{display} latest research advantages limitations roadmap"
    _ => "\{display} architecture implementation"
  }
}

///|
pub fn risk_query(topic : String, display : String) -> String {
  match topic {
    "opc" => "one person company risks operations legal finance"
    _ if is_external_domain_topic(topic) =>
      "\{display} bottlenecks risks supply chain adoption"
    _ => "site:github.com vectie \{topic}"
  }
}

///|
pub fn web_queries(topic : String) -> Array[String] {
  match topic {
    "moontown" =>
      [
        "vectie moontown", "moontown moonbook moonclaw", "site:github.com vectie moontown",
      ]
    "moonbook" =>
      [
        "vectie moonbook", "moonbook wiki moonbit", "site:github.com vectie moonbook",
      ]
    "moonclaw" =>
      [
        "vectie moonclaw", "moonclaw moonbit agent", "site:github.com vectie moonclaw",
      ]
    "opc" =>
      [
        "one person company latest news AI", "one-person company solo founder AI startup",
        "one person company business model trend", "one-person unicorn AI startup trend",
        "Anthropic CEO one-person billion-dollar company AI", "OPC entrepreneur one person company current evidence",
        "one person company risks legal finance operations",
      ]
    _ if is_external_domain_topic(topic) => {
      let display = display_topic_name(topic)
      [
        "\{display} latest research advantages limitations",
        "\{display} technology roadmap 2026",
        "\{display} market analysis suppliers adoption",
        "\{display} new advances bottlenecks comparison",
        "\{display} research report risks supplements",
        "\{display} alternatives complementary technologies comparison",
        "\{display} route comparison maturity cost scalability",
      ]
    }
    _ =>
      ["vectie \{topic}", "\{topic} moonbit", "site:github.com vectie \{topic}"]
  }
}

///|
pub fn reference_urls(topic : String) -> Array[String] {
  match topic {
    "moontown" => ["https://github.com/vectie/moontown"]
    "moonbook" => ["https://github.com/vectie/moonbook"]
    "moonclaw" => ["https://github.com/vectie/moonclaw"]
    "opc" =>
      [
        "https://www.opc.community/", "https://www.forbes.com/sites/elainepofeldt/2026/01/28/as-more-founders-aim-to-build-billion-dollar-one-person-businesses-new-research-points-to-high-potential-niches/",
        "https://www.europeanbusinessreview.com/one-person-startups-are-on-the-rise-thanks-to-ai/",
        "https://www.worldbank.org/en/programs/entrepreneurship", "https://www.gov.uk/running-a-limited-company",
      ]
    _ if is_external_domain_topic(topic) => []
    _ => ["https://github.com/vectie/\{topic}"]
  }
}

///|
pub fn local_paths(topic : String) -> Array[String] {
  match topic {
    "moontown" =>
      [
        "README.md", "README.mbt.md", "AGENTS.md", "moon.mod", "src/cmd/main/main.mbt",
        "src/town_runtime/goal_run.mbt", "src/adapters/moonbook/client.mbt", "src/adapters/moonclaw/import.mbt",
        "src/roles/mayor.mbt",
      ]
    "moonbook" | "moonclaw" | "moondesk" => []
    "opc" => []
    _ if is_external_domain_topic(topic) => []
    _ => []
  }
}

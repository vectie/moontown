///|
fn research_topic_id(entry : BookCatalogEntry) -> String {
  for tag in entry.tags {
    if tag.has_prefix("topic:") {
      let topic = tag[6:].to_owned()
      if !topic.is_empty() {
        return topic
      }
    }
  }
  if catalog_entry_is_research(entry) && entry.id.has_prefix("research-") {
    entry.id[9:].to_owned()
  } else {
    normalize_topic_id(entry.id)
  }
}

///|
fn is_external_domain_research_topic(topic : String) -> Bool {
  !is_local_project_research_topic(topic)
}

///|
fn is_local_project_research_topic(topic : String) -> Bool {
  match topic {
    "moontown" | "moonbook" | "moonclaw" => true
    _ => false
  }
}

///|
fn research_mode_text(topic : String) -> String {
  if is_external_domain_research_topic(topic) {
    "web discovery first, source screening second, evidence extraction third, source triangulation fourth, MoonClaw raw handoff fifth, and MoonBook wiki materialization last. Local repository inspection is not part of the default path."
  } else {
    "web discovery first, source screening second, evidence extraction third, local repository inspection fourth, MoonClaw raw handoff fifth, and MoonBook wiki materialization last."
  }
}

///|
fn research_question_text(topic : String, display : String) -> String {
  match topic {
    "opc" =>
      "What is the One Person Company model, what current news and evidence show about its business reality, how AI tools and agentic workflows change its feasibility, what examples and risks matter, and what remains uncertain?"
    _ if is_external_domain_research_topic(topic) =>
      "What is \{display}, what new advantages or supplements are emerging, what evidence shows their technical and market significance, what routes or alternatives should be compared, what bottlenecks remain, and what should be watched next?"
    _ =>
      "What is \{display}, what problem does it solve, how is it implemented or operated, what evidence supports those claims, and what remains uncertain?"
  }
}

///|
fn research_followup_query(topic : String, display : String) -> String {
  match topic {
    "opc" => "AI solo founder one person company trend"
    _ if is_external_domain_research_topic(topic) =>
      "\{display} latest research advantages limitations roadmap"
    _ => "\{display} architecture implementation"
  }
}

///|
fn research_risk_query(topic : String, display : String) -> String {
  match topic {
    "opc" => "one person company risks operations legal finance"
    _ if is_external_domain_research_topic(topic) =>
      "\{display} bottlenecks risks supply chain adoption"
    _ => "site:github.com vectie \{topic}"
  }
}

///|
fn research_web_queries(topic : String) -> Array[String] {
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
    _ if is_external_domain_research_topic(topic) => {
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
fn research_reference_urls(topic : String) -> Array[String] {
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
    _ if is_external_domain_research_topic(topic) => []
    _ => ["https://github.com/vectie/\{topic}"]
  }
}

///|
fn research_local_paths(topic : String) -> Array[String] {
  match topic {
    "moontown" =>
      [
        "/Users/kq/Workspace/moontown/README.md", "/Users/kq/Workspace/moontown/README.mbt.md",
        "/Users/kq/Workspace/moontown/AGENTS.md", "/Users/kq/Workspace/moontown/moon.mod",
        "/Users/kq/Workspace/moontown/src/cmd/main/main.mbt", "/Users/kq/Workspace/moontown/src/town_runtime/goal_run.mbt",
        "/Users/kq/Workspace/moontown/src/adapters/moonbook/client.mbt", "/Users/kq/Workspace/moontown/src/adapters/moonclaw/import.mbt",
        "/Users/kq/Workspace/moontown/src/roles/mayor.mbt",
      ]
    "moonbook" =>
      [
        "/Users/kq/Workspace/moonbook/README.md", "/Users/kq/Workspace/moonbook/README.mbt.md",
        "/Users/kq/Workspace/moonbook/AGENTS.md", "/Users/kq/Workspace/moonbook/moon.mod.json",
        "/Users/kq/Workspace/moonbook/docs/SYSTEM_ARCHITECTURE.md", "/Users/kq/Workspace/moonbook/wiki/bookapi.mbt",
        "/Users/kq/Workspace/moonbook/wiki/init.mbt", "/Users/kq/Workspace/moonbook/wiki/ui_state.mbt",
      ]
    "moonclaw" =>
      [
        "/Users/kq/Workspace/moonclaw/README.mbt.md", "/Users/kq/Workspace/moonclaw/Agents.md",
        "/Users/kq/Workspace/moonclaw/moon.mod.json", "/Users/kq/Workspace/moonclaw/docs/research_controller_architecture.md",
        "/Users/kq/Workspace/moonclaw/job/provider_task.mbt", "/Users/kq/Workspace/moonclaw/job/analysis_contracts.mbt",
        "/Users/kq/Workspace/moonclaw/tools/web_search/tool.mbt", "/Users/kq/Workspace/moonclaw/tools/web_fetch/tool.mbt",
        "/Users/kq/Workspace/moonclaw/tools/search_files/tool.mbt",
      ]
    "opc" => []
    _ if is_external_domain_research_topic(topic) => []
    _ =>
      [
        "/Users/kq/Workspace/\{topic}/README.md",
        "/Users/kq/Workspace/\{topic}/moon.mod.json",
      ]
  }
}

///|
priv struct KnowledgeBookSourceReadiness {
  status : String
  configured_source_count : Int
  next_action : String
}

///|
fn knowledge_book_source_configuration_action(
  book : @domain_catalog.KnowledgeDomainBook,
) -> String {
  match book.source_policy {
    "owner-ledger" =>
      "Add the owning ledger or evidence-index reference to `websites`; do not copy private ledger content into the generated config."
    "primary-sources" =>
      "Add approved official or primary-source URLs to `websites`."
    "primary-plus-licensed" =>
      "Add approved primary and licensed-provider references to `websites`, then confirm license authority outside this command."
    "public-evidence" => "Add approved public-evidence URLs to `websites`."
    "mixed-reviewed" =>
      "Add the reviewed source set to `websites`; generated discovery alone is insufficient."
    "privacy-scoped" =>
      "Add only consented, privacy-scoped source references to `websites`."
    "protocol-derived" =>
      "Add the authoritative protocol receipt or round-ledger references to `websites`."
    "telemetry-first" =>
      "Add approved telemetry endpoint or adapter references to `websites`."
    "contractual-record" =>
      "Add approved contract, call, or record references to `websites`."
    _ => "Add approved source references to `websites`."
  }
}

///|
fn configured_source_references(value : Json) -> Array[String] {
  let references : Array[String] = []
  let fields = match value {
    Object(fields) => fields
    _ => return references
  }
  let values = match fields.get("websites") {
    Some(Array(values)) => values
    _ => return references
  }
  for value in values {
    match value {
      String(reference) => {
        let normalized = reference.trim().to_owned()
        if !normalized.is_empty() && !references.contains(normalized) {
          references.push(normalized)
        }
      }
      _ => ()
    }
  }
  references
}

///|
async fn inspect_knowledge_book_source_readiness(
  book : @domain_catalog.KnowledgeDomainBook,
  config_path : String,
) -> KnowledgeBookSourceReadiness {
  if book.status != "active" {
    return {
      status: "inactive",
      configured_source_count: 0,
      next_action: "Activate the catalog book before provisioning it.",
    }
  }
  if !@fs.exists(config_path) {
    return {
      status: "source_configuration_required",
      configured_source_count: 0,
      next_action: knowledge_book_source_configuration_action(book),
    }
  }
  let text = @fs.read_file(config_path).text() catch {
    _ =>
      return {
        status: "source_configuration_invalid",
        configured_source_count: 0,
        next_action: "Make the existing config readable, then " +
        knowledge_book_source_configuration_action(book),
      }
  }
  let parsed = @json.parse(text) catch {
    _ =>
      return {
        status: "source_configuration_invalid",
        configured_source_count: 0,
        next_action: "Repair the existing config JSON, then " +
        knowledge_book_source_configuration_action(book),
      }
  }
  let references = configured_source_references(parsed)
  if references.is_empty() {
    {
      status: "source_configuration_required",
      configured_source_count: 0,
      next_action: knowledge_book_source_configuration_action(book),
    }
  } else {
    {
      status: "source_configured",
      configured_source_count: references.length(),
      next_action: "Review source authority and licensing before running research.",
    }
  }
}

///|
fn knowledge_book_research_readiness(
  book : @domain_catalog.KnowledgeDomainBook,
  provisioning_status : String,
  source_readiness : KnowledgeBookSourceReadiness,
) -> String {
  if book.status != "active" {
    return "inactive"
  }
  if source_readiness.status != "source_configured" {
    return "blocked_by_source_configuration"
  }
  match provisioning_status {
    "workspace_installed" => "source_configured_not_research_verified"
    "pending" | "pending_retry" => "source_configured_install_pending"
    "install_failed" => "source_configured_install_failed"
    _ => "source_configured_not_started"
  }
}

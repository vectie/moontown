///|
fn research_handoff_contract_version() -> String {
  "moontown.civic.communication.handoff.v1"
}

///|
fn research_handoff_inspection_reply_version() -> String {
  "moontown.research-handoff-inspection.reply.v1"
}

///|
fn research_handoff_execution_reply_version() -> String {
  "moontown.research-handoff-execution.reply.v1"
}

///|
fn initial_research_handoff_state() -> ResearchHandoffState {
  if !current_browser_query_param("moonflow_run").trim().is_empty() ||
    !current_browser_query_param("moonflow_handoff").trim().is_empty() {
    return NoResearchHandoff
  }
  let request = {
    handoff_url: current_browser_query_param("handoff_url").trim().to_owned(),
    handoff_contract: current_browser_query_param("handoff_contract")
    .trim()
    .to_owned(),
    handoff_id: current_browser_query_param("handoff_id").trim().to_owned(),
  }
  if request.handoff_url.is_empty() &&
    request.handoff_contract.is_empty() &&
    request.handoff_id.is_empty() {
    NoResearchHandoff
  } else if request.handoff_url.is_empty() ||
    request.handoff_contract.is_empty() ||
    request.handoff_id.is_empty() {
    BlockedResearchHandoff(
      "The handoff link is incomplete. handoff_url, handoff_contract, and handoff_id are all required.",
    )
  } else if request.handoff_contract != research_handoff_contract_version() {
    BlockedResearchHandoff(
      "The link requests unsupported contract `\{request.handoff_contract}`.",
    )
  } else {
    LoadingResearchHandoff(request)
  }
}

///|
fn research_handoff_validation_issues(
  request : ResearchHandoffRequest,
  handoff : ResearchHandoff,
) -> Array[String] {
  let issues : Array[String] = []
  if handoff.contract_version != request.handoff_contract ||
    handoff.contract_version != research_handoff_contract_version() {
    issues.push("artifact contract does not match the requested contract")
  }
  if handoff.handoff_id != request.handoff_id {
    issues.push("artifact id does not match the requested handoff id")
  }
  if handoff.producer.is_blank() || handoff.producer_run_id.is_blank() {
    issues.push("producer and producer run must be explicit")
  }
  if handoff.scenario.id.is_blank() || handoff.scenario.title.is_blank() {
    issues.push("research scenario identity is incomplete")
  }
  if handoff.scenario.communication_pattern_id != Some("research-salon") {
    issues.push("only the typed research-salon pattern is accepted here")
  }
  if handoff.scenario.review_gate != "named-human" ||
    handoff.scenario.review_owner.is_blank() {
    issues.push("the handoff must retain a named-human review boundary")
  }
  if handoff.scenario.participants.length() < 2 {
    issues.push("a research salon requires at least two participant books")
  }
  let participant_ids : Array[String] = []
  for participant in handoff.scenario.participants {
    if participant.book_id.is_blank() ||
      participant.title.is_blank() ||
      participant.current_question.is_blank() {
      issues.push(
        "every participant needs a book id, title, and current question",
      )
    } else if participant_ids.contains(participant.book_id) {
      issues.push("participant book ids must be unique")
    } else {
      participant_ids.push(participant.book_id)
    }
  }
  issues
}

///|
fn resolve_research_handoff_response(
  request : ResearchHandoffRequest,
  raw : String,
) -> ResearchHandoffState {
  let parsed = @json.parse(raw) catch {
    _ =>
      return BlockedResearchHandoff(
        "MoonTown's handoff inspection endpoint returned invalid JSON.",
      )
  }
  let reply : ResearchHandoffInspectionReply = @json.from_json(parsed) catch {
    _ =>
      return BlockedResearchHandoff(
        "MoonTown's handoff inspection response did not match its typed contract.",
      )
  }
  if reply.contract_version != research_handoff_inspection_reply_version() {
    return BlockedResearchHandoff(
      "MoonTown returned unsupported inspection contract `\{reply.contract_version}`.",
    )
  }
  if reply.requested_url != request.handoff_url {
    return BlockedResearchHandoff(
      "The inspected URL does not exactly match the handoff_url from the link.",
    )
  }
  if !reply.ok {
    return BlockedResearchHandoff(
      if reply.error.is_blank() {
        "The typed handoff is unavailable."
      } else {
        reply.error
      },
    )
  }
  if reply.upstream_status < 200 || reply.upstream_status >= 300 {
    return BlockedResearchHandoff(
      "The handoff source returned HTTP \{reply.upstream_status}.",
    )
  }
  guard reply.handoff is Some(value) else {
    return BlockedResearchHandoff(
      "The successful inspection response did not contain a handoff artifact.",
    )
  }
  let handoff : ResearchHandoff = @json.from_json(value) catch {
    _ =>
      return BlockedResearchHandoff(
        "The fetched artifact did not match the typed research-handoff contract.",
      )
  }
  let issues = research_handoff_validation_issues(request, handoff)
  if issues.is_empty() {
    ReadyResearchHandoff(request, handoff)
  } else {
    BlockedResearchHandoff(
      "Handoff validation failed: " + issues.join("; ") + ".",
    )
  }
}

///|
fn resolve_research_handoff_execution_response(
  request : ResearchHandoffRequest,
  handoff : ResearchHandoff,
  expected_action : String,
  raw : String,
) -> ResearchHandoffState {
  let parsed = @json.parse(raw) catch {
    _ =>
      return BlockedResearchHandoff(
        "MoonTown's execution endpoint returned invalid JSON. The durable attempt may still exist; reopen the exact handoff before taking further action.",
      )
  }
  let reply : ResearchHandoffExecutionReply = @json.from_json(parsed) catch {
    _ =>
      return BlockedResearchHandoff(
        "MoonTown's execution response did not match the typed reply contract.",
      )
  }
  if reply.contract_version != research_handoff_execution_reply_version() ||
    reply.action != expected_action ||
    reply.requested_url != request.handoff_url ||
    reply.handoff_id != request.handoff_id ||
    reply.handoff_id != handoff.handoff_id {
    return BlockedResearchHandoff(
      "MoonTown blocked an execution response whose action or handoff identity drifted.",
    )
  }
  SettledResearchHandoff(request, handoff, reply)
}

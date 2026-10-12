///|
fn revision_prefix(saved : @contract.SavedDraft) -> String {
  "revisions/" + saved.revision + "/"
}

///|
fn source_packet(saved : @contract.SavedDraft) -> Bytes {
  let value : Json = {
    "contract_version": "moontown.collaboration-source-packet.v1",
    "draft_id": saved.draft.draft_id,
    "revision": saved.revision,
    "recorded_at": saved.recorded_at,
    "status": "pending_review",
    "execution": "not_started",
    "draft": saved.draft.to_json(),
    "sources": saved.sources
    .map(source => {
      ..source,
      artifact_ref: revision_prefix(saved) + source.artifact_ref,
    })
    .to_json(),
  }
  @utf8.encode(value.stringify(indent=2))
}

///|
/// Existing civic v1 wire contract; plans contain no generated ideas.
pub fn civic_handoff(
  saved : @contract.SavedDraft,
) -> @civic.CivicCommunicationScenarioHandoff raise {
  let issues = @contract.preparation_issues(saved)
  guard issues.is_empty() else { raise CollaborationError(issues.join("; ")) }
  let draft = saved.draft
  let participants : Array[@civic.CivicCommunicationParticipantBook] = draft.participants.map(p => {
      book_id: p.book_id,
      title: saved.sources.filter(s => s.book_id == p.book_id)[0].book_title,
      focus_area: p.focus_area,
      perspective: p.perspective,
      cadence: "one-off",
      current_question: draft.question,
      contribution: p.contribution,
      next_artifact: p.next_artifact,
    },
  )
  let scenario : @civic.CivicCommunicationScenario = {
    id: "collaboration-" + draft.draft_id,
    title: draft.title,
    communication_pattern_id: Some("research-salon"),
    communication_pattern_label: Some("Research Salon"),
    building_id: "collaboration-desk",
    building_book_id: "collaboration-" + draft.draft_id,
    domain_label: "User-authored cross-Book collaboration",
    topic: draft.question,
    cadence: "one-off",
    interval_ms: None,
    skill_name: "source-bound-collaboration",
    skill_description: "Prepare participant contributions to the authored question using only the captured sources. This exported plan has not executed.",
    protocol_channel: "collaboration-briefs",
    reduction_kind: "research-salon",
    output_channel: "reviewable-collaboration",
    review_gate: "named-human",
    review_owner: draft.reviewer_name,
    review_reason: draft.decision_prompt,
    backlog_path: "wiki/collaboration-backlog.md",
    synthesis_path: "wiki/collaboration-synthesis.md",
    metrics_path: "wiki/collaboration-metrics.md",
    review_path: "review/collaboration-review.md",
    returned_ideas_path: "review/collaboration-return.md",
    participant_contract_path: "collaboration-participants.json",
    quality_rules: [
      "No synthesis, execution, acceptance, or Book update has occurred.",
      "Use exact source snapshots in " +
      revision_prefix(saved) +
      "source-packet.json",
      "Every resulting claim must retain its captured source reference and named-human review.",
    ],
    skill_rules: [
      "Contributions and next artifacts are user-authored assignments.", "Do not substitute live files for frozen source bytes.",
      "Do not infer an approval or recurring schedule from this plan.",
    ],
    participants,
    ideas: [],
  }
  let handoff : @civic.CivicCommunicationScenarioHandoff = {
    contract_version: @civic.civic_communication_handoff_contract_version(),
    handoff_id: "collaboration-" + draft.draft_id + "-" + saved.revision,
    producer: "moontown",
    producer_run_id: saved.revision,
    scenario,
  }
  guard @civic.validate_civic_communication_handoff(handoff).is_empty() else {
    raise CollaborationError("Civic handoff failed validation")
  }
  handoff
}

///|
fn participant_brief(
  saved : @contract.SavedDraft,
  p : @contract.Participant,
) -> String {
  let sources = saved.sources.filter(s => s.book_id == p.book_id)
  [
    "# " + saved.draft.title + ": " + p.book_id,
    "",
    "Status: authored assignment; not executed or accepted",
    "Revision: " + saved.revision,
    "",
    "## Question",
    saved.draft.question,
    "",
    "## Focus",
    p.focus_area,
    "",
    "## Perspective",
    p.perspective,
    "",
    "## Contribution",
    p.contribution,
    "",
    "## Next artifact",
    p.next_artifact,
    "",
    "## Named human review",
    saved.draft.reviewer_name + " (" + saved.draft.reviewer_id + ")",
    saved.draft.decision_prompt,
    "",
    "## Captured sources",
    sources
    .map(s => {
      "- " +
      revision_prefix(saved) +
      s.artifact_ref +
      " | " +
      s.digest +
      " | " +
      s.size_bytes.to_string() +
      " bytes"
    })
    .join("\n"),
    "",
  ].join("\n")
}

///|
fn draft_bundle(
  saved : @contract.SavedDraft,
  packet : Bytes,
) -> @review.ConversationReviewBundle raise {
  let draft = saved.draft
  let author : @review.ReviewParticipant = {
    participant_id: "town-composer",
    display_name: "Town collaboration composer",
    participant_kind: "agent",
  }
  let reviewer : @review.ReviewParticipant = {
    participant_id: draft.reviewer_id,
    display_name: draft.reviewer_name,
    participant_kind: "human",
  }
  let participants = [author, reviewer]
  let refs = saved.sources.map(s => revision_prefix(saved) + s.artifact_ref)
  let entry = @review.draft_review_entry(
    "question",
    entry_id="question",
    author_participant_id=author.participant_id,
    turn={
      turn_id: saved.revision + "-question",
      client_turn_id: saved.revision + "-question-client",
      command_id: saved.revision + "-question-command",
    },
    body=draft.question,
    evidence_refs=refs,
  )
  let entries = [entry]
  let required = [
    @review.draft_required_decision(
      decision_id="review-plan",
      subject_entry_id="question",
      reviewer~,
      prompt=draft.decision_prompt,
    ),
  ]
  if !draft.objection.trim().is_empty() {
    let objection_reviewer : @review.ReviewParticipant = {
      participant_id: draft.objection_reviewer_id,
      display_name: draft.objection_reviewer_name,
      participant_kind: "human",
    }
    if objection_reviewer.participant_id != reviewer.participant_id {
      participants.push(objection_reviewer)
    } else {
      guard objection_reviewer == reviewer else {
        raise CollaborationError("One reviewer ID cannot name two people")
      }
    }
    entries.push(
      @review.draft_review_entry(
        "objection",
        entry_id="objection",
        author_participant_id=author.participant_id,
        turn={
          turn_id: saved.revision + "-objection",
          client_turn_id: saved.revision + "-objection-client",
          command_id: saved.revision + "-objection-command",
        },
        body=draft.objection,
        evidence_refs=refs,
      ),
    )
    required.push(
      @review.draft_required_decision(
        decision_id="resolve-objection",
        subject_entry_id="objection",
        reviewer=objection_reviewer,
        prompt="Resolve the authored objection before accepting this collaboration plan.",
      ),
    )
  }
  @review.draft_review_bundle(
    review_id="collaboration-" + draft.draft_id,
    source_artifact_ref=revision_prefix(saved) + "source-packet.json",
    source_bytes=packet,
    source_revision_id=saved.revision,
    conversation={
      contract_id: @review.conversation_contract_id(),
      protocol: "moontown-collaboration",
      product_id: "moontown",
      conversation_id: "collaboration-" + draft.draft_id,
    },
    participants~,
    entries~,
    required_decisions=required,
    recorded_at=saved.recorded_at,
  )
}

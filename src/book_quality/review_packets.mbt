///|
pub fn review_output_contract() -> String {
  "moontown.book_quality.ai_review.v1"
}

///|
pub fn review_packet(
  score : BookQualityScore,
  review_dir : String,
) -> BookQualityReviewPacket {
  {
    book_id: score.book_id,
    book_type: score.book_type,
    policy: @policy.policy_for_type(score.book_type),
    workspace_root: score.workspace_root,
    structural_score: score.structural_score,
    review_skill_path: review_skill_path(review_dir),
    context_pages: context_pages_for_score(score),
    prompt: review_prompt(score),
    output_contract: review_output_contract(),
  }
}

///|
fn score_precedes_review_candidate(
  score : BookQualityScore,
  current : BookQualityScore,
) -> Bool {
  score.structural_score < current.structural_score
}

///|
fn first_review_candidate(
  scores : Array[BookQualityScore],
) -> BookQualityScore? {
  let mut candidate : BookQualityScore? = None
  for score in scores {
    match candidate {
      Some(current) if !score_precedes_review_candidate(score, current) => ()
      _ => candidate = Some(score)
    }
  }
  candidate
}

///|
fn review_candidates_without_results(
  scores : Array[BookQualityScore],
  completed_book_ids : Array[String],
) -> Array[BookQualityScore] {
  let pending : Array[BookQualityScore] = []
  for score in scores {
    if completed_book_ids.contains(score.book_id) {
      continue
    }
    pending.push(score)
  }
  pending
}

///|
fn first_review_candidate_without_results(
  scores : Array[BookQualityScore],
  completed_book_ids : Array[String],
) -> BookQualityScore? {
  first_review_candidate(
    review_candidates_without_results(scores, completed_book_ids),
  )
}

///|
pub fn first_pending_review_score_for_completed(
  audit : BookQualityAudit,
  completed_book_ids : Array[String],
) -> BookQualityScore? {
  first_review_candidate_without_results(audit.scores, completed_book_ids)
}

///|
pub fn review_skill_path(review_dir : String) -> String {
  "\{review_dir}/BOOK_QUALITY_REVIEW_SKILL.md"
}

///|
fn context_pages_for_score(score : BookQualityScore) -> Array[String] {
  context_pages_for_type(score.book_type)
}

///|
fn review_prompt(score : BookQualityScore) -> String {
  [
    "Review MoonBook workspace `\{score.book_id}` as a `\{score.book_type}`.",
    "",
    "Use this composed policy as the source of truth for what the book should do:",
    "",
    @policy.markdown(@policy.policy_for_type(score.book_type)),
    "",
    "Structural readiness score is `\{score.structural_score}`. Do not blindly accept it as quality. Structural readiness only proves that expected files exist. Use the book's own contracts and skills to judge real quality.",
    "",
    "Judge:",
    "- usefulness to its intended user",
    "- correctness and evidence discipline",
    "- originality, imagination, curiosity, and judgment where appropriate",
    "- whether the book is using the right genre instead of leaking research/course/civic/plan behavior",
    "- whether operational evidence is separated from domain/service evidence",
    "- whether generated site/projection is meaningful enough to use",
    "",
    "Return the exact output contract from `BOOK_QUALITY_REVIEW_SKILL.md`.",
  ].join("\n")
}

///|
fn review_external_notes() -> Array[String] {
  [
    "This is a semantic review, not a structural existence check.", "Do not modify the book workspace; return the required review contract.",
    "Do not inflate score for operational logs or scaffolding.",
  ]
}

///|
fn review_external_tags(packet : BookQualityReviewPacket) -> Array[String] {
  ["book-quality", "ai-review", packet.book_type, packet.book_id]
}

///|
fn review_external_metadata(
  packet : BookQualityReviewPacket,
  result_path : String,
  execution_target : String,
) -> Json {
  let fields : Map[String, Json] = {}
  add_review_no_input_policy(fields)
  fields["producer"] = "moontown".to_json()
  fields["book_id"] = packet.book_id.to_json()
  let policy_fields = @core.json_object_copy(
    Some(@policy.policy_context_metadata(packet.book_type, packet.policy)),
  )
  for key, value in policy_fields {
    fields[key] = value
  }
  fields["result_path"] = result_path.to_json()
  fields["profile_metadata"] = review_no_input_policy_json()
  fields["step_metadata"] = review_packet_step_metadata_json(
    packet.output_contract,
    execution_target,
  )
  Json::object(fields)
}

///|
fn review_external_request(
  packet : BookQualityReviewPacket,
  absolute_workspace_root : String,
  result_path : String,
) -> String {
  [
    "You are the MoonBook semantic quality reviewer for Moontown.",
    "",
    "Book id: `\{packet.book_id}`",
    @policy.book_type_line(packet.book_type),
    "Workspace root: `\{absolute_workspace_root}`",
    "Structural score: `\{packet.structural_score}`",
    "Result target after reconciliation: `\{result_path}`",
    "",
    @policy.markdown(packet.policy),
    "",
    "Task:",
    "1. Read the review skill and the listed context pages.",
    "2. Judge the book's real quality for its role, not file completeness.",
    "3. Separate domain/service evidence from operational logs and scaffolding.",
    "4. Return exactly the `\{review_output_contract()}` Markdown contract.",
    "5. Do not write repository files directly; Moontown will reconcile your returned contract into the durable result path.",
    "",
    packet.prompt,
  ].join("\n")
}

///|
fn review_no_input_policy_json() -> Json {
  @moonclaw_policy.no_input_policy_json()
}

///|
fn add_review_no_input_policy(fields : Map[String, Json]) -> Unit {
  @moonclaw_policy.add_no_input_policy(fields)
}

///|
pub fn review_skill_markdown() -> String {
  [
    "# Book Quality AI Review Skill", "", "This review is the semantic judge above Moontown's structural doctor.",
    "", "## Rule", "", "Do not score a book as world-class just because files exist. Read the book's own contract and skill files, then decide whether the book genuinely performs its role.",
    "", "## Genre-Specific Quality", "", "- Research: evidence quality, source diversity, synthesis depth, uncertainty handling, insight, and report/projection usefulness.",
    "- Course: beginner progression, exercises, checkpoints, examples, and ability to teach judgment.",
    "- Planbook: repository-specific plan quality, acceptance criteria, validation, rollback, and resumability.",
    "- Cookbook: stable-state coverage, ownership clarity, drift accounting, and operator usefulness.",
    "- Civic service: building protocol behavior, service-native workflow, review gates, ledger/projection usefulness, and no forced research genre.",
    "- Operational: safe memory, review policy, journey trace, and sensitive-boundary discipline.",
    "", "## Output Contract", "", "```md", "ai_quality_score: <0-100>", "ai_quality_grade: world-class | excellent | strong | usable | weak | not-managed",
    "book_role_fit: excellent | acceptable | wrong-genre", "semantic_gaps:", "- <gap>",
    "best_strengths:", "- <strength>", "repair_owner: moontown | moonbook | moonclaw | moondesk | mixed",
    "next_repair_task: <one concrete task>", "projection_quality: excellent | acceptable | weak",
    "evidence_accounting_ok: yes | no", "```", "", "## Concrete Example", "", "```md",
    "ai_quality_score: 72", "ai_quality_grade: usable", "book_role_fit: acceptable",
    "semantic_gaps:", "- Civic workspace has contracts but no accepted service result, so it is not yet proven operationally.",
    "best_strengths:", "- Building protocol and module-specific skill are clear.",
    "repair_owner: mixed", "next_repair_task: Run one service-native exchange/reduction/review loop and update the projection with accepted output.",
    "projection_quality: acceptable", "evidence_accounting_ok: yes", "```",
  ].join("\n")
}

///|
pub fn review_readme(
  audit : BookQualityAudit,
  packets : Array[BookQualityReviewPacket],
) -> String {
  let rows : Array[String] = [
    "| Book | Type | Structural Score | Packet |", "| --- | --- | ---: | --- |",
  ]
  for packet in packets {
    rows.push(
      "|\{packet.book_id}|\{packet.book_type}|\{packet.structural_score}|`\{packet.book_id}.json`|",
    )
  }
  [
    "# AI Book Quality Review Packets",
    "",
    "These packets are the semantic quality layer above `.moonsuite/products/moontown/book-quality/audit.json`.",
    "",
    "The structural doctor is deliberately deterministic. It checks existence, contracts, and routing shape. These packets should be sent to MoonClaw/MoonBook so an AI reviewer can judge whether each book is actually useful, insightful, correct, and genre-appropriate.",
    "",
    "- Total packets: `\{packets.length()}`",
    "- Weakest structural book: `\{audit.weakest_book_id}` (`\{audit.weakest_score}`)",
    "",
    rows.join("\n"),
  ].join("\n")
}

///|
fn book_quality_review_packet(
  score : BookQualityScore,
  review_dir : String,
) -> BookQualityReviewPacket {
  {
    book_id: score.book_id,
    book_type: score.book_type,
    workspace_root: score.workspace_root,
    structural_score: score.structural_score,
    review_skill_path: book_quality_review_skill_path(review_dir),
    context_pages: book_quality_context_pages(score),
    prompt: book_quality_review_prompt(score),
    output_contract: book_quality_review_output_contract(),
  }
}

///|
fn book_quality_review_skill_path(review_dir : String) -> String {
  "\{review_dir}/BOOK_QUALITY_REVIEW_SKILL.md"
}

///|
fn book_quality_context_pages(score : BookQualityScore) -> Array[String] {
  book_quality_context_pages_for_type(score.book_type)
}

///|
fn book_quality_review_prompt(score : BookQualityScore) -> String {
  [
    "Review MoonBook workspace `\{score.book_id}` as a `\{score.book_type}`.",
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
fn book_quality_ai_review_skill_markdown() -> String {
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
fn book_quality_review_readme(
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
    "These packets are the semantic quality layer above `.moontown/book-quality/audit.json`.",
    "",
    "The structural doctor is deliberately deterministic. It checks existence, contracts, and routing shape. These packets should be sent to MoonClaw/MoonBook so an AI reviewer can judge whether each book is actually useful, insightful, correct, and genre-appropriate.",
    "",
    "- Total packets: `\{packets.length()}`",
    "- Weakest structural book: `\{audit.weakest_book_id}` (`\{audit.weakest_score}`)",
    "",
    rows.join("\n"),
  ].join("\n")
}

///|
async fn first_pending_ai_review_book(
  audit : BookQualityAudit,
  result_dir : String,
) -> BookQualityScore? {
  let mut candidate : BookQualityScore? = None
  for score in audit.scores {
    if book_quality_ai_review_result_exists(result_dir, score.book_id) {
      continue
    }
    match candidate {
      Some(current) if !book_quality_score_precedes_review_candidate(
          score, current,
        ) => ()
      _ => candidate = Some(score)
    }
  }
  candidate
}

///|
fn book_quality_score_precedes_review_candidate(
  score : BookQualityScore,
  current : BookQualityScore,
) -> Bool {
  score.structural_score < current.structural_score
}

///|
async fn book_quality_ai_review_result_exists(
  result_dir : String,
  book_id : String,
) -> Bool {
  @fs.exists(book_quality_ai_review_result_path(result_dir, book_id))
}

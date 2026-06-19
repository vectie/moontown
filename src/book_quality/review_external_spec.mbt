///|
pub fn review_external_proposal_spec_with_paths(
  packet : BookQualityReviewPacket,
  result_dir : String,
  execution_target : String,
  absolute_workspace_root : String,
  absolute_review_skill_path : String,
) -> BookQualityReviewProposalSpec {
  let result_path = review_result_path(result_dir, packet.book_id)
  let context_pages : Array[String] = []
  for page in packet.context_pages {
    context_pages.push(
      book_quality_path(absolute_workspace_root)
      .join(book_quality_path(page))
      .to_string(),
    )
  }
  {
    packet_id: "book-quality-ai-review-\{packet.book_id}",
    title: "AI semantic quality review: \{packet.book_id}",
    summary: "Semantic quality review for MoonBook `\{packet.book_id}`.",
    request_text: review_external_request(
      packet, absolute_workspace_root, result_path,
    ),
    profile: review_profile_id(),
    output_contract: packet.output_contract,
    context_pages,
    skill_paths: [absolute_review_skill_path],
    notes: review_external_notes(),
    tags: review_external_tags(packet),
    metadata: review_external_metadata(packet, result_path, execution_target),
  }
}

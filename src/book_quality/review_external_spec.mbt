///|
pub fn review_external_proposal_spec(
  packet : BookQualityReviewPacket,
  result_dir : String,
  execution_target : String,
) -> BookQualityReviewProposalSpec {
  let root = @core.absolute_path_from_cwd(packet.workspace_root)
  let result_path = review_result_path(result_dir, packet.book_id)
  let context_pages : Array[String] = []
  for page in packet.context_pages {
    context_pages.push(@path.Path(root).join(@path.Path(page)).to_string())
  }
  let skill_path = @core.absolute_path_from_cwd(packet.review_skill_path)
  {
    packet_id: "book-quality-ai-review-\{packet.book_id}",
    title: "AI semantic quality review: \{packet.book_id}",
    summary: "Semantic quality review for MoonBook `\{packet.book_id}`.",
    request_text: review_external_request(packet, root, result_path),
    profile: review_profile_id(),
    output_contract: packet.output_contract,
    context_pages,
    skill_paths: [skill_path],
    notes: review_external_notes(),
    tags: review_external_tags(packet),
    metadata: review_external_metadata(packet, result_path, execution_target),
  }
}

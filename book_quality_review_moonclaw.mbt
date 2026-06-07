///|
fn book_quality_external_review_packet(
  packet : BookQualityReviewPacket,
  result_dir : String,
) -> @moonclaw.ExternalProposalPacket {
  let root = @core.absolute_path_from_cwd(packet.workspace_root)
  let context_pages : Array[String] = []
  for page in packet.context_pages {
    context_pages.push(@path.Path(root).join(@path.Path(page)).to_string())
  }
  let skill_path = @core.absolute_path_from_cwd(packet.review_skill_path)
  @moonclaw.ExternalProposalPacket::new(
    packet_id="book-quality-ai-review-\{packet.book_id}",
    title="AI semantic quality review: \{packet.book_id}",
    summary="Semantic quality review for MoonBook `\{packet.book_id}`.",
    request_text=book_quality_external_review_request(packet, result_dir),
    profile=book_quality_review_profile_id(),
    output_contract=packet.output_contract,
    context_pages~,
    skill_paths=[skill_path],
    notes=[
      "This is a semantic review, not a structural existence check.", "Do not modify the book workspace; return the required review contract.",
      "Do not inflate score for operational logs or scaffolding.",
    ],
    tags=["book-quality", "ai-review", packet.book_type, packet.book_id],
    metadata=book_quality_external_review_metadata(packet, result_dir),
  )
}

///|
fn book_quality_external_review_metadata(
  packet : BookQualityReviewPacket,
  result_dir : String,
) -> Json {
  let fields : Map[String, Json] = {}
  add_moonclaw_no_input_policy(fields)
  fields["producer"] = "moontown".to_json()
  fields["book_id"] = packet.book_id.to_json()
  fields["book_type"] = packet.book_type.to_json()
  fields["result_path"] = book_quality_ai_review_result_path(
    result_dir,
    packet.book_id,
  ).to_json()
  fields["profile_metadata"] = moonclaw_no_input_policy_json()
  fields["step_metadata"] = book_quality_review_packet_step_metadata_json(
    packet.output_contract,
  )
  Json::object(fields)
}

///|
fn book_quality_external_review_request(
  packet : BookQualityReviewPacket,
  result_dir : String,
) -> String {
  [
    "You are the MoonBook semantic quality reviewer for Moontown.",
    "",
    "Book id: `\{packet.book_id}`",
    "Book type: `\{packet.book_type}`",
    "Workspace root: `\{@core.absolute_path_from_cwd(packet.workspace_root)}`",
    "Structural score: `\{packet.structural_score}`",
    "Result target after reconciliation: `\{book_quality_ai_review_result_path(result_dir, packet.book_id)}`",
    "",
    "Task:",
    "1. Read the review skill and the listed context pages.",
    "2. Judge the book's real quality for its role, not file completeness.",
    "3. Separate domain/service evidence from operational logs and scaffolding.",
    "4. Return exactly the `\{book_quality_review_output_contract()}` Markdown contract.",
    "5. Do not write repository files directly; Moontown will reconcile your returned contract into the durable result path.",
    "",
    packet.prompt,
  ].join("\n")
}

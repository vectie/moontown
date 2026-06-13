///|
fn review_external_proposal_spec(
  packet : @book_quality.BookQualityReviewPacket,
  result_dir : String,
) -> @book_quality.BookQualityReviewProposalSpec {
  @book_quality.review_external_proposal_spec_with_paths(
    packet,
    result_dir,
    @codex.codex_main_target_id(),
    @core.absolute_path_from_cwd(packet.workspace_root),
    @core.absolute_path_from_cwd(packet.review_skill_path),
  )
}

///|
fn book_quality_review_external_packet(
  spec : @book_quality.BookQualityReviewProposalSpec,
) -> @moonclaw.ExternalProposalPacket {
  @moonclaw.ExternalProposalPacket::new(
    packet_id=spec.packet_id,
    title=spec.title,
    summary=spec.summary,
    request_text=spec.request_text,
    profile=spec.profile,
    output_contract=spec.output_contract,
    context_pages=spec.context_pages,
    skill_paths=spec.skill_paths,
    notes=spec.notes,
    tags=spec.tags,
    metadata=spec.metadata,
  )
}

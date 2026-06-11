///|
async fn write_book_quality_review_packet_files(
  book_catalog_path : String,
  snapshot_path : String,
  review_dir : String,
) -> String {
  ignore(bootstrap_default_operational_books(book_catalog_path))
  let audit = inspect_book_quality(book_catalog_path~, snapshot_path~)
  write_text_file(
    "\{review_dir}/BOOK_QUALITY_REVIEW_SKILL.md",
    @book_quality.review_skill_markdown(),
  )
  let packets = write_book_quality_review_score_packets(audit, review_dir)
  write_text_file(
    "\{review_dir}/README.md",
    @book_quality.review_readme(audit, packets),
  )
  "Wrote \{packets.length()} AI quality review packet(s) to \{review_dir}. Run these with MoonClaw/MoonBook and write results to \{@book_quality.default_review_result_dir()}/<book-id>.md; structural checks only gate readiness."
}

///|
async fn write_book_quality_review_score_packets(
  audit : @book_quality.BookQualityAudit,
  review_dir : String,
) -> Array[@book_quality.BookQualityReviewPacket] {
  let packets : Array[@book_quality.BookQualityReviewPacket] = []
  for score in audit.scores {
    let packet = @book_quality.review_packet(score, review_dir)
    packets.push(packet)
    write_text_file(
      "\{review_dir}/\{score.book_id}.json",
      packet.to_json().stringify(indent=2),
    )
  }
  packets
}

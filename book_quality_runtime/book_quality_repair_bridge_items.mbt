///|
async fn write_book_quality_repair_review_page(
  item : @book_quality.BookQualityRepairBridgeItem,
  result_text : String,
) -> Unit {
  @support.write_text_file(
    item.book_review_path,
    @book_quality.repair_review_page_markdown(item, result_text),
  )
}

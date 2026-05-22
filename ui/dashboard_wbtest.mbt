///|
test "standing watch stage wins over bootstrap baseline text" {
  assert_eq(
    stage_label_for_text(
      "standing-watch-opc-news-tick-5", "Research OPC with raw/bootstrap as baseline context.",
    ),
    "Watch",
  )
}

///|
test "street feed leads with content and named icon actions" {
  let event : Json = {
    "id": "walk",
    "title": "河边散步",
    "description": "沿河观察植物",
    "state": "published",
    "location": "河边广场",
    "starts_ms": 4102444800000,
    "ends_ms": 4102452000000,
    "capacity": 20,
    "confirmed_count": 2,
  }
  let snapshot : Json = { "events": [event], "stories": [] }
  let state = { ..initial_neighborhood_state(), snapshot: Some(snapshot), }
  let html = disclosure_test_html(
    render_neighborhood_feed(_ => @rabbita.none, state),
  )
  assert_true(html.contains("河边散步"))
  assert_true(html.contains("沿河观察植物"))
  assert_true(html.contains("河边广场"))
  assert_true(html.contains("aria-label=\"查看河边散步\""))
  assert_true(html.contains("town-ui-icon"))
  assert_false(html.contains("了解安排，选择"))
  assert_false(html.contains(">查看</"))
  assert_true(html.contains("北京时间"))
}

///|
test "short street forms retain private visibility and explicit publication consent" {
  let dispatch : Dispatch[Msg] = _ => @rabbita.none
  let (_, model) = update_neighborhood_manage(
    dispatch,
    neighborhood_manage_fixture(),
    EditStory("story-a"),
  )
  let html = disclosure_test_html(render_neighborhood_manage(dispatch, model))
  assert_true(html.contains("nh-story-title"))
  assert_true(html.contains("nh-story-consent"))
  assert_true(html.contains("任何访客都能查看"))
  assert_true(html.contains("公开发布"))
  assert_false(html.contains("先保存草稿，再决定"))
  let receipt = disclosure_test_html(
    render_neighborhood_followup_receipt({
      "state": "resolved",
      "message": "希望继续交流",
      "next_step": "确认时间",
      "outcome": "已回复",
    }),
  )
  assert_true(receipt.contains("确认时间"))
  assert_true(receipt.contains("已有回复"))
  assert_false(receipt.contains("回复说明"))
}

///|
test "work attention has a named refresh action instead of a paragraph of instructions" {
  let html = disclosure_test_html(
    render_collaboration_attention(
      _ => @rabbita.none,
      @collaboration.Client::new(),
    ),
  )
  assert_true(html.contains("工作区待处理"))
  assert_true(html.contains("aria-label=\"刷新待处理\""))
  assert_true(html.contains("全部成果"))
  assert_false(html.contains("历史列表不代表"))
  assert_false(html.contains("先查看结果，再由"))
}

///|
test "spatial lift is one action while routing stays available on demand" {
  let html = disclosure_test_html(
    render_indoor_compute_lift(_ => @rabbita.none),
  )
  let primary = html.split_once("<details").unwrap().0.to_owned()
  assert_true(primary.contains("地下算力"))
  assert_true(primary.contains("aria-label="))
  assert_false(primary.contains("<h2"))
  assert_false(primary.contains("只读查看授权机器"))
  assert_true(html.contains("MoonGate"))
  assert_false(html.contains(" open"))
}

///|
test "compact disclosures do not repeat their labels as secondary headings" {
  let html = disclosure_test_html(
    render_advanced_details("对象目录", compact_label="对象", [
      p("正文"),
    ]),
  )
  assert_false(html.contains("town-advanced-heading"))
  assert_true(html.contains("正文"))
  assert_true(html.contains("aria-label=\"Advanced · 对象目录\""))
}

///|
test "imported output shell retains refresh and close without verification boilerplate" {
  let state = { ..initial_imported_outputs_state(), open: true, }
  let html = disclosure_test_html(
    render_imported_outputs_drawer(_ => @rabbita.none, state),
  )
  assert_true(html.contains("导入成果"))
  assert_true(html.contains("aria-label=\"刷新导入成果\""))
  assert_true(html.contains("aria-label=\"Close imported outputs\""))
  assert_false(html.contains("IMPORTED BOOK FILES"))
  assert_false(html.contains("host verifies every read"))
}

///|
fn disclosure_test_html(view : @rabbita.Html) -> String {
  @rabbita.render_to_string(@rabbita.static_cell(view))
}

///|
fn disclosure_test_book() -> KnowledgeDomainBook {
  {
    book_id: "research-fixture",
    title: "本地研究",
    question: "需要解决什么问题？",
    role: "researcher",
    template_id: "domain-research-book",
    policy_id: "governed-policy-v1",
    schedule_tier: "daily",
    cadence_ticks: 24,
    tags: ["policy"],
    source_policy: "primary-sources",
    status: "active",
  }
}

///|
test "advanced disclosure is closed by default and keyboard native" {
  let html = disclosure_test_html(
    render_advanced_details("运行规则", [p("细节")]),
  )
  assert_true(html.contains("<details"))
  assert_true(html.contains("aria-label=\"Advanced · 运行规则\""))
  assert_true(html.contains("title=\"运行规则\""))
  assert_true(html.contains("town-ui-icon"))
  assert_false(html.contains(" open"))
  assert_true(html.contains("细节"))
  assert_true(
    disclosure_test_html(
      render_advanced_details("需要修正", needs_attention=true, [
        p("错误"),
      ]),
    ).contains(" open"),
  )
}

///|
test "watch fields retain values and reveal invalid advanced settings" {
  let dispatch : Dispatch[Msg] = Emit(_ => @rabbita.none)
  let model = init_model()
  let html = disclosure_test_html(render_request_composer(dispatch, model))
  let primary = html.split("<details").to_array()[0]
  assert_true(primary.contains("watch-title"))
  assert_true(primary.contains("watch-target-book"))
  assert_false(primary.contains("watch-quality-threshold"))
  assert_false(primary.contains("request-check-frequency"))
  assert_false(html.contains(" open"))
  assert_true(html.contains("value=\"85\""))
  assert_true(html.contains("value=\"60\""))
  for value in ["", "oops", "0", "101"] {
    let invalid = { ..model, request_quality_threshold: value, }
    assert_true(
      disclosure_test_html(render_request_composer(dispatch, invalid)).contains(
        " open",
      ),
    )
  }
  assert_false(advanced_integer_needs_attention("1", max=100))
  assert_false(advanced_integer_needs_attention("100", max=100))
}

///|
test "library shows results first and keeps unproduced catalog in advanced" {
  let book = disclosure_test_book()
  let domain : KnowledgeDomain = {
    domain_id: "fixture",
    title: "政策研究",
    icon: "",
    building_id: "policy-hall",
    kind: "civic-core",
    primary_book_id: book.book_id,
    policy_id: book.policy_id,
    communication_scenario_ids: [],
    summary: "研究本地议题",
    books: [book],
  }
  let empty = disclosure_test_html(
    render_knowledge_domain_library(init_model(), domain),
  )
  let primary = empty.split("<details").to_array()[0]
  assert_true(primary.contains("还没有可查看的研究结果"))
  assert_false(primary.contains(book.book_id))
  assert_false(primary.contains(book.policy_id))
  assert_false(primary.contains("knowledge-book-card"))
  assert_true(empty.contains(book.book_id))
  assert_false(empty.contains(" open"))
  let projection = {
    ..knowledge_projection_fixture(None),
    links: [
      {
        label: "阅读结果",
        kind: "report",
        url: "/book-output/research-fixture/report.html",
      },
    ],
  }
  let model = { ..init_model(), module_projections: [projection], }
  let ready = disclosure_test_html(
    render_knowledge_domain_library(model, domain),
  )
  let primary = ready.split("<details").to_array()[0]
  assert_true(primary.contains("已有资料"))
  assert_true(primary.contains("/book-output/research-fixture/report.html"))
  assert_false(primary.contains("已验收"))
  assert_false(primary.contains("Cadence"))
  assert_false(primary.contains("Source policy"))
  let unsafe_projection = {
    ..projection,
    links: [{ label: "Unsafe", kind: "report", url: "javascript:alert(1)", }],
  }
  let unsafe_model = { ..model, module_projections: [unsafe_projection], }
  let unsafe_html = disclosure_test_html(
    render_knowledge_book_card(unsafe_model, book, false),
  )
  assert_false(unsafe_html.contains("href="))
}

///|
test "town actions keep work visible and maintenance in advanced" {
  let dispatch : Dispatch[Msg] = Emit(_ => @rabbita.none)
  let html = disclosure_test_html(
    render_town_action_rail(dispatch, init_model(), false, 7),
  )
  let sections = html.split("<details class=\"town-advanced\"").to_array()
  assert_eq(sections.length(), 2)
  assert_true(sections[0].contains("发起工作"))
  assert_true(sections[0].contains("联络"))
  assert_false(sections[0].contains("地图诊断"))
  assert_false(sections[0].contains("重置小镇"))
  assert_true(sections[1].contains("地图诊断"))
  assert_true(sections[1].contains("重置小镇"))
  assert_true(sections[1].contains("town-pack-tools-open"))
}

///|
test "work dialog omits repeated headings without hiding the active task form" {
  let dispatch : Dispatch[Msg] = Emit(_ => @rabbita.none)
  let html = disclosure_test_html(
    render_energy_valley_request_dialog(dispatch, {
      ..init_model(),
      request_composer: StandingWatchComposer,
    }),
  )
  assert_false(html.contains("Request Desk"))
  assert_true(html.contains("发起工作"))
  assert_true(html.contains("watch-request"))
  assert_true(html.contains("保存关注"))
}

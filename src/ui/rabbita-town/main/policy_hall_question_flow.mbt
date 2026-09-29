///|
let policy_hall_question_context_key = "policy-hall:changping"

///|
fn policy_hall_question_selected(model : Model) -> Bool {
  match spatial_origin_building(model) {
    Some(building) =>
      golden_valley_building_module_key(building) == "policy-hall"
    None => false
  }
}

///|
fn policy_hall_question_prompts() -> Array[String] {
  [
    "这个昌平本地议题涉及哪些人群和政策领域？还缺哪些证据？",
    "从问题、证据到政策选项，需要准备哪些材料？", "哪些政策金额和条件必须向主管部门复核？",
  ]
}

///|
fn policy_hall_question_greeting() -> String {
  "这里是昌平政策大厅，不限青年领域。先说明你的议题、受影响人群、现状与目标；我们一起区分证据、政策选项和实施约束。目前已整理的专题资料主要是青年创业，其他领域尚待补充权威来源，不能据此断言政策覆盖。"
}

///|
fn render_policy_hall_map_entry(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  if model.energy_selected_building is Some(_) || model.phone_open {
    return @html.nothing
  }
  button(
    class="policy-hall-map-entry pointer-events-auto",
    on_click=dispatch(EnterEnergyBuilding("policy-hall")),
    attrs=@html.Attrs::build().aria_label(
      "进入政策大厅，查看并询问昌平政策",
    ),
    [
      span(class="policy-hall-map-entry-dot", "●"),
      span(class="policy-hall-map-entry-copy", [
        span(class="policy-hall-map-entry-title", "昌平政策大厅"),
        span(class="policy-hall-map-entry-hint", "进入政策大厅"),
      ]),
      span(class="policy-hall-map-entry-arrow", "→"),
    ],
  )
}

///|
fn render_policy_hall_question_action(
  dispatch : Dispatch[Msg],
  building : GoldenValleyBuilding,
) -> @rabbita.Html {
  if golden_valley_building_module_key(building) != "policy-hall" {
    return @html.nothing
  }
  section(
    class="policy-hall-question-action",
    attrs=@html.Attrs::build().aria_label("昌平政策问答"),
    [
      div(class="policy-hall-question-copy", [
        span(
          class="policy-hall-question-eyebrow",
          "POLICY Q&A · 有来源边界",
        ),
        h2(class="policy-hall-question-title", "你的本地议题是什么？"),
        p(
          class="policy-hall-question-description",
          "从现状、受影响人群和目标开始；一起梳理证据与政策选项。回答区分官网、OCR 与待复核项，未覆盖的领域会明确说明。",
        ),
      ]),
      button(
        class="policy-hall-question-button",
        on_click=dispatch(OpenMoonclawGuide),
        attrs=@html.Attrs::build().aria_label(
          "打开 Moonclaw，询问昌平政策",
        ),
        "询问政策 →",
      ),
    ],
  )
}

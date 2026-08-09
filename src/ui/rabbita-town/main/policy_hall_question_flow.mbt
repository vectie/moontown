///|
let policy_hall_question_context_key = "policy-hall:changping-youth-entrepreneurship-policy"

///|
fn policy_hall_question_selected(model : Model) -> Bool {
  match model.energy_selected_building {
    Some(building) =>
      golden_valley_building_module_key(building) == "policy-hall"
    None => false
  }
}

///|
fn policy_hall_question_prompts() -> Array[String] {
  [
    "我可能符合哪些昌平青年创业支持？请先告诉我还缺哪些资格信息。",
    "申请昌平青年创业支持前，需要准备哪些材料？", "哪些政策金额和条件必须向主管部门复核？",
  ]
}

///|
fn policy_hall_question_greeting() -> String {
  "这里是政策大厅的昌平青创政策问答。我会先了解年龄、学历或出站情况、企业在昌注册经营、社保和当前需求，再给出初步匹配；答复会区分官网确认、现场 OCR 和待复核信息。"
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
    on_click=dispatch(OpenEnergyBuilding("policy-hall")),
    attrs=@html.Attrs::build().aria_label(
      "进入政策大厅，查看并询问昌平青年创新创业政策",
    ),
    [
      span(class="policy-hall-map-entry-dot", "●"),
      span(class="policy-hall-map-entry-copy", [
        span(class="policy-hall-map-entry-title", "昌平青创政策"),
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
    attrs=@html.Attrs::build().aria_label(
      "昌平青年创新创业政策问答",
    ),
    [
      div(class="policy-hall-question-copy", [
        span(
          class="policy-hall-question-eyebrow",
          "POLICY Q&A · 有来源边界",
        ),
        h2(class="policy-hall-question-title", "问昌平青创政策"),
        p(
          class="policy-hall-question-description",
          "告诉小爪你的年龄、学历/出站情况、企业注册经营、社保和需求；回答会标注官网、OCR 与待复核项。",
        ),
      ]),
      button(
        class="policy-hall-question-button",
        on_click=dispatch(OpenMoonclawGuide),
        attrs=@html.Attrs::build().aria_label(
          "打开 Moonclaw，询问昌平青年创新创业政策",
        ),
        "询问政策 →",
      ),
    ],
  )
}

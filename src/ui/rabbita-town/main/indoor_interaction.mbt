///|
fn render_indoor_slot_inspector(
  dispatch : Dispatch[Msg],
  model : Model,
  snapshot : @energy_valley_contract.TownSnapshot,
  place : @energy_valley_contract.Place,
) -> @rabbita.Html {
  let selected = place.interaction_slots
    .iter()
    .find_first(slot => slot.id.local_key() == model.indoor_selected_slot_id)
  section(
    class="building-interior-panel indoor-slot-inspector",
    attrs=@html.Attrs::build().aria_live("polite"),
    [
      h2(selected.map(slot => slot.label).unwrap_or("选择房间里的家具")),
      div(
        class="indoor-slot-roster",
        place.interaction_slots
        .iter()
        .map(slot => {
          button(
            class=if selected is Some(value) && value.id == slot.id {
              "is-selected"
            } else {
              ""
            },
            on_click=dispatch(SelectIndoorSlot(slot.id.local_key())),
            attrs=@html.Attrs::build().aria_pressed(
              if model.indoor_selected_slot_id == slot.id.local_key() {
                "true"
              } else {
                "false"
              },
            ),
            slot.label,
          )
        })
        .to_array(),
      ),
      match selected {
        None =>
          p(
            "点击家具或上方名称，查看用途和居民；工作台可创建真实工作，门可返回小镇。",
          )
        Some(slot) =>
          div([
            p(
              "\{town_snapshot_interior_kind_label(slot.kind)} · 容量 \{slot.capacity}",
            ),
            p(
              "\{town_snapshot_slot_presences(snapshot, place.id, slot.id).length()} 位居民在此；预览居民不代表真实执行。",
            ),
            match slot.kind {
              @energy_valley_contract.TransitGate =>
                button(
                  on_click=dispatch(ExitEnergyBuilding),
                  "从门口返回小镇",
                )
              @energy_valley_contract.Bench =>
                p(
                  "休息与会面地点；选择楼内工作可查看真实协作，不会模拟新任务。",
                )
              @energy_valley_contract.Exhibit | @energy_valley_contract.Stage =>
                p(
                  "在下方楼内工作中选择一项，打开它已发布的结果并记录审阅。没有证据时不展示虚构成果。",
                )
              _ =>
                button(
                  on_click=dispatch(StartIndoorWork),
                  "在这里提出议题 / 创建工作",
                )
            },
            @html.details([
              @html.summary("语义实体信息"),
              p(
                "Place：\{place.id.local_key()} · Slot：\{slot.id.local_key()}",
              ),
            ]),
          ])
      },
    ],
  )
}

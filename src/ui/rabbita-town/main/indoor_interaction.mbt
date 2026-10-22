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
      h2(selected.map(slot => slot.label).unwrap_or("选择家具")),
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
          p("点击家具或上方名称，查看用途并开始工作。")
        Some(slot) =>
          div([
            p(
              "\{town_snapshot_interior_kind_label(slot.kind)} · 容量 \{slot.capacity}",
            ),
            p(
              "\{town_snapshot_slot_presences(snapshot, place.id, slot.id).length()} 位居民在此 · 含预览",
            ),
            match slot.kind {
              @energy_valley_contract.TransitGate =>
                button(
                  on_click=dispatch(ExitEnergyBuilding),
                  town_ui_label("back", "小镇"),
                )
              @energy_valley_contract.Bench => p("休息与会面地点。")
              @energy_valley_contract.Exhibit | @energy_valley_contract.Stage =>
                p("选择楼内工作，阅读已发布的结果。")
              _ =>
                button(
                  on_click=dispatch(StartIndoorWork),
                  town_ui_label("work", "新工作"),
                )
            },
            render_advanced_details("语义实体信息", [
              p(
                "预览居民不代表真实执行；楼内工作以运行时记录为准。",
              ),
              p(
                "Place：\{place.id.local_key()} · Slot：\{slot.id.local_key()}",
              ),
            ]),
          ])
      },
    ],
  )
}

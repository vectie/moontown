///|
priv struct TownRoomSlot {
  id : String
  name : String
  kind : String
  x : Double
  z : Double
} derive(FromJson)

///|
priv struct TownRoomInput {
  title : String
  slots : Array[TownRoomSlot]
} derive(FromJson)

///|
/// Reuses the authored interior furniture for semantic town workspaces. This is
/// a presentation layout, never a surveyed replacement for the G3 reference plan.
pub fn town_interior_study(text : String) -> Json {
  let input : TownRoomInput = @json.from_json(
    @json.parse(text) catch {
      _ => return Json::null()
    },
  ) catch {
    _ => return Json::null()
  }
  guard input.slots.length() <= 128 else { return Json::null() }
  let p : Array[Part] = []
  box(p, "oak", 0, -0.12, 0, 24, 0.25, 18, layer="floor")
  box(p, "plaster", 0, 1.8, -9, 24, 3.6, 0.22, layer="walls")
  box(p, "plaster", -12, 1.8, 0, 0.22, 3.6, 18, layer="walls")
  box(p, "wood", 0, 3.65, -9, 24, 0.18, 0.4, layer="walls")
  box(p, "wood", -12, 3.65, 0, 0.4, 0.18, 18, layer="walls")
  for i in 0..<6 {
    let x = -9.5 + i.to_double() * 3.7
    box(p, "glassLight", x, 2.0, -8.85, 2.8, 2.2, 0.08, layer="walls")
    box(p, "ivory", x, 2.0, -8.76, 0.07, 2.3, 0.12, layer="walls")
    box(p, "ivory", x, 2.0, -8.76, 2.9, 0.07, 0.12, layer="walls")
  }
  let entities : Array[ComputeEntity] = []
  for slot in input.slots {
    let x = (slot.x.clamp(min=0.1, max=0.9) - 0.5) * 22
    let z = (slot.z.clamp(min=0.1, max=0.9) - 0.5) * 14
    let start = p.length()
    let u = x / 0.06 + 840
    let v = z / 0.06 + 710
    match slot.kind {
      "meeting" => meeting_table(p, u, v, 4)
      "bench" => {
        box(p, "fabric", x, 0.45, z, 2.1, 0.5, 0.8)
        box(p, "fabric", x, 0.9, z - 0.35, 2.1, 0.7, 0.18)
      }
      "gate" => {
        box(p, "metal", x, 1.5, z, 2.1, 3, 0.14)
        box(p, "glassLight", x, 1.55, z + 0.08, 1.8, 2.7, 0.06)
        box(p, "lamp", x, 3.1, z, 2.3, 0.12, 0.25)
      }
      "stage" | "exhibit" => {
        box(p, "wood", x, 0.15, z, 2.5, 0.3, 1.6)
        box(p, "metal", x, 1.3, z - 0.5, 1.8, 1.2, 0.12)
        box(p, "screen", x, 1.3, z - 0.42, 1.65, 1.05, 0.03)
      }
      "service" | "exchange" => {
        box(p, "oak", x, 0.55, z, 2.3, 1.1, 0.9)
        box(p, "ivory", x, 1.14, z, 2.5, 0.12, 1.0)
        box(p, "screen", x + 0.5, 1.4, z, 0.55, 0.35, 0.08)
      }
      _ => workdesk(p, u, v)
    }
    box(p, "carpetSage", x, 0.02, z, 3.2, 0.03, 2.8)
    for i in start..<p.length() {
      p[i] = { ..p[i], layer: slot.id, caption: slot.id, }
    }
    entities.push(
      dc_entity(
        slot.id,
        slot.name,
        slot.kind,
        [x, 0.8, z],
        "系统工作空间",
      ),
    )
  }
  for (x, z) in [(-10.5, -7.5), (10.5, -7.5), (-10.5, 7.0)] {
    interior_plant(p, x / 0.06 + 840, z / 0.06 + 710)
  }
  ToJson::to_json(
    dc_view(
      "room",
      input.title,
      "语义工作空间 · 示意布局",
      30,
      [0, 0, 0],
      [18, 18, 22],
      p,
      entities,
      [],
    ),
  )
}

///|
priv struct ComputeEntity {
  id : String
  name : String
  kind : String
  position : Array[Double]
  detail : String
  visit : String
} derive(ToJson)

///|
priv struct ComputeFlow {
  id : String
  family : String
  title : String
  detail : String
  points : Array[Array[Double]]
} derive(ToJson)

///|
priv struct ComputeView {
  study : Study
  entities : Array[ComputeEntity]
  flows : Array[ComputeFlow]
} derive(ToJson)

///|
fn dc_entity(
  id : String,
  name : String,
  kind : String,
  position : Array[Double],
  detail : String,
  visit? : String = "",
) -> ComputeEntity {
  { id, name, kind, position, detail, visit, }
}

///|
fn dc_flow(
  id : String,
  family : String,
  title : String,
  detail : String,
  points : Array[Array[Double]],
) -> ComputeFlow {
  { id, family, title, detail, points, }
}

///|
// A semantic layer is also a pick target. Decorative meshes inherit that ID.
fn dc_box(
  p : Array[Part],
  id : String,
  mat : String,
  x : Double,
  y : Double,
  z : Double,
  w : Double,
  h : Double,
  d : Double,
) -> Unit {
  box(p, mat, x, y, z, w, h, d, layer=id)
}

///|
fn dc_view(
  id : String,
  title : String,
  subtitle : String,
  span : Double,
  focus : Array[Double],
  offset : Array[Double],
  parts : Array[Part],
  entities : Array[ComputeEntity],
  flows : Array[ComputeFlow],
) -> ComputeView {
  {
    study: {
      id,
      title,
      subtitle,
      description: "MoonTown infrastructure design study",
      note: "Concept geometry · illustrative flows · not an as-built survey",
      span,
      focus,
      detail_focus: focus,
      detail_offset: offset,
      parts,
    },
    entities,
    flows,
  }
}

///|
/// Multiscale concept model. No physical placement or sensor values are claimed.
pub fn data_center_study() -> Json {
  let views = [
    dc_site(),
    dc_hall(),
    dc_rack(),
    dc_server(false),
    dc_server(true),
  ]
  {
    "schema": "moontown.datacenter-study.v1",
    "provenance": "Design scenario — not a surveyed facility or measured hardware",
    "views": views.to_json(),
  }
}

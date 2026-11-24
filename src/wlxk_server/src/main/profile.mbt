///|
fn hash(value : String) -> String {
  @crypto.bytes_to_hex_string(@crypto.sha256(@utf8.encode(value)))
}

///|
fn field(value : Json, key : String) -> Json {
  match value {
    Object(fields) => fields.get(key).unwrap_or(Json::null())
    _ => Json::null()
  }
}

///|
fn text_field(value : Json, key : String) -> String {
  match field(value, key) {
    String(value) => value
    _ => ""
  }
}

///|
fn valid_name(value : String) -> Bool {
  !value.is_empty() &&
  value.length() <= 10 &&
  value.all(c => {
    c
    is ('\u{4e00}'..<='\u{9fff}'
    | 'A'..<='Z'
    | 'a'..<='z'
    | '0'..<='9'
    | '_'
    | '-'
    | '·')
  })
}

///|
fn valid_number(value : Json, bound : Double) -> Bool {
  match value {
    Number(n, ..) => n >= -bound && n <= bound
    _ => false
  }
}

///|
fn clean_pos(value : Json) -> Json? {
  if valid_number(field(value, "x"), 10000.0) &&
    valid_number(field(value, "z"), 10000.0) &&
    valid_number(field(value, "yaw"), 100.0) {
    Some({
      "x": field(value, "x"),
      "z": field(value, "z"),
      "yaw": field(value, "yaw"),
    })
  } else {
    None
  }
}

///|
fn clean_look(value : Json) -> Json {
  let result : Map[String, Json] = Map([])
  for
    key in [
      "gender", "skin", "hairC", "shirt", "pants", "hair", "top", "bot", "hat",
    ] {
    match field(value, key) {
      String(v) if v.length() <= 32 &&
        v.all(c => c is ('a'..<='z' | 'A'..<='Z' | '0'..<='9' | '#' | '-' | '_')) =>
        result[key] = Json(v)
      Null if key == "hat" => result[key] = Json::null()
      _ => ()
    }
  }
  Json::object(result)
}

///|
fn merge_save(previous : Json, incoming : Json) -> Json {
  // Identity, nickname and storage keys are never accepted from a save payload.
  let fields : Map[String, Json] = Map([])
  if previous is Object(old) {
    for k, v in old {
      fields[k] = v
    }
  }
  if clean_pos(field(incoming, "pos")) is Some(pos) {
    fields["pos"] = pos
  }
  if field(incoming, "look") is Object(_) {
    fields["look"] = clean_look(field(incoming, "look"))
  }
  if field(incoming, "visited") is Array(items) {
    fields["visited"] = Json(
      items[:items.length().min(50)]
      .to_owned()
      .filter(item => {
        match item {
          String(s) => s.length() <= 100
          _ => false
        }
      }),
    )
  }
  if field(incoming, "metGuide") is True {
    fields["metGuide"] = Json(true)
  }
  if field(incoming, "metGuide") is False {
    fields["metGuide"] = Json(false)
  }
  Json::object(fields)
}

///|
fn public_player(profile : Json, pose : Json) -> Json {
  let out : Map[String, Json] = {
    "id": field(profile, "id"),
    "name": field(profile, "name"),
    "look": field(profile, "look"),
    "st": field(pose, "st"),
  }
  for key in ["x", "y", "z", "yaw"] {
    out[key] = field(pose, key)
  }
  Json::object(out)
}

///|
test "saves cannot replace identity, and invalid positions cannot corrupt a save" {
  let old : Json = {
    "id": "owner",
    "name": "Alice",
    "pos": { "x": 1, "z": 2, "yaw": 0 },
  }
  let changed = merge_save(old, {
    "id": "victim",
    "name": "Bob",
    "pos": { "x": 100001, "z": 2, "yaw": 0 },
    "visited": ["plaza", {}],
    "look": { "script": "no", "shirt": "#aa1122" },
  })
  assert_eq(field(changed, "id"), Json("owner"))
  assert_eq(field(changed, "name"), Json("Alice"))
  assert_eq(field(changed, "pos"), field(old, "pos"))
  assert_eq(field(changed, "visited"), Json([Json("plaza")]))
  assert_eq(
    field(changed, "look"),
    ({ "shirt": "#aa1122", "hat": null } : Json),
  )
}

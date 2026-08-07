///|
fn town_snapshot_installation_tag(
  installation : @energy_valley_contract.Installation,
  prefix : String,
) -> String? {
  for tag in installation.tags {
    if tag.has_prefix(prefix) {
      return Some(tag[prefix.length():].to_owned())
    }
  }
  None
}

///|
fn town_snapshot_installation_tag_int(
  installation : @energy_valley_contract.Installation,
  prefix : String,
  fallback : Int,
) -> Int {
  match town_snapshot_installation_tag(installation, prefix) {
    Some(value) => @string.parse_int(value) catch { _ => fallback }
    None => fallback
  }
}

///|
fn town_snapshot_installation_position(
  installation : @energy_valley_contract.Installation,
) -> @energy_valley_contract.WorldPoint? {
  installation.representative_position()
}

///|
fn town_snapshot_installation_depth(
  installation : @energy_valley_contract.Installation,
) -> Int {
  if installation.kind is @energy_valley_contract.Boardwalk {
    let x = town_snapshot_installation_tag_int(installation, "tile-x:", 0)
    let y = town_snapshot_installation_tag_int(installation, "tile-y:", 0)
    x + y + 1
  } else {
    town_snapshot_installation_position(installation)
    .map(point => (point.x + point.y + 0.45).floor().to_int())
    .unwrap_or(-1)
  }
}

///|
fn town_snapshot_installations_by_depth(
  snapshot : @energy_valley_contract.TownSnapshot,
) -> Map[Int, Array[@energy_valley_contract.Installation]] {
  let result : Map[Int, Array[@energy_valley_contract.Installation]] = Map([])
  for installation in snapshot.world.installations {
    let depth = town_snapshot_installation_depth(installation)
    match result.get(depth) {
      Some(items) => items.push(installation)
      None => result[depth] = [installation]
    }
  }
  result
}

///|
fn golden_draw_town_snapshot_installations(
  context : @dom.CanvasRenderingContext2D,
  installations : ArrayView[@energy_valley_contract.Installation],
  viewport_width : Int,
  viewport_height : Int,
  hour : Double,
) -> Unit {
  for installation in installations {
    match installation.kind {
      @energy_valley_contract.Boardwalk => {
        let x = town_snapshot_installation_tag_int(installation, "tile-x:", 0)
        let y = town_snapshot_installation_tag_int(installation, "tile-y:", 0)
        let edge = town_snapshot_installation_tag_int(installation, "edge:", 0)
        golden_draw_public_boardwalk(
          context,
          golden_screen_x(
            x.to_double() + 0.5,
            y.to_double() + 0.5,
            viewport_width,
          ),
          golden_screen_y(
            x.to_double() + 0.5,
            y.to_double() + 0.5,
            viewport_height,
          ),
          golden_valley_camera_zoom(),
          edge,
        )
      }
      @energy_valley_contract.Tree =>
        match town_snapshot_installation_position(installation) {
          None => ()
          Some(point) =>
            if town_snapshot_installation_tag(installation, "kind:") ==
              Some("woodland") {
              golden_draw_reference_tree(
                context,
                golden_screen_x(point.x, point.y, viewport_width),
                golden_screen_y(point.x, point.y, viewport_height),
                golden_valley_camera_zoom(),
                golden_reference_hash(installation.id.to_string()),
                golden_animation_seconds(),
              )
            } else {
              golden_draw_public_street_tree(
                context,
                golden_screen_x(point.x, point.y, viewport_width),
                golden_screen_y(point.x, point.y, viewport_height),
                golden_valley_camera_zoom(),
                town_snapshot_installation_tag_int(
                  installation, "road-mask:", 0,
                ),
                town_snapshot_installation_tag_int(installation, "side:", 1),
              )
            }
        }
      @energy_valley_contract.Light =>
        match town_snapshot_installation_position(installation) {
          Some(point) =>
            golden_draw_public_streetlight(
              context,
              golden_screen_x(point.x, point.y, viewport_width),
              golden_screen_y(point.x, point.y, viewport_height),
              golden_valley_camera_zoom(),
              town_snapshot_installation_tag_int(installation, "road-mask:", 0),
              town_snapshot_installation_tag_int(installation, "side:", 1),
              golden_public_realm_is_night(hour),
            )
          None => ()
        }
      @energy_valley_contract.Bench =>
        match town_snapshot_installation_position(installation) {
          Some(point) =>
            golden_draw_public_bench(
              context,
              golden_screen_x(point.x, point.y, viewport_width),
              golden_screen_y(point.x, point.y, viewport_height),
              golden_valley_camera_zoom(),
              if ecosystem_stable_hash(installation.id.to_string()) % 2 == 0 {
                1
              } else {
                -1
              },
            )
          None => ()
        }
      @energy_valley_contract.Custom("planter") =>
        match town_snapshot_installation_position(installation) {
          Some(point) =>
            golden_draw_public_planter(
              context,
              golden_screen_x(point.x, point.y, viewport_width),
              golden_screen_y(point.x, point.y, viewport_height),
              golden_valley_camera_zoom(),
            )
          None => ()
        }
      _ => ()
    }
  }
}

///|
fn golden_draw_town_snapshot_metro_underlay(
  context : @dom.CanvasRenderingContext2D,
  snapshot : @energy_valley_contract.TownSnapshot,
  visible : Bool,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  if !visible {
    return
  }
  for installation in snapshot.world.installations {
    if !(installation.kind is @energy_valley_contract.MetroAlignment) {
      continue
    }
    guard installation.geometry is @energy_valley_contract.AlongPath(path) else {
      continue
    }
    let points : Array[String] = []
    for point in path {
      points.push(
        "[\{golden_screen_x(point.x, point.y, viewport_width)},\{golden_screen_y(point.x, point.y, viewport_height)}]",
      )
    }
    golden_draw_metro_line(
      context,
      "[\{points.join(",")}]",
      golden_valley_camera_zoom(),
    )
  }
}

///|
fn golden_draw_town_snapshot_metro_landmarks(
  context : @dom.CanvasRenderingContext2D,
  snapshot : @energy_valley_contract.TownSnapshot,
  visible : Bool,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  if !visible {
    return
  }
  for place in snapshot.world.places {
    if place.kind is @energy_valley_contract.TransitStation {
      let center = ecosystem_canvas_place_center(place)
      golden_draw_metro_station(
        context,
        golden_screen_x(center.0, center.1, viewport_width),
        golden_screen_y(center.0, center.1, viewport_height),
        golden_valley_camera_zoom(),
        place.name,
        "\{place.entrances.length()} 个出入口",
      )
    }
  }
  for installation in snapshot.world.installations {
    if installation.kind is @energy_valley_contract.TransitEntrance {
      match town_snapshot_installation_position(installation) {
        Some(point) =>
          golden_draw_metro_station_exit(
            context,
            golden_screen_x(point.x, point.y, viewport_width),
            golden_screen_y(point.x, point.y, viewport_height),
            golden_valley_camera_zoom(),
            town_snapshot_installation_tag(installation, "exit:").unwrap_or(
              "•",
            ),
          )
        None => ()
      }
    }
  }
}

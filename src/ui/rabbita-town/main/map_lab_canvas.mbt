///|
extern "js" fn map_lab_canvas_save(
  context : @dom.CanvasRenderingContext2D,
) -> Unit =
  #| context => context.save()

///|
extern "js" fn map_lab_canvas_restore(
  context : @dom.CanvasRenderingContext2D,
) -> Unit =
  #| context => context.restore()

///|
extern "js" fn map_lab_canvas_line_dash(
  context : @dom.CanvasRenderingContext2D,
  dashed : Bool,
) -> Unit =
  #| (context, dashed) => context.setLineDash(dashed ? [6, 5] : [])

///|
extern "js" fn schedule_map_lab_canvas(callback : () -> Unit) -> Unit =
  #| callback => {
  #|   if (typeof globalThis.requestAnimationFrame === "function") {
  #|     globalThis.requestAnimationFrame(() => callback());
  #|   }
  #| }

///|
/// The transparent diagnostic canvas tracks camera/viewport changes without
/// coupling itself to the legacy renderer's frame loop. Polling only triggers
/// a paint when those values change; reduced-motion users therefore receive
/// no continuous diagnostic animation.
extern "js" fn install_map_lab_canvas_renderer(callback : () -> Unit) -> Unit =
  #| callback => {
  #|   globalThis.__moontownMapLabRender = callback;
  #|   if (typeof globalThis.requestAnimationFrame !== "function") return;
  #|   if (globalThis.__moontownMapLabObserver) return;
  #|   globalThis.__moontownMapLabObserver = true;
  #|   let signature = "";
  #|   const frame = () => {
  #|     const canvas = globalThis.document?.getElementById("map-lab-canvas");
  #|     const camera = globalThis.__moontownGoldenValleyCamera;
  #|     if (canvas && camera) {
  #|       const next = [camera.x, camera.y, camera.z,
  #|         canvas.clientWidth, canvas.clientHeight].join(":");
  #|       if (next !== signature) {
  #|         signature = next;
  #|         globalThis.__moontownMapLabRender?.();
  #|       }
  #|     } else {
  #|       signature = "";
  #|     }
  #|     globalThis.requestAnimationFrame(frame);
  #|   };
  #|   globalThis.requestAnimationFrame(frame);
  #| }

///|
/// Read-only presentation state for the diagnostic overlay. The semantic
/// frame is supplied separately and shared with the main town Canvas.
priv struct MapLabCanvasViewState {
  open : Bool
  layers : Array[MapLabLayer]
  selected_id : String
}

///|
fn map_lab_polygon_center(
  polygon : @energy_valley_contract.Polygon,
) -> @energy_valley_contract.WorldPoint {
  if polygon.vertices.is_empty() {
    return @energy_valley_contract.world_point(0.0, 0.0)
  }
  let mut x = 0.0
  let mut y = 0.0
  let mut z = 0.0
  for point in polygon.vertices {
    x += point.x
    y += point.y
    z += point.z
  }
  let count = polygon.vertices.length().to_double()
  @energy_valley_contract.world_point(x / count, y / count, z=z / count)
}

///|
fn map_lab_draw_path(
  context : @dom.CanvasRenderingContext2D,
  points : ReadOnlyArray[@energy_valley_contract.WorldPoint],
  viewport_width : Int,
  viewport_height : Int,
  color : String,
  width : Double,
  closed : Bool,
  fill : String?,
) -> Unit {
  if points.length() < 2 {
    return
  }
  golden_ctx_stroke_style(context, color)
  golden_ctx_line_width(context, width)
  context.begin_path()
  context.move_to(
    golden_screen_x(points[0].x, points[0].y, viewport_width),
    golden_screen_y(points[0].x, points[0].y, viewport_height),
  )
  for index in 1..<points.length() {
    context.line_to(
      golden_screen_x(points[index].x, points[index].y, viewport_width),
      golden_screen_y(points[index].x, points[index].y, viewport_height),
    )
  }
  if closed {
    context.close_path()
  }
  match fill {
    Some(fill_color) => {
      golden_ctx_fill_style(context, fill_color)
      context.fill()
    }
    None => ()
  }
  context.stroke()
}

///|
fn map_lab_draw_polygon(
  context : @dom.CanvasRenderingContext2D,
  polygon : @energy_valley_contract.Polygon,
  viewport_width : Int,
  viewport_height : Int,
  color : String,
  width : Double,
  fill : String?,
) -> Unit {
  map_lab_draw_path(
    context,
    polygon.vertices,
    viewport_width,
    viewport_height,
    color,
    width,
    true,
    fill,
  )
}

///|
fn map_lab_draw_marker(
  context : @dom.CanvasRenderingContext2D,
  point : @energy_valley_contract.WorldPoint,
  viewport_width : Int,
  viewport_height : Int,
  color : String,
  radius : Double,
  ring : Bool,
) -> Unit {
  let x = golden_screen_x(point.x, point.y, viewport_width)
  let y = golden_screen_y(point.x, point.y, viewport_height)
  context.begin_path()
  context.arc(x, y, radius, 0.0, 6.2832)
  if ring {
    golden_ctx_stroke_style(context, color)
    golden_ctx_line_width(context, 2.0)
    context.stroke()
  } else {
    golden_ctx_fill_style(context, color)
    context.fill()
  }
}

///|
fn map_lab_terrain_colors(
  kind : @energy_valley_contract.TerrainKind,
) -> (String, String) {
  match kind {
    Water => ("rgba(56,189,248,.72)", "rgba(14,116,144,.20)")
    Wetland => ("rgba(45,212,191,.66)", "rgba(13,148,136,.16)")
    Woodland => ("rgba(74,222,128,.64)", "rgba(22,163,74,.13)")
    Meadow => ("rgba(163,230,53,.56)", "rgba(101,163,13,.10)")
    Paving => ("rgba(203,213,225,.52)", "rgba(100,116,139,.10)")
    Restricted => ("rgba(251,113,133,.64)", "rgba(190,24,93,.12)")
    Custom(_) => ("rgba(192,132,252,.62)", "rgba(126,34,206,.10)")
  }
}

///|
fn map_lab_program_color(program_key : String) -> String {
  match program_key {
    "research-lab" | "research-garden" => "rgba(129,140,248,.62)"
    "street-homes" | "residential-court" => "rgba(251,146,60,.58)"
    "park-pavilion" | "park-commons" => "rgba(74,222,128,.58)"
    "waterfront-walk" | "waterfront-pavilion" => "rgba(34,211,238,.62)"
    "transit-hall" | "transit-court" => "rgba(244,114,182,.64)"
    "civic-hall" | "civic-court" => "rgba(250,204,21,.60)"
    _ => "rgba(226,232,240,.50)"
  }
}

///|
fn map_lab_road_color(road_class : @energy_valley_contract.RoadClass) -> String {
  match road_class {
    Arterial => "rgba(251,191,36,.94)"
    Collector => "rgba(253,224,71,.82)"
    Local => "rgba(226,232,240,.72)"
    Service => "rgba(148,163,184,.68)"
    Footpath => "rgba(52,211,153,.82)"
    Bridge => "rgba(56,189,248,.92)"
  }
}

///|
fn map_lab_road_segment_is_source_evidence(
  world : @energy_valley_contract.CompiledTownWorld,
  segment : @energy_valley_contract.RoadSegment,
) -> Bool {
  if segment.id.scope() != "road-segment" {
    return false
  }
  match
    (
      world.road_network.find_node(segment.from_node_id),
      world.road_network.find_node(segment.to_node_id),
    ) {
    (Some(from), Some(to)) =>
      from.provenance.kind is WenyuReference &&
      to.provenance.kind is WenyuReference
    _ => false
  }
}

///|
fn map_lab_provenance_color(
  kind : @energy_valley_contract.ProvenanceKind,
) -> String {
  match kind {
    WenyuReference => "rgba(34,211,238,.94)"
    Procedural => "rgba(167,139,250,.94)"
    UserDelta => "rgba(251,146,60,.96)"
    RuntimeProjection => "rgba(52,211,153,.96)"
    Derived => "rgba(203,213,225,.82)"
  }
}

///|
fn map_lab_draw_source_evidence(
  context : @dom.CanvasRenderingContext2D,
  world : @energy_valley_contract.CompiledTownWorld,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  map_lab_canvas_line_dash(context, true)
  for region in world.terrain_regions {
    if region.provenance.kind is WenyuReference {
      map_lab_draw_polygon(
        context,
        region.boundary,
        viewport_width,
        viewport_height,
        "rgba(34,211,238,.72)",
        1.4,
        None,
      )
    }
  }
  for block in world.land_blocks {
    if block.provenance.kind is WenyuReference {
      map_lab_draw_polygon(
        context,
        block.boundary,
        viewport_width,
        viewport_height,
        "rgba(103,232,249,.74)",
        1.4,
        None,
      )
    }
  }
  for segment in world.road_network.segments {
    // Segment provenance is Derived because adjacency is compiler output. Its
    // endpoint nodes retain the source truth needed to distinguish accepted
    // Wenyu evidence from user roads and generated pedestrian spurs.
    if map_lab_road_segment_is_source_evidence(world, segment) {
      map_lab_draw_path(
        context,
        segment.centerline,
        viewport_width,
        viewport_height,
        "rgba(34,211,238,.62)",
        1.0,
        false,
        None,
      )
    }
  }
  map_lab_canvas_line_dash(context, false)
}

///|
fn map_lab_draw_terrain(
  context : @dom.CanvasRenderingContext2D,
  world : @energy_valley_contract.CompiledTownWorld,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  for region in world.terrain_regions {
    let (stroke, fill) = map_lab_terrain_colors(region.kind)
    map_lab_draw_polygon(
      context,
      region.boundary,
      viewport_width,
      viewport_height,
      stroke,
      1.3,
      Some(fill),
    )
  }
}

///|
fn map_lab_draw_land_blocks(
  context : @dom.CanvasRenderingContext2D,
  world : @energy_valley_contract.CompiledTownWorld,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  for block in world.land_blocks {
    map_lab_draw_polygon(
      context,
      block.boundary,
      viewport_width,
      viewport_height,
      "rgba(251,191,36,.88)",
      1.8,
      Some("rgba(245,158,11,.045)"),
    )
  }
}

///|
fn map_lab_draw_parcels(
  context : @dom.CanvasRenderingContext2D,
  world : @energy_valley_contract.CompiledTownWorld,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  for parcel in world.parcels {
    let color = match world.parcel_program_for(parcel.id) {
      Some(program) => map_lab_program_color(program.id.local_key())
      None => "rgba(226,232,240,.52)"
    }
    map_lab_draw_polygon(
      context,
      parcel.boundary,
      viewport_width,
      viewport_height,
      color,
      1.1,
      Some("rgba(15,23,42,.035)"),
    )
  }
}

///|
fn map_lab_draw_roads(
  context : @dom.CanvasRenderingContext2D,
  world : @energy_valley_contract.CompiledTownWorld,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  for segment in world.road_network.segments {
    let width = if segment.road_class is Arterial {
      2.8
    } else if segment.road_class is Footpath {
      1.2
    } else {
      1.8
    }
    map_lab_draw_path(
      context,
      segment.centerline,
      viewport_width,
      viewport_height,
      map_lab_road_color(segment.road_class),
      width,
      false,
      None,
    )
  }
  for node in world.road_network.nodes {
    if world.road_network.access_anchor_node_ids.contains(node.id) {
      map_lab_draw_marker(
        context,
        node.position,
        viewport_width,
        viewport_height,
        "rgba(250,204,21,.96)",
        5.0,
        true,
      )
    }
  }
}

///|
fn map_lab_draw_portals(
  context : @dom.CanvasRenderingContext2D,
  world : @energy_valley_contract.CompiledTownWorld,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  map_lab_canvas_line_dash(context, true)
  for place in world.places {
    for portal in place.entrances {
      match portal.road_node_id {
        Some(node_id) =>
          match world.road_network.find_node(node_id) {
            Some(node) =>
              map_lab_draw_path(
                context,
                [portal.position, node.position],
                viewport_width,
                viewport_height,
                "rgba(45,212,191,.78)",
                1.2,
                false,
                None,
              )
            None => ()
          }
        None => ()
      }
      map_lab_draw_marker(
        context,
        portal.position,
        viewport_width,
        viewport_height,
        if portal.road_node_id is Some(_) {
          "rgba(45,212,191,.98)"
        } else {
          "rgba(251,113,133,.98)"
        },
        if portal.primary {
          4.0
        } else {
          2.6
        },
        portal.primary,
      )
    }
  }
  map_lab_canvas_line_dash(context, false)
}

///|
fn map_lab_place_is_public_realm(place : @energy_valley_contract.Place) -> Bool {
  match place.kind {
    Park | Plaza | TransitStation | Waterfront | Landmark | Installation => true
    _ => false
  }
}

///|
fn map_lab_slot_is_public_installation(
  slot : @energy_valley_contract.InteractionSlot,
) -> Bool {
  match slot.kind {
    Bench | Exhibit | Stage | TransitGate | ServicePoint => true
    _ => false
  }
}

///|
fn map_lab_draw_public_realm(
  context : @dom.CanvasRenderingContext2D,
  world : @energy_valley_contract.CompiledTownWorld,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  for place in world.places {
    if map_lab_place_is_public_realm(place) {
      map_lab_draw_polygon(
        context,
        place.footprint,
        viewport_width,
        viewport_height,
        "rgba(244,114,182,.86)",
        1.8,
        Some("rgba(219,39,119,.08)"),
      )
      map_lab_draw_marker(
        context,
        map_lab_polygon_center(place.footprint),
        viewport_width,
        viewport_height,
        "rgba(244,114,182,.96)",
        3.2,
        false,
      )
    }
    for slot in place.interaction_slots {
      if map_lab_slot_is_public_installation(slot) {
        map_lab_draw_marker(
          context,
          slot.position,
          viewport_width,
          viewport_height,
          "rgba(251,207,232,.92)",
          2.4,
          false,
        )
      }
    }
  }
  for installation in world.installations {
    let color = match installation.kind {
      MetroAlignment | TransitEntrance => "rgba(45,212,191,.94)"
      Boardwalk => "rgba(251,191,36,.92)"
      Tree => "rgba(74,222,128,.90)"
      Light => "rgba(253,224,71,.96)"
      Bench | Signage | Custom(_) => "rgba(244,114,182,.92)"
    }
    match installation.geometry {
      AtPoint(point) =>
        map_lab_draw_marker(
          context, point, viewport_width, viewport_height, color, 2.8, false,
        )
      AlongPath(points) =>
        map_lab_draw_path(
          context,
          points,
          viewport_width,
          viewport_height,
          color,
          1.8,
          false,
          None,
        )
      WithinArea(boundary) =>
        map_lab_draw_polygon(
          context,
          boundary,
          viewport_width,
          viewport_height,
          color,
          1.6,
          Some("rgba(244,114,182,.06)"),
        )
    }
  }
}

///|
fn map_lab_place_anchor(
  world : @energy_valley_contract.CompiledTownWorld,
  place_id : @energy_valley_contract.StableId,
) -> @energy_valley_contract.WorldPoint? {
  match world.find_place(place_id) {
    Some(place) =>
      match place.primary_entrance() {
        Some(portal) => Some(portal.position)
        None => Some(map_lab_polygon_center(place.footprint))
      }
    None => None
  }
}

///|
fn map_lab_presence_anchor(
  world : @energy_valley_contract.CompiledTownWorld,
  presence : @energy_valley_contract.ActorPresence,
) -> @energy_valley_contract.WorldPoint? {
  match presence.route_position {
    Some(route) => return Some(route.position)
    None => ()
  }
  match presence.interaction_slot_id {
    Some(slot_id) =>
      match world.find_interaction_slot(slot_id) {
        Some(slot) => Some(slot.position)
        None => map_lab_place_anchor(world, presence.place_id)
      }
    None =>
      match presence.portal_id {
        Some(portal_id) => {
          for place in world.places {
            for portal in place.entrances {
              if portal.id == portal_id {
                return Some(portal.position)
              }
            }
          }
          map_lab_place_anchor(world, presence.place_id)
        }
        None => map_lab_place_anchor(world, presence.place_id)
      }
  }
}

///|
fn map_lab_draw_activity(
  context : @dom.CanvasRenderingContext2D,
  snapshot : @energy_valley_contract.TownSnapshot,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  for relation in snapshot.world.place_relations {
    match
      (
        map_lab_place_anchor(snapshot.world, relation.source_place_id),
        map_lab_place_anchor(snapshot.world, relation.target_place_id),
      ) {
      (Some(source), Some(target)) =>
        map_lab_draw_path(
          context,
          [source, target],
          viewport_width,
          viewport_height,
          "rgba(56,189,248,.38)",
          1.2,
          true,
          None,
        )
      _ => ()
    }
  }
  for exchange in snapshot.active_exchanges() {
    match
      (
        map_lab_place_anchor(snapshot.world, exchange.source_place_id),
        map_lab_place_anchor(snapshot.world, exchange.target_place_id),
      ) {
      (Some(source), Some(target)) =>
        map_lab_draw_path(
          context,
          [source, target],
          viewport_width,
          viewport_height,
          "rgba(167,139,250,.88)",
          2.3,
          false,
          None,
        )
      _ => ()
    }
  }
  for presence in snapshot.active_presences() {
    match map_lab_presence_anchor(snapshot.world, presence) {
      Some(point) => {
        let runtime = presence.provenance.kind is RuntimeProjection
        map_lab_draw_marker(
          context,
          point,
          viewport_width,
          viewport_height,
          if runtime {
            "rgba(52,211,153,.98)"
          } else {
            "rgba(125,211,252,.94)"
          },
          if runtime {
            4.8
          } else {
            3.2
          },
          runtime,
        )
      }
      None => ()
    }
  }
}

///|
fn map_lab_draw_provenance(
  context : @dom.CanvasRenderingContext2D,
  world : @energy_valley_contract.CompiledTownWorld,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  for region in world.terrain_regions {
    map_lab_draw_marker(
      context,
      map_lab_polygon_center(region.boundary),
      viewport_width,
      viewport_height,
      map_lab_provenance_color(region.provenance.kind),
      2.4,
      false,
    )
  }
  for block in world.land_blocks {
    map_lab_draw_marker(
      context,
      map_lab_polygon_center(block.boundary),
      viewport_width,
      viewport_height,
      map_lab_provenance_color(block.provenance.kind),
      2.8,
      false,
    )
  }
  for place in world.places {
    map_lab_draw_marker(
      context,
      map_lab_polygon_center(place.footprint),
      viewport_width,
      viewport_height,
      map_lab_provenance_color(place.provenance.kind),
      3.2,
      true,
    )
  }
  for installation in world.installations {
    match installation.representative_position() {
      Some(position) =>
        map_lab_draw_marker(
          context,
          position,
          viewport_width,
          viewport_height,
          map_lab_provenance_color(installation.provenance.kind),
          3.0,
          installation.interactive,
        )
      None => ()
    }
  }
}

///|
fn map_lab_entity_anchor(
  world : @energy_valley_contract.CompiledTownWorld,
  entity_id : String,
) -> @energy_valley_contract.WorldPoint? {
  // The blueprint is the default selection and intentionally has no spatial
  // anchor. Return before walking the high-cardinality world collections.
  if entity_id.is_empty() || entity_id == world.blueprint_id.to_string() {
    return None
  }
  if entity_id.has_prefix("actor-profile::") ||
    entity_id.has_prefix("attention-focus::") ||
    entity_id.has_prefix("actor-presence::") {
    return None
  }
  for node in world.road_network.nodes {
    if node.id.to_string() == entity_id {
      return Some(node.position)
    }
  }
  for segment in world.road_network.segments {
    if segment.id.to_string() == entity_id && !segment.centerline.is_empty() {
      return Some(segment.centerline[segment.centerline.length() / 2])
    }
  }
  for region in world.terrain_regions {
    if region.id.to_string() == entity_id {
      return Some(map_lab_polygon_center(region.boundary))
    }
  }
  for block in world.land_blocks {
    if block.id.to_string() == entity_id {
      return Some(map_lab_polygon_center(block.boundary))
    }
  }
  for parcel in world.parcels {
    if parcel.id.to_string() == entity_id {
      return Some(map_lab_polygon_center(parcel.boundary))
    }
  }
  for place in world.places {
    if place.id.to_string() == entity_id {
      return Some(map_lab_polygon_center(place.footprint))
    }
    for portal in place.entrances {
      if portal.id.to_string() == entity_id {
        return Some(portal.position)
      }
    }
    for slot in place.interaction_slots {
      if slot.id.to_string() == entity_id {
        return Some(slot.position)
      }
    }
  }
  for relation in world.place_relations {
    if relation.id.to_string() == entity_id {
      return world
        .find_place(relation.source_place_id)
        .map(place => map_lab_polygon_center(place.footprint))
    }
  }
  for installation in world.installations {
    if installation.id.to_string() == entity_id {
      return installation.representative_position()
    }
  }
  for diagnostic in world.diagnostics {
    if diagnostic.id.to_string() == entity_id {
      match diagnostic.position {
        Some(position) => return Some(position)
        None =>
          match diagnostic.entity_id {
            Some(target) if target != diagnostic.id =>
              return map_lab_entity_anchor(world, target.to_string())
            _ => ()
          }
      }
    }
  }
  None
}

///|
fn map_lab_draw_world_diagnostics(
  context : @dom.CanvasRenderingContext2D,
  world : @energy_valley_contract.CompiledTownWorld,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  for diagnostic in world.diagnostics {
    let anchor = match diagnostic.position {
      Some(position) => Some(position)
      None =>
        match diagnostic.entity_id {
          Some(entity_id) => map_lab_entity_anchor(world, entity_id.to_string())
          None => None
        }
    }
    match anchor {
      Some(position) =>
        map_lab_draw_marker(
          context,
          position,
          viewport_width,
          viewport_height,
          match diagnostic.severity {
            Information => "rgba(34,211,238,.95)"
            Caution => "rgba(250,204,21,.98)"
            Failure => "rgba(251,113,133,.98)"
          },
          match diagnostic.severity {
            Information => 2.8
            Caution => 4.2
            Failure => 5.4
          },
          !(diagnostic.severity is Information),
        )
      None => ()
    }
  }
}

///|
fn map_lab_draw_validation(
  context : @dom.CanvasRenderingContext2D,
  snapshot : @energy_valley_contract.TownSnapshot,
  rejections : ReadOnlyArray[@energy_valley_contract.RejectedPlacement],
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  map_lab_draw_world_diagnostics(
    context,
    snapshot.world,
    viewport_width,
    viewport_height,
  )
  for issue in map_lab_validation_issues(snapshot) {
    match issue.entity_id {
      Some(entity_id) =>
        match map_lab_entity_anchor(snapshot.world, entity_id.to_string()) {
          Some(point) => {
            let x = golden_screen_x(point.x, point.y, viewport_width)
            let y = golden_screen_y(point.x, point.y, viewport_height)
            let color = match issue.severity {
              Warning => "rgba(250,204,21,.98)"
              Error => "rgba(251,113,133,.98)"
            }
            golden_ctx_stroke_style(context, color)
            golden_ctx_line_width(context, 2.5)
            context.begin_path()
            context.move_to(x - 5.0, y - 5.0)
            context.line_to(x + 5.0, y + 5.0)
            context.move_to(x + 5.0, y - 5.0)
            context.line_to(x - 5.0, y + 5.0)
            context.stroke()
          }
          None => ()
        }
      None => ()
    }
  }
  for rejection in rejections {
    let boundary = rejection.footprint
    map_lab_draw_polygon(
      context,
      boundary,
      viewport_width,
      viewport_height,
      "rgba(251,113,133,.98)",
      2.4,
      Some("rgba(225,29,72,.12)"),
    )
    let center = map_lab_polygon_center(boundary)
    let x = golden_screen_x(center.x, center.y, viewport_width)
    let y = golden_screen_y(center.x, center.y, viewport_height)
    golden_ctx_stroke_style(context, "rgba(255,228,230,.98)")
    golden_ctx_line_width(context, 2.2)
    context.begin_path()
    context.move_to(x - 6.0, y - 6.0)
    context.line_to(x + 6.0, y + 6.0)
    context.move_to(x + 6.0, y - 6.0)
    context.line_to(x - 6.0, y + 6.0)
    context.stroke()
  }
}

///|
fn map_lab_rejection_anchor(
  rejections : ReadOnlyArray[@energy_valley_contract.RejectedPlacement],
  entity_id : String,
) -> @energy_valley_contract.WorldPoint? {
  for rejection in rejections {
    if rejection.id.to_string() == entity_id {
      return Some(map_lab_polygon_center(rejection.footprint))
    }
  }
  None
}

///|
fn draw_map_lab_canvas(
  snapshot : @energy_valley_contract.TownSnapshot,
  view : MapLabCanvasViewState,
) -> Unit {
  if !view.open {
    return
  }
  let canvas_id = "map-lab-canvas"
  prepare_golden_valley_canvas(canvas_id)
  let width = golden_valley_canvas_width(canvas_id)
  let height = golden_valley_canvas_height(canvas_id)
  match @canvas.get_context2d(canvas_id) {
    None => ()
    Some(context) => {
      context.clear_rect(0.0, 0.0, width.to_double(), height.to_double())
      let world = snapshot.world
      let rejections = world.rejected_placements
      map_lab_canvas_save(context)
      if map_lab_layer_enabled(view.layers, MapLabTerrain) {
        map_lab_draw_terrain(context, world, width, height)
      }
      if map_lab_layer_enabled(view.layers, MapLabSourceEvidence) {
        map_lab_draw_source_evidence(context, world, width, height)
      }
      if map_lab_layer_enabled(view.layers, MapLabLandBlocks) {
        map_lab_draw_land_blocks(context, world, width, height)
      }
      if map_lab_layer_enabled(view.layers, MapLabParcelsPrograms) {
        map_lab_draw_parcels(context, world, width, height)
      }
      if map_lab_layer_enabled(view.layers, MapLabRoadsNavigation) {
        map_lab_draw_roads(context, world, width, height)
      }
      if map_lab_layer_enabled(view.layers, MapLabPublicRealm) {
        map_lab_draw_public_realm(context, world, width, height)
      }
      if map_lab_layer_enabled(view.layers, MapLabPortalsSpurs) {
        map_lab_draw_portals(context, world, width, height)
      }
      if map_lab_layer_enabled(view.layers, MapLabActivity) {
        map_lab_draw_activity(context, snapshot, width, height)
      }
      if map_lab_layer_enabled(view.layers, MapLabProvenance) {
        map_lab_draw_provenance(context, world, width, height)
      }
      if map_lab_layer_enabled(view.layers, MapLabValidation) {
        map_lab_draw_validation(context, snapshot, rejections, width, height)
      }
      if !view.selected_id.is_empty() {
        match map_lab_entity_anchor(world, view.selected_id) {
          Some(point) =>
            map_lab_draw_marker(
              context, point, width, height, "rgba(255,255,255,.98)", 8.0, true,
            )
          None =>
            match map_lab_rejection_anchor(rejections, view.selected_id) {
              Some(point) =>
                map_lab_draw_marker(
                  context, point, width, height, "rgba(255,255,255,.98)", 8.0, true,
                )
              None => ()
            }
        }
      }
      map_lab_canvas_restore(context)
    }
  }
}

///|
fn render_map_lab_canvas(
  snapshot : @energy_valley_contract.TownSnapshot,
  view : MapLabCanvasViewState,
) -> @rabbita.Html {
  if !view.open {
    return @html.nothing
  }
  schedule_map_lab_canvas(() => draw_map_lab_canvas(snapshot, view))
  schedule_map_lab_canvas(() => {
    install_map_lab_canvas_renderer(() => draw_map_lab_canvas(snapshot, view))
  })
  canvas(
    id="map-lab-canvas",
    class="map-lab-canvas absolute inset-0 h-full w-full",
    attrs=@html.Attrs::build().aria_hidden("true"),
    no_children(),
  )
}

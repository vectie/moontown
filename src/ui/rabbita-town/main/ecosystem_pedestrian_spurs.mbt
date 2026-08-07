///|
/// Draws one compiled pedestrian link beneath town life and building mass.
/// The two-stroke treatment reads as a small paved path at normal zoom while
/// remaining quiet enough not to compete with the authored Wenyu road network.
extern "js" fn golden_draw_ecosystem_spur_segment(
  context : @dom.CanvasRenderingContext2D,
  from_x : Double,
  from_y : Double,
  to_x : Double,
  to_y : Double,
  zoom : Double,
  begins_at_door : Bool,
  joins_road : Bool,
) -> Unit =
  #| (context, fromX, fromY, toX, toY, zoom, beginsAtDoor, joinsRoad) => {
  #|   if (!context || zoom < 0.13) return;
  #|   const z = Math.max(0.32, zoom);
  #|   context.save();
  #|   context.lineCap = "round";
  #|   context.lineJoin = "round";
  #|   context.strokeStyle = "rgba(69, 55, 39, .45)";
  #|   context.lineWidth = Math.max(1.25, 4.4 * z);
  #|   context.beginPath();
  #|   context.moveTo(fromX, fromY);
  #|   context.lineTo(toX, toY);
  #|   context.stroke();
  #|   context.strokeStyle = "rgba(230, 208, 157, .92)";
  #|   context.lineWidth = Math.max(.75, 2.5 * z);
  #|   context.setLineDash([Math.max(1.6, 3.5 * z), Math.max(1.1, 2.2 * z)]);
  #|   context.beginPath();
  #|   context.moveTo(fromX, fromY);
  #|   context.lineTo(toX, toY);
  #|   context.stroke();
  #|   context.setLineDash([]);
  #|   if (beginsAtDoor && zoom >= .25) {
  #|     context.fillStyle = "rgba(255, 220, 143, .94)";
  #|     context.beginPath();
  #|     context.arc(fromX, fromY, Math.max(1.2, 2.1 * z), 0, Math.PI * 2);
  #|     context.fill();
  #|   }
  #|   if (joinsRoad && zoom >= .22) {
  #|     context.strokeStyle = "rgba(250, 230, 180, .72)";
  #|     context.lineWidth = Math.max(.7, 1.2 * z);
  #|     context.beginPath();
  #|     context.arc(toX, toY, Math.max(1.8, 3.1 * z), 0, Math.PI * 2);
  #|     context.stroke();
  #|   }
  #|   context.restore();
  #| }

///|
/// Renders only genuinely indirect links. A building already touching a road
/// retains its direct frontage and therefore receives no duplicate decoration.
fn golden_draw_ecosystem_pedestrian_spurs(
  context : @dom.CanvasRenderingContext2D,
  snapshot : @energy_valley_contract.TownSnapshot,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  let zoom = golden_valley_camera_zoom()
  if zoom < 0.13 {
    return
  }
  let portal_node_ids : Map[@energy_valley_contract.StableId, Bool] = Map([])
  for place in snapshot.world.places {
    for portal in place.entrances {
      match portal.road_node_id {
        Some(node_id) => portal_node_ids[node_id] = true
        None => ()
      }
    }
  }
  for segment in snapshot.world.road_network.segments {
    if !(segment.road_class is @energy_valley_contract.Footpath) ||
      segment.centerline.length() < 2 {
      continue
    }
    for index in 0..<(segment.centerline.length() - 1) {
      let from = segment.centerline[index]
      let to = segment.centerline[index + 1]
      golden_draw_ecosystem_spur_segment(
        context,
        golden_screen_x(from.x, from.y, viewport_width),
        golden_screen_y(from.x, from.y, viewport_height),
        golden_screen_x(to.x, to.y, viewport_width),
        golden_screen_y(to.x, to.y, viewport_height),
        zoom,
        index == 0 && portal_node_ids.contains(segment.from_node_id),
        index == segment.centerline.length() - 2 &&
        segment.to_node_id.scope() == "road-node",
      )
    }
  }
}

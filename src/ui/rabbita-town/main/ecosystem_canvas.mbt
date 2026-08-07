///|
/// The ecosystem overlay is deliberately downstream of the semantic world
/// snapshot. It never invents a second coordinate system: every vignette,
/// attention beacon, and relationship line is anchored to an existing place,
/// entrance, or runtime binding from the compiled Energy Valley world.
fn ecosystem_canvas_place_for_building(
  snapshot : EcosystemWorldSnapshot,
  building : GoldenValleyBuilding,
) -> EcosystemPlace? {
  let runtime_key = golden_valley_building_module_key(building)
  if !runtime_key.is_empty() {
    for place in snapshot.places {
      match place.runtime.runtime_key {
        Some(key) if ecosystem_runtime_key_matches(key, runtime_key) =>
          return Some(place)
        _ => ()
      }
    }
  }
  let custom_id = ecosystem_custom_place_id(building)
  match ecosystem_place_by_id(snapshot, custom_id) {
    Some(place) => Some(place)
    None => {
      for place in snapshot.places {
        if place.footprint.x == building.x &&
          place.footprint.y == building.y &&
          place.footprint.width == building.width &&
          place.footprint.depth == building.depth {
          return Some(place)
        }
      }
      None
    }
  }
}

///|
fn ecosystem_canvas_profile_scene_kind(
  profile : EcosystemPlaceProfile,
) -> String {
  match profile.id {
    "town-shell" | "policy-hall" | "vitality-dashboard" => "civic"
    "social-square" | "talent-avenue" => "social"
    "valley-market" | "contest-express" => "market"
    "ai-garden" => "garden"
    "resident-twins" => "home"
    "physical-bridge" => "infrastructure"
    id if id.has_prefix("research-") => "research"
    _ =>
      match profile.style {
        "custom-home" | "home" | "row" | "courtyard" => "home"
        "custom-hall" | "hall" | "plaza" => "social"
        "garden" | "campus" => "garden"
        "market" => "market"
        "custom-lab" | "lab" | "custom-tower" | "tower" => "research"
        _ => "civic"
      }
  }
}

///|
/// The parcel program is the bounded procedural DNA for a place. It selects
/// the street-level vignette while the authored Wenyu footprint remains
/// authoritative. Legacy profile styling is used only for unprogrammed
/// landmarks and migration-edge places.
fn ecosystem_canvas_scene_kind(
  profile : EcosystemPlaceProfile,
  place : @energy_valley_contract.Place?,
) -> String {
  match place {
    Some(semantic_place) =>
      match semantic_place.program_id {
        Some(program_id) =>
          match program_id.local_key() {
            "research-lab" => "research"
            "research-garden"
            | "park-pavilion"
            | "park-commons"
            | "waterfront-walk" => "garden"
            "street-homes" | "residential-court" => "home"
            "valley-market" | "waterfront-pavilion" => "market"
            "civic-court" | "mixed-court" => "social"
            "transit-hall" | "transit-court" => "infrastructure"
            "civic-hall" => "civic"
            _ => ecosystem_canvas_profile_scene_kind(profile)
          }
        None => ecosystem_canvas_profile_scene_kind(profile)
      }
    None => ecosystem_canvas_profile_scene_kind(profile)
  }
}

///|
fn ecosystem_canvas_behavior_color(behavior : EcosystemBehavior) -> String {
  match behavior {
    Coordinate => "#f6c85f"
    Research | Learn => "#a5b4fc"
    Review => "#fcd34d"
    Exchange | Celebrate => "#f9a8d4"
    Observe | Browse => "#67e8f9"
    Walk | Deliver => "#7dd3fc"
    Rest => "#fdba74"
  }
}

///|
fn ecosystem_canvas_attention_total(
  attention : EcosystemAttentionProfile,
) -> Int {
  (
    attention.urgency * 3 +
    attention.activity * 2 +
    attention.social +
    attention.novelty +
    attention.visual
  ) /
  8
}

///|
fn ecosystem_canvas_attention_tone(
  place : EcosystemPlace,
  presence : EcosystemPlacePresenceView,
) -> String {
  if place.attention.urgency >= 80 {
    "urgent"
  } else if presence.runtime_inside_count > 0 ||
    presence.runtime_arriving_count > 0 {
    "live"
  } else if place.attention.social >= 75 {
    "social"
  } else {
    "ambient"
  }
}

///|
fn ecosystem_canvas_semantic_attention(
  snapshot : @energy_valley_contract.TownSnapshot,
  place : @energy_valley_contract.Place,
) -> Int {
  let target_ids : Map[@energy_valley_contract.StableId, Bool] = Map([])
  let mut score = 0
  for target in snapshot.world.attention_targets {
    if target.owner_id == Some(place.id) {
      target_ids[target.id] = true
      score += target.base_salience_per_mille / 10
    }
  }
  for signal in snapshot.active_signals() {
    if target_ids.contains(signal.target_id) {
      score += signal.intensity_per_mille / 10
    }
  }
  score.min(100)
}

///|
fn ecosystem_canvas_semantic_attention_tone(
  snapshot : @energy_valley_contract.TownSnapshot,
  place : @energy_valley_contract.Place,
  presence : EcosystemPlacePresenceView,
) -> String {
  if presence.runtime_inside_count > 0 || presence.runtime_arriving_count > 0 {
    return "live"
  }
  let target_ids : Map[@energy_valley_contract.StableId, Bool] = Map([])
  for target in snapshot.world.attention_targets {
    if target.owner_id == Some(place.id) {
      target_ids[target.id] = true
    }
  }
  for signal in snapshot.active_signals() {
    if target_ids.contains(signal.target_id) {
      if signal.kind is @energy_valley_contract.Need &&
        signal.intensity_per_mille >= 800 {
        return "urgent"
      }
      if signal.kind is @energy_valley_contract.Social {
        return "social"
      }
    }
  }
  "ambient"
}

///|
fn ecosystem_canvas_attention_label(
  profile : EcosystemPlaceProfile,
  presence : EcosystemPlacePresenceView,
) -> String {
  if presence.runtime_inside_count > 0 {
    "真实工作 · 在场"
  } else if presence.runtime_arriving_count > 0 {
    "真实工作 · 在途"
  } else {
    profile.characteristic
  }
}

///|
extern "js" fn golden_draw_ecosystem_place_vignette(
  context : @dom.CanvasRenderingContext2D,
  ground_x : Double,
  ground_y : Double,
  entrance_x : Double,
  entrance_y : Double,
  zoom : Double,
  floors : Int,
  scene_kind : String,
  accent : String,
  glyph : String,
  label : String,
  tone : String,
  attention : Int,
  occupancy : Int,
  arrivals : Int,
  departures : Int,
  activity_glyph : String,
  activity_label : String,
  selected : Bool,
  reduced_motion : Bool,
  seconds : Double,
) -> Unit =
  #| (context, groundX, groundY, entranceX, entranceY, zoom, floors,
  #|  sceneKind, accent, glyph, label, tone, attention, occupancy, arrivals,
  #|  departures, activityGlyph, activityLabel, selected, reducedMotion,
  #|  seconds) => {
  #|   if (!context || zoom < 0.09) return;
  #|   const z = Math.max(0.32, zoom);
  #|   const phase = reducedMotion ? 0 : seconds;
  #|   const roofY = groundY - Math.max(18, (18 + floors * 7) * z);
  #|   const pulse = reducedMotion ? 0.5 : (Math.sin(phase * 2.1) + 1) / 2;
  #|   context.save();
  #|   context.lineCap = "round";
  #|   context.lineJoin = "round";
  #|
  #|   // Semantic occupancy remains visible at overview zoom as a warm pulse.
  #|   // Names and intentions appear only nearby or on explicit selection.
  #|   const activePeople = Math.max(0, occupancy + arrivals);
  #|   if (activePeople > 0 || departures > 0) {
  #|     const activityRadius = Math.max(3.2, (4.5 + activePeople * 1.15) * z);
  #|     const activityGlow = context.createRadialGradient(
  #|       entranceX, entranceY - 2 * z, 0,
  #|       entranceX, entranceY - 2 * z, activityRadius * 3.2,
  #|     );
  #|     activityGlow.addColorStop(0, "rgba(255,219,143,.62)");
  #|     activityGlow.addColorStop(1, "rgba(255,208,118,0)");
  #|     context.globalAlpha = .22 + pulse * .14;
  #|     context.fillStyle = activityGlow;
  #|     context.beginPath();
  #|     context.arc(
  #|       entranceX, entranceY - 2 * z,
  #|       activityRadius * (2.4 + pulse * .3),
  #|       0, Math.PI * 2,
  #|     );
  #|     context.fill();
  #|     context.globalAlpha = 1;
  #|     const shown = Math.min(3, Math.max(1, activePeople));
  #|     for (let index = 0; index < shown; index += 1) {
  #|       const offset = (index - (shown - 1) / 2) * Math.max(3, 4.6 * z);
  #|       context.fillStyle = index < occupancy ? "#f8e1a5" : accent;
  #|       context.beginPath();
  #|       context.arc(
  #|         entranceX + offset,
  #|         entranceY - Math.max(2, 4 * z),
  #|         Math.max(1.5, 2.35 * z),
  #|         0, Math.PI * 2,
  #|       );
  #|       context.fill();
  #|     }
  #|     if (zoom >= .42 || selected) {
  #|       const activityText = selected && activityLabel
  #|         ? `${activityGlyph} ${activityLabel}`
  #|         : `${activityGlyph} ${occupancy} 在内${arrivals ? ` · ${arrivals} 将到` : ""}`;
  #|       const fontSize = Math.max(8, 10 * z);
  #|       context.font = `650 ${fontSize}px ui-sans-serif, system-ui, sans-serif`;
  #|       const padding = fontSize * .52;
  #|       const width = Math.min(
  #|         190,
  #|         context.measureText(activityText).width + padding * 2,
  #|       );
  #|       const top = entranceY + Math.max(5, 8 * z);
  #|       context.fillStyle = "rgba(16,24,32,.82)";
  #|       context.beginPath();
  #|       context.roundRect(
  #|         entranceX - width / 2, top,
  #|         width, fontSize * 1.5, fontSize * .55,
  #|       );
  #|       context.fill();
  #|       context.fillStyle = "#fff3cf";
  #|       context.textAlign = "center";
  #|       context.textBaseline = "middle";
  #|       context.fillText(
  #|         activityText,
  #|         entranceX,
  #|         top + fontSize * .75,
  #|         width - padding,
  #|       );
  #|     }
  #|   }
  #|
  #|   // A place-specific street vignette makes program visible without a
  #|   // permanent label wall. These marks stay at the compiled entrance.
  #|   if (zoom >= 0.24) {
  #|     const unit = Math.max(1.2, 3.5 * z);
  #|     if (sceneKind === "social") {
  #|       for (let i = 0; i < 3; i += 1) {
  #|         const angle = phase * 0.18 + i * Math.PI * 2 / 3;
  #|         const px = entranceX + Math.cos(angle) * unit * 2.2;
  #|         const py = entranceY + Math.sin(angle) * unit * 0.9;
  #|         context.fillStyle = i === 0 ? accent : "rgba(255,239,198,.86)";
  #|         context.beginPath();
  #|         context.arc(px, py - unit, unit * 0.62, 0, Math.PI * 2);
  #|         context.fill();
  #|       }
  #|     } else if (sceneKind === "market") {
  #|       for (let i = -1; i <= 1; i += 2) {
  #|         context.fillStyle = i < 0 ? accent : "#f8cf76";
  #|         context.fillRect(
  #|           entranceX + i * unit * 2.1 - unit,
  #|           entranceY - unit * 2.6,
  #|           unit * 2,
  #|           unit * 1.15,
  #|         );
  #|         context.strokeStyle = "rgba(58,36,26,.72)";
  #|         context.lineWidth = Math.max(.7, z);
  #|         context.strokeRect(
  #|           entranceX + i * unit * 2.1 - unit,
  #|           entranceY - unit * 2.6,
  #|           unit * 2,
  #|           unit * 1.15,
  #|         );
  #|       }
  #|     } else if (sceneKind === "garden") {
  #|       for (let i = 0; i < 5; i += 1) {
  #|         const angle = i * Math.PI * 2 / 5 + phase * 0.08;
  #|         context.fillStyle = i % 2 ? accent : "#fde68a";
  #|         context.beginPath();
  #|         context.arc(
  #|           entranceX + Math.cos(angle) * unit * 2.5,
  #|           entranceY + Math.sin(angle) * unit,
  #|           unit * .48,
  #|           0,
  #|           Math.PI * 2,
  #|         );
  #|         context.fill();
  #|       }
  #|     } else if (sceneKind === "research") {
  #|       context.strokeStyle = accent;
  #|       context.globalAlpha = .42 + pulse * .4;
  #|       context.lineWidth = Math.max(.8, 1.5 * z);
  #|       context.beginPath();
  #|       context.moveTo(entranceX - unit * 2.4, entranceY - unit * .3);
  #|       context.quadraticCurveTo(
  #|         entranceX,
  #|         entranceY - unit * (2.2 + pulse),
  #|         entranceX + unit * 2.4,
  #|         entranceY - unit * .3,
  #|       );
  #|       context.stroke();
  #|       context.globalAlpha = 1;
  #|     } else if (sceneKind === "home") {
  #|       const glow = context.createRadialGradient(
  #|         entranceX, entranceY - unit * 1.8, 0,
  #|         entranceX, entranceY - unit * 1.8, unit * 3.2,
  #|       );
  #|       glow.addColorStop(0, "rgba(255,208,118,.64)");
  #|       glow.addColorStop(1, "rgba(255,208,118,0)");
  #|       context.fillStyle = glow;
  #|       context.beginPath();
  #|       context.arc(
  #|         entranceX,
  #|         entranceY - unit * 1.8,
  #|         unit * 3.2,
  #|         0,
  #|         Math.PI * 2,
  #|       );
  #|       context.fill();
  #|     } else if (sceneKind === "infrastructure") {
  #|       context.strokeStyle = accent;
  #|       context.globalAlpha = .5 + pulse * .35;
  #|       context.lineWidth = Math.max(.8, 1.3 * z);
  #|       for (let ring = 1; ring <= 2; ring += 1) {
  #|         context.beginPath();
  #|         context.arc(
  #|           entranceX,
  #|           entranceY - unit,
  #|           unit * ring * (1.6 + pulse * .15),
  #|           Math.PI * 1.08,
  #|           Math.PI * 1.92,
  #|         );
  #|         context.stroke();
  #|       }
  #|       context.globalAlpha = 1;
  #|     } else {
  #|       context.fillStyle = accent;
  #|       context.globalAlpha = .72;
  #|       context.fillRect(
  #|         entranceX - unit * .55,
  #|         entranceY - unit * 3.5,
  #|         unit * 1.1,
  #|         unit * 3.2,
  #|       );
  #|       context.globalAlpha = 1;
  #|     }
  #|   }
  #|
  #|   const showBeacon = selected || tone === "urgent" || tone === "live";
  #|   if (showBeacon) {
  #|     const urgent = tone === "urgent";
  #|     const radius = Math.max(5, (8 + attention * .035) * z);
  #|     context.strokeStyle = urgent ? "#fb7185" : accent;
  #|     context.globalAlpha = selected ? .95 : .48 + pulse * .34;
  #|     context.lineWidth = Math.max(1, 1.8 * z);
  #|     context.beginPath();
  #|     context.arc(groundX, roofY, radius * (1 + pulse * .14), 0, Math.PI * 2);
  #|     context.stroke();
  #|     context.globalAlpha = 1;
  #|     context.fillStyle = urgent ? "#fb7185" : accent;
  #|     context.beginPath();
  #|     context.arc(groundX, roofY, Math.max(2.3, 3.8 * z), 0, Math.PI * 2);
  #|     context.fill();
  #|     if (zoom >= .42 || selected || urgent) {
  #|       const fontSize = Math.max(8, 11 * z);
  #|       const text = `${glyph} ${label}`;
  #|       context.font = `600 ${fontSize}px ui-sans-serif, system-ui, sans-serif`;
  #|       const padding = fontSize * .55;
  #|       const width = context.measureText(text).width + padding * 2;
  #|       const left = groundX - width / 2;
  #|       const top = roofY - radius - fontSize * 1.65;
  #|       context.fillStyle = "rgba(7,18,26,.84)";
  #|       context.beginPath();
  #|       context.roundRect(left, top, width, fontSize * 1.55, fontSize * .55);
  #|       context.fill();
  #|       context.strokeStyle = urgent ? "rgba(251,113,133,.7)" : `${accent}aa`;
  #|       context.lineWidth = Math.max(.7, z);
  #|       context.stroke();
  #|       context.fillStyle = "#f8fafc";
  #|       context.textAlign = "center";
  #|       context.textBaseline = "middle";
  #|       context.fillText(text, groundX, top + fontSize * .78);
  #|     }
  #|   }
  #|   context.restore();
  #| }

///|
fn golden_draw_ecosystem_place_layer(
  context : @dom.CanvasRenderingContext2D,
  town_snapshot : @energy_valley_contract.TownSnapshot,
  semantic_building : TownCanvasBuilding,
  selected : Bool,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  let building = semantic_building.visual()
  match town_snapshot.world.find_place(semantic_building.place_id) {
    None => ()
    Some(semantic_place) => {
      let profile = ecosystem_place_profile_for_building(building)
      let presence = ecosystem_place_presence_view_from_snapshot(
        town_snapshot,
        semantic_place.id,
      )
      let center_x = building.x.to_double() + building.width.to_double() / 2.0
      let center_y = building.y.to_double() + building.depth.to_double() / 2.0
      let entrance = semantic_place.primary_entrance()
      let entrance_x = entrance
        .map(portal => portal.position.x)
        .unwrap_or(center_x)
      let entrance_y = entrance
        .map(portal => portal.position.y)
        .unwrap_or(center_y)
      golden_draw_ecosystem_place_vignette(
        context,
        golden_screen_x(center_x, center_y, viewport_width),
        golden_screen_y(center_x, center_y, viewport_height),
        golden_screen_x(entrance_x, entrance_y, viewport_width),
        golden_screen_y(entrance_x, entrance_y, viewport_height),
        golden_valley_camera_zoom(),
        building.floors,
        ecosystem_canvas_scene_kind(profile, Some(semantic_place)),
        profile.accent,
        profile.glyph,
        ecosystem_canvas_attention_label(profile, presence),
        ecosystem_canvas_semantic_attention_tone(
          town_snapshot, semantic_place, presence,
        ),
        (ecosystem_canvas_semantic_attention(town_snapshot, semantic_place) +
        presence.attention_boost / 3).min(100),
        presence.occupant_names.length(),
        presence.arriving_names.length(),
        presence.departing_names.length(),
        presence.activity_glyph,
        presence.activity_label,
        selected,
        golden_prefers_reduced_motion(),
        golden_animation_seconds(),
      )
    }
  }
}

///|
extern "js" fn golden_draw_ecosystem_relation(
  context : @dom.CanvasRenderingContext2D,
  from_x : Double,
  from_y : Double,
  to_x : Double,
  to_y : Double,
  accent : String,
  reduced_motion : Bool,
  seconds : Double,
) -> Unit =
  #| (context, fromX, fromY, toX, toY, accent, reducedMotion, seconds) => {
  #|   const dx = toX - fromX;
  #|   const dy = toY - fromY;
  #|   const bend = Math.min(90, Math.max(24, Math.hypot(dx, dy) * .14));
  #|   const controlX = (fromX + toX) / 2 - Math.sign(dy || 1) * bend;
  #|   const controlY = (fromY + toY) / 2 + Math.sign(dx || 1) * bend * .45;
  #|   context.save();
  #|   context.strokeStyle = accent;
  #|   context.globalAlpha = .34;
  #|   context.lineWidth = 1.5;
  #|   context.setLineDash([5, 7]);
  #|   context.lineDashOffset = reducedMotion ? 0 : -(seconds * 8) % 12;
  #|   context.beginPath();
  #|   context.moveTo(fromX, fromY);
  #|   context.quadraticCurveTo(controlX, controlY, toX, toY);
  #|   context.stroke();
  #|   context.setLineDash([]);
  #|   context.globalAlpha = .75;
  #|   context.fillStyle = accent;
  #|   context.beginPath();
  #|   context.arc(toX, toY, 2.6, 0, Math.PI * 2);
  #|   context.fill();
  #|   context.restore();
  #| }

///|
extern "js" fn golden_draw_ecosystem_exchange(
  context : @dom.CanvasRenderingContext2D,
  from_x : Double,
  from_y : Double,
  to_x : Double,
  to_y : Double,
  accent : String,
  progress_per_mille : Int,
  reduced_motion : Bool,
  seconds : Double,
) -> Unit =
  #| (
  #|   context, fromX, fromY, toX, toY, accent, progressPerMille,
  #|   reducedMotion, seconds,
  #| ) => {
  #|   if (!context) return;
  #|   const dx = toX - fromX;
  #|   const dy = toY - fromY;
  #|   const length = Math.hypot(dx, dy);
  #|   if (length < 8) return;
  #|   const bend = Math.min(62, Math.max(16, length * .11));
  #|   const controlX = (fromX + toX) / 2 - Math.sign(dy || 1) * bend;
  #|   const controlY = (fromY + toY) / 2 + Math.sign(dx || 1) * bend * .42;
  #|   const pointAt = t => {
  #|     const u = 1 - t;
  #|     return {
  #|       x: u * u * fromX + 2 * u * t * controlX + t * t * toX,
  #|       y: u * u * fromY + 2 * u * t * controlY + t * t * toY,
  #|     };
  #|   };
  #|   context.save();
  #|   const gradient = context.createLinearGradient(fromX, fromY, toX, toY);
  #|   gradient.addColorStop(0, "rgba(255,255,255,.04)");
  #|   gradient.addColorStop(.48, accent);
  #|   gradient.addColorStop(1, "rgba(255,225,164,.14)");
  #|   context.strokeStyle = gradient;
  #|   context.globalAlpha = .28;
  #|   context.lineWidth = 1.15;
  #|   context.setLineDash([2, 5]);
  #|   context.beginPath();
  #|   context.moveTo(fromX, fromY);
  #|   context.quadraticCurveTo(controlX, controlY, toX, toY);
  #|   context.stroke();
  #|   context.setLineDash([]);
  #|   const base = Math.max(0, Math.min(1, progressPerMille / 1000));
  #|   const t = reducedMotion ? base : (base + seconds * .035) % 1;
  #|   const packet = pointAt(t);
  #|   context.globalAlpha = .88;
  #|   context.fillStyle = accent;
  #|   context.beginPath();
  #|   context.arc(packet.x, packet.y, 2.6, 0, Math.PI * 2);
  #|   context.fill();
  #|   context.strokeStyle = "rgba(255,255,255,.72)";
  #|   context.lineWidth = .8;
  #|   context.stroke();
  #|   context.restore();
  #| }

///|
priv struct EcosystemExchangeCanvasSpec {
  source_position : (Double, Double)
  target_position : (Double, Double)
  accent : String
  progress_per_mille : Int
}

///|
fn ecosystem_canvas_slot_supports_exchange(
  exchange_kind : @energy_valley_contract.ExchangeKind,
  slot_kind : @energy_valley_contract.InteractionKind,
) -> Bool {
  match (exchange_kind, slot_kind) {
    (
      @energy_valley_contract.Knowledge,
      @energy_valley_contract.Workstation
      | @energy_valley_contract.Exhibit
      | @energy_valley_contract.ExchangeDesk,
    ) => true
    (
      @energy_valley_contract.Social,
      @energy_valley_contract.MeetingPoint
      | @energy_valley_contract.ExchangeDesk
      | @energy_valley_contract.Stage,
    ) => true
    (
      @energy_valley_contract.Delivery,
      @energy_valley_contract.ExchangeDesk
      | @energy_valley_contract.ServicePoint,
    ) => true
    (@energy_valley_contract.Mobility, @energy_valley_contract.TransitGate) =>
      true
    (
      @energy_valley_contract.Care,
      @energy_valley_contract.Bench
      | @energy_valley_contract.ServicePoint,
    ) => true
    (
      @energy_valley_contract.Service,
      @energy_valley_contract.ServicePoint
      | @energy_valley_contract.Exhibit,
    ) => true
    (@energy_valley_contract.Custom(_), _) => true
    _ => false
  }
}

///|
fn ecosystem_canvas_place_center(
  place : @energy_valley_contract.Place,
) -> (Double, Double) {
  if place.footprint.vertices.is_empty() {
    return (0.0, 0.0)
  }
  let mut total_x = 0.0
  let mut total_y = 0.0
  for vertex in place.footprint.vertices {
    total_x += vertex.x
    total_y += vertex.y
  }
  let count = place.footprint.vertices.length().to_double()
  (total_x / count, total_y / count)
}

///|
/// Exchange arcs attach to the semantic interaction surface that can actually
/// host the exchange. The primary entrance is the stable fallback for places
/// without a compatible slot; footprint centers are used only for incomplete
/// third-party worlds with neither semantic anchor.
fn ecosystem_canvas_exchange_anchor(
  place : @energy_valley_contract.Place,
  exchange_kind : @energy_valley_contract.ExchangeKind,
) -> (Double, Double) {
  for slot in place.interaction_slots {
    if ecosystem_canvas_slot_supports_exchange(exchange_kind, slot.kind) {
      return (slot.position.x, slot.position.y)
    }
  }
  match place.primary_entrance() {
    Some(portal) => (portal.position.x, portal.position.y)
    None => ecosystem_canvas_place_center(place)
  }
}

///|
fn ecosystem_canvas_exchange_accent(
  kind : @energy_valley_contract.ExchangeKind,
) -> String {
  match kind {
    @energy_valley_contract.Knowledge =>
      ecosystem_canvas_behavior_color(Research)
    @energy_valley_contract.Social => ecosystem_canvas_behavior_color(Exchange)
    @energy_valley_contract.Delivery => ecosystem_canvas_behavior_color(Deliver)
    @energy_valley_contract.Mobility => ecosystem_canvas_behavior_color(Walk)
    @energy_valley_contract.Care => ecosystem_canvas_behavior_color(Rest)
    @energy_valley_contract.Service => ecosystem_canvas_behavior_color(Observe)
    @energy_valley_contract.Custom(_) =>
      ecosystem_canvas_behavior_color(Coordinate)
  }
}

///|
/// Packet progress is derived from the exchange ledger's own lifetime. An
/// open-ended exchange uses its intensity as a stable visual phase instead of
/// consulting resident animation state.
fn ecosystem_canvas_exchange_progress(
  tick : Int,
  exchange : @energy_valley_contract.PlaceExchange,
) -> Int {
  match exchange.expires_tick {
    Some(expires_tick) if expires_tick > exchange.started_tick =>
      ((tick - exchange.started_tick).max(0) *
      1000 /
      (expires_tick - exchange.started_tick)).clamp(min=0, max=1000)
    _ => exchange.intensity_per_mille.clamp(min=0, max=1000)
  }
}

///|
/// This is the only adapter between the authoritative exchange ledger and the
/// canvas. Missing endpoints are ignored rather than reconstructed from the
/// animation or legacy building arrays.
fn ecosystem_canvas_active_exchange_specs(
  snapshot : @energy_valley_contract.TownSnapshot,
) -> Array[EcosystemExchangeCanvasSpec] {
  let specs : Array[EcosystemExchangeCanvasSpec] = []
  for exchange in snapshot.active_exchanges() {
    match
      (
        snapshot.world.find_place(exchange.source_place_id),
        snapshot.world.find_place(exchange.target_place_id),
      ) {
      (Some(source), Some(target)) =>
        specs.push({
          source_position: ecosystem_canvas_exchange_anchor(
            source,
            exchange.kind,
          ),
          target_position: ecosystem_canvas_exchange_anchor(
            target,
            exchange.kind,
          ),
          accent: ecosystem_canvas_exchange_accent(exchange.kind),
          progress_per_mille: ecosystem_canvas_exchange_progress(
            snapshot.tick,
            exchange,
          ),
        })
      _ => ()
    }
  }
  specs
}

///|
fn golden_draw_active_ecosystem_exchanges(
  context : @dom.CanvasRenderingContext2D,
  snapshot : @energy_valley_contract.TownSnapshot,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit {
  if golden_valley_camera_zoom() < 0.1 {
    return
  }
  for spec in ecosystem_canvas_active_exchange_specs(snapshot) {
    golden_draw_ecosystem_exchange(
      context,
      golden_screen_x(
        spec.source_position.0,
        spec.source_position.1,
        viewport_width,
      ),
      golden_screen_y(
        spec.source_position.0,
        spec.source_position.1,
        viewport_height,
      ),
      golden_screen_x(
        spec.target_position.0,
        spec.target_position.1,
        viewport_width,
      ),
      golden_screen_y(
        spec.target_position.0,
        spec.target_position.1,
        viewport_height,
      ),
      spec.accent,
      spec.progress_per_mille,
      golden_prefers_reduced_motion(),
      golden_animation_seconds(),
    )
  }
}

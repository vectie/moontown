///|
/// A read-only review cue; compass sampled at town center, not a claim of one
/// global compass angle over a projectively calibrated map.
fn town_bearing_review(
  context : @dom.CanvasRenderingContext2D,
  width : Int,
  buildings : Map[Int, Array[IntersectionRoadPreviewBuilding]],
) -> Unit {
  let histogram : Map[String, Int] = Map([])
  let archetypes : Map[String, Int] = Map([])
  let origins : Map[String, Int] = Map([])
  let mut count = 0
  let mut infill_count = 0
  let mut infill_min_width = 256
  let mut infill_max_gap = 0.0
  for _, items in buildings {
    for building in items {
      histogram[building.style] = histogram.get(building.style).unwrap_or(0) + 1
      let name = town_bearing_archetype(
          building.style,
          town_bearing_variant(building.id),
        ).name
      archetypes[name] = archetypes.get(name).unwrap_or(0) + 1
      let origin = if building.id.has_prefix("procedural-grid-") {
        "grid"
      } else if building.id.has_prefix("procedural-source-") {
        "source"
      } else {
        "curated"
      }
      origins[origin] = origins.get(origin).unwrap_or(0) + 1
      count += 1
      if building.id.has_prefix("procedural-grid-density-") {
        infill_count += 1
        infill_min_width = infill_min_width.min(building.width)
        infill_max_gap = infill_max_gap.max(town_street_lot_gap(building))
      }
    }
  }
  town_bearing_record_mix(
    histogram.to_json().stringify(),
    origins.to_json().stringify(),
    archetypes.to_json().stringify(),
  )
  town_street_record_review(
    town_street_segments.length(),
    infill_count,
    if infill_count > 0 {
      infill_min_width
    } else {
      0
    },
    infill_max_gap,
  )
  let b = town_bearing_at(128.0, 72.0)
  town_bearing_review_paint(
    context,
    width,
    count,
    32.0 * (b.north.x - b.north.y),
    16.0 * (b.north.x + b.north.y),
  )
}

///|
extern "js" fn town_street_record_review(
  segments : Int,
  count : Int,
  width : Int,
  gap : Double,
) -> Unit =
  #| (s,n,w,g)=>{const d=document.documentElement.dataset;d.townStreetFrontageSegments=String(s);d.townStreetInfillCount=String(n);d.townStreetMinInfillWidth=String(w);d.townStreetMaxInfillGap=String(g);}

///|
extern "js" fn town_bearing_record_mix(
  styles : String,
  origins : String,
  archetypes : String,
) -> Unit =
  #| (styles,origins,archetypes)=>{const d=document.documentElement.dataset;d.townBearingStyles=styles;d.townBearingOrigins=origins;d.townBearingArchetypes=archetypes;d.townBearingArchetypeCount=String(Object.keys(JSON.parse(archetypes)).length);}

///|
extern "js" fn town_bearing_review_paint(
  c : @dom.CanvasRenderingContext2D,
  width : Int,
  count : Int,
  nx : Double,
  ny : Double,
) -> Unit =
  #| (c,width,count,nx,ny)=>{
  #|   const root=document.documentElement;
  #|   root.dataset.townBuildingOrientation='geographic-prefab-review';
  #|   root.dataset.townBearingBuildings=String(count);
  #|   root.dataset.townBearingNorthDegrees=String(Math.atan2(nx,-ny)*180/Math.PI);
  #|   root.dataset.townBearingMaximumStreetDeviation='10';
  #|   const len=Math.hypot(nx,ny),dx=nx/len,dy=ny/len,x=width-106,y=140;
  #|   c.save();c.fillStyle='rgba(246,246,230,0.92)';c.beginPath();c.roundRect(x-50,y-35,132,77,12);c.fill();
  #|   c.strokeStyle='#3a5b4b';c.lineWidth=2;c.beginPath();c.moveTo(x-22*dx,y-22*dy);c.lineTo(x+22*dx,y+22*dy);c.stroke();
  #|   c.beginPath();c.moveTo(x+22*dx,y+22*dy);c.lineTo(x+12*dx-5*dy,y+12*dy+5*dx);c.lineTo(x+12*dx+5*dy,y+12*dy-5*dx);c.closePath();c.fillStyle='#3a5b4b';c.fill();
  #|   c.font='600 13px system-ui';c.fillText('N',x+32*dx,y+32*dy+4);
  #|   c.font='11px system-ui';c.fillText('North · town center',x-40,y+29);c.restore();
  #| }

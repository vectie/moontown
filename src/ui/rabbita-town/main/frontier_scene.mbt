///|
/// Exterior is an additional layer, never an alternative world renderer.
fn frontier_draw_ground(
  context : @dom.CanvasRenderingContext2D,
  chunks : Array[@frontier.Chunk],
  width : Int32,
  height : Int32,
) -> Unit {
  if chunks.is_empty() {
    return
  }
  frontier_clip_exterior(context, width, height)
  let zoom = golden_valley_camera_zoom()
  // A low-detail continuous lawn avoids a sea of empty background at overview.
  frontier_paint_lawn(context, width, height, town_daylight_color("grass"))
  if zoom >= 0.35 {
    for c in chunks {
      for y in (c.y * 32)..<(c.y * 32 + 32) {
        for x in (c.x * 32)..<(c.x * 32 + 32) {
          if frontier_core.contains({
              x: x.to_double() + 0.5,
              y: y.to_double() + 0.5,
            }) {
            continue
          }
          let sx = golden_screen_x(
            x.to_double() + 0.5,
            y.to_double() + 0.5,
            width,
          )
          let sy = golden_screen_y(
            x.to_double() + 0.5,
            y.to_double() + 0.5,
            height,
          )
          if sx < -80 ||
            sx > width.to_double() + 80 ||
            sy < -80 ||
            sy > height.to_double() + 80 {
            continue
          }
          golden_draw_canonical_old_map_terrain(
            context,
            "grass",
            sx,
            sy,
            town_scene_ground_variation(x, y),
            x,
            y,
          )
        }
      }
    }
  }
  let patches : Array[Json] = []
  for c in chunks {
    for iy in 0..<2 {
      for ix in 0..<2 {
        let x = (c.x * 32 + ix * 16 + 8).to_double()
        let y = (c.y * 32 + iy * 16 + 8).to_double()
        patches.push([x, y, @frontier.woodland({ x, y, })])
      }
    }
  }
  frontier_paint_meadow(context, patches.to_json().stringify(), width, height)
  frontier_draw_edge_ground(context, width, height)
  let corners = [
    (0.0, 0.0),
    (width.to_double(), 0.0),
    (0.0, height.to_double()),
    (width.to_double(), height.to_double()),
  ].map(p => {
    golden_canvas_world_at_screen(
      p.0,
      p.1,
      width,
      height,
      golden_valley_camera_x(),
      golden_valley_camera_y(),
      zoom,
    )
  })
  for m in frontier_mouths {
    let reach = corners
      .fold(init=-1.0e12, (a, p) => {
        a.max((p.0 - m.point.x) * m.normal.x + (p.1 - m.point.y) * m.normal.y)
      })
      .ceil()
      .to_int() +
      8
    let start = (corners
    .fold(init=1.0e12, (a, p) => {
      a.min((p.0 - m.point.x) * m.normal.x + (p.1 - m.point.y) * m.normal.y)
    })
    .floor()
    .to_int() -
    8).max(0)
    if reach <= start {
      continue
    }
    let left : Array[@frontier.Point] = []
    let right : Array[@frontier.Point] = []
    for i in start..<=reach {
      let d = i.to_double()
      let center = m.center_at(d)
      for (points, side) in [(left, -1.0), (right, 1.0)] {
        let offset = side * m.radius_at(d)
        points.push({
          x: center.x - offset * m.normal.y,
          y: center.y + offset * m.normal.x,
        })
      }
    }
    left.append(right.rev())
    frontier_paint_water(context, left.to_json().stringify(), width, height)
  }
  let lots : Array[@frontier.Lot] = []
  let roads : Array[@frontier.Road] = []
  for c in chunks {
    lots.append(c.lots)
    roads.append(c.roads)
  }
  for l in lots {
    town_bearing_draw_lot(
      context,
      frontier_lot_building(l),
      width,
      height,
      bearing=frontier_lot_bearing(l),
      variant=l.variant,
      connect_street=false,
    )
  }
  frontier_paint_roads(
    context,
    roads.to_json().stringify(),
    lots.to_json().stringify(),
    width,
    height,
  )
  context.restore()
}

///|
fn frontier_draw_props(
  context : @dom.CanvasRenderingContext2D,
  chunks : Array[@frontier.Chunk],
  view : TownCanvasViewState,
  width : Int32,
  height : Int32,
) -> Unit {
  let lots : Array[@frontier.Lot] = []
  let plants : Array[@frontier.Plant] = []
  let ordered : Array[(Double, Int32, Int32)] = []
  let zoom = golden_valley_camera_zoom()
  for c in chunks {
    for l in c.lots {
      let x = l.x.to_double() + l.size.to_double() / 2
      let y = l.y.to_double() + l.size.to_double() / 2
      if !golden_spring_building_asset_visible(
          golden_screen_x(x, y, width),
          golden_screen_y(x, y, height),
          l.size.to_double(),
          l.size.to_double(),
          zoom,
          width,
          height,
        ) {
        continue
      }
      ordered.push(((l.x + l.y + l.size * 2).to_double(), 0, lots.length()))
      lots.push(l)
    }
    for p in c.plants {
      let sx = golden_screen_x(p.point.x, p.point.y, width)
      let sy = golden_screen_y(p.point.x, p.point.y, height)
      if sx < -80 ||
        sx > width.to_double() + 80 ||
        sy < -80 ||
        sy > height.to_double() + 160 {
        continue
      }
      if zoom < 0.2 &&
        ((p.point.x * 10).to_int() + (p.point.y * 10).to_int()) % 3 != 0 {
        continue
      }
      ordered.push((p.point.x + p.point.y, 1, plants.length()))
      plants.push(p)
    }
  }
  let position = match
    town_canvas_follow_position({ ..view, follow_enabled: true, }) {
    Some(p) => Some(p)
    None => street_spawn()
  }
  if position is Some(p) && !frontier_core.contains({ x: p.0, y: p.1, }) {
    ordered.push((p.0 + p.1, 2, 0))
  }
  ordered.sort_by((a, b) => a.0.compare(b.0))
  for item in ordered {
    match item.1 {
      0 => {
        let l = lots[item.2]
        town_bearing_draw_building(
          context,
          frontier_lot_building(l),
          width,
          height,
          bearing=frontier_lot_bearing(l),
          variant=l.variant,
        )
      }
      1 => {
        let p = plants[item.2]
        let sx = golden_screen_x(p.point.x, p.point.y, width)
        let sy = golden_screen_y(p.point.x, p.point.y, height)
        if sx < -80 ||
          sx > width.to_double() + 80 ||
          sy < -80 ||
          sy > height.to_double() + 160 {
          continue
        }
        town_botanical_draw_tree(
          context,
          sx,
          sy,
          golden_valley_camera_zoom(),
          p.kind,
          p.size,
          0.4,
        )
        if item.2 % 3 == 0 && golden_valley_camera_zoom() >= 0.2 {
          town_botanical_draw_flowers(
            context,
            sx + 12,
            sy + 6,
            golden_valley_camera_zoom(),
            p.kind % 4,
          )
        }
      }
      _ =>
        street_draw_visitor(
          context,
          view,
          item.0.floor().to_int(),
          width,
          height,
        )
    }
  }
  frontier_publish(
    frontier_render_cache.length(),
    frontier_navigation_chunks.length(),
    position
    .map(p => frontier_core.contains({ x: p.0, y: p.1, }))
    .unwrap_or(true),
  )
}

///|
/// Use the generator's actual street frame. Never extrapolate the finite-core
/// projective calibration to distant procedural land.
fn frontier_lot_bearing(l : @frontier.Lot) -> TownBuildingBearing {
  {
    east: { x: l.east.x, y: l.east.y, },
    north: { x: l.north.x, y: l.north.y, },
    deviation: 0,
  }
}

///|
fn frontier_lot_building(l : @frontier.Lot) -> IntersectionRoadPreviewBuilding {
  {
    id: l.id,
    style: l.style,
    asset_path: "",
    x: l.x,
    y: l.y,
    width: l.size,
    depth: l.size,
    apron: 0,
    depth_key: l.x + l.y + l.size * 2,
  }
}

///|
/// Extend authored edge land-cover outwards, fading only on the new side.
/// No blur, alpha mask or repaint is ever applied to the accepted core.
fn frontier_draw_edge_ground(
  context : @dom.CanvasRenderingContext2D,
  width : Int32,
  height : Int32,
) -> Unit {
  let cells : Array[Json] = []
  for y in -20..<164 {
    for x in -20..<276 {
      let p : @frontier.Point = {
        x: x.to_double() + 0.5,
        y: y.to_double() + 0.5,
      }
      if frontier_core.contains(p) {
        continue
      }
      let d = frontier_core.distance(p)
      if d > 20 {
        continue
      }
      let sx = golden_screen_x(p.x, p.y, width)
      let sy = golden_screen_y(p.x, p.y, height)
      if sx < -80 ||
        sx > width.to_double() + 80 ||
        sy < -80 ||
        sy > height.to_double() + 80 {
        continue
      }
      let terrain = intersection_road_view_stale_ground_terrain(
        x.clamp(min=0, max=255),
        y.clamp(min=0, max=143),
      )
      cells.push([x, y, terrain, (1.0 - d / 20).max(0)])
    }
  }
  frontier_paint_edge_ground(
    context,
    cells.to_json().stringify(),
    width,
    height,
  )
}

///|
extern "js" fn frontier_paint_edge_ground(
  c : @dom.CanvasRenderingContext2D,
  cells : String,
  w : Int32,
  h : Int32,
) -> Unit =
  #| (c,raw,w,h)=>{const cam=globalThis.__moontownGoldenValleyCamera,z=cam.z;c.save();c.transform(32*z,16*z,-32*z,16*z,w/2-cam.x*z,h/2-cam.y*z);
  #| for(const [x,y,t,a] of JSON.parse(raw)){c.globalAlpha=a*a*(3-2*a);const light=Math.sin(x*.061+y*.029)*3.5+Math.sin(y*.047-x*.019)*2.5;c.fillStyle=`rgb(${Math.round(171+light)},${Math.round(216+light)},${Math.round(94+light)})`;c.fillRect(x,y,1.02,1.02);}c.restore();}

///|
/// Explicit even-odd cutout protects core pixels even when a long generated
/// river, wide road stroke, or ground-cache padding spans the original extent.
extern "js" fn frontier_clip_exterior(
  c : @dom.CanvasRenderingContext2D,
  w : Int32,
  h : Int32,
) -> Unit =
  #| (c,w,h)=>{const cam=globalThis.__moontownGoldenValleyCamera,z=cam.z; c.save();c.beginPath();c.rect(-1,-1,w+2,h+2);
  #| const ps=[[0,0],[256,0],[256,144],[0,144]].map(([x,y])=>[w/2+(32*(x-y)-cam.x)*z,h/2+(16*(x+y)-cam.y)*z]);
  #| ps.forEach(([x,y],i)=>i?c.lineTo(x,y):c.moveTo(x,y));c.closePath();c.clip('evenodd');}

///|
extern "js" fn frontier_paint_lawn(
  c : @dom.CanvasRenderingContext2D,
  w : Int32,
  h : Int32,
  color : String,
) -> Unit =
  #| (c,w,h,color)=>{c.fillStyle=color;c.fillRect(0,0,w,h);}

///|
extern "js" fn frontier_paint_meadow(
  c : @dom.CanvasRenderingContext2D,
  patches : String,
  w : Int32,
  h : Int32,
) -> Unit =
  #| (c,raw,w,h)=>{const cam=globalThis.__moontownGoldenValleyCamera,z=cam.z;c.save();c.transform(32*z,16*z,-32*z,16*z,w/2-cam.x*z,h/2-cam.y*z);
  #| for(const [x,y,value] of JSON.parse(raw)){if(value<=.1)continue;const d=Math.hypot(Math.max(0,-x,x-256),Math.max(0,-y,y-144)),g=c.createRadialGradient(x,y,0,x,y,20);g.addColorStop(0,`rgba(102,161,68,${Math.min(.28,value*.24)*Math.min(1,d/24)})`);g.addColorStop(1,'rgba(102,161,68,0)');c.fillStyle=g;c.fillRect(x-20,y-20,40,40);}c.restore();}

///|
extern "js" fn frontier_paint_water(
  c : @dom.CanvasRenderingContext2D,
  polygon : String,
  width : Int32,
  height : Int32,
) -> Unit =
  #| (c,raw,w,h)=>{const ps=JSON.parse(raw),cam=globalThis.__moontownGoldenValleyCamera,z=cam.z;c.save();c.transform(32*z,16*z,-32*z,16*z,w/2-cam.x*z,h/2-cam.y*z);
  #| const n=ps.length/2,band=(lo,hi,color)=>{const q=(i,t)=>{const a=ps[i],b=ps[ps.length-1-i];return [a.x+(b.x-a.x)*t,a.y+(b.y-a.y)*t]};c.beginPath();for(let i=0;i<n;i++)i?c.lineTo(...q(i,lo)):c.moveTo(...q(i,lo));for(let i=n-1;i>=0;i--)c.lineTo(...q(i,hi));c.closePath();c.fillStyle=color;c.fill();};
  #| band(0,1,'#eeddb8');band(.025,.975,'#91d6bd');band(.07,.93,'#67cfce');band(.16,.84,'#319fc8');band(.34,.66,'rgba(34,111,158,.62)');c.restore();}

///|
extern "js" fn frontier_paint_roads(
  c : @dom.CanvasRenderingContext2D,
  roads : String,
  lots : String,
  width : Int32,
  height : Int32,
) -> Unit =
  #| (c,raw,rawLots,w,h)=>{const rs=JSON.parse(raw),ls=JSON.parse(rawLots),cam=globalThis.__moontownGoldenValleyCamera,z=cam.z;c.save();c.transform(32*z,16*z,-32*z,16*z,w/2-cam.x*z,h/2-cam.y*z);c.lineCap='round';c.lineJoin='round';
  #| const line=(a,b,color,width)=>{c.beginPath();c.moveTo(a.x,a.y);c.lineTo(b.x,b.y);c.strokeStyle=color;c.lineWidth=width;c.stroke();};
  #| for(const l of ls)line(l.entrance,l.frontage,'#e4ddc7',.6);
  #| for(const r of rs)line(r.a,r.b,r.bridge?'#9a9986':'#c4b698',r.width+.09);
  #| for(const r of rs)line(r.a,r.b,r.bridge?'#ded3b4':'#eeddb8',r.width);c.restore();}

///|
extern "js" fn frontier_publish(
  chunks : Int32,
  nav_chunks : Int32,
  in_core : Bool,
) -> Unit =
  #| (chunks,nav,inCore)=>{const root=document.documentElement;root.dataset.frontierChunks=String(chunks);root.dataset.frontierNavChunks=String(nav);root.dataset.frontierVersion='exterior-city-v3';root.dataset.frontierCorePreserved='true';root.dataset.frontierArea=inCore?'core':'exterior';
  #| const el=document.getElementById('frontier-diagnostics');if(el){const text=`原图 256 × 144 保留 · seed 20261028 · ${chunks} 绘制块 / ${nav} 临近导航块 · 4 个原路出口`;if(el.textContent!==text)el.textContent=text;}
  #| const name=document.querySelector('.street-location .town-ui-label > span:last-child');const overview=document.getElementById('energy-valley-canvas')?.dataset.townView==='street-overview';const title=overview?'全镇':inCore?'未来中心':'外围街区';if(name&&name.textContent!==title)name.textContent=title;}

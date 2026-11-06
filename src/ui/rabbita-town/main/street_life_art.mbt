///|
/// The existing resident roster supplies bodies. Cups, books and small gestures
/// communicate activity without names, dashboard badges or invented messages.
fn street_life_draw(
  c : @dom.CanvasRenderingContext2D,
  actors : Array[StreetLifeActor],
  depth : Int32,
  w : Int32,
  h : Int32,
) -> Unit {
  let reduced = golden_prefers_reduced_motion()
  let scale = (golden_valley_camera_zoom() * 0.26).min(0.92).max(0.32)
  for a in actors {
    if (a.point.0 + a.point.1).floor().to_int() != depth {
      continue
    }
    let sx = golden_screen_x(a.point.0, a.point.1, w)
    let sy = golden_screen_y(a.point.0, a.point.1, h)
    if sx < -80 ||
      sx > w.to_double() + 80 ||
      sy < -80 ||
      sy > h.to_double() + 100 {
      continue
    }
    let left = a.facing.0 - a.facing.1 < a.point.0 - a.point.1
    street_life_pose_begin(c, sy, a.pose == "rest")
    golden_draw_sprite_agent(
      c,
      sx,
      sy,
      scale,
      golden_valley_agent_sprite_path("resident", a.sprite),
      left,
      if a.pose == "walk" && !reduced {
        a.phase * 7
      } else {
        0
      },
      "",
      "",
      "",
      false,
      false,
    )
    c.restore()
    street_life_paint_activity(
      c,
      sx,
      sy,
      scale,
      a.pose,
      left,
      a.attentive,
      if reduced {
        0
      } else {
        street_life_clock.elapsed
      },
      reduced,
    )
  }
  if !actors.is_empty() {
    street_life_birds(c, depth, w, h, street_life_clock.elapsed, reduced)
  }
}

///|
extern "js" fn street_life_pose_begin(
  c : @dom.CanvasRenderingContext2D,
  y : Double,
  seated : Bool,
) -> Unit =
  #| (c,y,seated)=>{c.save();if(seated){c.translate(0,y-5);c.scale(1,.8);c.translate(0,-y);}}

///|
extern "js" fn street_life_paint_activity(
  c : @dom.CanvasRenderingContext2D,
  x : Double,
  y : Double,
  scale : Double,
  pose : String,
  left : Bool,
  attentive : Bool,
  time : Double,
  reduced : Bool,
) -> Unit =
  #| (c,x,y,s,pose,left,attentive,t,reduced)=>{
  #| c.save();c.translate(x,y);c.scale(left?-s:s,s);c.lineCap='round';c.lineJoin='round';
  #| const line=(x,y,a,b,color,width)=>{c.beginPath();c.moveTo(x,y);c.lineTo(a,b);c.strokeStyle=color;c.lineWidth=width;c.stroke();};
  #| const poly=(ps,color)=>{c.beginPath();ps.forEach(([a,b],i)=>i?c.lineTo(a,b):c.moveTo(a,b));c.closePath();c.fillStyle=color;c.fill();};
  #| const lift=attentive?3:0;
  #| if(pose==='coffee'){
  #| const sip=!reduced&&t%14>10?Math.sin((t%14-10)/4*Math.PI)*7:0;
  #| c.translate(10,-30-sip);poly([[-5,-7],[5,-7],[4,3],[-4,3]],'#fff3d9');
  #| line(-5,-7,5,-7,'#698773',2);c.strokeStyle='#fff3d9';c.lineWidth=2;c.beginPath();c.arc(5,-2,3,-Math.PI/2,Math.PI/2);c.stroke();
  #| }else if(pose==='read'||pose==='rest'){
  #| c.translate(2,pose==='rest'?-25:-29+lift);
  #| poly([[-12,-6],[-1,-3],[-1,9],[-12,5]],'#e9dcb9');poly([[-1,-3],[11,-6],[11,5],[-1,9]],'#fff4d8');
  #| line(-1,-3,-1,9,'#8eaa86',1);line(3,-1,8,-2,'#8eaa86',1);line(3,2,8,1,'#8eaa86',1);
  #| }else if(pose!=='walk'&&(pose==='chat'||attentive)){
  #| const wave=reduced?0:Math.sin(t*2.6)*2;
  #| line(11,-29,17,-33-wave,'#dec39e',3.5);line(17,-33-wave,18,-37-wave,'#dec39e',3);
  #| }
  #| c.restore();}

///|
/// A bird spends most of its time perched/pecking, then crosses to the other
/// side. The flight is continuous, bounded, and shares the paused scenery clock.
fn street_life_bird_position(
  time : Double,
  index : Int32,
) -> (Double, Double, Double) {
  let t = time.max(0) + index.to_double() * 13
  let cycle = (t / 32).floor().to_int()
  let phase = t - (t / 32).floor() * 32
  let (a, b) = if cycle % 2 == 0 { (-91.0, 30.0) } else { (30.0, -91.0) }
  if phase < 27 {
    return (a, 157 + index.to_double() * 5, 0)
  }
  let u = (phase - 27) / 5
  (
    a + (b - a) * u,
    157 + index.to_double() * 5 - @math.sin(u * @math.PI) * 12,
    @math.sin(u * @math.PI) * 20,
  )
}

///|
fn street_life_birds(
  c : @dom.CanvasRenderingContext2D,
  depth : Int32,
  w : Int32,
  h : Int32,
  time : Double,
  reduced : Bool,
) -> Unit {
  guard town_landmark_find("center") is Some(l) else { return }
  for i in 0..<2 {
    let (x, z, altitude) = street_life_bird_position(time, i)
    let p = town_landmark_at(l, x, z)
    if (p.x + p.y).floor().to_int() != depth {
      continue
    }
    let scale = l.elevation * golden_valley_camera_zoom()
    street_life_paint_bird(
      c,
      golden_screen_x(p.x, p.y, w),
      golden_screen_y(p.x, p.y, h),
      scale,
      altitude,
      time + i.to_double(),
      reduced,
    )
  }
}

///|
extern "js" fn street_life_paint_bird(
  c : @dom.CanvasRenderingContext2D,
  x : Double,
  y : Double,
  scale : Double,
  altitude : Double,
  time : Double,
  reduced : Bool,
) -> Unit =
  #| (c,x,y,s,alt,t,reduced)=>{
  #| if(s<.4)return;c.save();c.translate(x,y);c.scale(s,s);
  #| c.fillStyle='rgba(42,76,62,.16)';c.beginPath();c.ellipse(3,2,5,1.8,0,0,Math.PI*2);c.fill();
  #| c.translate(0,-alt);const peck=!reduced&&alt<1&&t%7<.6?2:0;
  #| c.fillStyle='#6f8c8c';c.beginPath();c.ellipse(0,-3,4.2,2.8,-.2,0,Math.PI*2);c.fill();
  #| c.fillStyle='#edf0d9';c.beginPath();c.arc(3,-5+peck,2.4,0,Math.PI*2);c.fill();
  #| c.fillStyle='#c99852';c.beginPath();c.moveTo(4,-5+peck);c.lineTo(7,-4+peck);c.lineTo(4,-3+peck);c.fill();
  #| c.fillStyle='#365254';c.fillRect(3.4,-5+peck,.8,.8);
  #| if(alt>1){const f=reduced?0:Math.sin(t*12)*5;c.fillStyle='#d6e2d6';c.beginPath();c.moveTo(-2,-4);c.lineTo(-10,-6-f);c.lineTo(1,-2);c.lineTo(7,-9+f);c.closePath();c.fill();}
  #| c.restore();}

///|
/// All furniture uses the landmark's east/south/elevation basis. The renderer
/// consumes geometry; it cannot change routes, content permissions or models.
let street_courtyard_props : Array[(String, Double, Double)] = [
  ("tree", -112, 104),
  ("cafe", -75, 110),
  ("pot", -48, 104),
  ("table", -15, 120),
  ("seat", -15, 140),
  ("seat", 95, 147),
  ("board", 55, 118),
  ("events", 100, 118),
  ("pot", 120, 130),
  ("tree", -105, 170),
  ("tree", 154, 178),
  ("flowers", 45, 164),
  ("flowers", -93, 151),
  ("flowers", 132, 161),
]

///|
fn street_courtyard_basis(width : Int32, height : Int32) -> Array[Double]? {
  guard town_landmark_find("center") is Some(l) else { return None }
  let z = golden_valley_camera_zoom()
  Some([
    golden_screen_x(l.origin.x, l.origin.y, width),
    golden_screen_y(l.origin.x, l.origin.y, height),
    32.0 * (l.east.x - l.east.y) * z,
    16.0 * (l.east.x + l.east.y) * z,
    32.0 * (l.south.x - l.south.y) * z,
    16.0 * (l.south.x + l.south.y) * z,
    l.elevation * z,
  ])
}

///|
fn street_courtyard_draw_ground(
  c : @dom.CanvasRenderingContext2D,
  w : Int32,
  h : Int32,
) -> Unit {
  guard street_courtyard_basis(w, h) is Some(basis) else { return }
  let paths : Array[Array[Double]] = []
  if street_spawn() is Some(gate) &&
    street_courtyard_point("seat") is Some(seat) {
    paths.push([
      golden_screen_x(gate.0, gate.1, w),
      golden_screen_y(gate.0, gate.1, h),
      golden_screen_x(seat.0, seat.1, w),
      golden_screen_y(seat.0, seat.1, h),
    ])
  }
  street_paint_terrace(
    c,
    basis.to_json().stringify(),
    paths.to_json().stringify(),
  )
}

///|
fn street_courtyard_draw_depth(
  c : @dom.CanvasRenderingContext2D,
  depth : Int32,
  w : Int32,
  h : Int32,
) -> Unit {
  guard town_landmark_find("center") is Some(l) &&
    street_courtyard_basis(w, h) is Some(basis) else {
    return
  }
  for (kind, x, z) in street_courtyard_props {
    let p = town_landmark_at(l, x, z)
    if (p.x + p.y).floor().to_int() == depth {
      if kind == "tree" {
        town_botanical_draw_tree(
          c,
          golden_screen_x(p.x, p.y, w),
          golden_screen_y(p.x, p.y, h),
          basis[6] * 0.72,
          if x == -105 {
            1
          } else {
            0
          },
          1.0,
          x.abs() / 160.0,
        )
        continue
      }
      street_paint_furniture(
        c,
        basis.to_json().stringify(),
        kind,
        x,
        z,
        golden_prefers_reduced_motion(),
        street_life_clock.elapsed,
      )
    }
  }
}

///|
extern "js" fn street_paint_terrace(
  c : @dom.CanvasRenderingContext2D,
  raw : String,
  paths : String,
) -> Unit =
  #| (c,raw,paths)=>{
  #| const [ox,oy,ex,ey,sx,sy,v]=JSON.parse(raw),p=(x,z)=>[ox+x*ex+z*sx,oy+x*ey+z*sy];
  #| const polygon=(ps,fill)=>{c.beginPath();ps.forEach(([x,z],i)=>{const q=p(x,z);i?c.lineTo(...q):c.moveTo(...q)});c.closePath();c.fillStyle=fill;c.fill()};
  #| c.save();c.lineCap='round';
  #| // A single continuous forecourt, not a tile-by-tile pattern.
  #| polygon([[-115,94],[125,94],[125,158],[112,172],[-100,172],[-115,155]],'#a9ca78');
  #| polygon([[-100,97],[115,97],[115,152],[100,161],[-90,161],[-100,150]],'#f4e8cb');
  #| for(const [x,y,a,b] of JSON.parse(paths)){c.beginPath();c.moveTo(x,y);c.lineTo(a,b);c.lineWidth=Math.max(1,v*8);c.strokeStyle='#e9ddc3';c.stroke();}
  #| if(v>.65){
  #| c.strokeStyle='rgba(146,137,106,.15)';c.lineWidth=.7;
  #| for(let x=-80;x<115;x+=20){c.beginPath();c.moveTo(...p(x,98));c.lineTo(...p(x,153));c.stroke();}
  #| for(const z of [116,136,153]){c.beginPath();c.moveTo(...p(-98,z));c.lineTo(...p(112,z));c.stroke();}
  #| }
  #| c.restore();
  #| }

///|
/// Low-poly volumes and a shared sunlight direction, rather than mixed-angle
/// sprite furniture. Object dimensions are illustrative for street readability.
extern "js" fn street_paint_furniture(
  c : @dom.CanvasRenderingContext2D,
  raw : String,
  kind : String,
  x : Double,
  z : Double,
  reduced : Bool,
  time : Double,
) -> Unit =
  #| (c,raw,kind,x,z,reduced,time)=>{
  #| const [ox,oy,ex,ey,sx,sy,v]=JSON.parse(raw);if(v<.10)return;
  #| const p=(a,b,h=0)=>[ox+(x+a)*ex+(z+b)*sx,oy+(x+a)*ey+(z+b)*sy-h*v];
  #| const poly=(points,color)=>{c.beginPath();points.forEach((q,i)=>i?c.lineTo(...q):c.moveTo(...q));c.closePath();c.fillStyle=color;c.fill();};
  #| const line=(a,b,color,width=1)=>{c.beginPath();c.moveTo(...a);c.lineTo(...b);c.strokeStyle=color;c.lineWidth=Math.max(.45,width*v);c.stroke();};
  #| const box=(a,b,w,d,h,top='#e6d7b7',left='#9c9777',right='#c2b593')=>{
  #| poly([p(a,b),p(a+w,b),p(a+w,b,h),p(a,b,h)],left);
  #| poly([p(a+w,b),p(a+w,b+d),p(a+w,b+d,h),p(a+w,b,h)],right);
  #| poly([p(a,b,h),p(a+w,b,h),p(a+w,b+d,h),p(a,b+d,h)],top);};
  #| const disc=(a,b,h,rx,ry,color)=>{const q=p(a,b,h);c.beginPath();c.ellipse(q[0],q[1],Math.max(.1,rx*v),Math.max(.1,ry*v),0,0,Math.PI*2);c.fillStyle=color;c.fill();};
  #| const shadow=(r)=>{
  #| const q=p(0,0),rx=r*v,dy=r*v*.48;
  #| const footprint=[[-.65,-.12],[.42,-.23],[.83,.2],[.35,.43],[-.48,.25]];
  #| poly(footprint.map(([a,b])=>[q[0]+a*rx+dy*.48,q[1]+b*rx+dy*.3]),'rgba(56,96,76,.15)');
  #| disc(0,0,0,r*.35,r*.10,'rgba(56,96,76,.13)');};
  #| const leaf=(a,b,h,rx,ry,color)=>{const q=p(a,b,h);const points=[];
  #| for(let i=0;i<11;i++){const angle=i*Math.PI*2/11,r=.9+.12*Math.sin(i*4.7+a*.3+b*.7+x);points.push([q[0]+Math.cos(angle)*rx*v*r,q[1]+Math.sin(angle)*ry*v*r]);}poly(points,color);};
  #| c.save();c.lineJoin='round';c.lineCap='round';
  #| if(kind==='cafe'){
  #| shadow(35);box(-18,-9,36,18,20,'#e9d9b8','#a99370','#c5b38e');
  #| // Recessed service window, stone counter, and a canvas awning.
  #| poly([p(-15,10,9),p(15,10,9),p(15,10,18),p(-15,10,18)],'#425c50');
  #| // A decorative host in the service window, not a fabricated online agent.
  #| const tending=reduced?0:Math.sin(time*.55)*2;
  #| disc(4+tending,9,17,3.2,3.2,'#d4b38a');disc(4+tending,9,19,3.5,2,'#625b45');
  #| poly([p(tending,9,10),p(8+tending,9,10),p(7+tending,9,15),p(1+tending,9,15)],'#c9d4af');
  #| box(-19,8,38,6,9,'#f5edd9','#b7a78a','#d3c5a6');
  #| poly([p(-21,-12,24),p(21,-12,24),p(21,17,21),p(-21,17,21)],'#61a78e');
  #| for(let a=-21;a<21;a+=12)poly([p(a,-12,24),p(a+5,-12,24),p(a+5,17,21),p(a,17,21)],'#fff1cc');
  #| for(const a of [-20,20])line(p(a,16),p(a,16,21),'#8b8461',1.1);
  #| for(const a of [-9,3]){disc(a,12,10,2.4,1,'#f6f0de');line(p(a,12,10),p(a,12,13),'#f6f0de',3);}
  #| line(p(7+tending,10,14),p(3+tending*2,12,12),'#d4b38a',2);
  #| if(v>.75){const q=p(0,10,16);c.font=`600 ${Math.max(9,5*v)}px system-ui`;c.textAlign='center';c.fillStyle='#f2ecd3';c.fillText('COFFEE',q[0],q[1]);}
  #| if(document.documentElement.dataset.streetMemories?.split(',').includes('cafe')&&!reduced){
  #| const t=performance.now()/1800;for(let i=0;i<2;i++){const q=p(3,12,15+i*4);c.strokeStyle='rgba(255,254,238,.6)';c.lineWidth=v;c.beginPath();c.moveTo(q[0],q[1]);c.quadraticCurveTo(q[0]+Math.sin(t+i)*4*v,q[1]-3*v,q[0]+v,q[1]-6*v);c.stroke();}}
  #| }else if(kind==='table'){
  #| shadow(24);box(-2,-2,4,4,11,'#8c8064','#8c8064','#8c8064');
  #| disc(0,0,12,13,5.4,'#b6a380');disc(-1,-1,13,13,5.4,'#f0e4c8');
  #| line(p(0,0,12),p(0,0,37),'#92876b',1.2);
  #| const ring=[[-18,-10],[9,-17],[23,-2],[12,15],[-15,13],[-24,0]].map(([a,b])=>p(a,b,32));
  #| for(let i=0;i<6;i++)poly([p(0,0,40),ring[i],ring[(i+1)%6]],['#fff4d0','#f2ddb0','#f0d8a5','#dfcca1','#f9e7bc','#fff7dc'][i]);
  #| }else if(kind==='seat'){
  #| shadow(19);for(const a of [-12,11]){box(a,-3,2,8,5,'#68796a','#68796a','#68796a');}
  #| box(-14,-5,28,11,6,'#d7bc8f','#a08b69','#bda47d');
  #| for(let b=-4;b<6;b+=3)line(p(-14,b,6.3),p(14,b,6.3),'#a38e68',.55);
  #| poly([p(-14,-5,7),p(14,-5,7),p(14,-5,15),p(-14,-5,15)],'#cdb082');
  #| line(p(-14,-5,11),p(14,-5,11),'#ead5ac',.7);
  #| }else if(kind==='board'||kind==='events'){
  #| shadow(18);for(const a of [-10,10])line(p(a,4),p(a,-1,26),'#978263',1.5);
  #| poly([p(-12,0,8),p(12,0,8),p(12,0,28),p(-12,0,28)],'#c6af86');
  #| poly([p(-10,0,10),p(10,0,10),p(10,0,26),p(-10,0,26)],'#fff7e4');
  #| if(kind==='board'){
  #| poly([p(-8,-.1,12),p(8,-.1,12),p(8,-.1,24),p(-8,-.1,24)],'#b1cfbd');
  #| poly([p(-8,-.2,12),p(1,-.2,22),p(8,-.2,12)],'#5c8d7a');disc(-4,-.3,22,2.5,2.5,'#f1dda1');
  #| }else{for(const a of [-6,1])for(const h of [14,19])box(a,0,4,0.15,h,'#d49c74','#d49c74','#d49c74');}
  #| if(document.documentElement.dataset.streetMemories?.split(',').includes(kind==='board'?'stories':'events')){
  #| poly([p(6,-.5,27),p(10,-.5,27),p(10,-.5,21),p(8,-.5,23),p(6,-.5,21)],'#64886a');}
  #| }else if(kind==='pot'){
  #| shadow(11);box(-5,-4,10,8,8,'#d4b493','#a7866c','#c5a385');
  #| for(let i=0;i<5;i++)leaf(-4+(i*5)%9,-2+(i*3)%5,12+(i%3)*3,5,4,['#4f8258','#719b65','#9ab979'][i%3]);
  #| }else{
  #| for(let i=0;i<15;i++){const a=-18+(i*13)%38,b=(i*7)%11;line(p(a,b),p(a,b,4),'#689751',.6);disc(a,b,5,1.7,1.3,i%3?'#fff5da':x<0?'#f8d86a':'#f2a7ae');disc(a,b,5.2,.5,.4,'#d4a849');}
  #| // One tiny visitor to a flower drift, not a particle field or real agent.
  #| if(x===45&&!reduced&&v>.6){const t=performance.now()/1000,flight=(t%22)/22;if(flight<.5){const q=p(-14+flight*65,4+Math.sin(t*.7)*4,9+Math.sin(t)*2),wing=(.5+Math.abs(Math.sin(t*7)))*2*v;c.globalAlpha=Math.min(1,flight*20,(.5-flight)*20);c.fillStyle='#fff0b8';c.beginPath();c.ellipse(q[0]-wing*.5,q[1],wing,1.3*v,-.4,0,Math.PI*2);c.ellipse(q[0]+wing*.5,q[1],wing,1.3*v,.4,0,Math.PI*2);c.fill();}}
  #| }
  #| c.restore();
  #| }

///|
/// Stable grove palette: oak, poplar, pine, willow, flowering cherry, ginkgo.
/// Presentation only: no installation identities, coordinates or species claims
/// in the semantic world are changed by this illustrated planting mix.
fn town_botanical_tree_kind(
  x : Int32,
  y : Int32,
  seed : Double,
  waterside : Bool,
) -> Int32 {
  let local = (seed * 1000.0).floor().to_int().abs() % 10
  if waterside && local < 6 {
    return 3
  }
  let grove = energy_valley_mod(x / 13 * 7 + y / 11 * 3, 5)
  let dominant = [0, 1, 2, 4, 5][grove]
  if local < 7 {
    dominant
  } else {
    [0, 1, 2, 4, 5][local % 5]
  }
}

///|
fn town_botanical_tree_scale(seed : Double) -> Double {
  0.78 + seed.max(0.0).min(1.0) * 0.42
}

///|
let town_botanical_water_cache : Map[String, Bool] = Map([])

///|
fn town_botanical_waterside(x : Int32, y : Int32) -> Bool {
  if !reference_tile_snapshot_ready() {
    return false
  }
  let key = town_canvas_road_key(x, y)
  match town_botanical_water_cache.get(key) {
    Some(v) => return v
    None => ()
  }
  let mut water = false
  for dy in [-3, 0, 3] {
    for dx in [-3, 0, 3] {
      if reference_tile_kind_at(x + dx, y + dy)
        is Some("river" | "lake" | "water" | "wetland") {
        water = true
      }
    }
  }
  town_botanical_water_cache[key] = water
  water
}

///|
/// Sparse, coherent flower drifts rather than a checkerboard of single blooms.
/// -1 means no patch; 0 daisy, 1 buttercup, 2 violet spikes, 3 pink cosmos.
fn town_botanical_flower_kind(x : Int32, y : Int32) -> Int32 {
  let grove = energy_valley_mod(x / 7 * 11 + y / 6 * 17, 13)
  if grove > 3 || energy_valley_mod(x * 19 + y * 23, 7) > 1 {
    return -1
  }
  grove
}

///|
/// Reuses the existing Canvas material language and fixed screen-vertical trunks.
/// No bitmap/camera changes, and no minimum-pixel outline at overview scale.
fn town_botanical_draw_tree(
  context : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  zoom : Double,
  kind : Int32,
  size : Double,
  seed : Double,
) -> Unit {
  town_paint_botanical_tree(
    context,
    sx,
    sy,
    zoom,
    kind,
    size,
    seed,
    town_breeze(
      golden_animation_seconds(),
      seed,
      golden_prefers_reduced_motion(),
    ),
  )
}

///|
/// One slow canopy displacement; roots and collision/route coordinates never move.
fn town_breeze(time : Double, seed : Double, reduced : Bool) -> Double {
  if reduced {
    0.0
  } else {
    @math.sin(time * 0.8 + seed * 6.28) * 0.42
  }
}

///|
extern "js" fn town_paint_botanical_tree(
  context : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  zoom : Double,
  kind : Int32,
  size : Double,
  seed : Double,
  breeze : Double,
) -> Unit =
  #| (c,sx,sy,zoom,kind,size,seed,breeze)=>{
  #|   c.save(); c.translate(sx,sy); c.scale(zoom*2.5*size,zoom*2.5*size);
  #|   const oval=(x,y,rx,ry,fill)=>{
  #|     c.beginPath();c.ellipse(x,y,rx,ry,0,0,Math.PI*2);c.fillStyle=fill;c.fill();
  #|   };
  #|   const ellipse=(x,y,rx,ry,fill)=>{
  #|     // Consistent faceted lobes, not a stack of smooth disks.
  #|     c.beginPath();for(let i=0;i<10;i++){const a=i*Math.PI/5,r=.94+.07*Math.sin(i*4.3+seed*23+x);const px=x+Math.cos(a)*rx*r,py=y+Math.sin(a)*ry*r;i?c.lineTo(px,py):c.moveTo(px,py);}c.closePath();c.fillStyle=fill;c.fill();
  #|   };
  #|   const branch=(x,y,xx,yy,color,width)=>{
  #|     c.beginPath();c.moveTo(x,y);c.lineTo(xx,yy);c.strokeStyle=color;c.lineWidth=width;c.stroke();
  #|   };
  #|   c.lineCap='round';
  #|   // Sun upper-left: tapered, lobed cast shadow and a separate contact patch.
  #|   c.save();c.transform(1,.38,-.48,-.30,0,0);ellipse(0,-18,kind===1?5.5:11,kind===1?14:10,'rgba(35,80,58,.28)');c.restore();
  #|   oval(0,.4,3,1.4,'rgba(34,72,51,.34)');
  #|   branch(0,0,0,-18,'#8b7654',kind===1?1.5:2.1);
  #|   branch(-.4,-10,-5,-22,'#8b7654',1);branch(0,-13,6,-23,'#8b7654',1);
  #|   c.translate(zoom>.3?breeze:0,0);
  #|   if(kind===2){
  #|     // Three asymmetric soft tiers make an evergreen silhouette.
  #|     for(let i=0;i<3;i++){
  #|       const y=-8-i*7,w=10-i*2.3;
  #|       c.beginPath();c.moveTo(-w,y);c.quadraticCurveTo(-w*.45,y-6,0,y-14);
  #|       c.quadraticCurveTo(w*.36,y-6,w*.86,y);c.quadraticCurveTo(0,y+3,-w,y);
  #|       c.fillStyle=['#2c6454','#4b9561','#8fc36b'][i];c.fill();
  #|     }
  #|   }else if(kind===1){
  #|     ellipse(1,-20,5.4,14,'#347848');ellipse(-1.5,-23,4.2,12,'#79b64f');
  #|     ellipse(-2.5,-26,2.5,7,'#b7dc6a');
  #|   }else if(kind===3){
  #|     ellipse(0,-17,12,9,'#3b8054');ellipse(-3,-21,9,6,'#94c45d');
  #|     for(let i=-3;i<=3;i++){
  #|       const x=i*3.1, y=-19+Math.abs(i)*1.3;
  #|       c.beginPath();c.moveTo(x,y);c.quadraticCurveTo(x+2,y+7,x+1,y+13);
  #|       c.strokeStyle=i<0?'#34784f':'#83bd59';c.lineWidth=2;c.stroke();
  #|     }
  #|   }else if(kind===5){
  #|     branch(0,-9,-6,-19,'#917952',1.3);branch(0,-9,6,-18,'#917952',1.3);
  #|     ellipse(-6,-19,6.5,7,'#8da552');ellipse(6,-20,6,7.5,'#c2ce68');
  #|     ellipse(-1,-26,7.6,6.7,'#e3dc85');ellipse(-3,-28,4,3.5,'#f3e8a1');
  #|   }else{
  #|     const pink=kind===4;
  #|     ellipse(2,-14,9,7,pink?'#a96081':'#286147');
  #|     ellipse(-5,-19,8.5,7.4,pink?'#df87a0':'#438e51');
  #|     ellipse(6,-21,8,6.8,pink?'#f2a2b2':'#6cb14f');
  #|     ellipse(-1,-25,8.5,7,pink?'#f8bdc6':'#99cc62');
  #|     ellipse(-4,-28,4.3,3.2,pink?'#ffdbcf':'#c2df7b');
  #|     if(pink && zoom>.22){
  #|       for(let i=0;i<7;i++) ellipse(-7+(i*5.3)%15,-16-(i*3.7)%12,.65,.5,'#fff0dd');
  #|     }
  #|   }
  #|   c.restore();
  #| }

///|
extern "js" fn town_botanical_draw_flowers(
  c : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  zoom : Double,
  kind : Int32,
) -> Unit =
  #| (c,sx,sy,z,kind)=>{
  #|   if(kind<0)return;
  #|   c.save();c.translate(sx,sy);c.scale(z,z);
  #|   const petals=['#fff5da','#f8d86a','#b5a1db','#f2a7ae'];
  #|   c.fillStyle='rgba(126,158,97,0.32)';c.beginPath();c.ellipse(0,0,15,6,0,0,Math.PI*2);c.fill();
  #|   for(let i=0;i<7;i++){
  #|     const x=-11+(i*7)%24,y=-3+(i*3)%7;
  #|     c.strokeStyle='#79915b';c.lineWidth=.9;c.beginPath();c.moveTo(x,y+1);c.lineTo(x,y-3);c.stroke();
  #|     c.fillStyle=petals[kind];c.beginPath();
  #|     if(kind===2)c.ellipse(x,y-4,1.5,3.3,-.12,0,Math.PI*2);
  #|     else c.arc(x,y-3,kind===3?2.6:2.1,0,Math.PI*2);
  #|     c.fill();
  #|     if(z>.22 && kind!==2){c.fillStyle=kind===1?'#aa8b3e':'#d8bd63';c.beginPath();c.arc(x,y-3,.65,0,Math.PI*2);c.fill();}
  #|   }
  #|   c.restore();
  #| }

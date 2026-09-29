///|
/// Stable grove palette: oak, poplar, pine, willow, flowering cherry, ginkgo.
/// Presentation only: no installation identities, coordinates or species claims
/// in the semantic world are changed by this illustrated planting mix.
fn town_botanical_tree_kind(
  x : Int,
  y : Int,
  seed : Double,
  waterside : Bool,
) -> Int {
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
fn town_botanical_waterside(x : Int, y : Int) -> Bool {
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
fn town_botanical_flower_kind(x : Int, y : Int) -> Int {
  let grove = energy_valley_mod(x / 7 * 11 + y / 6 * 17, 13)
  if grove > 3 || energy_valley_mod(x * 19 + y * 23, 7) > 1 {
    return -1
  }
  grove
}

///|
/// Reuses the existing Canvas material language and fixed screen-vertical trunks.
/// No bitmap/camera changes, and no minimum-pixel outline at overview scale.
extern "js" fn town_botanical_draw_tree(
  context : @dom.CanvasRenderingContext2D,
  sx : Double,
  sy : Double,
  zoom : Double,
  kind : Int,
  size : Double,
  seed : Double,
) -> Unit =
  #| (c,sx,sy,zoom,kind,size,seed)=>{
  #|   c.save(); c.translate(sx,sy); c.scale(zoom*2.5*size,zoom*2.5*size);
  #|   const ellipse=(x,y,rx,ry,fill)=>{
  #|     c.beginPath();c.ellipse(x,y,rx,ry,0,0,Math.PI*2);c.fillStyle=fill;c.fill();
  #|   };
  #|   const branch=(x,y,xx,yy,color,width)=>{
  #|     c.beginPath();c.moveTo(x,y);c.lineTo(xx,yy);c.strokeStyle=color;c.lineWidth=width;c.stroke();
  #|   };
  #|   c.lineCap='round';
  #|   ellipse(3,1,kind===1?5:9,3.6,'rgba(53,77,53,0.15)');
  #|   branch(0,0,0,-18,'#8b7654',kind===1?1.5:2.1);
  #|   if(kind===2){
  #|     // Three asymmetric soft tiers make an evergreen silhouette.
  #|     for(let i=0;i<3;i++){
  #|       const y=-8-i*7,w=10-i*2.3;
  #|       c.beginPath();c.moveTo(-w,y);c.quadraticCurveTo(-w*.45,y-6,0,y-14);
  #|       c.quadraticCurveTo(w*.36,y-6,w*.86,y);c.quadraticCurveTo(0,y+3,-w,y);
  #|       c.fillStyle=['#497b68','#67957a','#91b28a'][i];c.fill();
  #|     }
  #|   }else if(kind===1){
  #|     ellipse(1,-20,5.4,14,'#719057');ellipse(-1.5,-23,4.2,12,'#9db975');
  #|     ellipse(-2.5,-26,2.5,7,'#becd8e');
  #|   }else if(kind===3){
  #|     ellipse(0,-17,12,9,'#80a974');ellipse(-3,-21,9,6,'#afc98b');
  #|     for(let i=-3;i<=3;i++){
  #|       const x=i*3.1, y=-19+Math.abs(i)*1.3;
  #|       c.beginPath();c.moveTo(x,y);c.quadraticCurveTo(x+2,y+7,x+1,y+13);
  #|       c.strokeStyle=i<0?'#719866':'#a6bf80';c.lineWidth=2;c.stroke();
  #|     }
  #|   }else if(kind===5){
  #|     branch(0,-9,-6,-19,'#917952',1.3);branch(0,-9,6,-18,'#917952',1.3);
  #|     ellipse(-6,-19,6.5,7,'#a4b562');ellipse(6,-20,6,7.5,'#becb7c');
  #|     ellipse(-1,-26,7.6,6.7,'#d1d992');ellipse(-3,-28,4,3.5,'#e1e3aa');
  #|   }else{
  #|     const pink=kind===4;
  #|     ellipse(-5,-16,7.5,6.4,pink?'#be8f9b':'#689061');
  #|     ellipse(5,-18,8,6.8,pink?'#dfafbd':'#90ac70');
  #|     ellipse(-1,-23,8.5,7,pink?'#efc9ce':'#b2c78a');
  #|     ellipse(-4,-25,4.3,3.2,pink?'#f7dce0':'#c5d5a0');
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
  kind : Int,
) -> Unit =
  #| (c,sx,sy,z,kind)=>{
  #|   if(kind<0)return;
  #|   c.save();c.translate(sx,sy);c.scale(z,z);
  #|   const petals=['#f7f1d6','#e6c65a','#a897ca','#e3a9bc'];
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

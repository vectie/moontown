///|
/// Presentation palette only. Terrain classes and calibrated coordinates are
/// still the authority; greens share one base so cells do not read as a mosaic.
fn town_daylight_color(role : String) -> String {
  match role {
    "water" => "#319fc8"
    "shallow" => "#67cfce"
    "deep" => "#226f9e"
    "path" => "#eeddb8"
    "leaf" => "#286147"
    "paper" => "#fff3d9"
    "pink" => "#f2a7ae"
    "yellow" => "#f8d86a"
    _ => "#abd85e"
  }
}

///|
extern "js" fn town_paint_daylight_ground(
  c : @dom.CanvasRenderingContext2D,
  terrain : String,
  sx : Double,
  sy : Double,
  zoom : Double,
  x : Int32,
  y : Int32,
) -> Bool =
  #| (c,terrain,sx,sy,z,x,y)=>{
  #| const camera=globalThis.__moontownGoldenValleyCamera;
  #| if(!camera?.livingRoom||!['grass','meadow','field','forest','wetland'].includes(terrain))return false;
  #| // Low-frequency light varies in world space, never by tile seed or viewport.
  #| const light=Math.sin(x*.061+y*.029)*3.5+Math.sin(y*.047-x*.019)*2.5;
  #| const wet=terrain==='wetland'?5:0;
  #| c.fillStyle=`rgb(${Math.round(171+light-wet)},${Math.round(216+light-wet*.4)},${Math.round(94+light+wet)})`;c.fill();
  #| if(z>.8&&(x*13+y*17)%19===0){c.save();c.clip();c.strokeStyle='rgba(243,240,186,.34)';c.lineWidth=Math.max(.6,z*.65);
  #| c.beginPath();c.moveTo(sx-3*z,sy);c.lineTo(sx-4*z,sy-2*z);c.moveTo(sx+z,sy+z);c.lineTo(sx+2*z,sy-z);c.stroke();c.restore();}
  #| return true;
  #| }

///|
/// Distance from authored land, not bathymetry. Two chamfer passes preserve the
/// exact water mask, including bridges; out-of-map edges are not invented banks.
fn town_water_distances(
  water : Array[Bool],
  width : Int32,
  height : Int32,
) -> Array[Double] {
  guard width > 0 && height > 0 && water.length() == width * height else {
    return []
  }
  let d = water.map(w => if w { 32.0 } else { 0.0 })
  for y in 0..<height {
    for x in 0..<width {
      let i = y * width + x
      if x > 0 {
        d[i] = d[i].min(d[i - 1] + 1)
      }
      if y > 0 {
        d[i] = d[i].min(d[i - width] + 1)
        if x > 0 {
          d[i] = d[i].min(d[i - width - 1] + 1.41421356)
        }
        if x + 1 < width {
          d[i] = d[i].min(d[i - width + 1] + 1.41421356)
        }
      }
    }
  }
  for yy in 0..<height {
    let y = height - 1 - yy
    for xx in 0..<width {
      let x = width - 1 - xx
      let i = y * width + x
      if x + 1 < width {
        d[i] = d[i].min(d[i + 1] + 1)
      }
      if y + 1 < height {
        d[i] = d[i].min(d[i + width] + 1)
        if x > 0 {
          d[i] = d[i].min(d[i + width - 1] + 1.41421356)
        }
        if x + 1 < width {
          d[i] = d[i].min(d[i + width + 1] + 1.41421356)
        }
      }
    }
  }
  d
}

///|
fn town_daylight_draw_water(
  c : @dom.CanvasRenderingContext2D,
  width : Int32,
  height : Int32,
) -> Unit {
  if !reference_tile_snapshot_ready() {
    return
  }
  if !town_water_texture_ready() {
    let water = Array::make(256 * 144, false)
    for y in 0..<144 {
      for x in 0..<256 {
        water[y * 256 + x] = reference_tile_kind_at(x, y)
          is Some("river" | "lake" | "water" | "bridge")
      }
    }
    town_water_texture_prepare(town_water_distances(water, 256, 144))
  }
  town_water_texture_draw(c, width, height)
}

///|
extern "js" fn town_water_texture_ready() -> Bool =
  #| ()=>Boolean(globalThis.__townSunnyWater && globalThis.__townSunnyWater.source===globalThis.__wenyuReferenceLabels?.rows)

///|
/// One bounded 1024×576 color texture and one exact native-grid clip, shared by
/// every camera. Only this paint transport touches pixels, never source assets.
extern "js" fn town_water_texture_prepare(distance : Array[Double]) -> Unit =
  #| d=>{
  #| const w=256,h=144,s=4,canvas=document.createElement('canvas');canvas.width=w*s;canvas.height=h*s;
  #| const c=canvas.getContext('2d'),data=c.createImageData(w*s,h*s),mask=new Path2D(),ripples=[];
  #| const at=(x,y)=>d[Math.max(0,Math.min(h-1,y))*w+Math.max(0,Math.min(w-1,x))];
  #| const stops=[[0,[238,221,184]],[.28,[145,214,189]],[.6,[103,207,206]],[1.3,[49,159,200]],[4,[34,111,158]]];
  #| for(let y=0;y<h;y++)for(let x=0;x<w;x++){
  #| if(d[y*w+x]===0)continue;if(x===0||d[y*w+x-1]===0){let end=x+1;while(end<w&&d[y*w+end]>0)end++;mask.rect(x,y,end-x,1);}
  #| if(d[y*w+x]>2&&(x*37+y*19)%71===0){const gx=at(x+1,y)-at(x-1,y),gy=at(x,y+1)-at(x,y-1),n=Math.hypot(gx,gy);let tx=n>0?gy/n:.3,ty=n>0?-gx/n:.95;if(ty<0){tx=-tx;ty=-ty;}ripples.push([x+.5,y+.5,tx,ty]);}
  #| for(let py=0;py<s;py++)for(let px=0;px<s;px++){
  #| const wx=x+(px+.5)/s,wy=y+(py+.5)/s,fx=wx-.5,fy=wy-.5,ix=Math.floor(fx),iy=Math.floor(fy),u=fx-ix,v=fy-iy;
  #| const depth=Math.max(0,(at(ix,iy)*(1-u)+at(ix+1,iy)*u)*(1-v)+(at(ix,iy+1)*(1-u)+at(ix+1,iy+1)*u)*v-.5);
  #| let k=1;while(k<stops.length-1&&depth>stops[k][0])k++;
  #| const [lo,a]=stops[k-1],[hi,b]=stops[k],t=Math.min(1,Math.max(0,(depth-lo)/(hi-lo))),f=t*t*(3-2*t);
  #| const offset=((y*s+py)*w*s+x*s+px)*4,light=Math.sin(wx*.32+wy*.14)*1.3;
  #| for(let ch=0;ch<3;ch++)data.data[offset+ch]=Math.round(a[ch]+(b[ch]-a[ch])*f+light);data.data[offset+3]=255;
  #| }}
  #| c.putImageData(data,0,0);globalThis.__townSunnyWater={source:globalThis.__wenyuReferenceLabels?.rows,canvas,mask,ripples,d};
  #| }

///|
extern "js" fn town_water_texture_draw(
  c : @dom.CanvasRenderingContext2D,
  width : Int32,
  height : Int32,
) -> Unit =
  #| (c,w,h)=>{
  #| const a=globalThis.__townSunnyWater,cam=globalThis.__moontownGoldenValleyCamera;if(!a||!cam?.livingRoom)return;
  #| const z=cam.z;c.save();c.transform(32*z,16*z,-32*z,16*z,w/2-cam.x*z,h/2-cam.y*z);c.clip(a.mask);
  #| c.imageSmoothingEnabled=true;c.drawImage(a.canvas,0,0,256,144);c.restore();
  #| }

///|
/// Separate from the cached ground: water keeps moving while the camera rests.
/// The conservative road occupancy excludes bridge decks and road crossings.
extern "js" fn town_water_ripples_draw(
  c : @dom.CanvasRenderingContext2D,
  width : Int32,
  height : Int32,
  time : Double,
  reduced : Bool,
  roads : Array[Int32],
) -> Unit =
  #| (c,w,h,time,reduced,roads)=>{
  #| const a=globalThis.__townSunnyWater,cam=globalThis.__moontownGoldenValleyCamera;if(!a||!cam?.livingRoom||cam.z<.55||roads.length!==257*145)return;
  #| const z=cam.z;c.save();c.transform(32*z,16*z,-32*z,16*z,w/2-cam.x*z,h/2-cam.y*z);c.clip(a.mask);
  #| c.lineCap='round';c.lineWidth=.025;c.strokeStyle='rgba(235,255,247,.5)';
  #| for(const [x,y,tx,ty] of a.ripples){const sx=w/2+(32*(x-y)-cam.x)*z,sy=h/2+(16*(x+y)-cam.y)*z;if(sx< -80||sx>w+80||sy< -80||sy>h+80)continue;
  #| const x0=Math.max(0,Math.floor(x)-1),y0=Math.max(0,Math.floor(y)-1),x1=Math.min(256,x0+3),y1=Math.min(144,y0+3);
  #| if(roads[y1*257+x1]-roads[y0*257+x1]-roads[y1*257+x0]+roads[y0*257+x0]>0)continue;
  #| const phase=reduced?.35:(time*.1+x*.31+y*.17)%1,shift=(phase-.5)*.8,px=x+tx*shift,py=y+ty*shift;
  #| c.globalAlpha=reduced?.65:Math.sin(phase*Math.PI)*.7;c.beginPath();c.moveTo(px-tx*.33,py-ty*.33);c.quadraticCurveTo(px-ty*.09,py+tx*.09,px+tx*.33,py+ty*.33);c.stroke();}
  #| c.restore();
  #| }

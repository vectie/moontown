// Wheel presentation for large, memory-limited screens. Geometry and picking
// retain the live camera; every image comes from that same public world camera.
const art = new URL('./town-projections/',import.meta.url)
const overview = [-14592,-9088,32768,24576], fine = [-6400,-4992,4096]
const copy = c => ({x:c.x,y:c.y,z:c.z})
const cache = new Map()
let base, tick = 0, frontierArt = false
const frontierView = () => /[?&]frontier=1(?:&|$)/.test(location.search)
function image(name) {
  const img=new Image()
  img.decoding='async'
  img.src=new URL((frontierArt?'frontier-wheel-':'wheel-')+name+'.webp',art)
  const entry={img,ready:false,age:++tick}
  img.decode().then(()=>entry.ready=true,()=>{})
  return entry
}
function tiles(c,w,h,load) {
  const [left,top,step]=fine
  const x0=Math.max(0,Math.floor((c.x-w/(2*c.z)-left)/step)),x1=Math.min(3,Math.floor((c.x+w/(2*c.z)-left)/step))
  const y0=Math.max(0,Math.floor((c.y-h/(2*c.z)-top)/step)),y1=Math.min(3,Math.floor((c.y+h/(2*c.z)-top)/step))
  const found=[]
  if(c.z<.15)return found
  for(let y=y0;y<=y1;y++)for(let x=x0;x<=x1;x++){
    const key=x+'-'+y
    let e=cache.get(key)
    if(!e&&load&&cache.size<10){e=image(key);cache.set(key,e)}
    if(e){e.age=++tick;if(e.ready)found.push([e.img,left+x*step,top+y*step,step,step])}
  }
  if(load&&cache.size>=10){const inView=k=>{const [x,y]=k.split('-').map(Number);return x>=x0&&x<=x1&&y>=y0&&y<=y1}
    for(const [k] of [...cache].sort((a,b)=>a[1].age-b[1].age))if(!inView(k)&&cache.size>=9)cache.delete(k)}
  return found
}
function covered(c,w,h) {
  return c.z>0 && Math.abs(c.x-1792)+w/(2*c.z)<=16384 && Math.abs(c.y-3200)+h/(2*c.z)<=12288
}
function canUse(owner,world,w,h) {
  return globalThis.__townDisplay?.compact && w*h>=2000000 && globalThis.__townPublicBaseline?.world===world &&
    globalThis.__townLandmarkPainter?.districtReady?.() && document.documentElement.dataset.landmarkModels==='ready' &&
    !globalThis.__townLandmarkPainter?.wheelArtBlocked?.() &&
    (!frontierView() || document.documentElement.dataset.frontierVersion==='exterior-city-v3') &&
    !/[?&](road-trial|shore-review|site-review|edit|seed|building-bearing|bake-tiles)=/.test(location.search)
}
// Clip in source space before scaling: asking Chromium 114 to draw the
// entire overview enlarged to 60,000 pixels stalls the shared GPU queue.
function stamp(ctx,img,r,box,pw,ph){
  const [x,y,w,h]=r,[a,b,c,d]=box, x0=Math.max(x,a),y0=Math.max(y,b),x1=Math.min(x+w,a+c),y1=Math.min(y+h,b+d)
  if(x1<=x0||y1<=y0)return
  ctx.drawImage(img,(x0-x)/w*img.width,(y0-y)/h*img.height,(x1-x0)/w*img.width,(y1-y0)/h*img.height,
    (x0-a)/c*pw,(y0-b)/d*ph,(x1-x0)/c*pw,(y1-y0)/d*ph)
}
function place(node,c,w,h,box){
  const [x,y,a,b]=box
  node.style.transform='translate3d('+(w/2+(x-c.x)*c.z)+'px,'+(h/2+(y-c.y)*c.z)+'px,0) scale('+a*c.z/node.width+','+b*c.z/node.height+')'
}
const sheet=()=>{const el=document.createElement('canvas');el.style.cssText='position:absolute;left:0;top:0;transform-origin:0 0;will-change:transform;max-width:none;max-height:none;pointer-events:none';return el}
function preparePlate(owner,c,w,h){
  const factor=6.75, view={...c,z:c.z/factor}
  const imgs=tiles(view,w,h,true), key=[c.x,c.y,c.z,w,h,imgs.length].join(',')
  const old=owner.wheelPlate
  if(old?.key===key)return
  // If the richer sheet still covers the next zoom-out, reuse it. Rebuilding
  // the future gesture's backdrop during the return to live traffic competes
  // with the first GPU upload of the new street view.
  if(old && imgs.every(([img])=>old.images.has(img)) && old.zoom>=c.z-1e-8 &&
     fits({...c,z:c.z/2},w,h,old.box))return
  const el=owner.wheelPlate?.el||sheet(),pw=1536,ph=Math.ceil(pw*h/w),box=[c.x-w/(2*view.z),c.y-h/(2*view.z),w/view.z,h/view.z]
  if(el.width!==pw||el.height!==ph){el.width=pw;el.height=ph}
  const ctx=el.getContext('2d');stamp(ctx,base.img,overview,box,pw,ph)
  for(const [im,...r] of imgs)stamp(ctx,im,r,box,pw,ph)
  owner.wheelPlate={el,box,key,zoom:c.z,images:new Set(imgs.map(([img])=>img))}
}
function mount(owner,c,w,h){
  const pane=document.createElement('div'),canvas=owner.canvas
  pane.ariaHidden='true';pane.style.cssText='pointer-events:none;position:absolute;overflow:hidden;contain:strict;inset:0;'
  const img=sheet();img.width=canvas.width;img.height=canvas.height;img.getContext('2d').drawImage(canvas,0,0)
  pane.append(owner.wheelPlate.el,img);canvas.after(pane)
  return {pane,img,near:[c.x-w/(2*c.z),c.y-h/(2*c.z),w/c.z,h/c.z]}
}
function fits(c,w,h,r){
  return c.x-w/(2*c.z)>=r[0]&&c.y-h/(2*c.z)>=r[1]&&c.x+w/(2*c.z)<=r[0]+r[2]&&c.y+h/(2*c.z)<=r[1]+r[3]
}
const wheel={
  defer(world,night){
    const o=globalThis.__moontownGoldenValleyCanvasLifecycle,c=globalThis.__moontownGoldenValleyCamera
    if(o && (o.wheelMotion||o.panArt) && frontierArt!==frontierView()){this.release(o);return false}
    if(o?.panArt){
      if(o.cameraDragging && !night && world===o.wheelWorld && o.canvas.clientWidth===o.wheelWidth && o.canvas.clientHeight===o.wheelHeight && !globalThis.__townLandmarkPainter?.wheelArtBlocked?.())return true
      this.endPan(o)
    }
    if(!o?.wheelMotion)return false
    const {to}=o.wheelMotion
    if(!night && o.wheelWorld===world && o.canvas.isConnected && o.canvas.clientWidth===o.wheelWidth && o.canvas.clientHeight===o.wheelHeight &&
      c.z===to.z && c.x===to.x && c.y===to.y && !c.streetTransition && !globalThis.__townLandmarkPainter?.wheelArtBlocked?.())return true
    this.cancel(o);return false
  },
  prepare(owner,world,w,h) {
    owner.zoomPresented=false
    if(frontierArt!==frontierView()){this.release(owner);frontierArt=frontierView()}
    const c=globalThis.__moontownGoldenValleyCamera
    owner.presentedZoom=c.z
    if(!c.livingRoom || !canUse(owner,world,w,h)){this.endPan(owner);this.cancel(owner);owner.wheelWorld=null;return false}
    if(owner.wheelWorld!==world || owner.wheelWidth!==w || owner.wheelHeight!==h){
      this.endPan(owner);this.cancel(owner);owner.wheelWorld=world;owner.wheelWidth=w;owner.wheelHeight=h
    }
    if(!base)base=image('overview')
    const s=owner.wheelMotion
    if(!s || !owner.wheelFrame){
      if(base.ready&&covered(c,w,h))preparePlate(owner,c,w,h)
      return false
    }
    return true
  },
  startPan(owner,c) {
    const w=owner.wheelWidth,h=owner.wheelHeight;
    if(!owner.wheelWorld || !owner.wheelPlate || !covered(c,w,h) || !fits(c,w,h,owner.wheelPlate.box))return false
    this.endPan(owner)
    owner.panArt={...mount(owner,c,w,h),origin:copy(c)}
    const signs=document.querySelector('.street-destinations')
    if(signs?.querySelector('[data-anchored="true"]'))owner.panArt.signs=signs
    this.pan(owner,c)
    return true
  },
  pan(owner,c) {
    if(!owner.panArt)return false
    const w=owner.wheelWidth,h=owner.wheelHeight
    if(!fits(c,w,h,owner.wheelPlate.box)||!covered(c,w,h)){this.endPan(owner);return false}
    place(owner.wheelPlate.el,c,w,h,owner.wheelPlate.box)
    place(owner.panArt.img,c,w,h,owner.panArt.near)
    const {signs,origin}=owner.panArt
    if(signs){
      const x=(origin.x-c.x)*c.z,y=(origin.y-c.y)*c.z+(owner.canvas.townProjection?.shear||0)*x
      signs.style.transform='translate('+x+'px,'+y+'px)'
    }
    globalThis.__townLandmarkPainter?.projectPins?.({cx:c.x,cy:c.y,z:c.z,w,h})
    return true
  },
  endPan(owner) {
    if(owner.panArt){if(owner.panArt.signs)owner.panArt.signs.style.transform='';owner.panArt.pane.remove();owner.panArt.img.width=0;owner.panArt=null}
  },
  begin(owner,c,to) {
    const w=owner.wheelWidth,h=owner.wheelHeight
    if(!owner.wheelWorld||!base?.ready||!owner.wheelPlate||!covered(c,w,h)||!covered(to,w,h)||!fits(to,w,h,owner.wheelPlate.box)){this.cancel(owner);return}
    if(!frontierArt)globalThis.__townLandmarkPainter?.warmGround?.(to.x,to.y,to.z,w,h)
    const now=performance.now()
    let s=owner.wheelMotion
    if(!s){
      s=owner.wheelMotion={origin:copy(c),...mount(owner,c,w,h),last:copy(c)}
    }
    Object.assign(s,{from:copy(s.last),to:copy(to),start:now})
  },
  enter(owner,c,now,reason) {
    const s=owner.wheelMotion
    if(!s)return
    if((reason!=='interaction'&&reason!=='animation'&&reason!=='region-ground'&&reason!=='road-overlay')||s.to.z!==c.z||s.to.x!==c.x||s.to.y!==c.y||
       now-s.start>=295){this.cancel(owner);c.zoomUntil=0;owner.zoomPreview=false;return}
    const saved=copy(c),t=globalThis.matchMedia('(prefers-reduced-motion: reduce)').matches?1:Math.min(1,(now-s.start)/265),
      b=t*(2-t),a=1-b,z=a*s.from.z+b*s.to.z
    Object.assign(c,{z,x:(a*s.from.x*s.from.z+b*s.to.x*s.to.z)/z,y:(a*s.from.y*s.from.z+b*s.to.y*s.to.z)/z})
    s.last=copy(c);owner.wheelFrame=true
    return saved
  },
  paint(ctx,world,w,h,night) {
    const owner=globalThis.__moontownGoldenValleyCanvasLifecycle
    if(owner && night){this.endPan(owner);this.cancel(owner);owner.wheelWorld=null;owner.zoomPresented=false;return false}
    if(!owner||!this.prepare(owner,world,w,h))return false
    const c=globalThis.__moontownGoldenValleyCamera,s=owner.wheelMotion
    place(owner.wheelPlate.el,c,w,h,owner.wheelPlate.box)
    place(s.img,c,w,h,s.near)
    globalThis.__townLandmarkPainter?.projectPins?.({cx:c.x,cy:c.y,z:c.z,w,h})
    owner.zoomPresented=true
    return true
  },
  cancel(owner) {
    if(owner.wheelMotion){owner.wheelMotion.pane.remove();owner.wheelMotion.img.width=0;owner.wheelMotion.img.height=0;owner.wheelMotion=null}
    owner.wheelFrame=false
  },
  release(owner){this.endPan(owner);this.cancel(owner);owner.wheelWorld=null;if(owner.wheelPlate){owner.wheelPlate.el.width=0;owner.wheelPlate=null}base=null;cache.clear()}
}
globalThis.__townWheel=wheel

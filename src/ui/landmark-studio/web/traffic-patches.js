// At street scale cars occupy a small part of the screen. Keep only those
// rectangles from the painter's ordered layers. Overlapping cars share a
// rectangle so translucent shadows and the order of passing vehicles survive.
export function makeTrafficPatches(target, rows, frame, ratio, strips) {
  const width=target.canvas.width, height=target.canvas.height, boxes=[]
  for(const [depth,items] of rows) for(const car of items) {
    if(car.k==='lamp')continue
    const radius=frame.z*18+4
    const box={l:Math.max(0,Math.floor((car.x-radius)*ratio)),t:Math.max(0,Math.floor((car.y-radius)*ratio)),
      r:Math.min(width,Math.ceil((car.x+radius)*ratio)),b:Math.min(height,Math.ceil((car.y+radius)*ratio)),
      depths:new Set([depth,car.adjacent])}
    if(box.l>=box.r||box.t>=box.b)continue
    for(let i=0;i<boxes.length;) {
      const other=boxes[i]
      if(box.r<=other.l||box.l>=other.r||box.b<=other.t||box.t>=other.b){i++;continue}
      box.l=Math.min(box.l,other.l);box.r=Math.max(box.r,other.r)
      box.t=Math.min(box.t,other.t);box.b=Math.max(box.b,other.b)
      for(const d of other.depths)box.depths.add(d)
      boxes.splice(i,1);i=0
    }
    boxes.push(box)
  }
  const cuts=new Set(strips.map(s=>s.depth))
  const atlasWidth=Math.max(512,...boxes.map(b=>b.r-b.l))
  let x=0,y=0,shelf=0
  for(const box of boxes) {
    box.width=box.r-box.l;box.height=box.b-box.t
    box.layers=new Map()
    const depths=[...box.depths].filter(d=>cuts.has(d)).sort((a,b)=>a-b)
    box.first=depths[0]
    for(const depth of [null,...depths]) {
      if(x+box.width>atlasWidth){y+=shelf;shelf=0;x=0}
      const slot={x,y}
      if(depth===null)box.base=slot
      else box.layers.set(depth,slot)
      x+=box.width;shelf=Math.max(shelf,box.height)
    }
  }
  if(!boxes.length || atlasWidth*(y+shelf)>1800000 || y+shelf>4096)return null
  const owner=globalThis.__moontownGoldenValleyCanvasLifecycle
  function surface(key,w,h){
    const tile=owner[key]??=document.createElement('canvas')
    if(tile.width!==w)tile.width=w
    if(tile.height!==h)tile.height=h
    const g=tile.getContext('2d')
    g.setTransform(1,0,0,1,0,0);g.clearRect(0,0,w,h)
    return g
  }
  const atlas=surface('trafficPatchAtlas',atlasWidth,y+shelf)
  const scratch=surface('trafficScratch',width,height)
  let index=-1
  function flush(){
    if(index<0)return
    const {top,bottom}=strips[index]
    if(bottom<=top)return
    target.save();target.setTransform(1,0,0,1,0,0)
    target.drawImage(scratch.canvas,0,top,width,bottom-top,0,top,width,bottom-top)
    target.restore()
    for(const b of boxes){
      const a=b.active, t=Math.max(top,b.t),end=Math.min(bottom,b.b)
      if(a && t<end)atlas.drawImage(scratch.canvas,b.l,t,b.width,end-t,a.x,a.y+t-b.t,b.width,end-t)
    }
    scratch.setTransform(1,0,0,1,0,0);scratch.clearRect(0,top,width,bottom-top)
  }
  function advance(i){
    flush();index=i
    const d=strips[i].depth
    for(const b of boxes){
      const next=b.layers.get(d)
      if(!next)continue
      if(d===b.first)atlas.drawImage(target.canvas,b.l,b.t,b.width,b.height,b.base.x,b.base.y,b.width,b.height)
      b.active=next
    }
    scratch.setTransform(ratio,0,0,ratio,0,0)
  }
  return {
    depth(d){
      while(index+1<strips.length && strips[index+1].first<=d)advance(index+1)
      return scratch
    },
    finish:flush,
    present(current,drawCars){
      const groups=new Map()
      for(const [d,items] of current)for(const car of items){
        if(car.k==='lamp')continue
        const px=car.x*ratio,py=car.y*ratio,pad=(frame.z*5+1)*ratio
        if(px+pad<=0||py+pad<=0||px-pad>=width||py-pad>=height)continue
        const b=boxes.find(b=>b.layers.has(d)&&Math.max(0,px-pad)>=b.l&&Math.min(width,px+pad)<=b.r&&Math.max(0,py-pad)>=b.t&&Math.min(height,py+pad)<=b.b)
        if(!b)return false
        const layer=b.layers.get(d)
        if(!groups.has(layer))groups.set(layer,[])
        groups.get(layer).push(car)
      }
      function blit(b,s){
        target.drawImage(atlas.canvas,s.x,s.y,b.width,b.height,b.l/ratio,b.t/ratio,b.width/ratio,b.height/ratio)
      }
      for(const b of boxes){
        blit(b,b.base)
        for(const [d,layer] of b.layers){
          const cars=groups.get(layer)
          if(cars)drawCars(d,cars)
          blit(b,layer)
        }
      }
      return true
    },
  }
}

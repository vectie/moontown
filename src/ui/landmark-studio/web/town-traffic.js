// Town-space grid from the shoreline compiler; no second road overlay or camera.
import { makeTrafficPatches } from './traffic-patches.js'
import { lane, sample } from './street-motion.js'
import { visibleMotorRoads } from './town-region.js'
let network = [],
  rows = new Map(),
  last = null,
  time = 0,
  visibleCount = 0,
  firstCar = null
export async function loadTraffic() {
  const r = await fetch(new URL('./town-motor-streets.json', import.meta.url))
  if (!r.ok) throw Error('motor streets ' + r.status)
  network = (await r.json()).map(([id, dir, pts]) => {
    const path = lane(pts),
      xs = pts.map((p) => 32 * (p[0] - p[1])),
      ys = pts.map((p) => 16 * (p[0] + p[1]))
    return {
      id,
      dir,
      path,
      l: Math.min(...xs),
      r: Math.max(...xs),
      t: Math.min(...ys),
      b: Math.max(...ys),
    }
  })
}
export function prepare(f, sec, reduced, hour) {
  rows.clear()
  visibleCount = 0
  firstCar = null
  // Use elapsed time under load; reset after a hidden tab rather than slowing every car with the frame rate.
  if (!reduced && last !== null && sec - last < 3)
    time += Math.max(0, sec - last)
  last = sec
  if (f.z < 0.17) return
  const night = hour < 7 || hour >= 18,
    hw = f.w / (2 * f.z) + 12,
    hh = f.h / (2 * f.z) + 12
  function place(k, p, dir, col, fade) {
    const x = f.w / 2 + (32 * (p.x - p.z) - f.cx) * f.z,
      y = f.h / 2 + (16 * (p.x + p.z) - f.cy) * f.z
    if (x < -12 || x > f.w + 12 || y < -12 || y > f.h + 12) return
    if (k !== 'lamp') {
      if (globalThis.__townBakeZoomArt) return
      if (globalThis.__townDisplay?.compact && visibleCount >= 60) return
      visibleCount++
      firstCar ??= [x, y]
    }
    const z = k === 'outside' ? -1 : Math.floor(p.x + p.z)
    if (!rows.has(z)) rows.set(z, [])
    rows
      .get(z)
      .push({
        k,
        x,
        y,
        dx: dir * (p.dx - p.dz),
        dy: (dir * (p.dx + p.dz)) / 2,
        adjacent: k === 'outside' ? -1 : (p.x+p.z-z < .22 ? z-1 : p.x+p.z-z > .78 ? z+1 : z),
        col,
        fade,
        night,
      })
  }
  for (const { id, dir, path, l, r, t, b } of network) {
    if (l > f.cx + hw || r < f.cx - hw || t > f.cy + hh || b < f.cy - hh)
      continue
    const n = Math.min(8, Math.max(1, Math.floor(path.length / 3.3))),
      seed = (id % 251) / 251
    for (let i = 0; i < n; i++) {
      const sign = dir || ((i + id) % 2 ? 1 : -1),
        s =
          (((time * (0.19 + seed * 0.09)) / path.length + seed + i / n) % 1) *
          path.length
      const p = sample(
        path,
        sign > 0 ? s : path.length - s,
        dir ? 0 : sign * 0.1,
      )
      place(
        'car',
        p,
        sign,
        (id + i) % 6,
        Math.min(1, s / 0.24, (path.length - s) / 0.24),
      )
    }
    if (f.z > (globalThis.__townDisplay?.compact ? 0.85 : 0.46))
      for (let d = 1.8 + seed; d < path.length - 0.5; d += 3.7) {
        place('lamp', sample(path, d, 0.49), 1, 0, 1)
      }
  }
  for (const road of visibleMotorRoads()) {
    if (visibleCount >= (globalThis.__townDisplay?.compact ? 60 : 140)) break
    if (
      road.b.left > f.cx + hw ||
      road.b.right < f.cx - hw ||
      road.b.top > f.cy + hh ||
      road.b.bottom < f.cy - hh
    )
      continue
    road.route ??= lane(
      road.points.map(([x, y]) => [
        (x / 32 + y / 16) / 2,
        (y / 16 - x / 32) / 2,
      ]),
    )
    const path = road.route
    if (path.p.length < 2) continue
    const sign = road.dir || 1,
      d = (time * 0.25 + road.id * 0.17) % path.length,
      p = sample(path, sign > 0 ? d : path.length - d, sign * 0.1)
    if (p.x >= 0 && p.x <= 256 && p.z >= 0 && p.z <= 144) continue
    place(
      'outside',
      p,
      sign,
      road.id % 6,
      Math.min(1, d / 0.2, (path.length - d) / 0.2),
    )
  }
}
const coats = ['#ba7259', '#f5ebcb', '#72929b', '#8da38d', '#cfac72', '#9bafba']
export function draw(c, depth, f, vehiclesOnly=false, items=rows.get(depth)) {
  if (!items) return
  for (const { k, x, y, dx, dy, col, fade, night } of items) {
    if (k === 'lamp' ? vehiclesOnly : (record && !vehiclesOnly)) continue
    c.save()
    c.translate(x, y)
    c.scale(f.z, f.z)
    if (k === 'lamp') {
      if (night) {
        const g = c.createRadialGradient(0, 0, 0, 0, 0, 8)
        g.addColorStop(0, 'rgba(255,222,144,.48)')
        g.addColorStop(1, 'rgba(255,213,130,0)')
        c.save()
        c.scale(1, 0.54)
        c.fillStyle = g
        c.fillRect(-8, -8, 16, 16)
        c.restore()
      }
      c.strokeStyle = '#657566'
      c.lineWidth = 0.75
      c.beginPath()
      c.moveTo(0, 0)
      c.lineTo(0, -5.6)
      c.lineTo(-1.5, -5.6)
      c.stroke()
      c.fillStyle = night ? '#ffe7a5' : '#dad9c0'
      c.fillRect(-2, -5.7, 1.6, 0.68)
    } else {
      c.rotate(Math.atan2(dy, dx))
      c.globalAlpha = fade
      c.fillStyle = 'rgba(62,71,57,.25)'
      c.fillRect(-3, -1.1, 6.7, 3.3)
      c.fillStyle = '#485c59'
      c.fillRect(-2.6, -1.72, 5.1, 3.48)
      c.fillStyle = coats[col]
      c.fillRect(-3.23, -1.45, 6.46, 2.9)
      c.fillStyle = '#517077'
      c.fillRect(-1.9, -1.16, 3.55, 2.29)
      c.fillStyle = coats[col]
      c.fillRect(-1.26, -1.12, 1.82, 2.2)
      c.fillStyle = night ? '#fff4bb' : '#eae5c8'
      c.fillRect(2.85, -1.27, 0.45, 0.64)
      c.fillRect(2.85, 0.6, 0.45, 0.64)
      c.fillStyle = '#bd6954'
      c.fillRect(-3.23, -1.25, 0.38, 0.6)
      c.fillRect(-3.23, 0.64, 0.38, 0.6)
    }
    c.restore()
  }
}

export const stats = () => ({
  visible: visibleCount,
  position: firstCar,
  seconds: time,
})

let record = null

// Each transparent strip starts where a moving car joins the existing
// painter's order. No pixels are read back from the display surface.
function composite(state) {
  const {target,f,ratio} = state
  for (const strip of state.strips) {
    draw(target,strip.depth,f,true)
    if (strip.bottom > strip.top) {
      const height=strip.bottom-strip.top, width=target.canvas.width
      target.drawImage(strip.g.canvas,0,strip.offset,width,height,0,strip.top/ratio,width/ratio,height/ratio)
    }
  }
}
function releaseStreetPages(owner) {
  clearTimeout(owner.streetPageExpiry)
  owner.streetPageExpiry=0
  for (const page of owner.streetPages || []) { page.width=0;page.height=0 }
  owner.streetPages=null
  owner.trafficCache=null
  for(const key of ['trafficGround','trafficScratch','trafficPatchAtlas'])if(owner[key]){owner[key].width=0;owner[key]=null}
}

// Several depths share each GPU canvas. Switching rows changes only the clip
// and translation. Keeping an atlas per depth exhausted graphics memory on Mali.
function packStreetPages(owner,strips,width) {
  clearTimeout(owner.streetPageExpiry)
  owner.streetPageExpiry=0
  const limit=Math.max(1024,Math.min(4096,Math.floor(2097152/width)))
  const heights=[0]
  for(const strip of strips) {
    const height=Math.max(1,strip.bottom-strip.top)
    let page=heights.length-1
    if(heights[page] && heights[page]+height>limit){page++;heights.push(0)}
    strip.page=page
    strip.offset=heights[page]
    heights[page]+=height
  }
  const pages=owner.streetPages ??= []
  for(let i=0;i<heights.length;i++) {
    const atlas=pages[i] ??= document.createElement('canvas')
    const capacity=Math.ceil(heights[i]/128)*128
    if(atlas.width!==width)atlas.width=width
    if(atlas.height<capacity || atlas.height>capacity+256)atlas.height=capacity
    const g=atlas.getContext('2d')
    g.setTransform(1,0,0,1,0,0);g.clearRect(0,0,width,atlas.height)
  }
  while(pages.length>heights.length){const old=pages.pop();old.width=0;old.height=0}
  for(const strip of strips)strip.g=pages[strip.page].getContext('2d')
}
export const layers = {
  release:releaseStreetPages,
  recording: () => !!record,
  begin(ctx, world, w, h, sec, reduced, hour) {
    record = null
    const owner=globalThis.__moontownGoldenValleyCanvasLifecycle, cam=globalThis.__moontownGoldenValleyCamera
    if (!owner) return
    owner.trafficCache = null
    if((owner.streetPages||owner.trafficScratch) && !owner.streetPageExpiry)
      owner.streetPageExpiry=setTimeout(()=>releaseStreetPages(owner),900)
    if (reduced || !globalThis.__townDisplay?.compact || !globalThis.__townLandmarkPainter?.ready ||
        cam.z<.17 || cam.z>1.65 || cam.streetTransition || owner.zoomPreview || owner.cameraDragging ||
        (globalThis.__townPublicBaseline && globalThis.__townPublicBaseline.world!==world)) return
    const f={w,h,z:cam.z,cx:cam.x,cy:cam.y}, m=ctx.getTransform(), ratio=m.a
    if (m.b || m.c || m.e || m.f || ratio!==m.d) return
    prepare(f,sec,reduced,hour)
    if (!visibleCount || rows.has(0)) return
    const depths=new Set([-1])
    for (const [d,items] of rows) for (const car of items) {
      if (car.k==='lamp') continue
      depths.add(d)
      if (car.adjacent>0 && car.adjacent<431) depths.add(car.adjacent)
    }
    const cuts=[...depths].sort((a,b)=>a-b), strips=[]
    let pixels=0
    for (let i=0;i<cuts.length;i++) {
      const first=Math.max(0,cuts[i]),last=(cuts[i+1]??433)-1
      // Ordinary installations are anchored to isometric depth rows. Include
      // the full registered envelope of district volumes and baked landmarks.
      const bounds={top:h/2+(first*16-f.cy-800)*f.z-16,
        bottom:h/2+(last*16-f.cy+320)*f.z+16}
      if (!i || i===cuts.length-1) {bounds.top=0;bounds.bottom=h}
      else globalThis.__townLandmarkPainter.expandTrafficBand?.(bounds,first,last,f)
      const top=Math.min(ctx.canvas.height,Math.max(0,Math.floor(bounds.top*ratio)))
      const bottom=Math.max(top,Math.min(ctx.canvas.height,Math.ceil(bounds.bottom*ratio)))
      pixels+=(bottom-top)*ctx.canvas.width
      strips.push({depth:cuts[i],first,top,bottom})
    }
    let patches=null
    if(pixels>10000000){
      patches=makeTrafficPatches(ctx,rows,f,ratio,strips)
      if(!patches)return
      clearTimeout(owner.streetPageExpiry);owner.streetPageExpiry=0
      if(owner.streetPages){for(const page of owner.streetPages)page.width=0;owner.streetPages=null}
    }
    const ground=owner.trafficGround ??= document.createElement('canvas')
    if(ground.width!==ctx.canvas.width)ground.width=ctx.canvas.width
    if(ground.height!==ctx.canvas.height)ground.height=ctx.canvas.height
    if(!patches){
      ground.getContext('2d').drawImage(ctx.canvas,0,0)
      packStreetPages(owner,strips,ctx.canvas.width)
    }
    record={patches,ground,world,target:ctx,f,ratio,strips,depths,hour,index:0,active:null}
  },
  depth(ctx,depth) {
    if (record?.target!==ctx) return ctx
    if(record.patches)return record.patches.depth(depth)
    while (record.index+1<record.strips.length && record.strips[record.index+1].first<=depth) record.index++
    const strip=record.strips[record.index]
    if(record.active!==strip) {
      record.active?.g.restore()
      const g=strip.g
      g.save();g.setTransform(1,0,0,1,0,0)
      g.beginPath();g.rect(0,strip.offset,ctx.canvas.width,strip.bottom-strip.top);g.clip()
      g.setTransform(record.ratio,0,0,record.ratio,0,strip.offset-strip.top)
      record.active=strip
    }
    return strip.g
  },
  finish(ctx) {
    if (record?.target!==ctx) return
    const state=record
    state.active?.g.restore()
    record=null
    if(state.patches){
      state.patches.finish()
      state.ground.getContext('2d').drawImage(ctx.canvas,0,0)
      state.patches.present(rows,(d,cars)=>draw(ctx,d,state.f,true,cars))
    }else composite(state)
    state.at=performance.now()
    globalThis.__moontownGoldenValleyCanvasLifecycle.trafficCache=state
  },
  replay(ctx,world,w,h,hour) {
    record=null
    const owner=globalThis.__moontownGoldenValleyCanvasLifecycle,state=owner?.trafficCache,cam=globalThis.__moontownGoldenValleyCamera
    if (!state || globalThis.__townLandmarkPainter?.wheelArtBlocked?.() || owner.paintReason!=='animation' || owner.cameraDragging || cam.streetTransition ||
        state.target!==ctx || state.world!==world || state.f.w!==w || state.f.h!==h ||
        cam.x!==state.f.cx || cam.y!==state.f.cy || cam.z!==state.f.z || hour!==state.hour ||
        performance.now()-state.at>500 || document.hidden) return false
    prepare(state.f,performance.now()/1000,false,hour)
    for (const [depth,items] of rows) if (!state.depths.has(depth) && items.some(item=>item.k!=='lamp')) return false
    ctx.drawImage(state.ground,0,0,w,h)
    if(state.patches){
      if(!state.patches.present(rows,(d,cars)=>draw(ctx,d,state.f,true,cars)))return false
    }else composite(state)
    owner.vehicleOnlyFrames=(owner.vehicleOnlyFrames||0)+1
    return true
  },
}

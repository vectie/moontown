// The geographic surroundings are painted below the calibrated 256 × 144 core.
// Use its local east/south tangent for the outside, where extrapolating the core
// homography would introduce a pole. Never draw a regional road over a town road.
import { geo, register, bounds } from './region-geometry.js'
import { decodeStudyRing, facadePlan } from './district-facades.js'
import { drawVolume, hasProject, hasUnit } from './district-ground.js'
const iso = ([x, y]) => [(x - y) * 32, (x + y) * 16]
const colours = {
  farmland: '#bfce88',
  grass: '#acd574',
  meadow: '#aad47c',
  forest: '#8bb967',
  park: '#9aca73',
  orchard: '#9fc77a',
  residential: '#cfdbad',
  industrial: '#cbd4b3',
  commercial: '#d8d7b2',
  retail: '#ddd6b4',
  roof: '#bbbfab',
  water: '#72c2cc',
}
const widths = {
  river: 19,
  canal: 7,
  stream: 3,
  lane: 2.5,
  street: 5,
  artery: 8,
}
const order = [
  'farmland',
  'grass',
  'meadow',
  'park',
  'orchard',
  'forest',
  'residential',
  'industrial',
  'commercial',
  'retail',
  'roof',
  'stream',
  'canal',
  'river',
  'water',
  'lane',
  'street',
  'artery',
  'lane-bridge',
  'street-bridge',
  'artery-bridge',
]
let motorRoads = []
export const visibleMotorRoads = () => motorRoads
let grid,
  geometry,
  loading,
  catalog,
  catalogRequest,
  toTown,
  retryAfter = 0
const buildings = [],
  sites = new Map()
async function get(name) {
  const r = await fetch(new URL(name, import.meta.url))
  if (!r.ok) throw Error(name + ' ' + r.status)
  return name.endsWith('.bin')
    ? new Response(r.body.pipeThrough(new DecompressionStream('gzip'))).json()
    : r.json()
}
export function registerTown(vision) {
  const [east, south] = geo([116.47495692, 40.12507434])
  toTown = ([e, s]) =>
    iso([
      vision.x + (e - east) * vision.east[0] + (s - south) * vision.south[0],
      vision.y + (e - east) * vision.east[1] + (s - south) * vision.south[1],
    ])
}
export function directory() {
  return (catalogRequest ??= Promise.all([
    get('district-studies.json'),
    get('region-anchors.json'),
  ])
    .then(([db, anchors]) => {
      catalog = db.catalog.projects
      for (const block of db.blocks) {
        if (block.key === 'vision') continue
        const to = register(block, anchors)
        for (const [kind, height, encoded, id] of block.units) {
          if (hasUnit(id)) continue
          const metric = decodeStudyRing(encoded).map(to),
            ring = metric.map(toTown)
          if (
            hasProject(block.key) &&
            ring.some(([a, b]) => {
              const x = (a / 32 + b / 16) / 2,
                y = (b / 16 - a / 32) / 2
              return x >= 0 && x <= 256 && y >= 0 && y <= 144
            })
          )
            continue
          const court = block.courts?.[id]
            ? decodeStudyRing(block.courts[id]).map(to).map(toTown)
            : []
          const b = bounds(ring),
            item = {
              id,
              key: block.key,
              kind,
              h: height,
              ring,
              court,
              b,
              textures: [],
              metric,
            }
          buildings.push(item)
          if (!sites.has(block.key)) sites.set(block.key, [])
          sites.get(block.key).push(item)
        }
      }
      buildings.sort((a, b) => a.b.y - b.b.y)
      return catalog
    })
    .catch((e) => {
      catalogRequest = null
      throw e
    }))
}
export function locate(key, canvas, camera) {
  const project = catalog?.find((p) => p.id === key)
  const members = sites.get(project?.host || key)
  if (!members?.length) return false
  const { left, right, top, bottom, x, y } = bounds(
    members.flatMap((v) => [
      [v.b.left, v.b.top - v.h * 0.68],
      [v.b.right, v.b.bottom],
    ]),
  )
  delete camera.streetTransition
  Object.assign(camera, {
    x,
    y,
    z: Math.max(
      0.035,
      Math.min(
        2,
        (canvas.clientWidth - 40) / (right - left + 70),
        (canvas.clientHeight - 110) /
          (bottom - top + (right - left) * 0.4 + 70),
      ),
    ),
    streetFollow: false,
  })
  return true
}
const bucket = 640
async function prepare(rows) {
  const index = new Map(),
    features = []
  let slice=performance.now()
  for (const row of rows) {
    if(performance.now()-slice>5){
      await new Promise(resolve=>setTimeout(resolve,0))
      slice=performance.now()
    }
    const rank = order.indexOf(row.k)
    if (rank < 0 || !row.p.length) continue
    const points = row.p.map(toTown),
      b = bounds(points),
      path = new Path2D()
    for (let i = 0; i < points.length; i++)
      i ? path.lineTo(...points[i]) : path.moveTo(...points[i])
    if (row.k in colours) path.closePath()
    const id = features.length
    const motor = [
      'street',
      'artery',
      'street-bridge',
      'artery-bridge',
    ].includes(row.k)
    features.push({
      k: row.k,
      rank,
      b,
      path,
      points: motor ? points : null,
      id,
      dir: row.dir || 0,
    })
    for (
      let x = Math.floor(b.left / bucket);
      x <= Math.floor(b.right / bucket);
      x++
    )
      for (
        let y = Math.floor(b.top / bucket);
        y <= Math.floor(b.bottom / bucket);
        y++
      ) {
        const k = x + ',' + y
        if (!index.has(k)) index.set(k, [])
        index.get(k).push(id)
      }
  }
  grid = index
  geometry = features
}
function requestGround() {
  if (loading || !toTown || performance.now() < retryAfter) return
  loading = Promise.all([get('region-context.bin').then(prepare), directory()])
    .then(() => {
      document.documentElement.dataset.regionGround = 'ready'
      globalThis.__moontownGoldenValleyRender?.('region-ground')
    })
    .catch(() => {
      loading = null
      retryAfter = performance.now() + 10000
      document.documentElement.dataset.regionGround = 'unavailable'
    })
}
export function warmGround(cx,cy,z,w,h) {
  if(loading || !z)return
  for(const dx of [-w/2,w/2])for(const dy of [-h/2,h/2]){
    const x=(cx+dx/z)/32,y=(cy+dy/z)/16
    if((x+y)/2<0 || (x+y)/2>256 || (y-x)/2<0 || (y-x)/2>144){
      requestGround();return
    }
  }
}
export function ground(c, f) {
  const { cx, cy, z, w, h } = f
  const groundAt = (x, y) => [(x / 32 + y / 16) / 2, (y / 16 - x / 32) / 2]
  const left = cx - w / (2 * z),
    top = cy - h / (2 * z),
    right = cx + w / (2 * z),
    bottom = cy + h / (2 * z)
  const corners = [
    [left, top],
    [right, top],
    [left, bottom],
    [right, bottom],
  ]
  motorRoads = []
  if (
    corners.every((p) => {
      const [x, y] = groundAt(...p)
      return x >= 0 && y >= 0 && x <= 256 && y <= 144
    })
  )
    return
  requestGround()
  c.save()
  c.translate(w / 2 - cx * z, h / 2 - cy * z)
  c.scale(z, z)
  c.beginPath()
  c.rect(left - 1, top - 1, right - left + 2, bottom - top + 2)
  for (const [i, p] of [
    [0, 0],
    [256, 0],
    [256, 144],
    [0, 144],
  ].entries()) {
    const q = iso(p)
    i ? c.lineTo(...q) : c.moveTo(...q)
  }
  c.closePath()
  c.clip('evenodd')
  c.fillStyle = '#aed180'
  c.fillRect(left - 1, top - 1, right - left + 2, bottom - top + 2)
  if (grid) {
    const ids = new Set()
    for (
      let x = Math.floor(left / bucket);
      x <= Math.floor(right / bucket);
      x++
    )
      for (
        let y = Math.floor(top / bucket);
        y <= Math.floor(bottom / bucket);
        y++
      )
        for (const id of grid.get(x + ',' + y) || []) ids.add(id)
    const visible = [...ids]
      .map((i) => geometry[i])
      .filter(
        (o) =>
          o.b.right >= left &&
          o.b.left <= right &&
          o.b.top <= bottom &&
          o.b.bottom >= top,
      )
      .sort((a, b) => a.rank - b.rank)
    if (z > 0.22) motorRoads = visible.filter((v) => v.points)
    c.lineJoin = c.lineCap = 'round'
    for (const { k, b, path } of visible) {
      if (k in colours) {
        if ((b.right - b.left) * (b.bottom - b.top) * z * z < 2) continue
        c.fillStyle = colours[k]
        c.fill(path)
      } else {
        const kind = k.replace('-bridge', '')
        if (kind === 'lane' && z < 0.075) continue
        c.strokeStyle = ['river', 'stream', 'canal'].includes(kind)
          ? '#72c2cc'
          : '#efdfbb'
        c.lineWidth = Math.max(0.65 / z, widths[kind])
        c.stroke(path)
      }
    }
  }
  c.restore()
}
export function drawBuildings(c, { cx, cy, z, w, h }) {
  const screen = ([x, y]) => [(x - cx) * z + w / 2, (y - cy) * z + h / 2]
  for (const u of buildings) {
    const { left, right, top, bottom } = u.b
    if (
      (right - cx) * z < -w / 2 - 4 ||
      (left - cx) * z > w / 2 + 4 ||
      (bottom - cy) * z < -h / 2 - 4 ||
      (top - cy - u.h * 0.68) * z > h / 2 + 4
    )
      continue
    u.plan ??= facadePlan(u.key, u.kind, u.h, u.metric, u.id)
    drawVolume(
      c,
      u,
      u.ring.map(screen),
      u.h * 0.68 * z,
      { w, h, z },
      u.court.map(screen),
    )
  }
}

export function hit(sx, sy, f) {
  const x = (sx - f.w / 2) / f.z + f.cx,
    y = (sy - f.h / 2) / f.z + f.cy
  for (let i = buildings.length - 1; i >= 0; i--) {
    const u = buildings[i],
      h = u.h * 0.68
    if (x < u.b.left || x > u.b.right || y < u.b.top - h || y > u.b.bottom)
      continue
    const inside = (dy) => {
      let yes = false
      for (let j = 0, k = u.ring.length - 1; j < u.ring.length; k = j++) {
        const a = u.ring[j],
          b = u.ring[k]
        if (
          a[1] > dy !== b[1] > dy &&
          x < ((b[0] - a[0]) * (dy - a[1])) / (b[1] - a[1]) + a[0]
        )
          yes = !yes
      }
      return yes
    }
    if (inside(y) || inside(y + h)) return u.key
  }
  return null
}

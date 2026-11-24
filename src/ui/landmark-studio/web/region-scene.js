import { decodeStudyRing, facadePlan, buildingBands } from './district-facades.js'
import { drawVolume } from './district-ground.js'
import { lane, sample } from './street-motion.js'
import { bounds, camera, centre, geo, project, register } from './region-geometry.js'

const background = {
  residential: '#d9dfc8',
  industrial: '#d3dcd1',
  commercial: '#e6dcc5',
  retail: '#e4d8be',
  farmland: '#d4df96',
  grass: '#bfda99',
  meadow: '#bdd990',
  forest: '#92bf88',
  park: '#a5cf93',
  orchard: '#acc58a',
  roof: '#c5c9bc',
  water: '#65b9cc',
}
const roads = { lane: [4.7, '#ede1c9'], street: [9.5, '#e7ddc2'], artery: [13, '#e2d4b7'] }
const streams = { river: 28, canal: 12, stream: 4 }
const order = [
  'residential',
  'industrial',
  'commercial',
  'retail',
  'farmland',
  'grass',
  'meadow',
  'orchard',
  'park',
  'forest',
  'roof',
  'river',
  'canal',
  'stream',
  'water',
  'lane',
  'street',
  'artery',
  'lane-bridge',
  'street-bridge',
  'artery-bridge',
]
const isVisible = (a, b) =>
  a.right >= b.left && a.left <= b.right && a.bottom >= b.top && a.top <= b.bottom
function path(points, closed) {
  const p = new Path2D()
  points.forEach(([x, y], i) => (i ? p.lineTo(x, y) : p.moveTo(x, y)))
  if (closed) p.closePath()
  return p
}
function contains([x, y], r) {
  let flag = false
  for (let i = 0, j = r.length - 1; i < r.length; j = i++) {
    const a = r[i],
      b = r[j]
    if (a[1] > y !== b[1] > y && x < ((b[0] - a[0]) * (y - a[1])) / (b[1] - a[1]) + a[0])
      flag = !flag
  }
  return flag
}
function tint(color, n) {
  const k = parseInt(color.slice(1), 16)
  return (
    'rgb(' +
    [k >> 16, (k >> 8) & 255, k & 255].map((v) => Math.max(0, Math.min(255, v + n))).join(',') +
    ')'
  )
}
const ink = (ctx, p, color, width) => {
  ctx.strokeStyle = color
  ctx.lineWidth = width
  ctx.stroke(p)
}
const fill = (ctx, p, color) => {
  ctx.fillStyle = color
  ctx.fill(p)
}
const flora = []
function loadFlora(refresh) {
  for (const name of ['tree_large', 'tree_small', 'bush', 'flower_patch']) {
    const image = new Image()
    image.onload = refresh
    image.src = new URL('../tilemap/objects/' + name + '.png', import.meta.url)
    flora.push(image)
  }
}
function canopy(c, x, y, r, variant = 0) {
  const sprite = flora[variant % flora.length]
  if (sprite?.naturalWidth && r >= 2.2) {
    const h = r * (variant % 4 < 2 ? 3.45 : 1.9),
      w = (h * sprite.naturalWidth) / sprite.naturalHeight
    c.drawImage(sprite, x - w * 0.48, y - h * 0.88, w, h)
    return
  }
  c.beginPath()
  c.ellipse(x + r * 0.39, y + r * 0.47, r * 1.05, r * 0.64, -0.16, 0, Math.PI * 2)
  c.fillStyle = '#546e4942'
  c.fill()
  for (const [dx, dy, f, col] of [
    [0, 0, 1, '#679666'],
    [-0.3, -0.2, 0.72, '#88ad70'],
    [0.18, -0.34, 0.59, '#a3c67c'],
  ]) {
    c.beginPath()
    c.ellipse(x + dx * r, y + dy * r, r * f, r * f * 0.83, -0.2, 0, Math.PI * 2)
    c.fillStyle = col
    c.fill()
  }
}
let meadowTexture, waterTexture
function brushTexture(context, water = false) {
  const surface = document.createElement('canvas')
  surface.width = surface.height = 160
  const c = surface.getContext('2d')
  let seed = water ? 31 : 57
  const random = () => (seed = (Math.imul(1664525, seed) + 1013904223) >>> 0) / 4294967296
  c.lineCap = 'round'
  for (let i = 0; i < (water ? 40 : 360); i++) {
    const x = random() * 160,
      y = random() * 160
    if (water) {
      c.strokeStyle = i % 3 ? '#e2f8ef81' : '#379bb343'
      c.lineWidth = 0.55 + random() * 0.8
      c.beginPath()
      c.moveTo(x, y)
      c.quadraticCurveTo(x + 3, y - 1, x + 5 + random() * 7, y)
      c.stroke()
    } else {
      c.fillStyle = i % 5 === 0 ? '#6189533c' : i % 5 === 1 ? '#e6ed9a70' : '#ffffff27'
      c.fillRect(x, y, 0.55 + random() * 1.6, 0.6 + random() * 0.8)
    }
  }
  return context.createPattern(surface, 'repeat')
}
function compileContext(rows) {
  const layers = new Map(order.map((k) => [k, []]))
  rows.forEach(({ k, p, dir }, i) => {
    const points = p.map(project),
      b = bounds(points),
      area = (b.right - b.left) * (b.bottom - b.top)
    if (!layers.has(k)) return
    const trees = []
    if (['park', 'forest', 'orchard'].includes(k) && area > 400) {
      // Seed inside each actual green outline, so zoom and camera movement never reshuffle trees.
      let seed = i + 31
      const random = () => (seed = (Math.imul(1664525, seed) + 1013904223) >>> 0) / 4294967296
      for (let j = 0; j < Math.min(70, Math.ceil(area / 270)); j++) {
        const point = [
          b.left + random() * (b.right - b.left),
          b.top + random() * (b.bottom - b.top),
        ]
        if (contains(point, points)) trees.push([...point, 2.1 + random() * 3])
      }
    }
    const road = roads[k.replace('-bridge', '')],
      route = road && points.length > 1 ? lane(p) : null
    layers
      .get(k)
      .push({
        b,
        area,
        route,
        dir,
        seed: i,
        path: path(points, k in background),
        trees,
        color: k in background ? tint(background[k], ((i % 5) - 2) * 2) : null,
      })
  })
  return layers
}
async function data(name) {
  const response = await fetch(new URL(name, import.meta.url))
  if (!response.ok) throw Error(name + ' ' + response.status)
  return name.endsWith('.bin')
    ? new Response(response.body.pipeThrough(new DecompressionStream('gzip'))).json()
    : response.json()
}
export async function loadScene(refresh) {
  const [db, anchors, context, tiles, info] = await Promise.all(
    [
      'district-studies.json',
      'region-anchors.json',
      'region-context.bin',
      'region-projections.json',
      'region-building-info.json',
    ].map(data),
  )
  loadFlora(refresh)
  const sites = new Map(db.catalog.projects.map((p) => [p.id, { ...p, blocks: [], items: [] }]))
  for (const [id, name] of [
    ['center', '未来中心'],
    ['east-bridge', '未来科学城东路桥'],
    ['arch-bridge', '未来科学城路桥'],
  ])
    sites.set(id, { id, name, type: '地标', blocks: [], items: [] })
  const items = [],
    volumes = [],
    plots = [],
    gardens = []
  for (const block of db.blocks) {
    const to = register(block, anchors),
      site = sites.get(block.key),
      ground = decodeStudyRing(block.ring).map(to).map(project)
    const plot = { site, ground, b: bounds(ground), path: path(ground, true) }
    plots.push(plot)
    site.blocks.push(plot)
    for (const [kind, h, encoded, id] of block.units) {
      const metric = decodeStudyRing(encoded).map(to),
        ring = metric.map(project)
      const court = block.courts?.[id] ? decodeStudyRing(block.courts[id]).map(to).map(project) : []
      const b = bounds(ring),
        centreDepth = b.y
      const item = {
        id,
        key: site.id,
        block: block.block,
        site,
        kind,
        h,
        ring,
        court,
        textures: [],
        plan: facadePlan(site.id, kind, h, metric, id),
        b: { ...b, top: b.top - h * camera.up },
        depth: centreDepth,
      }
      items.push(item)
      site.items.push(item)
      const bands = buildingBands(id, metric, h)
      if (bands.length === 1) volumes.push(item)
      else
        for (const band of bands) {
          const part = band.shape(metric),
            outline = part.map(project),
            bb = bounds(outline)
          volumes.push({
            ...item,
            ring: outline,
            h: band.height,
            depth: bb.y,
            plan: facadePlan(site.id, kind, band.height, part, id),
            textures: [],
          })
        }
    }
    // The orbit model also landscapes the inside edge of the reviewed enclosure.
    const metric = decodeStudyRing(block.ring).map(to),
      mid = centre(metric),
      within = site.items.map((i) => i.ring)
    const inner = metric.map(([x, y]) => [
      mid[0] + (x - mid[0]) * 0.89,
      mid[1] + (y - mid[1]) * 0.89,
    ])
    for (let j = 0; j < inner.length; j++) {
      const a = inner[j],
        b = inner[(j + 1) % inner.length],
        count = Math.floor(Math.hypot(b[0] - a[0], b[1] - a[1]) / 12)
      for (let k = 0; k < count; k++) {
        const f = (k + 0.5) / count,
          pt = [a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f],
          q = project(pt)
        if (!contains(pt, metric) || within.some((r) => contains(q, r))) continue
        gardens.push({
          tree: q,
          variant: [0, 1, 0, 2, 1, 0, 3][(k + j) % 7],
          r: 2.5 + ((j + k) % 3) * 0.44,
          depth: q[1],
          b: { left: q[0] - 5, right: q[0] + 5, top: q[1] - 7, bottom: q[1] + 4 },
        })
      }
    }
  }
  for (const tile of tiles.tiles) {
    const site = sites.get(tile.id.startsWith('center-') ? 'center' : tile.id),
      [x, y] = project(geo(anchors.landmarks[tile.id]))
    const b = {
      left: x + tile.left,
      top: y - tile.top,
      right: x + tile.left + tile.width,
      bottom: y - tile.top + tile.height,
      x,
      y,
    }
    const item = { site, id: tile.id, tile, b, depth: y }
    items.push(item)
    volumes.push(item)
    site.items.push(item)
  }
  for (const s of sites.values()) {
    const owned = s.host ? (s.hosts || [s.host]).flatMap((k) => sites.get(k).items) : s.items
    if (!owned.length) throw Error('Empty regional project ' + s.id)
    const points = owned.flatMap((i) => [
      [i.b.left, i.b.top],
      [i.b.right, i.b.bottom],
    ])
    s.b = bounds(points)
    s.position = centre(points)
    s.method = anchors.registration[s.id]?.method
  }
  const boundsAll = bounds(
    [...sites.values()].flatMap((s) => [
      [s.b.left, s.b.top],
      [s.b.right, s.b.bottom],
    ]),
  )
  return {
    sites,
    info,
    sources: db.catalog.sources,
    items: items.sort((a, b) => a.depth - b.depth),
    objects: [...volumes, ...gardens].sort((a, b) => a.depth - b.depth),
    plots,
    layers: compileContext(context),
    boundsAll,
    refresh,
  }
}
function paintTile(ctx, tile, x, y, z, refresh) {
  if (!tile.image) {
    tile.image = new Image()
    tile.image.onload = refresh
    tile.image.src = new URL(tile.source, import.meta.url)
  }
  if (tile.image.naturalWidth)
    ctx.drawImage(tile.image, x + tile.left * z, y - tile.top * z, tile.width * z, tile.height * z)
}

export function paintScene(base, ctx, scene, f) {
  const { z, w, h, x, y, ratio } = f
  const world = {
    left: x - w / (2 * z),
    right: x + w / (2 * z),
    top: y - h / (2 * z),
    bottom: y + h / (2 * z),
  }
  const screen = ([a, b]) => [(a - x) * z + w / 2, (b - y) * z + h / 2]
  base.setTransform(ratio, 0, 0, ratio, 0, 0)
  base.fillStyle = '#d9e4bc'
  base.fillRect(0, 0, w, h)
  base.save()
  base.translate(w / 2, h / 2)
  base.scale(z, z)
  base.translate(-x, -y)
  base.lineJoin = 'round'
  base.lineCap = 'round'
  if (z > 0.31) {
    meadowTexture ??= brushTexture(base)
    waterTexture ??= brushTexture(base, true)
    base.fillStyle = meadowTexture
    base.fillRect(world.left, world.top, w / z, h / z)
  }
  const moving = []
  for (const [kind, features] of scene.layers) {
    if (kind === 'lane') {
      const active = scene.sites.get(f.selected),
        hosts = active?.hosts || [active?.host || active?.id]
      for (const p of scene.plots) {
        if (!isVisible(world, p.b)) continue
        fill(base, p.path, hosts.includes(p.site.id) ? '#cbdba8' : '#cadcaa')
        if (z > 0.31) fill(base, p.path, meadowTexture)
        if (z > 0.11) ink(base, p.path, '#a3b797', Math.max(0.45 / z, 0.7))
      }
    }
    if ((kind === 'roof' && z < 0.16) || (kind.startsWith('lane') && z < 0.085)) continue
    const bridge = kind.endsWith('-bridge'),
      road = roads[kind.replace('-bridge', '')]
    const visible = features.filter(
      (n) => isVisible(world, n.b) && (!n.color || n.area * z * z > 1.5),
    )
    if (road) {
      const width = Math.max(road[0], 0.65 / z)
      for (const n of visible)
        ink(base, n.path, bridge ? '#868879' : '#b3af97', width + Math.max(0.6 / z, 1.3))
      for (const n of visible) ink(base, n.path, road[1], width)
      if (z > 0.35) {
        if (!kind.startsWith('lane')) {
          base.setLineDash([4.5, 6])
          for (const n of visible) ink(base, n.path, '#fff5da', 0.6)
          base.setLineDash([])
        }
        for (const n of visible) if (n.route?.length > 30) moving.push(n)
      }
    } else
      for (const n of visible) {
        if (kind in streams) {
          const wide = streams[kind]
          ink(base, n.path, '#d9deae', wide + 6)
          ink(base, n.path, '#9fd4d4', wide)
          ink(base, n.path, '#70bbce', wide * 0.65)
        } else if (kind === 'water') {
          ink(base, n.path, '#f2e7c5', 4.5)
          fill(base, n.path, n.color)
          base.save()
          base.clip(n.path)
          ink(base, n.path, '#92cfd4', 15)
          ink(base, n.path, '#b3dfd5', 6)
          if (z > 0.31) fill(base, n.path, waterTexture)
          base.restore()
        } else {
          fill(base, n.path, n.color)
          if (kind === 'roof' && z > 0.65) ink(base, n.path, '#a7b1a0', 0.7)
          if (z > 0.31 && n.trees.length) fill(base, n.path, meadowTexture)
          if (z > 0.21)
            for (const [tx, ty, r] of n.trees)
              canopy(base, tx, ty, r, Math.abs(Math.round(tx + ty)) % 3)
        }
      }
  }
  for (const item of scene.items) {
    if (item.tile?.front && isVisible(world, item.b))
      paintTile(base, item.tile, item.b.x, item.b.y, 1, scene.refresh)
  }
  base.restore()
  ctx.setTransform(ratio, 0, 0, ratio, 0, 0)
  ctx.clearRect(0, 0, w, h)
  for (const item of scene.objects) {
    if (!isVisible(world, item.b)) continue
    if (item.tree) {
      if (z > 0.24) {
        const [tx, ty] = screen(item.tree)
        canopy(ctx, tx, ty, item.r * z, item.variant)
      }
      continue
    }
    if (item.tile) {
      const [a, b] = screen([item.b.x, item.b.y])
      paintTile(ctx, item.tile.front || item.tile, a, b, z, scene.refresh)
    } else
      drawVolume(
        ctx,
        item,
        item.ring.map(screen),
        item.h * camera.up * z,
        { w, h, z },
        item.court.map(screen),
      )
  }
  const chosen = f.unit && scene.items.find((o) => o.id === f.unit)
  if (chosen && chosen.ring) {
    const outline = chosen.ring.map(([a, b]) => screen([a, b - chosen.h * camera.up]))
    ctx.strokeStyle = '#326c53'
    ctx.lineWidth = 2
    ctx.stroke(path(outline, true))
  }
  const hits = [],
    selectedId = f.selected
  const priority = [
    'center',
    'robotics',
    'innovation-homes',
    'beisi',
    'cp1703',
    'xingke',
    'tugou',
    'huanyu',
    'vision',
    'cloud',
  ]
  const candidates = [...scene.sites.values()]
    .filter((s) => !s.host || s.id === selectedId)
    .sort((a, b) => {
      const index = (s) =>
        s.id === selectedId ? -2 : priority.includes(s.id) ? priority.indexOf(s.id) : 50
      return index(a) - index(b)
    })
  ctx.font = '600 12px system-ui'
  ctx.textBaseline = 'middle'
  for (const site of candidates) {
    const [a, b] = screen(site.position),
      sel = site.id === selectedId
    if (a < 2 || a > w - 2 || b < 3 || b > h - 3) continue
    const title = site.name,
      tw = ctx.measureText(title).width + 16,
      ty = sel && z > 0.22 ? screen([0, site.b.bottom])[1] + 10 : b + 6
    const left = Math.max(5, Math.min(w - tw - 5, a - tw / 2)),
      top = ty
    const box = { left, top, right: left + tw, bottom: top + 22, x: a, y: b }
    if (
      !sel &&
      hits.some((hit) =>
        isVisible(
          { left: left - 9, right: box.right + 9, top: top - 7, bottom: box.bottom + 7 },
          hit,
        ),
      )
    )
      continue
    if (!sel && selectedId && z > 0.27) continue
    ctx.fillStyle = sel ? '#305846' : '#fffcf0'
    ctx.strokeStyle = sel ? '#305846' : '#a7b99d'
    ctx.lineWidth = 1
    ctx.beginPath()
    ctx.roundRect(left, top, tw, 22, 9)
    ctx.fill()
    ctx.stroke()
    ctx.fillStyle = sel ? '#fffdeb' : '#355644'
    ctx.fillText(title, left + 8, top + 11)
    if (z < 0.19) {
      ctx.beginPath()
      ctx.arc(a, b, 3.2, 0, Math.PI * 2)
      ctx.fillStyle = '#426b51'
      ctx.fill()
    }
    hits.push({ ...box, id: site.id })
  }
  return { hits, moving }
}
export function hitProject(scene, point) {
  for (let i = scene.items.length - 1; i >= 0; i--) {
    const item = scene.items[i]
    if (!isVisible(item.b, { left: point[0], right: point[0], top: point[1], bottom: point[1] }))
      continue
    if (
      item.tile ||
      contains(point, item.ring) ||
      contains([point[0], point[1] + item.h * camera.up], item.ring)
    )
      return { id: item.site.id, unit: item.id }
    const r = item.ring,
      up = item.h * camera.up
    if (
      r.some((p, j) => {
        const q = r[(j + 1) % r.length]
        return contains(point, [p, q, [q[0], q[1] - up], [p[0], p[1] - up]])
      })
    )
      return { id: item.site.id, unit: item.id }
  }
  const plot = scene.plots.find((p) => contains(point, p.ground))
  return plot ? { id: plot.site.id } : null
}

const carColors = ['#d97f59', '#397b84', '#fff4da', '#7c96a9', '#c6b683', '#e9e6d8']
export function paintTraffic(ctx, roads, f, seconds) {
  const { z, w, h, x, y, ratio } = f
  ctx.setTransform(ratio, 0, 0, ratio, 0, 0)
  ctx.clearRect(0, 0, w, h)
  if (z <= 0.35) return
  for (const n of roads) {
    const route = n.route,
      number = Math.min(24, Math.max(1, Math.floor(route.length / 95)))
    for (let j = 0; j < number; j++) {
      const dir = n.dir || (j % 2 ? -1 : 1),
        dist =
          (((j + (n.seed % 19) / 19) * route.length) / number + seconds * (5 + (n.seed % 4))) %
          route.length
      const v = sample(route, dir > 0 ? dist : route.length - dist, n.dir ? 0 : dir * 1.8),
        pos = project([v.x, v.z]),
        a = (pos[0] - x) * z + w / 2,
        b = (pos[1] - y) * z + h / 2
      if (a < -6 || a > w + 6 || b < -6 || b > h + 6) continue
      const axis = project([v.dx * dir, v.dz * dir])
      ctx.save()
      ctx.translate(a, b)
      ctx.rotate(Math.atan2(axis[1], axis[0]))
      ctx.scale(z, z)
      ctx.fillStyle = '#48644b50'
      ctx.fillRect(-2.1, -0.35, 4.8, 1.9)
      ctx.fillStyle = carColors[(n.seed + j) % carColors.length]
      ctx.fillRect(-2.3, -1.3, 4.6, 1.9)
      ctx.fillStyle = '#577979'
      ctx.fillRect(-1, -1.1, 2.2, 1.45)
      ctx.restore()
    }
  }
}

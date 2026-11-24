import { viewerIcon } from './viewer-ui.js'
import { loadScene, paintScene, hitProject, paintTraffic } from './region-scene.js'

let dialog,
  canvas,
  ctx,
  select,
  study,
  street,
  status,
  scale,
  scene,
  pending,
  frame,
  hits = [],
  hooks,
  resize
let base,
  trafficCanvas,
  groundCtx,
  trafficCtx,
  moving = [],
  motionTimer = 0,
  paused = matchMedia('(prefers-reduced-motion: reduce)').matches
let selection = '',
  unit = '',
  inspect,
  unitList,
  unitInfo,
  unitSources,
  unitTitle,
  fitted = true,
  originFocus
const camera = { x: 0, y: 0, z: 0.05, w: 1, h: 1, ratio: 1 }
const clamp = (n, a, b) => Math.max(a, Math.min(b, n))
function paint() {
  frame = 0
  if (!dialog?.open || !scene) return
  const result = paintScene(groundCtx, ctx, scene, { ...camera, selected: selection, unit })
  hits = result.hits
  moving = result.moving
  animateTraffic()
  const dist = 70 / camera.z,
    decade = 10 ** Math.floor(Math.log10(dist))
  const m = ([5, 2, 1].find((n) => n * decade <= dist) || 1) * decade
  scale.style.width = m * camera.z + 'px'
  scale.textContent = m >= 1000 ? m / 1000 + ' km' : m + ' m'
  canvas.dataset.zoom = camera.z.toFixed(3)
}
function animateTraffic() {
  clearTimeout(motionTimer)
  if (!dialog?.open || document.hidden) return
  if (document.querySelector('.town-studio-dialog[open]')) {
    motionTimer = setTimeout(animateTraffic, 450)
    return
  }
  paintTraffic(trafficCtx, moving, camera, paused ? 0 : performance.now() / 1000)
  if (!paused && moving.length) motionTimer = setTimeout(animateTraffic, 80)
}
function repaint() {
  if (!frame && dialog?.open) frame = requestAnimationFrame(paint)
}
function frameSite() {
  if (!scene || !canvas.clientWidth) return
  const b = scene.sites.get(selection)?.b || scene.boundsAll,
    { w, h } = camera
  const fraction = selection ? 0.7 : 0.89,
    room = Math.max(
      0.01,
      Math.min(
        (w * fraction) / Math.max(100, b.right - b.left),
        ((h - 142) * fraction) / Math.max(85, b.bottom - b.top),
      ),
    )
  camera.z = clamp(room, 0.008, 3.2)
  camera.x = b.x
  camera.y = b.y - 12 / camera.z
  fitted = true
  repaint()
}
const positionNames = {
  'imagery-trace': '按现状影像辨认轮廓',
  revised: '已按匹配轮廓修订',
  court: '按影像重描外圈和中庭',
  strong: '与参考轮廓较强重合',
  partial: '与参考轮廓部分重合',
  weak: '与参考轮廓吻合度低',
  none: '未找到重合参考轮廓',
  local: '方案图配准',
}
const facadeNames = {
  unidentified: '研究推定',
  'project-height': '项目公布层数，窗墙推定',
  'documented-family': '有项目实景和设计资料',
  'design-study': '公开方案示意',
  'identified-view': '有该栋实景',
  'landmark-study': '专用建筑模型',
}
function unitName(o) {
  const legal = scene.info[o.id]?.[0]
  if (legal) return /^\d+$/.test(legal) ? legal + ' 号楼' : legal
  if (o.tile) return o.id.startsWith('center-') ? o.id.split('-')[1] + ' 号楼' : o.site.name
  if (o.id === 'xingke/东组团/西南配套') return '东组团 · 西南楼体'
  if (o.id === 'xingke/西组团/东侧配套') return '西组团 · 东侧楼体'
  const bits = o.id.split('/')
  return bits.length > 1
    ? bits.slice(-2).join(' · ')
    : '研究楼体 ' + o.id.split('-').at(-1) + ' · ' + o.block
}
function inspectUnit(id) {
  unit = id
  unitList.value = id
  const o = scene.items.find((v) => v.id === id)
  unitInfo.textContent = ''
  unitTitle.textContent = o ? unitName(o) : '建筑资料'
  if (o) {
    const [, p, f] = scene.info[id] || ['', 'local', 'landmark-study']
    unitInfo.textContent = [
      positionNames[p],
      facadeNames[f],
      o.h ? '模型高 ' + Number(o.h.toFixed(1)) + ' m' : '',
    ]
      .filter(Boolean)
      .join(' · ')
  }
  repaint()
}
function selectSite(id, { fit = true, building = '' } = {}) {
  const site = scene?.sites.get(id)
  selection = site?.id || ''
  select.value = selection
  study.hidden = !site
  street.hidden = !hooks.canEnter(selection)
  inspect.hidden = !site
  unitList.replaceChildren(new Option('选择楼体', ''))
  unitSources.replaceChildren()
  const members = site?.host
    ? (site.hosts || [site.host]).flatMap((k) => scene.sites.get(k).items)
    : site?.items || []
  for (const o of members) unitList.append(new Option(unitName(o), o.id))
  for (const [i, k] of (site?.refs || []).entries()) {
    const a = document.createElement('a')
    a.href = scene.sources[k]
    a.textContent = '资料 ' + (i + 1)
    a.target = '_blank'
    a.rel = 'noopener'
    unitSources.append(a)
  }
  if (site && !site.refs) {
    const a = document.createElement('button')
    a.textContent = '建筑研究'
    a.onclick = () => hooks.study(selection)
    unitSources.append(a)
  }
  inspectUnit(building)
  inspect.open = !!building
  const label = site?.host
    ? '入驻园区'
    : site?.method === 'campus'
      ? '园区定位 · 方案楼位'
      : site?.method === 'parcels'
        ? '按分区定位 · 方案楼位'
        : site?.method === 'numbered'
          ? '按楼号定位 · 方案楼位'
          : ''
  status.textContent = label
  status.hidden = !label
  dialog.dataset.project = selection
  hooks.selected(selection)
  if (fit) frameSite()
  else repaint()
}
function zoom(factor, sx = camera.w / 2, sy = camera.h / 2) {
  const old = camera.z
  camera.z = clamp(old * factor, 0.008, 5)
  camera.x += (sx - camera.w / 2) * (1 / old - 1 / camera.z)
  camera.y += (sy - camera.h / 2) * (1 / old - 1 / camera.z)
  fitted = false
  repaint()
}
function setup() {
  const styles = document.createElement('link')
  styles.rel = 'stylesheet'
  styles.href = new URL('region-map.css', import.meta.url)
  document.head.append(styles)
  dialog = document.createElement('dialog')
  dialog.className = 'region-map'
  dialog.setAttribute('aria-label', '未来科学城项目分布')
  base = document.createElement('canvas')
  trafficCanvas = document.createElement('canvas')
  for (const layer of [base, trafficCanvas]) {
    layer.setAttribute('aria-hidden', 'true')
    layer.className = 'region-plane'
  }
  groundCtx = base.getContext('2d', { alpha: false })
  trafficCtx = trafficCanvas.getContext('2d')
  canvas = document.createElement('canvas')
  canvas.tabIndex = 0
  canvas.setAttribute('aria-label', '未来科学城项目分布，方向键移动，加减键缩放')
  ctx = canvas.getContext('2d')
  const tools = document.createElement('header')
  tools.className = 'region-tools'
  function button(parent, label, icon, run) {
    const b = document.createElement('button')
    b.type = 'button'
    b.title = label
    b.setAttribute('aria-label', label)
    if (icon === 'plus' || icon === 'minus') b.textContent = icon === 'plus' ? '＋' : '−'
    else b.append(viewerIcon(icon))
    b.onclick = run
    parent.append(b)
    return b
  }
  button(tools, '返回小镇', 'back', () => dialog.close())
  select = document.createElement('select')
  select.setAttribute('aria-label', '定位项目')
  select.append(new Option('未来科学城 · 全域', ''))
  tools.append(select)
  select.onchange = () => selectSite(select.value)
  const actions = document.createElement('div')
  actions.className = 'region-actions'
  study = button(actions, '打开完整 3D', 'cube', () =>
    hooks.study(
      scene.items.find((o) => o.id === unit)?.site.id ||
        scene.sites.get(selection)?.host ||
        selection,
      unit,
    ),
  )
  street = button(actions, '进入街区', 'indoor', () => {
    if (hooks.enter(selection)) dialog.close()
  })
  study.hidden = street.hidden = true
  inspect = document.createElement('details')
  inspect.className = 'region-evidence'
  inspect.hidden = true
  const summary = document.createElement('summary')
  summary.title = '楼栋与资料'
  summary.setAttribute('aria-label', '楼栋与资料')
  summary.append(viewerIcon('sliders'))
  inspect.append(summary)
  const panel = document.createElement('section')
  unitTitle = document.createElement('strong')
  unitList = document.createElement('select')
  unitList.setAttribute('aria-label', '选择楼体')
  unitList.onchange = () => inspectUnit(unitList.value)
  unitInfo = document.createElement('p')
  unitSources = document.createElement('nav')
  unitSources.setAttribute('aria-label', '项目依据')
  panel.append(unitTitle, unitList, unitInfo, unitSources)
  inspect.append(panel)
  status = document.createElement('small')
  status.hidden = true
  status.className = 'region-status'
  status.setAttribute('role', 'status')
  const zooms = document.createElement('nav')
  zooms.className = 'region-zoom'
  zooms.setAttribute('aria-label', '地图视角')
  button(zooms, '放大', 'plus', () => zoom(1.6))
  button(zooms, '缩小', 'minus', () => zoom(1 / 1.6))
  button(zooms, '查看全域', 'fit', () => selectSite(''))
  const motion = button(zooms, '暂停车流', 'pause', () => {
    paused = !paused
    motionButton()
    animateTraffic()
  })
  function motionButton() {
    const label = paused ? '继续车流' : '暂停车流'
    motion.replaceChildren(viewerIcon(paused ? 'play' : 'pause'))
    motion.title = label
    motion.setAttribute('aria-label', label)
    motion.setAttribute('aria-pressed', String(paused))
  }
  motionButton()
  document.addEventListener('visibilitychange', animateTraffic)
  const footer = document.createElement('footer')
  scale = document.createElement('span')
  scale.className = 'region-scale'
  footer.append(scale)
  const north = document.createElement('span')
  north.className = 'region-north'
  north.title = '地理正北'
  north.setAttribute('aria-label', '地理正北')
  north.textContent = 'N'
  footer.prepend(north)
  const attribution = document.createElement('a')
  attribution.textContent = '© OpenStreetMap'
  attribution.href = 'https://www.openstreetmap.org/copyright'
  attribution.target = '_blank'
  attribution.rel = 'noopener'
  footer.append(attribution)
  const sources = document.createElement('a')
  sources.textContent = '建筑来源'
  sources.href = 'https://docs.overturemaps.org/attribution/'
  sources.target = '_blank'
  sources.rel = 'noopener'
  footer.append(sources)
  const hud = document.createElement('div')
  hud.className = 'region-head'
  hud.append(tools, actions, inspect, status)
  dialog.append(base, trafficCanvas, canvas, hud, zooms, footer)
  document.body.append(dialog)
  addEventListener('town-districts-ready', () => {
    if (dialog.open) street.hidden = !hooks.canEnter(selection)
  })
  dialog.addEventListener('close', () => {
    if (frame) cancelAnimationFrame(frame)
    frame = 0
    clearTimeout(motionTimer)
    resize.disconnect()
    hooks.closed()
    if (originFocus?.isConnected) originFocus.focus({ preventScroll: true })
  })
  resize = new ResizeObserver(() => {
    if (!dialog.open) return
    camera.w = canvas.clientWidth
    camera.h = canvas.clientHeight
    camera.ratio = Math.min(2, devicePixelRatio)
    for (const layer of [canvas, base, trafficCanvas]) {
      layer.width = Math.round(camera.w * camera.ratio)
      layer.height = Math.round(camera.h * camera.ratio)
    }
    if (fitted) frameSite()
    else repaint()
  })
  canvas.onwheel = (e) => {
    e.preventDefault()
    const r = canvas.getBoundingClientRect()
    zoom(
      Math.exp(-clamp(e.deltaY * (e.deltaMode === 1 ? 16 : 1), -180, 180) * 0.004),
      e.clientX - r.left,
      e.clientY - r.top,
    )
  }
  const pointers = new Map()
  let start,
    dragged = false
  const point = (e) => {
    const r = canvas.getBoundingClientRect()
    return [e.clientX - r.left, e.clientY - r.top]
  }
  const midpoint = (ps) =>
    ps.reduce((m, p) => [m[0] + p[0] / ps.length, m[1] + p[1] / ps.length], [0, 0])
  canvas.onpointerdown = (e) => {
    if (e.button !== 0) return
    canvas.setPointerCapture(e.pointerId)
    const p = point(e)
    pointers.set(e.pointerId, p)
    if (pointers.size === 1) {
      start = p
      dragged = false
    } else dragged = true
  }
  canvas.onpointermove = (e) => {
    if (!pointers.has(e.pointerId)) return
    const before = [...pointers.values()],
      p = point(e)
    pointers.set(e.pointerId, p)
    const after = [...pointers.values()]
    if (!dragged && Math.hypot(p[0] - start[0], p[1] - start[1]) < 4) return
    dragged = true
    const a = midpoint(before),
      b = midpoint(after)
    camera.x -= (b[0] - a[0]) / camera.z
    camera.y -= (b[1] - a[1]) / camera.z
    fitted = false
    if (after.length === 2) {
      const span = (ps) => Math.hypot(ps[0][0] - ps[1][0], ps[0][1] - ps[1][1])
      zoom(span(after) / Math.max(1, span(before)), ...b)
    } else repaint()
  }
  canvas.onpointerup = (e) => {
    if (!pointers.has(e.pointerId)) return
    pointers.delete(e.pointerId)
    if (dragged || pointers.size || !scene) return
    const [x, y] = point(e),
      label = hits.find((p) => x >= p.left && x <= p.right && y >= p.top && y <= p.bottom)
    if (label) {
      selectSite(label.id)
      return
    }
    const hit = hitProject(scene, [
      (x - camera.w / 2) / camera.z + camera.x,
      (y - camera.h / 2) / camera.z + camera.y,
    ])
    if (hit) selectSite(hit.id, { fit: selection !== hit.id, building: hit.unit })
  }
  canvas.onpointercancel = (e) => {
    pointers.delete(e.pointerId)
    dragged = true
  }
  canvas.onkeydown = (e) => {
    const d = 60 / camera.z
    if (e.key === '+' || e.key === '=') zoom(1.5)
    else if (e.key === '-') zoom(1 / 1.5)
    else if (e.key === 'Home') selectSite('')
    else if (e.key === 'ArrowRight') camera.x += d
    else if (e.key === 'ArrowLeft') camera.x -= d
    else if (e.key === 'ArrowDown') camera.y += d
    else if (e.key === 'ArrowUp') camera.y -= d
    else return
    e.preventDefault()
    if (e.key.startsWith('Arrow')) fitted = false
    repaint()
  }
}
export async function openRegion(id, callbacks) {
  hooks = callbacks
  if (!dialog) setup()
  if (!dialog.open) {
    originFocus = document.activeElement
    dialog.showModal()
    resize.observe(canvas)
    canvas.focus({ preventScroll: true })
  }
  if (!scene) {
    status.hidden = false
    status.textContent = '正在载入项目分布…'
    select.disabled = true
    if (!pending)
      pending = loadScene(repaint)
        .then((result) => {
          scene = result
          for (const category of ['住宅', '产业园', '产业空间', '地标']) {
            const group = document.createElement('optgroup')
            group.label = category
            for (const p of scene.sites.values())
              if (p.type === category) group.append(new Option(p.name, p.id))
            select.append(group)
          }
        })
        .catch((error) => {
          pending = null
          throw error
        })
    try {
      await pending
    } catch (error) {
      if (!dialog.open || hooks !== callbacks) return
      status.textContent = '项目分布载入失败'
      const retry = document.createElement('button')
      retry.textContent = '重试'
      retry.onclick = () => openRegion(id, callbacks)
      status.append(' ', retry)
      console.error(error)
      return
    }
  }
  if (!dialog.open || hooks !== callbacks) return
  select.disabled = false
  selectSite(id)
  dialog.dataset.state = 'ready'
}

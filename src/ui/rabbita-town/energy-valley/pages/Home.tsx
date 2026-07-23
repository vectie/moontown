// ============================================================
// Home —— 全屏地图即首页
// ============================================================

import { useEffect, useRef, useState, useCallback } from 'react'
import { createWorld, archetype } from '../engine/world'
import { createSim, updateSim, type SimState } from '../engine/sim'
import { render, pickTile, buildingAt, agentNear, type ViewState } from '../engine/renderer'
import { worldToScreen } from '../engine/iso'
import {
  checkBuilding, placeBuilding, checkRoad, placeRoad,
  checkPark, placePark, demolishAt, refreshAllRoadMasks,
} from '../engine/build'
import { isRiver } from '../engine/world'
import type { Agent, Building, ToolId, WeatherKind } from '../engine/types'
import {
  TownBadge, MetricChips, ToolDock, EventFeed, Inspector, Dashboard,
  Onboarding, Guide, ResetDialog,
} from '../components/Hud'

const SAVE_KEY = 'moontown-energy-valley-v1'
const INTRO_KEY = 'moontown-intro-seen-v1'

interface Snapshot {
  hour: number; day: number; weather: WeatherKind; weatherAuto: boolean
  population: number; vitality: number; budget: number; agentsOnline: number
  paused: boolean; timeScale: number
  events: SimState['events']
  buildings: Building[]
  history: SimState['metrics']['history']
}

export default function Home() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const wrapRef = useRef<HTMLDivElement>(null)
  const simRef = useRef<SimState | null>(null)
  const viewRef = useRef<ViewState>({ camX: 0, camY: 0, zoom: 1, hoverTile: null, ghost: null, selectedId: null })
  const dragRef = useRef<{ panning: boolean; painting: boolean; lastX: number; lastY: number; moved: boolean }>({ panning: false, painting: false, lastX: 0, lastY: 0, moved: false })
  const followRef = useRef<string | null>(null)

  const [tool, setTool] = useState<ToolId>('inspect')
  const toolRef = useRef<ToolId>('inspect')
  toolRef.current = tool
  const [snap, setSnap] = useState<Snapshot | null>(null)
  const [selected, setSelected] = useState<{ building?: Building; agent?: Agent }>({})
  const [following, setFollowing] = useState(false)
  const [boardOpen, setBoardOpen] = useState(false)
  const [guideOpen, setGuideOpen] = useState(false)
  const [resetOpen, setResetOpen] = useState(false)
  const [showIntro, setShowIntro] = useState(() => !localStorage.getItem(INTRO_KEY))
  const [toast, setToast] = useState<string | null>(null)

  const toastTimer = useRef<ReturnType<typeof setTimeout> | null>(null)
  const showToast = useCallback((msg: string) => {
    setToast(msg)
    if (toastTimer.current) clearTimeout(toastTimer.current)
    toastTimer.current = setTimeout(() => setToast(null), 2200)
  }, [])

  // ---------- 持久化 ----------
  const saveWorld = useCallback(() => {
    const sim = simRef.current
    if (!sim) return
    const data = {
      custom: sim.world.buildings.filter(b => !b.builtin).map(b => ({ a: b.archetype, tx: b.tx, ty: b.ty, p: b.progress })),
      roads: [] as [number, number, string][],
      budget: sim.metrics.budget,
      day: sim.day, hour: sim.hour,
    }
    for (let y = 0; y < sim.world.tiles.length; y++)
      for (let x = 0; x < sim.world.tiles[0].length; x++) {
        const t = sim.world.tiles[y][x]
        if (t.terrain === 'road' || t.terrain === 'bridge' || t.terrain === 'forest')
          data.roads.push([x, y, t.terrain])
      }
    try { localStorage.setItem(SAVE_KEY, JSON.stringify(data)) } catch { /* ignore */ }
  }, [])

  // ---------- 初始化 & 主循环 ----------
  useEffect(() => {
    const world = createWorld()
    const sim = createSim(world)

    // —— 存档恢复 ——
    try {
      const raw = localStorage.getItem(SAVE_KEY)
      if (raw) {
        const data = JSON.parse(raw) as {
          custom: { a: string; tx: number; ty: number; p: number }[]
          roads: [number, number, string][]
          budget: number; day: number; hour: number
        }
        // 先把人工地形复位为自然地貌
        for (let y = 0; y < world.tiles.length; y++)
          for (let x = 0; x < world.tiles[0].length; x++) {
            const t = world.tiles[y][x]
            if (t.terrain === 'road' || t.terrain === 'bridge' || t.terrain === 'forest') {
              t.terrain = isRiver(x, y) ? 'water' : 'grass'
              t.roadDir = undefined
            }
          }
        // 应用存档地形
        for (const [x, y, kind] of data.roads) {
          const t = world.tiles[y]?.[x]
          if (t && (kind === 'road' || kind === 'bridge' || kind === 'forest')) {
            t.terrain = kind
          }
        }
        refreshAllRoadMasks(world)
        // 自建建筑：恢复精确进度，避免刷新时丢失在建工程与已扣预算
        for (const c of data.custom) {
          const a = archetype(c.a)
          world.buildings.push({
            id: `user-r-${c.tx}-${c.ty}`,
            archetype: c.a, name: a.name,
            tx: c.tx, ty: c.ty, progress: Math.max(0, Math.min(1, c.p)), demolish: 0,
            isCivic: false, occupants: 0,
            vitality: 40 + Math.random() * 20, builtin: false,
          })
          const b = world.buildings[world.buildings.length - 1]
          for (let x = c.tx; x < c.tx + a.w; x++)
            for (let y = c.ty; y < c.ty + a.h; y++)
              if (world.tiles[y]?.[x]) world.tiles[y][x].buildingId = b.id
        }
        sim.metrics.budget = data.budget
        sim.day = data.day
        sim.hour = data.hour
      }
    } catch { /* 损坏存档则忽略 */ }

    simRef.current = sim

    // 初始相机：对准市政厅一带
    const c = worldToScreen(24, 27)
    const view = viewRef.current
    view.camX = c.x
    view.camY = c.y
    view.zoom = 0.95

    const canvas = canvasRef.current!
    const ctx = canvas.getContext('2d')!
    let raf = 0
    let last = performance.now()

    const resize = () => {
      const wrap = wrapRef.current!
      const dpr = Math.min(2, window.devicePixelRatio || 1)
      canvas.width = wrap.clientWidth * dpr
      canvas.height = wrap.clientHeight * dpr
      canvas.style.width = `${wrap.clientWidth}px`
      canvas.style.height = `${wrap.clientHeight}px`
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
    }
    resize()
    const ro = new ResizeObserver(resize)
    ro.observe(wrapRef.current!)

    const loop = (now: number) => {
      const dt = Math.min(0.05, (now - last) / 1000)
      last = now
      updateSim(sim, dt)
      // 跟随 Agent
      if (followRef.current) {
        const ag = sim.agents.find(a => a.id === followRef.current)
        if (ag && ag.state !== 'inside') {
          const p = worldToScreen(ag.x, ag.y)
          view.camX += (p.x - view.camX) * 0.06
          view.camY += (p.y - view.camY) * 0.06
        }
      }
      const wrap = wrapRef.current!
      render(ctx, sim, view, wrap.clientWidth, wrap.clientHeight, now)
      raf = requestAnimationFrame(loop)
    }
    raf = requestAnimationFrame(loop)

    // UI 快照
    let savedBuildProgress = ''
    const iv = setInterval(() => {
      setSnap({
        hour: sim.hour, day: sim.day, weather: sim.weather, weatherAuto: sim.weatherAuto,
        population: sim.metrics.population, vitality: sim.metrics.vitality,
        budget: sim.metrics.budget, agentsOnline: sim.metrics.agentsOnline,
        paused: sim.paused, timeScale: sim.timeScale,
        events: [...sim.events], buildings: [...sim.world.buildings],
        history: [...sim.metrics.history],
      })
      // 同步选中对象（可能被拆除）
      const sid = viewRef.current.selectedId
      if (sid) {
        setSelected(prev => {
          if (prev.building && !sim.world.buildings.find(b => b.id === prev.building!.id)) {
            viewRef.current.selectedId = null
            return {}
          }
          return prev
        })
      }
    }, 400)
    const saveIv = setInterval(() => {
      const nextBuildProgress = sim.world.buildings
        .filter(b => !b.builtin)
        .map(b => `${b.id}:${b.progress.toFixed(2)}`)
        .join('|')
      if (nextBuildProgress !== savedBuildProgress) {
        savedBuildProgress = nextBuildProgress
        saveWorld()
      }
    }, 1000)

    return () => { cancelAnimationFrame(raf); clearInterval(iv); clearInterval(saveIv); ro.disconnect() }
  }, [saveWorld])

  // ---------- 工具应用 ----------
  const applyToolAt = useCallback((tx: number, ty: number, click: boolean) => {
    const sim = simRef.current!
    const t = toolRef.current
    if (t === 'road') {
      if (placeRoad(sim, tx, ty)) {
        saveWorld()
        if (click) showToast('道路已铺设（-30）')
      }
      else if (click) {
        const chk = checkRoad(sim, tx, ty)
        if (chk.reason) showToast(chk.reason)
      }
    } else if (t === 'park') {
      if (placePark(sim, tx, ty)) {
        saveWorld()
        if (click) showToast('造林已完成（-20）')
      }
      else if (click) {
        const chk = checkPark(sim, tx, ty)
        if (chk.reason) showToast(chk.reason)
      }
    } else if (t === 'demolish') {
      if (demolishAt(sim, tx, ty)) {
        saveWorld()
        if (click) showToast('该地块已拆除')
      } else if (click) {
        showToast('这里没有可拆除的内容')
      }
    } else if (t.startsWith('bld:') && click) {
      const archId = t.slice(4)
      const chk = checkBuilding(sim, archId, tx, ty)
      if (!chk.valid) { showToast(chk.reason ?? '无法建造'); return }
      placeBuilding(sim, archId, tx, ty)
      saveWorld()
    }
  }, [saveWorld, showToast])

  const selectAt = useCallback((mx: number, my: number) => {
    const sim = simRef.current!
    const wrap = wrapRef.current!
    const view = viewRef.current
    const ag = agentNear(sim, view, wrap.clientWidth, wrap.clientHeight, mx, my)
    if (ag) {
      view.selectedId = ag.id
      setSelected({ agent: ag })
      return
    }
    const tile = pickTile(sim, view, wrap.clientWidth, wrap.clientHeight, mx, my)
    if (tile) {
      const b = buildingAt(sim, tile.x, tile.y)
      if (b) {
        view.selectedId = b.id
        setSelected({ building: b })
        return
      }
    }
    view.selectedId = null
    setSelected({})
    setFollowing(false)
    followRef.current = null
  }, [])

  // ---------- 鼠标 ----------
  const updateGhost = useCallback((mx: number, my: number) => {
    const sim = simRef.current
    if (!sim) return
    const wrap = wrapRef.current!
    const view = viewRef.current
    const tile = pickTile(sim, view, wrap.clientWidth, wrap.clientHeight, mx, my)
    view.hoverTile = tile
    const t = toolRef.current
    if (!tile || t === 'inspect') { view.ghost = null; return }
    if (t.startsWith('bld:')) {
      const a = archetype(t.slice(4))
      const chk = checkBuilding(sim, t.slice(4), tile.x, tile.y)
      view.ghost = { tx: tile.x, ty: tile.y, w: a.w, h: a.h, valid: chk.valid, label: a.name }
    } else if (t === 'road') {
      const chk = checkRoad(sim, tile.x, tile.y)
      view.ghost = { tx: tile.x, ty: tile.y, w: 1, h: 1, valid: chk.valid, label: '道路' }
    } else if (t === 'park') {
      const chk = checkPark(sim, tile.x, tile.y)
      view.ghost = { tx: tile.x, ty: tile.y, w: 1, h: 1, valid: chk.valid, label: '公园' }
    } else if (t === 'demolish') {
      const tileData = sim.world.tiles[tile.y]?.[tile.x]
      const has = !!tileData && (tileData.buildingId !== undefined || tileData.terrain === 'road' || tileData.terrain === 'bridge' || tileData.terrain === 'forest')
      view.ghost = { tx: tile.x, ty: tile.y, w: 1, h: 1, valid: has, label: '拆除' }
    }
  }, [])

  const onMouseDown = (e: React.MouseEvent) => {
    const d = dragRef.current
    d.lastX = e.clientX; d.lastY = e.clientY; d.moved = false
    if (e.button === 2 || e.button === 1 || toolRef.current === 'inspect') {
      d.panning = true
    } else {
      d.painting = true
      const sim = simRef.current!
      const tile = pickTile(sim, viewRef.current, wrapRef.current!.clientWidth, wrapRef.current!.clientHeight, e.nativeEvent.offsetX, e.nativeEvent.offsetY)
      if (tile) applyToolAt(tile.x, tile.y, true)
    }
  }

  const onMouseMove = (e: React.MouseEvent) => {
    const d = dragRef.current
    const dx = e.clientX - d.lastX
    const dy = e.clientY - d.lastY
    if (d.panning) {
      if (Math.abs(dx) + Math.abs(dy) > 2) d.moved = true
      const view = viewRef.current
      view.camX -= dx / view.zoom
      view.camY -= dy / view.zoom
      followRef.current = null
      setFollowing(false)
    } else if (d.painting && !toolRef.current.startsWith('bld:')) {
      const sim = simRef.current!
      const tile = pickTile(sim, viewRef.current, wrapRef.current!.clientWidth, wrapRef.current!.clientHeight, e.nativeEvent.offsetX, e.nativeEvent.offsetY)
      if (tile) applyToolAt(tile.x, tile.y, false)
    }
    d.lastX = e.clientX; d.lastY = e.clientY
    updateGhost(e.nativeEvent.offsetX, e.nativeEvent.offsetY)
  }

  const onMouseUp = (e: React.MouseEvent) => {
    const d = dragRef.current
    if (d.panning && !d.moved && toolRef.current === 'inspect') {
      selectAt(e.nativeEvent.offsetX, e.nativeEvent.offsetY)
    }
    d.panning = false
    d.painting = false
  }

  const onWheel = (e: React.WheelEvent) => {
    const view = viewRef.current
    const factor = e.deltaY < 0 ? 1.12 : 0.89
    const nz = Math.min(2.6, Math.max(0.35, view.zoom * factor))
    // 以光标为中心缩放
    const wrap = wrapRef.current!
    const mx = e.nativeEvent.offsetX - wrap.clientWidth / 2
    const my = e.nativeEvent.offsetY - wrap.clientHeight / 2
    view.camX += mx / view.zoom - mx / nz
    view.camY += my / view.zoom - my / nz
    view.zoom = nz
  }

  // ---------- 键盘 ----------
  useEffect(() => {
    const tools: ToolId[] = ['inspect', 'road', 'park', 'demolish', 'bld:c-tower', 'bld:c-lab', 'bld:c-hall', 'bld:c-home']
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        setTool('inspect')
        viewRef.current.selectedId = null
        setSelected({})
        setBoardOpen(false)
        setGuideOpen(false)
        setResetOpen(false)
      }
      else if (e.key === ' ') { e.preventDefault(); simRef.current!.paused = !simRef.current!.paused }
      else if (e.key >= '1' && e.key <= '8') setTool(tools[Number(e.key) - 1])
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])

  // ---------- HUD 回调 ----------
  const handleWeather = (w: WeatherKind) => {
    const sim = simRef.current!
    sim.weather = w
    sim.weatherAuto = false
  }
  const handleAuto = () => { simRef.current!.weatherAuto = !simRef.current!.weatherAuto }
  const handleFollow = (id: string | null) => {
    followRef.current = id
    setFollowing(!!id)
  }
  const handleDemolish = (b: Building) => {
    const sim = simRef.current!
    demolishAt(sim, b.tx, b.ty)
    viewRef.current.selectedId = null
    setSelected({})
    saveWorld()
  }
  const handleSelectBuilding = (b: Building) => {
    setBoardOpen(false)
    const view = viewRef.current
    view.selectedId = b.id
    setSelected({ building: b })
    const a = archetype(b.archetype)
    const c = worldToScreen(b.tx + a.w / 2, b.ty + a.h / 2)
    view.camX = c.x; view.camY = c.y
    if (view.zoom < 1) view.zoom = 1
  }
  const resetWorld = () => {
    localStorage.removeItem(SAVE_KEY)
    window.location.reload()
  }

  return (
    <div ref={wrapRef} className="relative h-screen w-screen overflow-hidden bg-slate-950 select-none">
      <canvas
        ref={canvasRef}
        className="absolute inset-0 cursor-grab active:cursor-grabbing"
        onMouseDown={onMouseDown}
        onMouseMove={onMouseMove}
        onMouseUp={onMouseUp}
        onMouseLeave={onMouseUp}
        onWheel={onWheel}
        onContextMenu={e => e.preventDefault()}
      />

      {/* 顶部左 */}
      <div className="town-badge-wrap pointer-events-none absolute left-4 top-4">
        {snap && (
          <TownBadge
            day={snap.day} hour={snap.hour} weather={snap.weather} weatherAuto={snap.weatherAuto}
            onToggleWeather={handleWeather} onToggleAuto={handleAuto}
          />
        )}
      </div>

      {/* 顶部右 */}
      <div className="town-metric-wrap pointer-events-none absolute right-4 top-4 flex flex-col items-end gap-2">
        {snap && (
          <MetricChips
            population={snap.population} vitality={snap.vitality} budget={snap.budget} agentsOnline={snap.agentsOnline}
            paused={snap.paused} timeScale={snap.timeScale}
            onPause={() => { simRef.current!.paused = !simRef.current!.paused }}
            onSpeed={s => { simRef.current!.timeScale = s }}
            onToggleBoard={() => setBoardOpen(o => !o)}
            boardOpen={boardOpen}
          />
        )}
        {snap && (
          <Dashboard
            open={boardOpen}
            vitality={snap.vitality}
            history={snap.history}
            buildings={snap.buildings}
            events={snap.events}
            onClose={() => setBoardOpen(false)}
            onSelect={handleSelectBuilding}
            onGuide={() => { setBoardOpen(false); setGuideOpen(true) }}
            onReset={() => { setBoardOpen(false); setResetOpen(true) }}
          />
        )}
      </div>

      {/* 事件流 */}
      <div className="town-event-wrap pointer-events-none absolute bottom-24 left-4">
        {snap && <EventFeed events={snap.events} />}
      </div>

      {/* 视察面板 */}
      <div className="town-inspector-wrap pointer-events-none absolute right-4 top-24">
        <Inspector
          building={selected.building}
          agent={selected.agent}
          onClose={() => { viewRef.current.selectedId = null; setSelected({}); setFollowing(false); followRef.current = null }}
          onFollow={handleFollow}
          following={following}
          onDemolish={handleDemolish}
        />
      </div>

      {/* 工具坞 */}
      <div className="town-tool-wrap pointer-events-none absolute bottom-4 left-1/2 -translate-x-1/2">
        <ToolDock tool={tool} onTool={setTool} />
      </div>

      {/* 次要操作：留在边角，不参与核心浏览流 */}
      <div className="town-actions">
        <button onClick={() => setGuideOpen(true)} className="town-action">
          ? 指南
        </button>
        <button onClick={() => setResetOpen(true)} title="重置小镇" className="town-action">
          ↺ 重置
        </button>
      </div>

      {/* Toast */}
      {toast && (
        <div className="absolute left-1/2 top-20 -translate-x-1/2 rounded-xl bg-rose-500/85 px-4 py-2 text-[13px] text-white shadow-xl backdrop-blur-sm">
          {toast}
        </div>
      )}

      {/* 首次引导 */}
      {showIntro && (
        <div className="absolute inset-0 z-10 flex items-center justify-center bg-slate-950/40">
          <Onboarding
            onClose={() => { setShowIntro(false); localStorage.setItem(INTRO_KEY, '1') }}
            onGuide={() => {
              setShowIntro(false)
              localStorage.setItem(INTRO_KEY, '1')
              setGuideOpen(true)
            }}
          />
        </div>
      )}

      {guideOpen && (
        <div className="absolute inset-0 z-20 flex items-center justify-center bg-slate-950/55 p-4">
          <Guide onClose={() => setGuideOpen(false)} />
        </div>
      )}

      {resetOpen && (
        <div className="absolute inset-0 z-30 flex items-center justify-center bg-slate-950/60 p-4">
          <ResetDialog
            onCancel={() => setResetOpen(false)}
            onConfirm={resetWorld}
          />
        </div>
      )}
    </div>
  )
}

// ============================================================
// 渲染器 —— Canvas 2D 等距场景
// 绘制顺序：地形（depth 升序）→ 对象（树/建筑/Agent，depth 升序）
//          → 天气粒子 → 昼夜色调 → 暗角
// ============================================================

import { HH, HW, worldToScreen, FLOOR_H } from './iso'
import { archetype, COLS, ROWS, riverCenter } from './world'
import { daylight, type SimState } from './sim'
import type { Agent, Building, WeatherKind } from './types'

export interface ViewState {
  camX: number      // 世界像素中心
  camY: number
  zoom: number
  hoverTile: { x: number; y: number } | null
  ghost: { tx: number; ty: number; w: number; h: number; valid: boolean; label: string } | null
  selectedId: string | null
}

interface Ctx2 extends CanvasRenderingContext2D {}

// ---------- 基础工具 ----------
function hashStr(s: string): number {
  let h = 2166136261
  for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619) }
  return (h >>> 0) / 4294967296
}

function easeOut(x: number): number { return 1 - Math.pow(1 - x, 2.2) }

function shade(hex: string, f: number): string {
  const n = parseInt(hex.slice(1), 16)
  const r = Math.min(255, Math.max(0, ((n >> 16) & 255) * f))
  const g = Math.min(255, Math.max(0, ((n >> 8) & 255) * f))
  const b = Math.min(255, Math.max(0, (n & 255) * f))
  return `rgb(${r | 0},${g | 0},${b | 0})`
}

// ---------- 主入口 ----------
export function render(
  ctx: Ctx2,
  sim: SimState,
  view: ViewState,
  vw: number,
  vh: number,
  now: number,
) {
  const t = now / 1000
  ctx.save()
  ctx.clearRect(0, 0, vw, vh)

  const toScreen = (wx: number, wy: number) => {
    const p = worldToScreen(wx, wy)
    return {
      x: (p.x - view.camX) * view.zoom + vw / 2,
      y: (p.y - view.camY) * view.zoom + vh / 2,
    }
  }

  // 背景底色（夜空渐变）
  const dl = daylight(sim.hour)
  const bg = ctx.createLinearGradient(0, 0, 0, vh)
  if (dl > 0.5) { bg.addColorStop(0, '#9fc8e8'); bg.addColorStop(1, '#cfe4d8') }
  else if (dl > 0.15) { bg.addColorStop(0, '#7d90c0'); bg.addColorStop(1, '#c9b49a') }
  else { bg.addColorStop(0, '#0b1026'); bg.addColorStop(1, '#182238') }
  ctx.fillStyle = bg
  ctx.fillRect(0, 0, vw, vh)

  setViewHalf(vw, vh)
  drawTerrain(ctx, sim, view, toScreen, t, vw, vh)
  drawObjects(ctx, sim, view, toScreen, t, dl, vw, vh)
  drawGhostAndHover(ctx, sim, view, toScreen, t)
  drawWeather(ctx, sim, vw, vh, t)
  drawDayNight(ctx, sim, vw, vh, dl)
  ctx.restore()
}

// ---------- 地形 ----------
function drawTerrain(
  ctx: Ctx2, sim: SimState, view: ViewState,
  toScreen: (x: number, y: number) => { x: number; y: number },
  t: number, vw: number, vh: number,
) {
  const tiles = sim.world.tiles
  const z = view.zoom
  const m = TILE_PX * z * 2
  for (let y = 0; y < ROWS; y++) {
    for (let x = 0; x < COLS; x++) {
      const tile = tiles[y][x]
      const p = toScreen(x + 0.5, y + 0.5)
      if (p.x < -m || p.x > vw + m || p.y < -m || p.y > vh + m) continue
      diamond(ctx, p.x, p.y, z)
      switch (tile.terrain) {
        case 'grass': {
          const v = ((x * 7 + y * 13) % 5) * 0.02
          ctx.fillStyle = shade('#5da25f', 1 + v)
          ctx.fill()
          break
        }
        case 'forest': {
          ctx.fillStyle = shade('#4d8a52', 1 + ((x * 3 + y) % 4) * 0.02)
          ctx.fill()
          break
        }
        case 'plaza': {
          ctx.fillStyle = '#c9c2b2'
          ctx.fill()
          ctx.strokeStyle = 'rgba(0,0,0,0.08)'
          ctx.lineWidth = 1
          ctx.stroke()
          break
        }
        case 'water': {
          drawWater(ctx, p.x, p.y, z, tile.riverFlow ?? 0, t)
          break
        }
        case 'road': {
          ctx.fillStyle = '#7a7f8a'
          ctx.fill()
          drawRoadMarkings(ctx, p.x, p.y, z, tile.roadDir ?? 15)
          break
        }
        case 'bridge': {
          // 先画水面，再画桥板
          drawWater(ctx, p.x, p.y, z, tile.riverFlow ?? 0, t)
          drawBridge(ctx, p.x, p.y, z)
          break
        }
      }
    }
  }
}

const TILE_PX = 64

function diamond(ctx: Ctx2, sx: number, sy: number, z: number) {
  ctx.beginPath()
  ctx.moveTo(sx, sy - HH * z)
  ctx.lineTo(sx + HW * z, sy)
  ctx.lineTo(sx, sy + HH * z)
  ctx.lineTo(sx - HW * z, sy)
  ctx.closePath()
}

function drawWater(ctx: Ctx2, sx: number, sy: number, z: number, phase: number, t: number) {
  // 基底
  const g = ctx.createLinearGradient(sx, sy - HH * z, sx, sy + HH * z)
  g.addColorStop(0, '#2e7f9e')
  g.addColorStop(1, '#1f5f7e')
  ctx.fillStyle = g
  ctx.fill()
  // 流动高光带（两条，沿对角方向移动）
  ctx.save()
  ctx.clip()
  for (let i = 0; i < 2; i++) {
    const ph = ((t * 0.35 + phase * 0.13 + i * 0.5) % 1)
    const off = (ph - 0.5) * 2 * HW * z
    ctx.strokeStyle = `rgba(180,230,245,${0.35 - i * 0.12})`
    ctx.lineWidth = 2 * z
    ctx.beginPath()
    ctx.moveTo(sx - HW * z * 0.6 + off * 0.3, sy + off * 0.55)
    ctx.quadraticCurveTo(
      sx + Math.sin(t * 2 + phase) * 4 * z, sy + off * 0.55 + 3 * z,
      sx + HW * z * 0.6 + off * 0.3, sy + off * 0.55,
    )
    ctx.stroke()
  }
  // 闪点
  const sp = (Math.sin(t * 3 + phase * 5) + 1) / 2
  ctx.fillStyle = `rgba(255,255,255,${0.12 + sp * 0.25})`
  ctx.beginPath()
  ctx.ellipse(sx + Math.sin(phase * 9) * 10 * z, sy + Math.cos(phase * 7) * 5 * z, 2.2 * z, 1.1 * z, 0, 0, Math.PI * 2)
  ctx.fill()
  ctx.restore()
}

function drawRoadMarkings(ctx: Ctx2, sx: number, sy: number, z: number, mask: number) {
  ctx.strokeStyle = 'rgba(255,255,255,0.35)'
  ctx.lineWidth = Math.max(1, 1.2 * z)
  ctx.setLineDash([6 * z, 5 * z])
  // 沿主轴画中线
  ctx.beginPath()
  if (mask & 1 && mask & 4) {          // N-S 向
    ctx.moveTo(sx - HW * z * 0.5, sy - HH * z * 0.5)
    ctx.lineTo(sx + HW * z * 0.5, sy + HH * z * 0.5)
  } else if (mask & 2 && mask & 8) {   // E-W 向
    ctx.moveTo(sx + HW * z * 0.5, sy - HH * z * 0.5)
    ctx.lineTo(sx - HW * z * 0.5, sy + HH * z * 0.5)
  }
  ctx.stroke()
  ctx.setLineDash([])
  // 路缘
  ctx.strokeStyle = 'rgba(0,0,0,0.15)'
  ctx.lineWidth = 1
  ctx.beginPath()
  ctx.moveTo(sx, sy - HH * z); ctx.lineTo(sx + HW * z, sy)
  ctx.lineTo(sx, sy + HH * z); ctx.lineTo(sx - HW * z, sy)
  ctx.closePath()
  ctx.stroke()
}

function drawBridge(ctx: Ctx2, sx: number, sy: number, z: number) {
  // 桥板：略小的木质菱形 + 两侧栏杆
  ctx.save()
  diamond(ctx, sx, sy - 3 * z, z * 0.86)
  const g = ctx.createLinearGradient(sx, sy - HH * z, sx, sy + HH * z)
  g.addColorStop(0, '#b08954')
  g.addColorStop(1, '#8a6a40')
  ctx.fillStyle = g
  ctx.fill()
  ctx.strokeStyle = 'rgba(60,40,20,0.5)'
  ctx.lineWidth = 1
  ctx.stroke()
  // 板缝
  ctx.strokeStyle = 'rgba(60,40,20,0.35)'
  for (let i = -1; i <= 1; i++) {
    ctx.beginPath()
    ctx.moveTo(sx - HW * z * 0.7, sy - 3 * z + i * 5 * z)
    ctx.lineTo(sx + HW * z * 0.7, sy - 3 * z + i * 5 * z)
    ctx.stroke()
  }
  // 栏杆（两条沿 x 方向的线 + 立柱）
  ctx.strokeStyle = '#5e4630'
  ctx.lineWidth = 2 * z
  ctx.beginPath()
  ctx.moveTo(sx - HW * z * 0.8, sy - 3 * z - HH * z * 0.42)
  ctx.lineTo(sx + HW * z * 0.8, sy - 3 * z - HH * z * 0.42)
  ctx.moveTo(sx - HW * z * 0.8, sy - 3 * z + HH * z * 0.42)
  ctx.lineTo(sx + HW * z * 0.8, sy - 3 * z + HH * z * 0.42)
  ctx.stroke()
  ctx.restore()
}

// ---------- 对象（树 / 建筑 / Agent） ----------
function drawObjects(
  ctx: Ctx2, sim: SimState, view: ViewState,
  toScreen: (x: number, y: number) => { x: number; y: number },
  t: number, dl: number, vw: number, vh: number,
) {
  type Obj = { depth: number; draw: () => void }
  const objs: Obj[] = []
  const z = view.zoom
  const m = 200 * z

  // 树
  for (let y = 0; y < ROWS; y++)
    for (let x = 0; x < COLS; x++) {
      if (sim.world.tiles[y][x].terrain !== 'forest') continue
      const p = toScreen(x + 0.5, y + 0.5)
      if (p.x < -m || p.x > vw + m || p.y < -m || p.y > vh + m) continue
      const seed = hashStr(`tree-${x}-${y}`)
      objs.push({ depth: x + y + 0.4, draw: () => drawTree(ctx, p.x, p.y, z, seed, t) })
    }

  // 建筑
  for (const b of sim.world.buildings) {
    const a = archetype(b.archetype)
    const depth = b.tx + b.ty + a.h + 0.5
    objs.push({
      depth,
      draw: () => drawBuilding(ctx, sim, view, toScreen, b, t, dl),
    })
  }

  // Agent
  for (const ag of sim.agents) {
    if (ag.state === 'inside') continue
    const p = toScreen(ag.x, ag.y)
    objs.push({ depth: ag.x + ag.y + 0.45, draw: () => drawAgent(ctx, sim, view, ag, p.x, p.y, z, t) })
  }

  objs.sort((m, n) => m.depth - n.depth)
  for (const o of objs) o.draw()
}

function drawTree(ctx: Ctx2, sx: number, sy: number, z: number, seed: number, t: number) {
  const sway = Math.sin(t * 1.2 + seed * 20) * 1.5 * z
  const h = (14 + seed * 10) * z
  // 影
  ctx.fillStyle = 'rgba(0,0,0,0.18)'
  ctx.beginPath()
  ctx.ellipse(sx + 3 * z, sy + 1 * z, 8 * z, 3.5 * z, 0, 0, Math.PI * 2)
  ctx.fill()
  // 干
  ctx.strokeStyle = '#6b4a2e'
  ctx.lineWidth = 2.4 * z
  ctx.beginPath()
  ctx.moveTo(sx, sy)
  ctx.lineTo(sx + sway * 0.3, sy - h * 0.45)
  ctx.stroke()
  // 冠（两层）
  const c1 = shade('#3e7d46', 0.9 + seed * 0.25)
  const c2 = shade('#4d9a52', 0.9 + seed * 0.25)
  ctx.fillStyle = c1
  ctx.beginPath()
  ctx.ellipse(sx + sway * 0.5, sy - h * 0.62, 9 * z, 6.5 * z, 0, 0, Math.PI * 2)
  ctx.fill()
  ctx.fillStyle = c2
  ctx.beginPath()
  ctx.ellipse(sx + sway * 0.8 - 2 * z, sy - h * 0.85, 6.5 * z, 5 * z, 0, 0, Math.PI * 2)
  ctx.fill()
}

// ---------- 建筑 ----------
interface Pt { x: number; y: number }

function lerp(a: Pt, b: Pt, f: number): Pt {
  return { x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f }
}

function quad(ctx: Ctx2, a: Pt, b: Pt, c: Pt, d: Pt, fill: string) {
  ctx.beginPath()
  ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.lineTo(c.x, c.y); ctx.lineTo(d.x, d.y)
  ctx.closePath()
  ctx.fillStyle = fill
  ctx.fill()
}

/** 画一个 iso 长方体；返回顶面四角与顶面中心（供屋顶细节用） */
function isoBox(
  ctx: Ctx2,
  toScreen: (x: number, y: number) => Pt,
  tx: number, ty: number, w: number, h: number,
  heightPx: number,
  colors: { top: string; left: string; right: string },
  opts?: { windows?: number; litFrac?: number; seed?: number; stroke?: boolean },
) {
  const N = toScreen(tx, ty)
  const E = toScreen(tx + w, ty)
  const S = toScreen(tx + w, ty + h)
  const W = toScreen(tx, ty + h)
  const up = (p: Pt): Pt => ({ x: p.x, y: p.y - heightPx })
  const Nt = up(N), Et = up(E), St = up(S), Wt = up(W)

  // 左面（W-S）右面（E-S）
  quad(ctx, Wt, St, S, W, colors.left)
  quad(ctx, Et, St, S, E, colors.right)
  quad(ctx, Nt, Et, St, Wt, colors.top)

  if (opts?.stroke) {
    ctx.strokeStyle = 'rgba(0,0,0,0.18)'
    ctx.lineWidth = 1
    ctx.beginPath()
    ctx.moveTo(Nt.x, Nt.y); ctx.lineTo(Et.x, Et.y); ctx.lineTo(St.x, St.y); ctx.lineTo(Wt.x, Wt.y)
    ctx.closePath(); ctx.stroke()
  }

  // 窗户（左右两面）
  if (opts?.windows && opts.windows > 0) {
    const rows = Math.max(1, Math.round(heightPx / (FLOOR_H * 0.8)))
    windowsOnFace(ctx, Wt, St, S, W, opts.windows, rows, opts.litFrac ?? 0, (opts.seed ?? 0) + 1)
    windowsOnFace(ctx, Et, St, S, E, opts.windows, rows, opts.litFrac ?? 0, (opts.seed ?? 0) + 7)
  }
  return { N: Nt, E: Et, S: St, W: Wt, center: lerp(lerp(Nt, St, 0.5), lerp(Et, Wt, 0.5), 0.5) }
}

/** 在竖直面上铺窗户网格；litFrac>0 时部分窗亮灯 */
function windowsOnFace(
  ctx: Ctx2, tl: Pt, tr: Pt, br: Pt, bl: Pt,
  cols: number, rows: number, litFrac: number, seed: number,
) {
  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      const h1 = hashStr(`w${seed}-${r}-${c}`)
      const lit = h1 < litFrac
      const dark = h1 > 0.82
      const f0 = c / cols + 0.12 / cols * cols / cols
      const f1 = (c + 0.62) / cols
      const g0 = r / rows + 0.18 / rows
      const g1 = (r + 0.62) / rows
      const topA = lerp(lerp(tl, tr, f0), lerp(tl, tr, f0), 0)
      const p00 = lerp(lerp(tl, tr, f0), lerp(bl, br, f0), g0)
      const p10 = lerp(lerp(tl, tr, f1), lerp(bl, br, f1), g0)
      const p11 = lerp(lerp(tl, tr, f1), lerp(bl, br, f1), g1)
      const p01 = lerp(lerp(tl, tr, f0), lerp(bl, br, f0), g1)
      void topA
      ctx.beginPath()
      ctx.moveTo(p00.x, p00.y); ctx.lineTo(p10.x, p10.y); ctx.lineTo(p11.x, p11.y); ctx.lineTo(p01.x, p01.y)
      ctx.closePath()
      ctx.fillStyle = lit ? 'rgba(255,205,110,0.95)' : dark ? 'rgba(15,25,40,0.55)' : 'rgba(200,220,235,0.4)'
      ctx.fill()
    }
  }
}

function drawBuilding(
  ctx: Ctx2, _sim: SimState, view: ViewState,
  toScreen: (x: number, y: number) => Pt,
  b: Building, t: number, dl: number,
) {
  const a = archetype(b.archetype)
  const z = view.zoom
  const seed = hashStr(b.id)
  const night = dl < 0.35
  const litFrac = night ? 0.45 : dl < 0.6 ? 0.15 : 0

  // 施工/拆除中的高度系数
  let rise = b.progress
  if (b.demolish > 0) rise = b.demolish
  rise = easeOut(Math.max(0.02, rise))
  const heightPx = a.floors * FLOOR_H * z * rise

  // 选中高亮
  const selected = view.selectedId === b.id

  // 基座阴影
  const cS = toScreen(b.tx + a.w / 2, b.ty + a.h / 2)
  ctx.fillStyle = 'rgba(0,0,0,0.15)'
  ctx.beginPath()
  ctx.ellipse(cS.x + 4 * z, cS.y + 2 * z, a.w * HW * z * 0.8, a.h * HH * z * 0.8, 0, 0, Math.PI * 2)
  ctx.fill()

  if (b.progress < 1 && b.demolish <= 0) drawScaffold(ctx, toScreen, b.tx, b.ty, a.w, a.h, z, t)

  let topCenter: Pt = cS
  const win = Math.max(2, Math.round(a.w * 2))

  switch (a.style) {
    case 'hall': {
      const r = isoBox(ctx, toScreen, b.tx, b.ty, a.w, a.h, heightPx,
        { top: '#e8e0cf', left: '#b8ad97', right: '#9a9080' },
        { windows: win, litFrac, seed, stroke: true })
      topCenter = r.center
      // 三角山墙（前檐）
      const peak = { x: r.center.x, y: r.center.y - 10 * z * rise }
      ctx.fillStyle = '#8a4f3a'
      ctx.beginPath()
      ctx.moveTo(r.W.x, r.W.y); ctx.lineTo(r.S.x, r.S.y); ctx.lineTo(peak.x, peak.y)
      ctx.closePath(); ctx.fill()
      // 柱廊
      ctx.strokeStyle = 'rgba(250,246,235,0.9)'
      ctx.lineWidth = 2.2 * z
      for (let i = 1; i <= 3; i++) {
        const base = lerp(r.W, r.S, i / 4)
        ctx.beginPath()
        ctx.moveTo(base.x, base.y)
        ctx.lineTo(base.x, base.y + 8 * z)
        ctx.stroke()
      }
      // 旗
      flag(ctx, peak.x, peak.y, z, t, '#d4553a')
      break
    }
    case 'tower':
    case 'custom-tower': {
      const main = a.style === 'tower'
        ? { top: '#bcd8e8', left: '#6f9cbd', right: '#54799a' }
        : { top: '#d8c8e8', left: '#9a7fbd', right: '#7a619a' }
      // 主体 + 退台
      isoBox(ctx, toScreen, b.tx, b.ty + 0.6, a.w, a.h - 0.6, heightPx,
        main, { windows: win + 1, litFrac, seed, stroke: true })
      const r2 = isoBox(ctx, toScreen, b.tx + 0.3, b.ty, a.w - 0.3, 0.6, heightPx + 8 * z * rise,
        { top: shade(main.top, 1.05), left: shade(main.left, 0.95), right: shade(main.right, 0.95) },
        { windows: win, litFrac, seed: seed + 3 })
      topCenter = { x: r2.center.x, y: r2.center.y - 8 * z * rise }
      // 玻璃高光
      ctx.fillStyle = 'rgba(255,255,255,0.12)'
      ctx.beginPath()
      ctx.moveTo(r2.N.x, r2.N.y); ctx.lineTo(r2.E.x, r2.E.y); ctx.lineTo(r2.S.x, r2.S.y); ctx.lineTo(r2.W.x, r2.W.y)
      ctx.closePath(); ctx.fill()
      // 天线
      ctx.strokeStyle = '#dfe8f0'
      ctx.lineWidth = 1.6 * z
      ctx.beginPath()
      ctx.moveTo(topCenter.x, topCenter.y)
      ctx.lineTo(topCenter.x, topCenter.y - 12 * z)
      ctx.stroke()
      const blink = (Math.sin(t * 2.5 + seed * 10) + 1) / 2
      ctx.fillStyle = `rgba(255,80,80,${0.4 + blink * 0.6})`
      ctx.beginPath()
      ctx.arc(topCenter.x, topCenter.y - 12 * z, 2 * z, 0, Math.PI * 2)
      ctx.fill()
      break
    }
    case 'lab':
    case 'custom-lab': {
      const col = a.style === 'lab'
        ? { top: '#d5e8dd', left: '#8fb8a0', right: '#729a84' }
        : { top: '#e8ddd0', left: '#b8a08f', right: '#9a8472' }
      const r = isoBox(ctx, toScreen, b.tx, b.ty, a.w, a.h, heightPx,
        col, { windows: win, litFrac, seed, stroke: true })
      topCenter = r.center
      // 屋顶设备
      if (rise > 0.9) {
        isoBox(ctx, toScreen, b.tx + 0.3, b.ty + 0.3, 0.6, 0.6, heightPx + 5 * z,
          { top: '#aab', left: '#889', right: '#778' })
        isoBox(ctx, toScreen, b.tx + a.w - 0.9, b.ty + 0.4, 0.5, 0.5, heightPx + 3.5 * z,
          { top: '#bba', left: '#998', right: '#877' })
      }
      break
    }
    case 'garden': {
      // 草地基座 + 温室穹顶
      isoBox(ctx, toScreen, b.tx, b.ty, a.w, a.h, 5 * z * rise,
        { top: '#69b56a', left: '#4d8a52', right: '#3f7345' })
      const c = toScreen(b.tx + a.w / 2, b.ty + a.h / 2)
      topCenter = { x: c.x, y: c.y - 18 * z * rise }
      if (rise > 0.5) {
        const domeH = 20 * z * rise
        const g = ctx.createLinearGradient(c.x, c.y - domeH, c.x, c.y)
        g.addColorStop(0, 'rgba(210,240,250,0.85)')
        g.addColorStop(1, 'rgba(150,200,220,0.45)')
        ctx.fillStyle = g
        ctx.beginPath()
        ctx.ellipse(c.x, c.y - 5 * z * rise, 16 * z, domeH * 0.8, 0, Math.PI, 0)
        ctx.fill()
        ctx.strokeStyle = 'rgba(255,255,255,0.6)'
        ctx.lineWidth = 1 * z
        for (let i = -2; i <= 2; i++) {
          ctx.beginPath()
          ctx.ellipse(c.x + i * 6 * z, c.y - 5 * z * rise, 3 * z, domeH * 0.75, 0, Math.PI, 0)
          ctx.stroke()
        }
      }
      // 小树点缀
      drawTree(ctx, toScreen(b.tx + 0.5, b.ty + a.h - 0.5).x, toScreen(b.tx + 0.5, b.ty + a.h - 0.5).y, z * 0.8, seed, t)
      break
    }
    case 'market': {
      // 棚架群：2×2 小摊
      const cols = ['#d4553a', '#e8a83a', '#3a8ad4', '#50b06a']
      let k = 0
      for (let i = 0; i < 2; i++)
        for (let j = 0; j < 2; j++) {
          const sw = a.w / 2 - 0.15
          const sd = a.h / 2 - 0.15
          const r = isoBox(ctx, toScreen, b.tx + i * a.w / 2 + 0.08, b.ty + j * a.h / 2 + 0.08,
            sw, sd, 7 * z * rise,
            { top: '#f0ead8', left: '#c8bfa8', right: '#aaa28c' }, { stroke: true })
          // 条纹雨棚
          const col = cols[(k++) % cols.length]
          ctx.fillStyle = col
          ctx.beginPath()
          ctx.moveTo(r.N.x, r.N.y); ctx.lineTo(r.E.x, r.E.y); ctx.lineTo(r.S.x, r.S.y); ctx.lineTo(r.W.x, r.W.y)
          ctx.closePath()
          ctx.globalAlpha = 0.85
          ctx.fill()
          ctx.globalAlpha = 1
          ctx.strokeStyle = 'rgba(255,255,255,0.5)'
          ctx.lineWidth = 1.5 * z
          ctx.beginPath()
          ctx.moveTo(lerp(r.N, r.W, 0.5).x, lerp(r.N, r.W, 0.5).y)
          ctx.lineTo(lerp(r.E, r.S, 0.5).x, lerp(r.E, r.S, 0.5).y)
          ctx.stroke()
        }
      topCenter = toScreen(b.tx + a.w / 2, b.ty + a.h / 2)
      break
    }
    case 'home':
    case 'custom-home': {
      // 双子：两个错落的坡顶体块
      const col = a.style === 'home'
        ? [{ top: '#f0d8c8', left: '#c89880', right: '#a87a64' }, { top: '#e8e0d0', left: '#b0a894', right: '#948c78' }]
        : [{ top: '#e0e8f0', left: '#98a8b8', right: '#7c8c9c' }]
      const hh = heightPx
      const r1 = isoBox(ctx, toScreen, b.tx, b.ty, a.w / 2, a.h, hh * 0.85,
        col[0], { windows: Math.max(2, win - 1), litFrac, seed, stroke: true })
      const r2 = isoBox(ctx, toScreen, b.tx + a.w / 2, b.ty + 0.3, a.w / 2, a.h - 0.3, hh,
        col[col.length - 1], { windows: Math.max(2, win - 1), litFrac, seed: seed + 5, stroke: true })
      topCenter = r2.center
      // 坡顶
      for (const r of [r1, r2]) {
        ctx.fillStyle = '#7a5240'
        ctx.beginPath()
        ctx.moveTo(r.N.x, r.N.y); ctx.lineTo(r.W.x, r.W.y)
        ctx.lineTo(r.S.x, r.S.y - 6 * z * rise)
        ctx.closePath(); ctx.fill()
        ctx.beginPath()
        ctx.moveTo(r.N.x, r.N.y); ctx.lineTo(r.E.x, r.E.y)
        ctx.lineTo(r.S.x, r.S.y - 6 * z * rise)
        ctx.closePath(); ctx.fillStyle = '#8a6248'; ctx.fill()
      }
      break
    }
    case 'radar': {
      const r = isoBox(ctx, toScreen, b.tx, b.ty, a.w, a.h, heightPx * 0.6,
        { top: '#d0d8e0', left: '#98a4b0', right: '#7e8a96' },
        { windows: win, litFrac, seed, stroke: true })
      topCenter = r.center
      if (rise > 0.6) {
        // 桅杆 + 旋转天线
        ctx.strokeStyle = '#cfd8e0'
        ctx.lineWidth = 2 * z
        ctx.beginPath()
        ctx.moveTo(r.center.x, r.center.y)
        ctx.lineTo(r.center.x, r.center.y - 22 * z)
        ctx.stroke()
        const ang = t * 1.4
        ctx.strokeStyle = '#5ec8e8'
        ctx.lineWidth = 3 * z
        ctx.beginPath()
        ctx.moveTo(r.center.x - Math.cos(ang) * 12 * z, r.center.y - 22 * z - Math.sin(ang) * 4 * z)
        ctx.lineTo(r.center.x + Math.cos(ang) * 12 * z, r.center.y - 22 * z + Math.sin(ang) * 4 * z)
        ctx.stroke()
        // 扫描波
        const wave = (t * 0.7 + seed) % 1
        ctx.strokeStyle = `rgba(94,200,232,${0.5 * (1 - wave)})`
        ctx.lineWidth = 1.5 * z
        ctx.beginPath()
        ctx.ellipse(r.center.x, r.center.y - 22 * z, 10 * z + wave * 22 * z, (10 * z + wave * 22 * z) * 0.35, 0, 0, Math.PI * 2)
        ctx.stroke()
      }
      break
    }
    case 'plaza-bld': {
      // 环廊：矮基座 + 周边柱列 + 中心旗/雕塑
      isoBox(ctx, toScreen, b.tx, b.ty, a.w, a.h, 4 * z * rise,
        { top: '#ddd6c4', left: '#b5ad99', right: '#98917d' }, { stroke: true })
      const c = toScreen(b.tx + a.w / 2, b.ty + a.h / 2)
      topCenter = { x: c.x, y: c.y - 14 * z * rise }
      if (rise > 0.4) {
        ctx.strokeStyle = 'rgba(250,246,235,0.95)'
        ctx.lineWidth = 2 * z
        const corners = [
          toScreen(b.tx + 0.3, b.ty + 0.3), toScreen(b.tx + a.w - 0.3, b.ty + 0.3),
          toScreen(b.tx + a.w - 0.3, b.ty + a.h - 0.3), toScreen(b.tx + 0.3, b.ty + a.h - 0.3),
        ]
        for (const p of corners) {
          ctx.beginPath()
          ctx.moveTo(p.x, p.y - 4 * z * rise)
          ctx.lineTo(p.x, p.y - 14 * z * rise)
          ctx.stroke()
        }
        // 中央喷泉：石盆 + 动画水柱
        const fx = c.x, fy = c.y - 4 * z * rise
        ctx.fillStyle = '#b8b0a0'
        ctx.beginPath()
        ctx.ellipse(fx, fy, 11 * z, 5.5 * z, 0, 0, Math.PI * 2)
        ctx.fill()
        ctx.fillStyle = '#3f8ab8'
        ctx.beginPath()
        ctx.ellipse(fx, fy - 1 * z, 8.5 * z, 4 * z, 0, 0, Math.PI * 2)
        ctx.fill()
        // 水柱（起伏）
        const jet = 6 * z + Math.sin(t * 3) * 2 * z
        ctx.strokeStyle = 'rgba(200,235,250,0.9)'
        ctx.lineWidth = 1.6 * z
        for (let i = -1; i <= 1; i++) {
          ctx.beginPath()
          ctx.moveTo(fx + i * 2.5 * z, fy - 1 * z)
          ctx.quadraticCurveTo(fx + i * 5 * z, fy - jet - 3 * z, fx + i * 6.5 * z, fy - 1 * z)
          ctx.stroke()
        }
        flag(ctx, c.x, c.y - 14 * z * rise, z, t, '#3a8ad4')
      }
      break
    }
    default: {
      isoBox(ctx, toScreen, b.tx, b.ty, a.w, a.h, heightPx,
        { top: '#d8d8d8', left: '#a8a8a8', right: '#8c8c8c' },
        { windows: win, litFrac, seed, stroke: true })
    }
  }

  // 夜晚整体压暗建筑（简单处理）
  if (night) {
    ctx.fillStyle = `rgba(20,30,60,${0.18 * (1 - dl / 0.35)})`
    const N = toScreen(b.tx, b.ty), E = toScreen(b.tx + a.w, b.ty),
      S = toScreen(b.tx + a.w, b.ty + a.h), W = toScreen(b.tx, b.ty + a.h)
    ctx.beginPath()
    ctx.moveTo(N.x, N.y - heightPx); ctx.lineTo(E.x, E.y - heightPx)
    ctx.lineTo(S.x, S.y); ctx.lineTo(W.x, W.y)
    ctx.closePath(); ctx.fill()
  }

  // 选中效果：脉动光圈 + 信标
  if (selected) {
    const pulse = (Math.sin(t * 4) + 1) / 2
    const N = toScreen(b.tx, b.ty), E = toScreen(b.tx + a.w, b.ty),
      S = toScreen(b.tx + a.w, b.ty + a.h), W = toScreen(b.tx, b.ty + a.h)
    ctx.strokeStyle = `rgba(255,210,90,${0.6 + pulse * 0.4})`
    ctx.lineWidth = 2.5 * z
    ctx.beginPath()
    ctx.moveTo(N.x, N.y); ctx.lineTo(E.x, E.y); ctx.lineTo(S.x, S.y); ctx.lineTo(W.x, W.y)
    ctx.closePath(); ctx.stroke()
    const c = toScreen(b.tx + a.w / 2, b.ty + a.h / 2)
    const g = ctx.createLinearGradient(c.x, c.y - 90 * z, c.x, c.y)
    g.addColorStop(0, 'rgba(255,210,90,0)')
    g.addColorStop(1, `rgba(255,210,90,${0.25 + pulse * 0.2})`)
    ctx.fillStyle = g
    ctx.fillRect(c.x - 14 * z, c.y - 90 * z, 28 * z, 90 * z)
  }

  // 名牌（市政建筑，缩放足够时）
  if (b.isCivic && z > 0.75) {
    const label = b.name
    ctx.font = `${Math.max(10, 11 * z)}px "PingFang SC", "Microsoft YaHei", sans-serif`
    const wTxt = ctx.measureText(label).width
    const ly = topCenter.y - 14 * z
    ctx.fillStyle = 'rgba(12,20,36,0.72)'
    roundRect(ctx, topCenter.x - wTxt / 2 - 6, ly - 9, wTxt + 12, 16, 8)
    ctx.fill()
    ctx.fillStyle = '#ffe9b8'
    ctx.textAlign = 'center'
    ctx.textBaseline = 'middle'
    ctx.fillText(label, topCenter.x, ly)
  }
}

function drawScaffold(
  ctx: Ctx2,
  toScreen: (x: number, y: number) => Pt,
  tx: number, ty: number, w: number, h: number,
  z: number, t: number,
) {
  const corners = [toScreen(tx, ty), toScreen(tx + w, ty), toScreen(tx + w, ty + h), toScreen(tx, ty + h)]
  ctx.strokeStyle = 'rgba(230,170,60,0.85)'
  ctx.lineWidth = 1.6 * z
  const H = 26 * z
  for (const p of corners) {
    ctx.beginPath()
    ctx.moveTo(p.x, p.y); ctx.lineTo(p.x, p.y - H)
    ctx.stroke()
  }
  for (let i = 0; i < 4; i++) {
    const a = corners[i], b = corners[(i + 1) % 4]
    ctx.beginPath()
    ctx.moveTo(a.x, a.y - H); ctx.lineTo(b.x, b.y - H)
    ctx.moveTo(a.x, a.y - H); ctx.lineTo(b.x, b.y)
    ctx.stroke()
  }
  // 施工尘雾
  const c = toScreen(tx + w / 2, ty + h / 2)
  for (let i = 0; i < 3; i++) {
    const ph = (t * 0.8 + i / 3) % 1
    ctx.fillStyle = `rgba(200,190,170,${0.25 * (1 - ph)})`
    ctx.beginPath()
    ctx.ellipse(c.x + Math.sin(i * 7 + t) * 14 * z, c.y - ph * 18 * z, 8 * z * (0.5 + ph), 4 * z * (0.5 + ph), 0, 0, Math.PI * 2)
    ctx.fill()
  }
}

function flag(ctx: Ctx2, x: number, y: number, z: number, t: number, color: string) {
  ctx.strokeStyle = '#e8e8e8'
  ctx.lineWidth = 1.5 * z
  ctx.beginPath()
  ctx.moveTo(x, y); ctx.lineTo(x, y - 14 * z)
  ctx.stroke()
  const wave = Math.sin(t * 5) * 2 * z
  ctx.fillStyle = color
  ctx.beginPath()
  ctx.moveTo(x, y - 14 * z)
  ctx.lineTo(x + 10 * z, y - 12 * z + wave)
  ctx.lineTo(x, y - 8 * z)
  ctx.closePath(); ctx.fill()
}

function roundRect(ctx: Ctx2, x: number, y: number, w: number, h: number, r: number) {
  ctx.beginPath()
  ctx.moveTo(x + r, y)
  ctx.arcTo(x + w, y, x + w, y + h, r)
  ctx.arcTo(x + w, y + h, x, y + h, r)
  ctx.arcTo(x, y + h, x, y, r)
  ctx.arcTo(x, y, x + w, y, r)
  ctx.closePath()
}

// ---------- Agent ----------
function drawAgent(
  ctx: Ctx2, _sim: SimState, view: ViewState,
  ag: Agent, sx: number, sy: number, z0: number, t: number,
) {
  const z = z0 * 1.5   // 角色整体放大，保证默认缩放可读
  const bobY = Math.abs(Math.sin(ag.bob)) * 2.2 * z
  const body = `hsl(${ag.hue}, 60%, 55%)`
  const bodyDark = `hsl(${ag.hue}, 55%, 40%)`
  const selected = view.selectedId === ag.id

  // 影
  ctx.fillStyle = 'rgba(0,0,0,0.25)'
  ctx.beginPath()
  ctx.ellipse(sx, sy + 1 * z, 5 * z, 2.2 * z, 0, 0, Math.PI * 2)
  ctx.fill()

  const y0 = sy - bobY
  // 腿（迈步）
  const step = Math.sin(ag.bob) * 3 * z
  ctx.strokeStyle = bodyDark
  ctx.lineWidth = 2 * z
  ctx.beginPath()
  ctx.moveTo(sx, y0 - 5 * z); ctx.lineTo(sx - step * 0.6, y0)
  ctx.moveTo(sx, y0 - 5 * z); ctx.lineTo(sx + step * 0.6, y0)
  ctx.stroke()
  // 身
  ctx.fillStyle = body
  ctx.beginPath()
  ctx.ellipse(sx, y0 - 8.5 * z, 4 * z, 5 * z, 0, 0, Math.PI * 2)
  ctx.fill()
  // 头
  ctx.fillStyle = '#f2d8b8'
  ctx.beginPath()
  ctx.arc(sx, y0 - 15 * z, 3.2 * z, 0, Math.PI * 2)
  ctx.fill()
  // 角色标识
  if (ag.role === 'mayor') {
    ctx.fillStyle = '#2c2c34'
    ctx.fillRect(sx - 3.4 * z, y0 - 21 * z, 6.8 * z, 4 * z)
    ctx.fillRect(sx - 4.6 * z, y0 - 17.6 * z, 9.2 * z, 1.6 * z)
  } else if (ag.role === 'worker') {
    ctx.fillStyle = '#f8c840'
    ctx.beginPath()
    ctx.arc(sx, y0 - 16.5 * z, 3.4 * z, Math.PI, 0)
    ctx.fill()
    ctx.fillRect(sx - 4 * z, y0 - 16.8 * z, 8 * z, 1.2 * z)
  } else if (ag.role === 'keeper') {
    ctx.fillStyle = '#3a6ad4'
    ctx.fillRect(sx + 2.6 * z, y0 - 11 * z, 3 * z, 4 * z)
  }

  if (selected) {
    const pulse = (Math.sin(t * 4) + 1) / 2
    ctx.strokeStyle = `rgba(255,210,90,${0.5 + pulse * 0.5})`
    ctx.lineWidth = 1.8 * z
    ctx.beginPath()
    ctx.ellipse(sx, sy, 8 * z, 3.6 * z, 0, 0, Math.PI * 2)
    ctx.stroke()
    // 路径
    if (ag.path.length > 1) {
      ctx.strokeStyle = 'rgba(255,210,90,0.5)'
      ctx.lineWidth = 1.5 * z
      ctx.setLineDash([4, 4])
      ctx.beginPath()
      for (let i = ag.pathIdx; i < ag.path.length; i++) {
        const wp = worldToScreen(ag.path[i].x, ag.path[i].y)
        const px = (wp.x - view.camX) * view.zoom
        const py = (wp.y - view.camY) * view.zoom
        if (i === ag.pathIdx) ctx.moveTo(sx, sy)
        ctx.lineTo(px + viewExtra.halfW, py + viewExtra.halfH)
      }
      ctx.stroke()
      ctx.setLineDash([])
    }
  }
}

/** 供 drawAgent 内路径投影使用的画布半尺寸（由 render 注入） */
const viewExtra = { halfW: 0, halfH: 0 }
export function setViewHalf(w: number, h: number) {
  viewExtra.halfW = w / 2
  viewExtra.halfH = h / 2
}

// ---------- 悬停 & 建造预览 ----------
function drawGhostAndHover(
  ctx: Ctx2, _sim: SimState, view: ViewState,
  toScreen: (x: number, y: number) => Pt, t: number,
) {
  const z = view.zoom
  if (view.hoverTile && !view.ghost) {
    const p = toScreen(view.hoverTile.x + 0.5, view.hoverTile.y + 0.5)
    diamond(ctx, p.x, p.y, z)
    ctx.strokeStyle = 'rgba(255,255,255,0.6)'
    ctx.lineWidth = 1.5
    ctx.stroke()
  }
  const g = view.ghost
  if (g) {
    const ok = g.valid
    const pulse = (Math.sin(t * 5) + 1) / 2
    for (let i = 0; i < g.w; i++)
      for (let j = 0; j < g.h; j++) {
        const p = toScreen(g.tx + i + 0.5, g.ty + j + 0.5)
        diamond(ctx, p.x, p.y, z)
        ctx.fillStyle = ok ? `rgba(90,220,130,${0.25 + pulse * 0.15})` : `rgba(230,70,70,${0.3 + pulse * 0.15})`
        ctx.fill()
        ctx.strokeStyle = ok ? 'rgba(90,220,130,0.9)' : 'rgba(230,70,70,0.9)'
        ctx.lineWidth = 1.4
        ctx.stroke()
      }
    // 幽灵体块
    if (ok && (g.w > 1 || g.h > 1)) {
      const c = toScreen(g.tx + g.w / 2, g.ty + g.h / 2)
      ctx.strokeStyle = 'rgba(90,220,130,0.7)'
      ctx.lineWidth = 1.5 * z
      ctx.setLineDash([4 * z, 4 * z])
      const H = 30 * z
      const corners = [toScreen(g.tx, g.ty), toScreen(g.tx + g.w, g.ty), toScreen(g.tx + g.w, g.ty + g.h), toScreen(g.tx, g.ty + g.h)]
      for (const p of corners) {
        ctx.beginPath(); ctx.moveTo(p.x, p.y); ctx.lineTo(p.x, p.y - H); ctx.stroke()
      }
      ctx.beginPath()
      for (let i = 0; i < 4; i++) {
        const a = corners[i], b = corners[(i + 1) % 4]
        ctx.moveTo(a.x, a.y - H); ctx.lineTo(b.x, b.y - H)
      }
      ctx.stroke()
      ctx.setLineDash([])
      void c
    }
  }
}

// ---------- 天气 ----------
const rainDrops: { x: number; y: number; v: number }[] = []
const snowFlakes: { x: number; y: number; v: number; ph: number }[] = []
const cloudShadows: { x: number; y: number; r: number; v: number }[] = []

function drawWeather(ctx: Ctx2, sim: SimState, vw: number, vh: number, t: number) {
  const kind: WeatherKind = sim.weather
  // 云影
  if (kind !== 'sunny') {
    if (cloudShadows.length === 0)
      for (let i = 0; i < 6; i++)
        cloudShadows.push({ x: Math.random() * vw, y: Math.random() * vh, r: 180 + Math.random() * 220, v: 8 + Math.random() * 14 })
    for (const c of cloudShadows) {
      c.x += c.v * 0.016
      if (c.x - c.r > vw) { c.x = -c.r; c.y = Math.random() * vh }
      const g = ctx.createRadialGradient(c.x, c.y, 0, c.x, c.y, c.r)
      g.addColorStop(0, 'rgba(30,40,70,0.16)')
      g.addColorStop(1, 'rgba(30,40,70,0)')
      ctx.fillStyle = g
      ctx.fillRect(c.x - c.r, c.y - c.r, c.r * 2, c.r * 2)
    }
  }
  if (kind === 'rain') {
    if (rainDrops.length < 160)
      for (let i = rainDrops.length; i < 160; i++)
        rainDrops.push({ x: Math.random() * vw, y: Math.random() * vh, v: 500 + Math.random() * 300 })
    ctx.strokeStyle = 'rgba(170,200,230,0.5)'
    ctx.lineWidth = 1.2
    ctx.beginPath()
    for (const d of rainDrops) {
      d.y += d.v * 0.016
      d.x -= d.v * 0.12 * 0.016
      if (d.y > vh) { d.y = -10; d.x = Math.random() * (vw + 100) }
      ctx.moveTo(d.x, d.y)
      ctx.lineTo(d.x - 2, d.y + 9)
    }
    ctx.stroke()
    ctx.fillStyle = 'rgba(120,150,190,0.12)'
    ctx.fillRect(0, 0, vw, vh)
  }
  if (kind === 'snow') {
    if (snowFlakes.length < 120)
      for (let i = snowFlakes.length; i < 120; i++)
        snowFlakes.push({ x: Math.random() * vw, y: Math.random() * vh, v: 30 + Math.random() * 40, ph: Math.random() * 6 })
    ctx.fillStyle = 'rgba(255,255,255,0.85)'
    for (const f of snowFlakes) {
      f.y += f.v * 0.016
      f.x += Math.sin(t + f.ph) * 0.5
      if (f.y > vh) { f.y = -5; f.x = Math.random() * vw }
      ctx.beginPath()
      ctx.arc(f.x, f.y, 1.8, 0, Math.PI * 2)
      ctx.fill()
    }
  }
  // 晴天的浮尘光斑
  if (kind === 'sunny') {
    for (let i = 0; i < 14; i++) {
      const px = (hashStr(`m${i}`) * vw + t * 6 * (i % 3 + 1)) % vw
      const py = hashStr(`n${i}`) * vh + Math.sin(t * 0.6 + i) * 14
      ctx.fillStyle = 'rgba(255,250,220,0.25)'
      ctx.beginPath()
      ctx.arc(px, py, 1.6, 0, Math.PI * 2)
      ctx.fill()
    }
  }
}

// ---------- 昼夜 ----------
function drawDayNight(ctx: Ctx2, _sim: SimState, vw: number, vh: number, dl: number) {
  // 黎明/黄昏暖调
  if (dl > 0 && dl < 0.45) {
    ctx.fillStyle = `rgba(255,140,60,${0.14 * (1 - dl / 0.45)})`
    ctx.fillRect(0, 0, vw, vh)
  }
  // 夜晚蓝调
  if (dl < 0.5) {
    const a = 0.42 * (1 - dl / 0.5)
    ctx.fillStyle = `rgba(8,14,40,${a})`
    ctx.fillRect(0, 0, vw, vh)
  }
  // 暗角
  const g = ctx.createRadialGradient(vw / 2, vh / 2, Math.min(vw, vh) * 0.42, vw / 2, vh / 2, Math.max(vw, vh) * 0.75)
  g.addColorStop(0, 'rgba(0,0,0,0)')
  g.addColorStop(1, 'rgba(0,0,0,0.28)')
  ctx.fillStyle = g
  ctx.fillRect(0, 0, vw, vh)
}

// ---------- 拾取 ----------
export function pickTile(
  _sim: SimState, view: ViewState, vw: number, vh: number,
  mx: number, my: number,
): { x: number; y: number } | null {
  const sx = (mx - vw / 2) / view.zoom + view.camX
  const sy = (my - vh / 2) / view.zoom + view.camY
  const wx = (sx / HW + sy / HH) / 2
  const wy = (sy / HH - sx / HW) / 2
  const tx = Math.floor(wx)
  const ty = Math.floor(wy)
  if (tx < 0 || ty < 0 || tx >= COLS || ty >= ROWS) return null
  return { x: tx, y: ty }
}

export function buildingAt(sim: SimState, tx: number, ty: number): Building | undefined {
  const id = sim.world.tiles[ty]?.[tx]?.buildingId
  return id ? sim.world.buildings.find(b => b.id === id) : undefined
}

export function agentNear(
  sim: SimState, view: ViewState, vw: number, vh: number,
  mx: number, my: number,
): Agent | null {
  for (const ag of sim.agents) {
    if (ag.state === 'inside') continue
    const p = worldToScreen(ag.x, ag.y)
    const sx = (p.x - view.camX) * view.zoom + vw / 2
    const sy = (p.y - view.camY) * view.zoom + vh / 2 - 10 * view.zoom
    if (Math.hypot(mx - sx, my - sy) < 14) return ag
  }
  return null
}

export { riverCenter }

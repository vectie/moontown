// ============================================================
// 搭建系统 —— 校验、计价、放置、拆除、铺路、造林
// 规则：
//  - 建筑需落在草地/广场，不压水、不压路、不压既有建筑
//  - 建筑需与既有路网相邻（保持小镇"沿路生长"的秩序感）
//  - 道路只能替换草地/树林；跨河自动成桥（高价）
//  - 公园把草地变成树林；拆除返还一半造价（初始市政建筑不可拆）
// ============================================================

import { archetype, COLS, nextBuildingId, ROWS, type World } from './world'
import { findPath } from './pathfind'
import type { Building } from './types'
import { pushEvent, type SimState } from './sim'

export const COSTS = {
  road: 30,
  bridgeRoad: 120,
  park: 20,
}

export interface CheckResult {
  valid: boolean
  reason?: string
  cost: number
}

function tileOf(w: World, x: number, y: number) {
  return w.tiles[y]?.[x]
}

/** 建筑落位校验 */
export function checkBuilding(sim: SimState, archId: string, tx: number, ty: number): CheckResult {
  const a = archetype(archId)
  const w = sim.world
  let adjacentRoad = false
  for (let x = tx; x < tx + a.w; x++) {
    for (let y = ty; y < ty + a.h; y++) {
      const t = tileOf(w, x, y)
      if (!t) return { valid: false, reason: '超出城区边界', cost: a.cost }
      if (t.buildingId) return { valid: false, reason: '与既有建筑冲突', cost: a.cost }
      if (t.terrain === 'water' || t.terrain === 'bridge')
        return { valid: false, reason: '不能建在温榆河上', cost: a.cost }
      if (t.terrain === 'road') return { valid: false, reason: '不能压在道路上', cost: a.cost }
      if (t.terrain === 'forest') return { valid: false, reason: '需先清理林地', cost: a.cost }
      if (t.terrain !== 'grass' && t.terrain !== 'plaza')
        return { valid: false, reason: '仅可建在草地或广场', cost: a.cost }
    }
  }
  // 邻接道路
  outer:
  for (let x = tx - 1; x <= tx + a.w; x++) {
    for (let y = ty - 1; y <= ty + a.h; y++) {
      const onEdge = x === tx - 1 || x === tx + a.w || y === ty - 1 || y === ty + a.h
      if (!onEdge) continue
      const t = tileOf(w, x, y)
      if (t && (t.terrain === 'road' || t.terrain === 'bridge')) { adjacentRoad = true; break outer }
    }
  }
  if (!adjacentRoad) return { valid: false, reason: '需要与道路相邻', cost: a.cost }
  if (sim.metrics.budget < a.cost) return { valid: false, reason: '预算不足', cost: a.cost }
  return { valid: true, cost: a.cost }
}

export function placeBuilding(sim: SimState, archId: string, tx: number, ty: number): Building | null {
  const chk = checkBuilding(sim, archId, tx, ty)
  if (!chk.valid) return null
  const a = archetype(archId)
  const b: Building = {
    id: nextBuildingId(),
    archetype: archId, name: a.name,
    tx, ty, progress: 0, demolish: 0,
    isCivic: false,
    occupants: 0, vitality: 40, builtin: false,
  }
  for (let x = tx; x < tx + a.w; x++)
    for (let y = ty; y < ty + a.h; y++)
      sim.world.tiles[y][x].buildingId = b.id
  sim.world.buildings.push(b)
  sim.metrics.budget -= a.cost
  sim.buildFlash.push({ tx, ty, t: 1 })
  pushEvent(sim, '🏗️', `${a.name} 破土动工（-${a.cost}）`, 'info')
  return b
}

/** 铺路校验（单格） */
export function checkRoad(sim: SimState, tx: number, ty: number): CheckResult {
  const t = tileOf(sim.world, tx, ty)
  if (!t) return { valid: false, reason: '超出边界', cost: COSTS.road }
  if (t.buildingId) return { valid: false, reason: '先拆除建筑', cost: COSTS.road }
  if (t.terrain === 'road' || t.terrain === 'bridge') return { valid: false, reason: '已是道路', cost: COSTS.road }
  if (t.terrain !== 'grass' && t.terrain !== 'forest' && t.terrain !== 'water')
    return { valid: false, reason: '道路仅可铺在草地、林地或河面', cost: COSTS.road }
  const cost = t.terrain === 'water' ? COSTS.bridgeRoad : COSTS.road
  if (sim.metrics.budget < cost) return { valid: false, reason: '预算不足', cost }
  return { valid: true, cost }
}

export function placeRoad(sim: SimState, tx: number, ty: number): boolean {
  const chk = checkRoad(sim, tx, ty)
  if (!chk.valid) return false
  const t = sim.world.tiles[ty][tx]
  t.terrain = t.terrain === 'water' ? 'bridge' : 'road'
  refreshRoadMask(sim.world, tx, ty)
  sim.metrics.budget -= chk.cost
  if (t.terrain === 'bridge') pushEvent(sim, '🌉', `新桥贯通温榆河（-${chk.cost}）`, 'good')
  return true
}

/** 公园（造林） */
export function checkPark(sim: SimState, tx: number, ty: number): CheckResult {
  const t = tileOf(sim.world, tx, ty)
  if (!t) return { valid: false, reason: '超出边界', cost: COSTS.park }
  if (t.buildingId || t.terrain !== 'grass') return { valid: false, reason: '仅可改造草地', cost: COSTS.park }
  if (sim.metrics.budget < COSTS.park) return { valid: false, reason: '预算不足', cost: COSTS.park }
  return { valid: true, cost: COSTS.park }
}

export function placePark(sim: SimState, tx: number, ty: number): boolean {
  const chk = checkPark(sim, tx, ty)
  if (!chk.valid) return false
  sim.world.tiles[ty][tx].terrain = 'forest'
  sim.metrics.budget -= COSTS.park
  sim.metrics.vitality = Math.min(100, sim.metrics.vitality + 0.8)
  return true
}

/** 拆除 */
export function demolishAt(sim: SimState, tx: number, ty: number): boolean {
  const w = sim.world
  const t = tileOf(w, tx, ty)
  if (!t) return false
  if (t.buildingId) {
    const b = w.buildings.find(x => x.id === t.buildingId)
    if (!b || b.builtin) {
      if (b?.builtin) pushEvent(sim, '⛔', '市政协议建筑不可拆除', 'warn')
      return false
    }
    const a = archetype(b.archetype)
    const refund = Math.round(a.cost * 0.5)
    for (let x = b.tx; x < b.tx + a.w; x++)
      for (let y = b.ty; y < b.ty + a.h; y++)
        if (w.tiles[y]?.[x]?.buildingId === b.id) w.tiles[y][x].buildingId = undefined
    w.buildings = w.buildings.filter(x => x.id !== b.id)
    sim.metrics.budget += refund
    sim.metrics.servicesActive = w.buildings.filter(x => x.progress >= 1).length
    pushEvent(sim, '🧹', `${b.name} 已拆除（+${refund}）`, 'info')
    return true
  }
  if (t.terrain === 'road' || t.terrain === 'bridge') {
    t.terrain = t.terrain === 'bridge' ? 'water' : 'grass'
    refreshRoadMask(sim.world, tx, ty)
    return true
  }
  if (t.terrain === 'forest') { t.terrain = 'grass'; return true }
  return false
}

/** 重算某格及周边的道路连接掩码 */
export function refreshRoadMask(w: World, tx: number, ty: number) {
  for (let y = Math.max(0, ty - 1); y <= Math.min(ROWS - 1, ty + 1); y++)
    for (let x = Math.max(0, tx - 1); x <= Math.min(COLS - 1, tx + 1); x++) {
      const t = w.tiles[y][x]
      if (t.terrain !== 'road' && t.terrain !== 'bridge') continue
      let m = 0
      const walk = (xx: number, yy: number) =>
        w.tiles[yy]?.[xx] && (w.tiles[yy][xx].terrain === 'road' || w.tiles[yy][xx].terrain === 'bridge')
      if (walk(x, y - 1)) m |= 1
      if (walk(x + 1, y)) m |= 2
      if (walk(x, y + 1)) m |= 4
      if (walk(x - 1, y)) m |= 8
      t.roadDir = m
    }
}

/** 全图道路掩码刷新（存档恢复用） */
export function refreshAllRoadMasks(w: World) {
  for (let y = 0; y < ROWS; y++)
    for (let x = 0; x < COLS; x++) refreshRoadMask(w, x, y)
}

/** 新铺路是否与旧网连通（用于提示，不强制） */
export function roadConnected(sim: SimState, tx: number, ty: number): boolean {
  const w = sim.world
  // 找到任一既有道路
  let anyRoad: { x: number; y: number } | null = null
  outer:
  for (let y = 0; y < ROWS; y++)
    for (let x = 0; x < COLS; x++) {
      const t = w.tiles[y][x]
      if (t.terrain === 'road' || t.terrain === 'bridge') { anyRoad = { x, y }; break outer }
    }
  if (!anyRoad) return true
  if (tx === anyRoad.x && ty === anyRoad.y) return true
  return findPath(w, tx, ty, anyRoad.x, anyRoad.y) !== null
}

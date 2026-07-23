// ============================================================
// 世界生成 —— 参考昌平未来科学城「能源谷」：
// 温榆河蜿蜒穿城，两座桥连接两岸，东岸为能源谷核心建成区，
// 西岸为温榆河公园绿带。11 座市政协议建筑对应 moontown 的
// civic module（Town Shell / Vitality Tower / AI Garden …）。
// ============================================================

import type { Building, BuildingArchetype, Tile } from './types'

export const COLS = 44
export const ROWS = 44

// ---------- 建筑原型表 ----------
export const ARCHETYPES: BuildingArchetype[] = [
  { id: 'town-shell',  name: '市政厅',     glyph: '政', w: 3, h: 3, floors: 2, style: 'hall',      cost: 0,    desc: 'Town Shell · 全镇协议中枢' },
  { id: 'vitality',    name: '活力塔',     glyph: '塔', w: 2, h: 2, floors: 7, style: 'tower',     cost: 0,    desc: 'Vitality Tower · 活力信号守望' },
  { id: 'ai-garden',   name: 'AI科学花园', glyph: '园', w: 3, h: 3, floors: 1, style: 'garden',    cost: 0,    desc: 'AI Garden · 学习共同体' },
  { id: 'talent',      name: '人才大道',   glyph: '才', w: 3, h: 2, floors: 3, style: 'plaza-bld', cost: 0,    desc: 'Talent Avenue · 人才撮合市集' },
  { id: 'contest',     name: '众创大厅',   glyph: '创', w: 2, h: 2, floors: 3, style: 'lab',       cost: 0,    desc: 'Contest Express · 赛事评审议会' },
  { id: 'policy',      name: '政策大厅',   glyph: '策', w: 2, h: 2, floors: 2, style: 'hall',      cost: 0,    desc: 'Policy Hall · 政策分诊台' },
  { id: 'social',      name: '社交广场',   glyph: '交', w: 3, h: 3, floors: 1, style: 'plaza-bld', cost: 0,    desc: 'Social Square · 研究沙龙' },
  { id: 'market',      name: '山谷市集',   glyph: '市', w: 3, h: 2, floors: 1, style: 'market',    cost: 0,    desc: 'Valley Market · 资源撮合' },
  { id: 'twins',       name: '居民双子楼', glyph: '居', w: 2, h: 2, floors: 4, style: 'home',      cost: 0,    desc: 'Resident Twins · 数字分身之家' },
  { id: 'radar',       name: '故事雷达',   glyph: '雷达', w: 2, h: 2, floors: 2, style: 'radar',   cost: 0,    desc: 'Story Radar · 叙事锻造' },
  // —— 搭建模式可选 ——
  { id: 'c-tower', name: '研发塔楼', glyph: '研', w: 2, h: 2, floors: 5, style: 'custom-tower', cost: 800,  desc: '高层研发办公' },
  { id: 'c-lab',   name: '实验室',   glyph: '实', w: 2, h: 2, floors: 2, style: 'custom-lab',   cost: 500,  desc: '中试与实验空间' },
  { id: 'c-hall',  name: '创新工坊', glyph: '坊', w: 2, h: 2, floors: 2, style: 'custom-hall',  cost: 400,  desc: '低层创客空间' },
  { id: 'c-home',  name: '人才公寓', glyph: '寓', w: 2, h: 2, floors: 3, style: 'custom-home',  cost: 350,  desc: '居住配套' },
]

export function archetype(id: string): BuildingArchetype {
  return ARCHETYPES.find(a => a.id === id) ?? ARCHETYPES[0]
}

// ---------- 河流 ----------
/** 河道中心行（随 tx 蜿蜒），±3 的摆幅保证两岸道路不与之相交 */
export function riverCenter(tx: number): number {
  return 19 + 2.6 * Math.sin(tx / 5.2) + 1.2 * Math.sin(tx / 2.1 + 1.7)
}
export const RIVER_HALF = 1.6 // 半宽（tile）

export function isRiver(tx: number, ty: number): boolean {
  if (tx < 0 || tx >= COLS) return false
  return Math.abs(ty - riverCenter(tx)) <= RIVER_HALF
}

// ---------- 道路 ----------
export const BRIDGE_STREETS = [10, 30]      // 两条跨河桥街
const EAST_AVE = 26                          // 东岸能源大道
const EAST_AVE2 = 35                         // 东岸次干道
const WEST_AVE = 12                          // 西岸滨河路
const EAST_CROSS = [20, 38]                  // 东岸纵街（不跨河）
const WEST_CROSS = [4]                       // 西岸纵街

export function isRoad(tx: number, ty: number): boolean {
  if (tx < 0 || tx >= COLS || ty < 0 || ty >= ROWS) return false
  if (BRIDGE_STREETS.includes(tx)) return true                      // 桥街全贯通
  if (ty === EAST_AVE && tx >= 6 && tx <= 42) return true
  if (ty === EAST_AVE2 && tx >= 8 && tx <= 42) return true
  if (ty === WEST_AVE && tx >= 2 && tx <= 40) return true
  if (EAST_CROSS.includes(tx) && ty >= EAST_AVE && ty <= 41) return true
  if (WEST_CROSS.includes(tx) && ty >= 4 && ty <= WEST_AVE) return true
  return false
}

/** 可行走（道路或桥） */
export function isWalkable(tx: number, ty: number): boolean {
  return isRoad(tx, ty)
}

// ---------- 世界 ----------
export interface World {
  tiles: Tile[][]
  buildings: Building[]
}

let bidSeq = 0

function placeCivic(
  tiles: Tile[][],
  list: Building[],
  archId: string, tx: number, ty: number, moduleKey: string,
) {
  const a = archetype(archId)
  const b: Building = {
    id: `civic-${moduleKey}`,
    archetype: archId, name: a.name,
    tx, ty, progress: 1, demolish: 0,
    isCivic: true, moduleKey,
    occupants: 0, vitality: 55 + Math.random() * 30, builtin: true,
  }
  for (let x = tx; x < tx + a.w; x++)
    for (let y = ty; y < ty + a.h; y++)
      if (tiles[y]?.[x]) tiles[y][x].buildingId = b.id
  list.push(b)
}

export function createWorld(): World {
  const tiles: Tile[][] = []
  for (let y = 0; y < ROWS; y++) {
    const row: Tile[] = []
    for (let x = 0; x < COLS; x++) {
      row.push({ terrain: 'grass' })
    }
    tiles.push(row)
  }

  // 河流
  for (let x = 0; x < COLS; x++) {
    const c = riverCenter(x)
    for (let y = 0; y < ROWS; y++) {
      if (Math.abs(y - c) <= RIVER_HALF) {
        tiles[y][x].terrain = 'water'
        tiles[y][x].riverFlow = x * 0.55 + (y - c) * 0.3
      }
    }
  }

  // 道路（桥街在河面上的部分标记为 bridge）
  for (let y = 0; y < ROWS; y++)
    for (let x = 0; x < COLS; x++) {
      if (isRoad(x, y)) {
        tiles[y][x].terrain = tiles[y][x].terrain === 'water' ? 'bridge' : 'road'
      }
    }

  // 道路连接掩码
  for (let y = 0; y < ROWS; y++)
    for (let x = 0; x < COLS; x++) {
      const t = tiles[y][x]
      if (t.terrain !== 'road' && t.terrain !== 'bridge') continue
      let m = 0
      const walk = (xx: number, yy: number) =>
        tiles[yy]?.[xx] && (tiles[yy][xx].terrain === 'road' || tiles[yy][xx].terrain === 'bridge')
      if (walk(x, y - 1)) m |= 1
      if (walk(x + 1, y)) m |= 2
      if (walk(x, y + 1)) m |= 4
      if (walk(x - 1, y)) m |= 8
      t.roadDir = m
    }

  // 温榆河公园绿带（西岸 & 河岸林带）
  const treeRand = mulberry(42)
  for (let y = 0; y < ROWS; y++)
    for (let x = 0; x < COLS; x++) {
      const t = tiles[y][x]
      if (t.terrain !== 'grass') continue
      const dRiver = Math.abs(y - riverCenter(x)) - RIVER_HALF
      const nearRiver = dRiver < 2.2
      const westPark = x >= 2 && x <= 40 && y >= 4 && y < WEST_AVE - 0.5
      if ((nearRiver && treeRand() < 0.4) || (westPark && treeRand() < 0.34) || treeRand() < 0.045) {
        t.terrain = 'forest'
      }
    }

  // 市政建筑落位（东岸核心区 + 西岸点缀）
  const buildings: Building[] = []
  placeCivic(tiles, buildings, 'town-shell', 12, 27, 'town-shell')             // 市政厅 · 能源大道北
  placeCivic(tiles, buildings, 'vitality', 16, 28, 'vitality-tower')           // 活力塔
  placeCivic(tiles, buildings, 'policy', 12, 31, 'policy-hall')                // 政策大厅
  placeCivic(tiles, buildings, 'talent', 16, 32, 'talent-avenue')              // 人才大道
  placeCivic(tiles, buildings, 'contest', 21, 27, 'contest-express')           // 众创大厅
  placeCivic(tiles, buildings, 'social', 24, 28, 'social-square')              // 社交广场
  placeCivic(tiles, buildings, 'market', 21, 31, 'valley-market')              // 山谷市集
  placeCivic(tiles, buildings, 'ai-garden', 31, 27, 'ai-garden')               // AI 科学花园
  placeCivic(tiles, buildings, 'twins', 31, 31, 'resident-twins')              // 居民双子楼
  placeCivic(tiles, buildings, 'twins', 36, 27, 'resident-twins-b')            // 双子楼 B 座
  placeCivic(tiles, buildings, 'radar', 34, 36, 'story-radar')                 // 故事雷达
  placeCivic(tiles, buildings, 'c-lab', 26, 36, 'energy-lab')                  // 能源实验室（配套）
  placeCivic(tiles, buildings, 'c-home', 39, 31, 'talent-flat')                // 人才公寓（配套）

  // 市政厅前广场
  for (let x = 11; x <= 15; x++)
    for (let y = 25; y <= 25; y++)
      if (tiles[y]?.[x] && tiles[y][x].terrain === 'grass') tiles[y][x].terrain = 'plaza'
  for (let x = 23; x <= 27; x++)
    for (let y = 25; y <= 25; y++)
      if (tiles[y]?.[x] && tiles[y][x].terrain === 'grass') tiles[y][x].terrain = 'plaza'

  return { tiles, buildings }
}

export function nextBuildingId() {
  return `user-${++bidSeq}-${Date.now() % 100000}`
}

/** 简单可复现随机 */
export function mulberry(seed: number) {
  let a = seed
  return () => {
    a |= 0; a = (a + 0x6d2b79f5) | 0
    let t = Math.imul(a ^ (a >>> 15), 1 | a)
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

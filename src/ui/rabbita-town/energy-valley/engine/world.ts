// ============================================================
// Energy Valley procedural grammar
//
// The authored Wenyu Valley reference is treated as a planning grammar:
// river corridor + tributary + wetland lake, dense civic grid, farm belt,
// forest buffers, satellite clusters, and bridge-linked districts.
// A seed varies the geometry while preserving those relationships.
// ============================================================

import type {
  AmbientStructure,
  Building,
  BuildingArchetype,
  Terrain,
  Tile,
  ValleyDistrict,
} from './types'

export const COLS = 56
export const ROWS = 52
export const DEFAULT_VALLEY_SEED = 20260727

export const ARCHETYPES: BuildingArchetype[] = [
  { id: 'town-shell', name: '市政厅', glyph: '政', w: 3, h: 3, floors: 2, style: 'hall', cost: 0, desc: 'Town Shell · 全镇协议中枢' },
  { id: 'vitality', name: '活力塔', glyph: '塔', w: 2, h: 2, floors: 7, style: 'tower', cost: 0, desc: 'Vitality Tower · 活力信号守望' },
  { id: 'ai-garden', name: 'AI科学花园', glyph: '园', w: 3, h: 3, floors: 1, style: 'garden', cost: 0, desc: 'AI Garden · 学习共同体' },
  { id: 'talent', name: '人才大道', glyph: '才', w: 3, h: 2, floors: 3, style: 'plaza-bld', cost: 0, desc: 'Talent Avenue · 人才撮合市集' },
  { id: 'contest', name: '众创大厅', glyph: '创', w: 2, h: 2, floors: 3, style: 'lab', cost: 0, desc: 'Contest Express · 赛事评审议会' },
  { id: 'policy', name: '政策大厅', glyph: '策', w: 2, h: 2, floors: 2, style: 'hall', cost: 0, desc: 'Policy Hall · 政策分诊台' },
  { id: 'social', name: '社交广场', glyph: '交', w: 3, h: 3, floors: 1, style: 'plaza-bld', cost: 0, desc: 'Social Square · 研究沙龙' },
  { id: 'market', name: '山谷市集', glyph: '市', w: 3, h: 2, floors: 1, style: 'market', cost: 0, desc: 'Valley Market · 资源撮合' },
  { id: 'twins', name: '居民双子楼', glyph: '居', w: 2, h: 2, floors: 4, style: 'home', cost: 0, desc: 'Resident Twins · 数字分身之家' },
  { id: 'radar', name: '故事雷达', glyph: '雷达', w: 2, h: 2, floors: 2, style: 'radar', cost: 0, desc: 'Story Radar · 叙事锻造' },
  { id: 'c-tower', name: '研发塔楼', glyph: '研', w: 2, h: 2, floors: 5, style: 'custom-tower', cost: 800, desc: '高层研发办公' },
  { id: 'c-lab', name: '实验室', glyph: '实', w: 2, h: 2, floors: 2, style: 'custom-lab', cost: 500, desc: '中试与实验空间' },
  { id: 'c-hall', name: '创新工坊', glyph: '坊', w: 2, h: 2, floors: 2, style: 'custom-hall', cost: 400, desc: '低层创客空间' },
  { id: 'c-home', name: '人才公寓', glyph: '寓', w: 2, h: 2, floors: 3, style: 'custom-home', cost: 350, desc: '居住配套' },
]

export function archetype(id: string): BuildingArchetype {
  return ARCHETYPES.find(a => a.id === id) ?? ARCHETYPES[0]
}

export interface ValleyLandmarks {
  civicCore: { x: number; y: number }
  lake: { x: number; y: number; rx: number; ry: number }
  bridgeRows: number[]
  mainRiverMeanX: number
}

export interface World {
  seed: number
  tiles: Tile[][]
  buildings: Building[]
  landmarks: ValleyLandmarks
}

interface Grammar {
  seed: number
  phase: number
  phase2: number
  riverMeanX: number
  riverAmplitude: number
  lakeX: number
  lakeY: number
  lakeRx: number
  lakeRy: number
  tributaryBaseY: number
  bridgeRows: number[]
  civicCore: { x: number; y: number }
}

interface CivicPlacement {
  archetype: string
  moduleKey: string
  district: ValleyDistrict
  anchorX: number
  anchorY: number
}

let bidSeq = 0

export function normalizeSeed(seed: number): number {
  if (!Number.isFinite(seed)) return DEFAULT_VALLEY_SEED
  const normalized = Math.abs(Math.trunc(seed)) >>> 0
  return normalized || DEFAULT_VALLEY_SEED
}

export function valleySeedLabel(seed: number): string {
  return normalizeSeed(seed).toString(36).toUpperCase().padStart(6, '0').slice(-6)
}

function grammarFor(seed: number): Grammar {
  const normalized = normalizeSeed(seed)
  const random = mulberry(normalized)
  const jitter = (amount: number) => (random() * 2 - 1) * amount
  const bridgeA = 11 + Math.round(jitter(2))
  const bridgeB = 27 + Math.round(jitter(2))
  const bridgeC = 42 + Math.round(jitter(2))
  return {
    seed: normalized,
    phase: random() * Math.PI * 2,
    phase2: random() * Math.PI * 2,
    riverMeanX: 43 + jitter(1.5),
    riverAmplitude: 3.8 + random() * 1.2,
    lakeX: 28 + jitter(1.8),
    lakeY: 31 + jitter(1.5),
    lakeRx: 6 + random() * 1.2,
    lakeRy: 3.6 + random() * 0.8,
    tributaryBaseY: 12.5 + jitter(1.5),
    bridgeRows: [bridgeA, bridgeB, bridgeC],
    civicCore: { x: 21 + Math.round(jitter(1)), y: 23 + Math.round(jitter(1)) },
  }
}

export function mainRiverCenterX(y: number, seed = DEFAULT_VALLEY_SEED): number {
  const g = grammarFor(seed)
  return g.riverMeanX +
    g.riverAmplitude * Math.sin(y / 7.2 + g.phase) +
    1.35 * Math.sin(y / 2.9 + g.phase2)
}

/** Compatibility helper: the west tributary centerline by column. */
export function riverCenter(x: number, seed = DEFAULT_VALLEY_SEED): number {
  const g = grammarFor(seed)
  return g.tributaryBaseY + x * 0.24 + 1.5 * Math.sin(x / 5.1 + g.phase2)
}

function lakeDistance(x: number, y: number, g: Grammar): number {
  const dx = (x - g.lakeX) / g.lakeRx
  const dy = (y - g.lakeY) / g.lakeRy
  return Math.sqrt(dx * dx + dy * dy)
}

function mainRiverHalfWidth(y: number, g: Grammar): number {
  return 2.15 + 0.45 * Math.sin(y / 4.2 + g.phase)
}

function tributaryCenterY(x: number, g: Grammar): number {
  return g.tributaryBaseY + x * 0.24 + 1.5 * Math.sin(x / 5.1 + g.phase2)
}

function lakeOutletCenterY(x: number, g: Grammar): number {
  const progress = (x - g.lakeX) / Math.max(1, g.riverMeanX - g.lakeX)
  return g.lakeY + progress * 2.6 + Math.sin(x / 2.7 + g.phase) * 0.55
}

function waterAt(x: number, y: number, g: Grammar): boolean {
  const river = Math.abs(x - (
    g.riverMeanX +
    g.riverAmplitude * Math.sin(y / 7.2 + g.phase) +
    1.35 * Math.sin(y / 2.9 + g.phase2)
  )) <= mainRiverHalfWidth(y, g)
  const lakeNoise = 0.08 * Math.sin(x * 1.7 + y * 0.8 + g.phase)
  const lake = lakeDistance(x, y, g) <= 1 + lakeNoise
  const tributaryEnd = g.lakeX - g.lakeRx * 0.45
  const tributary = x <= tributaryEnd &&
    Math.abs(y - tributaryCenterY(x, g)) <= 1.05 + 0.2 * Math.sin(x + g.phase)
  const outlet = x >= g.lakeX + g.lakeRx * 0.35 &&
    x <= g.riverMeanX + 2 &&
    Math.abs(y - lakeOutletCenterY(x, g)) <= 1.1
  return river || lake || tributary || outlet
}

export function isRiver(x: number, y: number, seed = DEFAULT_VALLEY_SEED): boolean {
  return x >= 0 && x < COLS && y >= 0 && y < ROWS && waterAt(x, y, grammarFor(seed))
}

function districtAt(x: number, y: number, g: Grammar): ValleyDistrict {
  if (waterAt(x, y, g)) return 'river-corridor'
  if (x >= 31 && x < g.riverMeanX - 2 && y >= 9 && y <= 24) return 'farm-belt'
  if (Math.abs(x - mainRiverCenterXFromGrammar(y, g)) < 5) return 'river-corridor'
  if (lakeDistance(x, y, g) < 1.8) return y < g.lakeY ? 'lake-learning' : 'lake-exchange'
  if (x < 12 && y > 26) return 'west-community'
  if (y < 15 && x >= 10 && x <= 34) return 'north-innovation'
  if (y > 37 && x >= 23 && x <= 40) return 'south-showcase'
  if (x >= 10 && x <= 33 && y >= 15 && y <= 37) return 'civic-core'
  return 'forest-buffer'
}

function mainRiverCenterXFromGrammar(y: number, g: Grammar): number {
  return g.riverMeanX +
    g.riverAmplitude * Math.sin(y / 7.2 + g.phase) +
    1.35 * Math.sin(y / 2.9 + g.phase2)
}

function nearWater(x: number, y: number, g: Grammar, radius: number): boolean {
  const r = Math.ceil(radius)
  for (let yy = Math.max(0, y - r); yy <= Math.min(ROWS - 1, y + r); yy++) {
    for (let xx = Math.max(0, x - r); xx <= Math.min(COLS - 1, x + r); xx++) {
      if (Math.hypot(xx - x, yy - y) <= radius && waterAt(xx, yy, g)) return true
    }
  }
  return false
}

function createNaturalTiles(g: Grammar): Tile[][] {
  const random = mulberry(g.seed ^ 0x71f3a5c9)
  const tiles: Tile[][] = []
  for (let y = 0; y < ROWS; y++) {
    const row: Tile[] = []
    for (let x = 0; x < COLS; x++) {
      const district = districtAt(x, y, g)
      const variation = random()
      let terrain: Terrain = 'grass'
      if (waterAt(x, y, g)) {
        terrain = 'water'
      } else if (nearWater(x, y, g, 1.55) && random() < 0.72) {
        terrain = 'wetland'
      } else if (district === 'farm-belt') {
        terrain = (x + Math.floor(y / 2)) % 7 === 0 ? 'meadow' : 'field'
      } else {
        const edge = Math.min(x, y, COLS - 1 - x, ROWS - 1 - y)
        const forestChance =
          edge < 4 ? 0.68 :
          district === 'forest-buffer' ? 0.34 :
          nearWater(x, y, g, 3.4) ? 0.22 :
          0.035
        if (random() < forestChance) terrain = 'forest'
        else if (random() < 0.18) terrain = 'meadow'
      }
      row.push({
        terrain,
        baseTerrain: terrain,
        generatedTerrain: terrain,
        district,
        variation,
        riverFlow: terrain === 'water' ? x * 0.31 + y * 0.57 : undefined,
      })
    }
    tiles.push(row)
  }
  return tiles
}

function drawRoadLine(
  tiles: Tile[][],
  points: { x: number; y: number }[],
  allowBridge = false,
) {
  for (let index = 1; index < points.length; index++) {
    let x = points[index - 1].x
    let y = points[index - 1].y
    const end = points[index]
    while (x !== end.x || y !== end.y) {
      setRoad(tiles, x, y, allowBridge)
      if (x !== end.x) x += Math.sign(end.x - x)
      else if (y !== end.y) y += Math.sign(end.y - y)
    }
    setRoad(tiles, end.x, end.y, allowBridge)
  }
}

function setRoad(tiles: Tile[][], x: number, y: number, allowBridge: boolean) {
  const tile = tiles[y]?.[x]
  if (!tile) return
  if (tile.terrain === 'water' && !allowBridge) return
  tile.terrain = tile.terrain === 'water' ? 'bridge' : 'road'
}

function createRoadNetwork(tiles: Tile[][], g: Grammar) {
  // Three east-west spines keep every district connected and become bridges
  // where they meet the main river. Their seed jitter changes the crossings.
  for (const y of g.bridgeRows) {
    drawRoadLine(tiles, [{ x: 3, y }, { x: COLS - 4, y }], true)
  }

  const verticals = [8, 15, 23, 31, 37]
  for (const x of verticals) {
    drawRoadLine(tiles, [{ x, y: 6 }, { x, y: ROWS - 6 }])
  }

  const locals = [17, 22, 34, 38]
  for (const y of locals) {
    drawRoadLine(tiles, [{ x: 7, y }, { x: 39, y }])
  }

  // An offset campus connector and a stepped wetland promenade keep the
  // network from reading as a generic Manhattan grid.
  drawRoadLine(tiles, [
    { x: 4, y: 7 },
    { x: 12, y: 7 },
    { x: 12, y: 13 },
    { x: 20, y: 13 },
  ])
  drawRoadLine(tiles, [
    { x: 18, y: 30 },
    { x: 18, y: 35 },
    { x: 25, y: 35 },
    { x: 25, y: 39 },
    { x: 33, y: 39 },
  ])
}

function refreshRoadMasks(tiles: Tile[][]) {
  const walkable = (x: number, y: number) => {
    const terrain = tiles[y]?.[x]?.terrain
    return terrain === 'road' || terrain === 'bridge'
  }
  for (let y = 0; y < ROWS; y++) {
    for (let x = 0; x < COLS; x++) {
      const tile = tiles[y][x]
      if (!walkable(x, y)) continue
      let mask = 0
      if (walkable(x, y - 1)) mask |= 1
      if (walkable(x + 1, y)) mask |= 2
      if (walkable(x, y + 1)) mask |= 4
      if (walkable(x - 1, y)) mask |= 8
      tile.roadDir = mask
    }
  }
}

function placementClear(
  tiles: Tile[][],
  buildings: Building[],
  archId: string,
  tx: number,
  ty: number,
): boolean {
  const arch = archetype(archId)
  if (tx < 1 || ty < 1 || tx + arch.w >= COLS - 1 || ty + arch.h >= ROWS - 1) return false
  for (let y = ty; y < ty + arch.h; y++) {
    for (let x = tx; x < tx + arch.w; x++) {
      const tile = tiles[y]?.[x]
      if (!tile || tile.buildingId || tile.terrain === 'water' || tile.terrain === 'bridge' || tile.terrain === 'road') return false
    }
  }
  const overlaps = buildings.some(building => {
    const other = archetype(building.archetype)
    return tx < building.tx + other.w + 1 &&
      tx + arch.w + 1 > building.tx &&
      ty < building.ty + other.h + 1 &&
      ty + arch.h + 1 > building.ty
  })
  if (overlaps) return false
  for (let x = tx - 1; x <= tx + arch.w; x++) {
    for (let y = ty - 1; y <= ty + arch.h; y++) {
      const edge = x === tx - 1 || x === tx + arch.w || y === ty - 1 || y === ty + arch.h
      if (edge && (tiles[y]?.[x]?.terrain === 'road' || tiles[y]?.[x]?.terrain === 'bridge')) return true
    }
  }
  return false
}

function findPlacement(
  tiles: Tile[][],
  buildings: Building[],
  placement: CivicPlacement,
  random: () => number,
): { x: number; y: number } {
  const candidates: { x: number; y: number; score: number }[] = []
  for (let radius = 0; radius <= 9; radius++) {
    for (let dy = -radius; dy <= radius; dy++) {
      for (let dx = -radius; dx <= radius; dx++) {
        if (Math.max(Math.abs(dx), Math.abs(dy)) !== radius) continue
        const x = Math.round(placement.anchorX + dx)
        const y = Math.round(placement.anchorY + dy)
        if (!placementClear(tiles, buildings, placement.archetype, x, y)) continue
        const districtPenalty = tiles[y][x].district === placement.district ? 0 : 4
        candidates.push({
          x,
          y,
          score: Math.hypot(dx, dy) + districtPenalty + random() * 0.45,
        })
      }
    }
    if (candidates.length >= 4) break
  }
  candidates.sort((a, b) => a.score - b.score)
  if (candidates[0]) return candidates[0]
  throw new Error(`Energy Valley grammar could not place ${placement.moduleKey}`)
}

function placeCivic(
  tiles: Tile[][],
  buildings: Building[],
  placement: CivicPlacement,
  random: () => number,
) {
  const arch = archetype(placement.archetype)
  const found = findPlacement(tiles, buildings, placement, random)
  const building: Building = {
    id: `civic-${placement.moduleKey}`,
    archetype: placement.archetype,
    name: arch.name,
    tx: found.x,
    ty: found.y,
    progress: 1,
    demolish: 0,
    isCivic: true,
    moduleKey: placement.moduleKey,
    occupants: 0,
    vitality: 55 + random() * 30,
    builtin: true,
  }
  for (let x = found.x; x < found.x + arch.w; x++) {
    for (let y = found.y; y < found.y + arch.h; y++) {
      const tile = tiles[y][x]
      tile.terrain = 'plaza'
      tile.baseTerrain = 'grass'
      tile.district = placement.district
      tile.buildingId = building.id
      tile.structure = undefined
    }
  }
  buildings.push(building)
}

function addCivicPlazas(tiles: Tile[][], buildings: Building[]) {
  const plazaModules = new Set(['town-shell', 'social-square', 'talent-avenue'])
  for (const building of buildings) {
    if (!building.moduleKey || !plazaModules.has(building.moduleKey)) continue
    const arch = archetype(building.archetype)
    for (let y = building.ty - 1; y <= building.ty + arch.h; y++) {
      for (let x = building.tx - 1; x <= building.tx + arch.w; x++) {
        const tile = tiles[y]?.[x]
        if (!tile || tile.buildingId || tile.terrain === 'road' || tile.terrain === 'bridge' || tile.terrain === 'water') continue
        tile.terrain = 'plaza'
        tile.baseTerrain = 'grass'
        tile.structure = undefined
      }
    }
  }
}

function civicPlacements(g: Grammar): CivicPlacement[] {
  const jx = g.civicCore.x - 21
  const jy = g.civicCore.y - 23
  return [
    { archetype: 'town-shell', moduleKey: 'town-shell', district: 'civic-core', anchorX: 17 + jx, anchorY: 22 + jy },
    { archetype: 'vitality', moduleKey: 'vitality-tower', district: 'civic-core', anchorX: 24 + jx, anchorY: 18 + jy },
    { archetype: 'policy', moduleKey: 'policy-hall', district: 'civic-core', anchorX: 13 + jx, anchorY: 25 + jy },
    { archetype: 'contest', moduleKey: 'contest-express', district: 'north-innovation', anchorX: 18 + jx, anchorY: 14 + jy },
    { archetype: 'radar', moduleKey: 'story-radar', district: 'north-innovation', anchorX: 10 + jx, anchorY: 10 + jy },
    { archetype: 'twins', moduleKey: 'resident-twins', district: 'west-community', anchorX: 8, anchorY: 31 + jy },
    { archetype: 'twins', moduleKey: 'resident-twins-b', district: 'west-community', anchorX: 11, anchorY: 37 + jy },
    { archetype: 'ai-garden', moduleKey: 'ai-garden', district: 'lake-learning', anchorX: 20 + jx, anchorY: 29 + jy },
    { archetype: 'social', moduleKey: 'social-square', district: 'lake-exchange', anchorX: 27 + jx, anchorY: 34 + jy },
    { archetype: 'c-lab', moduleKey: 'energy-lab', district: 'lake-exchange', anchorX: 31 + jx, anchorY: 30 + jy },
    { archetype: 'talent', moduleKey: 'talent-avenue', district: 'south-showcase', anchorX: 24 + jx, anchorY: 40 + jy },
    { archetype: 'market', moduleKey: 'valley-market', district: 'south-showcase', anchorX: 32 + jx, anchorY: 40 + jy },
    { archetype: 'c-home', moduleKey: 'talent-flat', district: 'south-showcase', anchorX: 37 + jx, anchorY: 37 + jy },
  ]
}

function adjacentToRoad(tiles: Tile[][], x: number, y: number): boolean {
  return (
    tiles[y - 1]?.[x]?.terrain === 'road' ||
    tiles[y + 1]?.[x]?.terrain === 'road' ||
    tiles[y]?.[x - 1]?.terrain === 'road' ||
    tiles[y]?.[x + 1]?.terrain === 'road'
  )
}

function addAmbientUrbanFabric(tiles: Tile[][], seed: number) {
  const random = mulberry(seed ^ 0xa53c9e17)
  const structureKinds: AmbientStructure[] = ['lowrise', 'row', 'tower', 'campus', 'courtyard']
  for (let y = 1; y < ROWS - 1; y++) {
    for (let x = 1; x < COLS - 1; x++) {
      const tile = tiles[y][x]
      if (tile.buildingId || !adjacentToRoad(tiles, x, y)) continue
      const density =
        tile.district === 'civic-core' ? 0.76 :
        tile.district === 'north-innovation' ? 0.43 :
        tile.district === 'west-community' ? 0.34 :
        tile.district === 'south-showcase' ? 0.46 :
        0
      if (density === 0 || random() > density) continue
      if (tile.terrain !== 'grass' && tile.terrain !== 'meadow') continue
      const roll = random()
      const structure =
        roll < 0.48 ? structureKinds[0] :
        roll < 0.7 ? structureKinds[1] :
        roll < 0.82 ? structureKinds[4] :
        roll < 0.92 ? structureKinds[3] :
        structureKinds[2]
      tile.terrain = 'urban'
      tile.structure = structure
      tile.structureFloors =
        structure === 'tower' ? 4 + Math.floor(random() * 4) :
        structure === 'campus' ? 2 :
        1 + Math.floor(random() * 3)
    }
  }
}

export function createWorld(seed = DEFAULT_VALLEY_SEED): World {
  const g = grammarFor(seed)
  const tiles = createNaturalTiles(g)
  createRoadNetwork(tiles, g)
  refreshRoadMasks(tiles)

  const buildings: Building[] = []
  const placementRandom = mulberry(g.seed ^ 0x9e3779b9)
  for (const placement of civicPlacements(g)) {
    placeCivic(tiles, buildings, placement, placementRandom)
  }
  addCivicPlazas(tiles, buildings)
  addAmbientUrbanFabric(tiles, g.seed)
  for (const tile of tiles.flat()) tile.generatedTerrain = tile.terrain

  return {
    seed: g.seed,
    tiles,
    buildings,
    landmarks: {
      civicCore: g.civicCore,
      lake: { x: g.lakeX, y: g.lakeY, rx: g.lakeRx, ry: g.lakeRy },
      bridgeRows: [...g.bridgeRows],
      mainRiverMeanX: g.riverMeanX,
    },
  }
}

export function nextBuildingId() {
  return `user-${++bidSeq}-${Date.now() % 100000}`
}

export function mulberry(seed: number) {
  let state = seed
  return () => {
    state |= 0
    state = (state + 0x6d2b79f5) | 0
    let value = Math.imul(state ^ (state >>> 15), 1 | state)
    value = (value + Math.imul(value ^ (value >>> 7), 61 | value)) ^ value
    return ((value ^ (value >>> 14)) >>> 0) / 4294967296
  }
}

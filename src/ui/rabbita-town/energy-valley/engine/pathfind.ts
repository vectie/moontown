// ============================================================
// 路网寻路 —— Agent 只能沿 road/bridge tile 行走（BFS）
// ============================================================

import type { World } from './world'

const DIRS = [
  { x: 0, y: -1 }, { x: 1, y: 0 }, { x: 0, y: 1 }, { x: -1, y: 0 },
]

function walkable(world: World, x: number, y: number): boolean {
  const t = world.tiles[y]?.[x]
  return !!t && (t.terrain === 'road' || t.terrain === 'bridge')
}

/** BFS 最短路，返回 tile 中心路径（含起点终点）；不可达返回 null */
export function findPath(
  world: World,
  sx: number, sy: number,
  ex: number, ey: number,
): { x: number; y: number }[] | null {
  sx |= 0; sy |= 0; ex |= 0; ey |= 0
  if (sx === ex && sy === ey) return [{ x: sx + 0.5, y: sy + 0.5 }]
  const rows = world.tiles.length
  const cols = world.tiles[0].length
  const prev = new Int32Array(cols * rows).fill(-1)
  const seen = new Uint8Array(cols * rows)
  const q: number[] = [sy * cols + sx]
  seen[sy * cols + sx] = 1
  let head = 0
  while (head < q.length) {
    const cur = q[head++]
    const cx = cur % cols
    const cy = (cur / cols) | 0
    if (cx === ex && cy === ey) {
      const path: { x: number; y: number }[] = []
      let n = cur
      while (n !== -1) {
        path.push({ x: (n % cols) + 0.5, y: ((n / cols) | 0) + 0.5 })
        n = prev[n]
      }
      return path.reverse()
    }
    for (const d of DIRS) {
      const nx = cx + d.x
      const ny = cy + d.y
      const ni = ny * cols + nx
      if (nx < 0 || ny < 0 || nx >= cols || ny >= rows || seen[ni]) continue
      if (!walkable(world, nx, ny)) continue
      seen[ni] = 1
      prev[ni] = cur
      q.push(ni)
    }
  }
  return null
}

/** 找建筑最近的可行走 tile（建筑四邻） */
export function nearestRoad(world: World, tx: number, ty: number, w: number, h: number) {
  const candidates: { x: number; y: number }[] = []
  for (let x = tx - 1; x <= tx + w; x++) {
    candidates.push({ x, y: ty - 1 }, { x, y: ty + h })
  }
  for (let y = ty - 1; y <= ty + h; y++) {
    candidates.push({ x: tx - 1, y }, { x: tx + w, y })
  }
  for (const c of candidates) {
    if (walkable(world, c.x, c.y)) return c
  }
  return null
}

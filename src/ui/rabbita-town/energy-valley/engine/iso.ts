// ============================================================
// 等距投影数学层 —— 所有绘制与拾取的唯一坐标真源
// tile (tx,ty) 为整数格；世界坐标 (wx,wy) 以 tile 为单位的浮点；
// 屏幕像素 = (wx-wy)*HW, (wx+wy)*HH
// ============================================================

export const TILE_W = 64
export const TILE_H = 32
export const HW = TILE_W / 2
export const HH = TILE_H / 2
/** 每层楼高（像素） */
export const FLOOR_H = 26

export function worldToScreen(wx: number, wy: number): { x: number; y: number } {
  return { x: (wx - wy) * HW, y: (wx + wy) * HH }
}

export function screenToWorld(sx: number, sy: number): { wx: number; wy: number } {
  const wx = (sx / HW + sy / HH) / 2
  const wy = (sy / HH - sx / HW) / 2
  return { wx, wy }
}

/** tile 中心点的世界坐标 */
export function tileCenter(tx: number, ty: number) {
  return { wx: tx + 0.5, wy: ty + 0.5 }
}

/** 由大到小深度排序键（绘制顺序） */
export function depthKey(tx: number, ty: number) {
  return tx + ty
}

/** 菱形四点（某 tile 的屏幕多边形，anchor 为该 tile 屏幕原点） */
export function diamondPath(
  ctx: CanvasRenderingContext2D,
  sx: number,
  sy: number,
  scale = 1,
) {
  const hw = HW * scale
  const hh = HH * scale
  ctx.beginPath()
  ctx.moveTo(sx, sy - hh)
  ctx.lineTo(sx + hw, sy)
  ctx.lineTo(sx, sy + hh)
  ctx.lineTo(sx - hw, sy)
  ctx.closePath()
}

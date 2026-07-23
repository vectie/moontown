// ============================================================
// MoonTown · 能源谷 —— 场景引擎类型定义
// ============================================================

export type Terrain = 'grass' | 'water' | 'road' | 'bridge' | 'plaza' | 'forest'

export type WeatherKind = 'sunny' | 'cloudy' | 'rain' | 'snow'

export type AgentRole = 'mayor' | 'keeper' | 'worker' | 'resident'

/** 建筑原型 —— 决定外观、占地、造价 */
export interface BuildingArchetype {
  id: string
  name: string
  glyph: string          // 图标字符，用于工具栏
  w: number              // 占地宽（格）
  h: number              // 占地深（格）
  floors: number         // 楼层数（决定高度）
  style: BuildingStyle
  cost: number
  desc: string
}

export type BuildingStyle =
  | 'hall'        // 市政厅：低宽体 + 柱廊
  | 'tower'       // 塔楼：高窄玻璃体
  | 'lab'         // 实验楼：中高层 + 顶部设备
  | 'garden'      // 花园：绿地 + 温室穹顶
  | 'market'      // 市集：低层棚架群
  | 'home'        // 住宅：双子坡顶
  | 'radar'       // 雷达站：基座 + 天线
  | 'plaza-bld'   // 广场建筑：环廊
  | 'custom-tower'
  | 'custom-hall'
  | 'custom-lab'
  | 'custom-home'
  | 'custom-park'

export interface Building {
  id: string
  archetype: string      // BuildingArchetype.id
  name: string
  tx: number             // 左上角 tile 坐标
  ty: number
  /** 0→1 建造进度，1 为完工 */
  progress: number
  /** 拆除动画：1→0 */
  demolish: number
  isCivic: boolean       // 是否为 11 座市政协议建筑
  moduleKey?: string     // 对应 moontown 市政模块 key
  occupants: number      // 在内 Agent 数
  vitality: number       // 活力值 0-100
  builtin: boolean       // 初始地图自带（不可拆）
}

export interface Tile {
  terrain: Terrain
  buildingId?: string    // 被建筑占用的 tile
  riverFlow?: number     // 河流相位（用于水流动画错相）
  roadDir?: number       // 道路连接位掩码 N=1 E=2 S=4 W=8
}

export interface Agent {
  id: string
  name: string
  role: AgentRole
  /** 平滑世界坐标（tile 单位，浮点） */
  x: number
  y: number
  path: { x: number; y: number }[]
  pathIdx: number
  speed: number          // tiles / 秒
  state: 'walking' | 'inside' | 'waiting'
  homeId?: string        // 所在建筑
  targetId?: string      // 目标建筑
  dwell: number          // 剩余停留秒
  purpose: string        // 当前目的（巡检/通勤/送货…）
  hue: number            // 角色主色相
  bob: number            // 步行摆动相位
}

export interface Particle {
  x: number; y: number; vx: number; vy: number
  life: number; maxLife: number
  kind: 'dust' | 'splash' | 'leaf' | 'spark'
  size: number
}

export interface WeatherState {
  kind: WeatherKind
  intensity: number      // 0-1
  windX: number
}

export interface TownEvent {
  id: number
  t: number
  icon: string
  text: string
  level: 'info' | 'good' | 'warn'
}

export interface TownMetrics {
  population: number
  vitality: number       // 全镇活力
  budget: number
  agentsOnline: number
  servicesActive: number
  history: { vitality: number; population: number }[]
}

export type ToolId =
  | 'inspect'
  | 'road'
  | 'park'
  | 'demolish'
  | `bld:${string}`

export interface Camera {
  cx: number   // 视野中心（世界像素）
  cy: number
  zoom: number
}

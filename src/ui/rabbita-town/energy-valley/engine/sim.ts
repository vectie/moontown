// ============================================================
// 模拟层 —— Agent 行为循环、镇级指标、事件流、时间与天气
// Agent 行为模型（来自 moontown 角色分层）：
//   Mayor(镇长)   → 在市政建筑间巡检，金色
//   Keeper(看护)  → 驻守建筑，偶尔跨楼同步，蓝色
//   Worker(执行)  → 高频通勤，承接任务，绿色
//   Resident(居民)→ 生活动线：家 ⇄ 广场/市集/公园，橙色
// ============================================================

import type { Agent, AgentRole, Building, TownEvent, TownMetrics, WeatherKind } from './types'
import { findPath, nearestRoad } from './pathfind'
import { archetype, type World } from './world'

export interface SimState {
  world: World
  agents: Agent[]
  events: TownEvent[]
  metrics: TownMetrics
  hour: number            // 0-24 游戏时间
  day: number
  weather: WeatherKind
  weatherAuto: boolean
  timeScale: number       // 游戏秒 = dt * timeScale
  paused: boolean
  selectedId: string | null
  followAgent: string | null
  eventSeq: number
  weatherTimer: number
  buildFlash: { tx: number; ty: number; t: number }[]
}

const NAMES: Record<AgentRole, string[]> = {
  mayor: ['明月'],
  keeper: ['守卷·壹', '守卷·贰', '守卷·叁', '守卷·肆', '守卷·伍'],
  worker: ['工蜂·阿執', '工蜂·小驰', '工蜂·阿织', '工蜂·小拓', '工蜂·阿研', '工蜂·小算', '工蜂·阿策', '工蜂·小觅'],
  resident: ['谷民·小温', '谷民·阿榆', '谷民·小创', '谷民·阿源', '谷民·小栖', '谷民·阿谷'],
}

const ROLE_HUE: Record<AgentRole, number> = {
  mayor: 45, keeper: 210, worker: 130, resident: 20,
}

const PURPOSES: Record<AgentRole, string[]> = {
  mayor: ['镇务巡检', '协议听证', '跨域综合'],
  keeper: ['基线比对', '知识看护', '投影巡检', '评审值守'],
  worker: ['任务投递', '证据采集', '资料搬运', '结果回传', '现场勘查'],
  resident: ['河畔散步', '市集采买', '沙龙串门', '公园遛弯', '通勤往返'],
}

let aidSeq = 0

function makeAgent(role: AgentRole, name: string, home: Building, world: World): Agent {
  const a = archetype(home.archetype)
  const road = nearestRoad(world, home.tx, home.ty, a.w, a.h)
  return {
    id: `agent-${++aidSeq}`,
    name, role,
    x: road ? road.x + 0.5 : home.tx + a.w / 2,
    y: road ? road.y + 0.5 : home.ty + a.h / 2,
    path: [], pathIdx: 0,
    speed: role === 'worker' ? 2.6 : role === 'mayor' ? 2.0 : 1.7,
    state: 'walking',
    homeId: home.id, targetId: undefined,
    dwell: 0,
    purpose: PURPOSES[role][0],
    hue: ROLE_HUE[role] + (Math.random() * 16 - 8),
    bob: Math.random() * Math.PI * 2,
  }
}

export function createSim(world: World): SimState {
  const agents: Agent[] = []
  const civic = world.buildings.filter(b => b.isCivic)
  const home = civic.find(b => b.moduleKey === 'resident-twins') ?? civic[0]
  const hall = civic.find(b => b.moduleKey === 'town-shell') ?? civic[0]

  agents.push(makeAgent('mayor', NAMES.mayor[0], hall, world))
  const keeperHomes = civic.slice(0, 5)
  NAMES.keeper.forEach((n, i) => agents.push(makeAgent('keeper', n, keeperHomes[i % keeperHomes.length], world)))
  NAMES.worker.forEach((n, i) => agents.push(makeAgent('worker', n, civic[(i + 2) % civic.length], world)))
  NAMES.resident.forEach(n => agents.push(makeAgent('resident', n, home, world)))

  const state: SimState = {
    world, agents,
    events: [],
    metrics: {
      population: 128, vitality: 62, budget: 2400,
      agentsOnline: agents.length, servicesActive: civic.length,
      history: [],
    },
    hour: 9.2, day: 1,
    weather: 'sunny', weatherAuto: true,
    timeScale: 60,   // 1 现实秒 = 1 游戏分钟
    paused: false,
    selectedId: null, followAgent: null,
    eventSeq: 0, weatherTimer: 90,
    buildFlash: [],
  }
  pushEvent(state, '☀️', '能源谷晨启，镇长明月开始今日巡检', 'info')
  pushEvent(state, '🏛️', `${civic.length} 座市政协议建筑在线`, 'good')
  return state
}

export function pushEvent(s: SimState, icon: string, text: string, level: TownEvent['level']) {
  s.events.unshift({ id: ++s.eventSeq, t: s.hour, icon, text, level })
  if (s.events.length > 30) s.events.length = 30
}

function pickDestination(s: SimState, agent: Agent): Building | null {
  const bs = s.world.buildings.filter(b => b.demolish <= 0 && b.progress >= 1 && b.id !== agent.homeId)
  if (!bs.length) return null
  // 角色 → 目的地偏好
  const weight = (b: Building): number => {
    const mk = b.moduleKey ?? ''
    switch (agent.role) {
      case 'mayor':   return b.isCivic ? 3 : 1
      case 'keeper':  return b.isCivic ? 2 : 0.6
      case 'worker':  return mk.includes('market') || mk.includes('contest') ? 2.5 : 1.2
      case 'resident':
        return mk.includes('social') || mk.includes('market') || mk.includes('garden') || mk.includes('twins') ? 3 : 0.5
    }
  }
  const bag: Building[] = []
  for (const b of bs) {
    const n = Math.max(1, Math.round(weight(b) * 2))
    for (let i = 0; i < n; i++) bag.push(b)
  }
  return bag[(Math.random() * bag.length) | 0]
}

function dispatchAgent(s: SimState, agent: Agent, from: Building) {
  const dest = pickDestination(s, agent)
  if (!dest) return
  const a0 = archetype(from.archetype)
  const a1 = archetype(dest.archetype)
  const r0 = nearestRoad(s.world, from.tx, from.ty, a0.w, a0.h)
  const r1 = nearestRoad(s.world, dest.tx, dest.ty, a1.w, a1.h)
  if (!r0 || !r1) return
  const path = findPath(s.world, r0.x, r0.y, r1.x, r1.y)
  if (!path || path.length < 2) return
  agent.path = path
  agent.pathIdx = 0
  agent.x = path[0].x; agent.y = path[0].y
  agent.targetId = dest.id
  agent.state = 'walking'
  agent.purpose = PURPOSES[agent.role][(Math.random() * PURPOSES[agent.role].length) | 0]
}

export function updateSim(s: SimState, dtReal: number) {
  if (s.paused) return
  const dt = dtReal * s.timeScale / 60          // 游戏分钟
  const prevHour = s.hour
  s.hour += dt
  if (s.hour >= 24) { s.hour -= 24; s.day++; pushEvent(s, '🌅', `第 ${s.day} 天开始`, 'info') }

  // 天气自动漂移
  if (s.weatherAuto) {
    s.weatherTimer -= dtReal
    if (s.weatherTimer <= 0) {
      const roll = Math.random()
      const next: WeatherKind = roll < 0.42 ? 'sunny' : roll < 0.68 ? 'cloudy' : roll < 0.88 ? 'rain' : 'snow'
      if (next !== s.weather) {
        s.weather = next
        const msg: Record<WeatherKind, string> = {
          sunny: '☀️ 天气转晴', cloudy: '☁️ 云层聚拢', rain: '🌧️ 温榆河起雨了', snow: '❄️ 飘雪覆盖能源谷',
        }
        pushEvent(s, msg[next].split(' ')[0], msg[next].split(' ')[1], 'info')
      }
      s.weatherTimer = 60 + Math.random() * 120
    }
  }

  // Agent 更新
  const wSpeed = s.weather === 'rain' ? 0.85 : s.weather === 'snow' ? 0.7 : 1
  for (const ag of s.agents) {
    ag.bob += dtReal * 9
    if (ag.state === 'inside') {
      ag.dwell -= dtReal
      if (ag.dwell <= 0) {
        const home = s.world.buildings.find(b => b.id === ag.homeId)
        if (home) {
          home.occupants = Math.max(0, home.occupants - 1)
          dispatchAgent(s, ag, home)
          if (ag.role === 'mayor' && Math.random() < 0.35) {
            const dest = s.world.buildings.find(b => b.id === ag.targetId)
            if (dest) pushEvent(s, '🎩', `镇长前往${dest.name} · ${ag.purpose}`, 'info')
          }
        } else {
          ag.state = 'walking'
        }
      }
      continue
    }
    // walking
    if (ag.path.length === 0) {
      let home = s.world.buildings.find(b => b.id === ag.homeId)
      if (!home) {
        // 驻地已被拆除：退回任一市政建筑重新出发
        home = s.world.buildings.find(b => b.isCivic && b.progress >= 1 && b.demolish <= 0)
        ag.homeId = home?.id
      }
      if (home) dispatchAgent(s, ag, home)
      continue
    }
    let remain = ag.speed * wSpeed * dtReal
    while (remain > 0 && ag.pathIdx < ag.path.length - 1) {
      const next = ag.path[ag.pathIdx + 1]
      const dx = next.x - ag.x
      const dy = next.y - ag.y
      const dist = Math.hypot(dx, dy)
      if (dist <= remain) {
        ag.x = next.x; ag.y = next.y
        ag.pathIdx++
        remain -= dist
      } else {
        ag.x += (dx / dist) * remain
        ag.y += (dy / dist) * remain
        remain = 0
      }
    }
    if (ag.pathIdx >= ag.path.length - 1) {
      // 到达
      const dest = s.world.buildings.find(b => b.id === ag.targetId)
      ag.state = 'inside'
      ag.dwell = 4 + Math.random() * (ag.role === 'keeper' ? 26 : 12)
      ag.homeId = ag.targetId
      ag.path = []
      if (dest) {
        dest.occupants++
        dest.vitality = Math.min(100, dest.vitality + 0.6)
        if (Math.random() < 0.06) {
          pushEvent(s, roleIcon(ag.role), `${ag.name} 抵达${dest.name} · ${ag.purpose}`, 'info')
        }
      }
    }
  }

  // 建造进度 & 拆除
  for (const b of s.world.buildings) {
    if (b.progress < 1) {
      b.progress = Math.min(1, b.progress + dtReal / 6)
      if (b.progress >= 1) {
        pushEvent(s, '🏗️', `${b.name} 竣工投用`, 'good')
        s.metrics.servicesActive = s.world.buildings.filter(x => x.progress >= 1 && x.demolish <= 0).length
      }
    }
  }

  // 指标
  const m = s.metrics
  const weatherDrift = s.weather === 'sunny' ? 0.35 : s.weather === 'cloudy' ? 0.05 : s.weather === 'rain' ? -0.2 : -0.3
  const activeRatio = s.agents.filter(a => a.state === 'walking').length / Math.max(1, s.agents.length)
  m.vitality = clamp(m.vitality + (weatherDrift + activeRatio * 0.5 - 0.18) * dtReal, 20, 100)
  m.population = Math.round(m.population + (Math.random() - 0.48) * dtReal * 0.6)
  const income = s.world.buildings.filter(b => b.progress >= 1 && b.demolish <= 0).length * 0.9
  m.budget += income * dtReal * 0.4
  if (Math.floor(prevHour) !== Math.floor(s.hour)) {
    m.history.push({ vitality: m.vitality, population: m.population })
    if (m.history.length > 48) m.history.shift()
  }

  // 建造闪光衰减
  for (const f of s.buildFlash) f.t -= dtReal
  s.buildFlash = s.buildFlash.filter(f => f.t > 0)
}

export function roleIcon(r: AgentRole): string {
  return r === 'mayor' ? '🎩' : r === 'keeper' ? '📘' : r === 'worker' ? '🐝' : '🏠'
}

function clamp(v: number, lo: number, hi: number) { return Math.max(lo, Math.min(hi, v)) }

/** 昼夜因子：0 = 深夜，1 = 正午 */
export function daylight(hour: number): number {
  // 6 点日出，19 点日落
  const t = (hour - 6) / 13
  if (t <= 0 || t >= 1) return 0
  return Math.sin(t * Math.PI)
}

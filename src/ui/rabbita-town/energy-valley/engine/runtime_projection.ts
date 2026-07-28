import type {
  RuntimeAgent,
  RuntimeAgentStatus,
  RuntimeProjection,
  RuntimeProjectionState,
  RuntimeWorkItem,
} from '../runtime/types'
import { nearestRoad } from './pathfind'
import {
  parkRuntimeAgent,
  routeAgentToBuilding,
  type SimState,
} from './sim'
import type {
  Agent,
  AgentRole,
  Building,
  WorkStatus,
} from './types'
import { archetype } from './world'

const STATUS_PRIORITY: Record<RuntimeWorkItem['status'], number> = {
  running: 7,
  waiting_review: 6,
  blocked: 5,
  assigned: 4,
  queued: 3,
  failed: 2,
  completed: 1,
}

const STATUS_COPY: Record<RuntimeWorkItem['status'], string> = {
  queued: '已排队',
  assigned: '已分派',
  running: '执行中',
  waiting_review: '等待评审',
  completed: '已完成',
  failed: '执行失败',
  blocked: '受阻',
}

const ROUTABLE_AGENT_STATUSES = new Set<RuntimeAgentStatus>([
  'assigned',
  'running',
  'waiting',
  'blocked',
])

function stableHue(id: string, role: AgentRole): number {
  let hash = 2166136261
  for (let i = 0; i < id.length; i++) {
    hash ^= id.charCodeAt(i)
    hash = Math.imul(hash, 16777619)
  }
  const base = role === 'mayor' ? 45 : role === 'keeper' ? 210 : 130
  return base + ((hash >>> 0) % 17) - 8
}

function spawnPoint(sim: SimState, building: Building) {
  const a = archetype(building.archetype)
  const road = nearestRoad(sim.world, building.tx, building.ty, a.w, a.h)
  return road
    ? { x: road.x + 0.5, y: road.y + 0.5 }
    : { x: building.tx + a.w / 2, y: building.ty + a.h / 2 }
}

function makeRuntimeAgent(
  sim: SimState,
  runtimeAgent: RuntimeAgent,
  spawnAnchor: Building,
): Agent {
  const p = spawnPoint(sim, spawnAnchor)
  return {
    id: `runtime-agent:${runtimeAgent.id}`,
    runtimeAgentId: runtimeAgent.id,
    name: runtimeAgent.name,
    role: runtimeAgent.role,
    x: p.x,
    y: p.y,
    path: [],
    pathIdx: 0,
    speed: runtimeAgent.role === 'worker' ? 2.6 : runtimeAgent.role === 'mayor' ? 2 : 1.7,
    state: 'waiting',
    homeId: spawnAnchor.id,
    dwell: 0,
    purpose: '空闲 · 等待真实任务',
    hue: stableHue(runtimeAgent.id, runtimeAgent.role),
    bob: 0,
    provenance: 'runtime',
  }
}

function clearWork(agent: Agent) {
  agent.workItemId = undefined
  agent.runId = undefined
  agent.workStatus = undefined
  agent.workSource = undefined
  agent.workSummary = undefined
  agent.buildingModuleKey = undefined
  agent.resolvedBuildingModuleKey = undefined
}

function workForAgent(agent: RuntimeAgent, tasks: RuntimeWorkItem[]) {
  if (agent.workItemId) {
    const exact = tasks.find(task => task.id === agent.workItemId)
    if (exact) return exact
  }
  return tasks
    .filter(task => task.agentId === agent.id)
    .sort((a, b) => STATUS_PRIORITY[b.status] - STATUS_PRIORITY[a.status])[0]
}

function canRouteRuntimeAgent(agent: RuntimeAgent): boolean {
  return ROUTABLE_AGENT_STATUSES.has(agent.status)
}

function agentStatusForWork(status: RuntimeWorkItem['status']): RuntimeAgent['status'] {
  switch (status) {
    case 'assigned': return 'assigned'
    case 'running': return 'running'
    case 'waiting_review': return 'waiting'
    case 'blocked': return 'blocked'
    default: return 'idle'
  }
}

function runtimeRoster(projection: RuntimeProjection): RuntimeAgent[] {
  const agents = [...projection.agents]
  const ids = new Set(agents.map(agent => agent.id))
  for (const task of projection.tasks) {
    if (!task.agentId || ids.has(task.agentId)) continue
    agents.push({
      id: task.agentId,
      name: task.agentName ?? task.agentId,
      role: task.role ?? 'worker',
      status: agentStatusForWork(task.status),
      buildingModuleKey: task.buildingModuleKey,
      workItemId: task.id,
      runId: task.runId,
    })
    ids.add(task.agentId)
  }
  return agents
}

function targetBuilding(sim: SimState, task: RuntimeWorkItem) {
  return sim.world.buildings.find(
    building => building.moduleKey === task.buildingModuleKey
      && building.progress >= 1
      && building.demolish <= 0,
  )
}

function resetBuildingProjection(building: Building) {
  building.workItemIds = []
  building.runIds = []
  building.workStatuses = []
  building.workSources = []
}

function projectTaskOntoBuilding(building: Building, task: RuntimeWorkItem) {
  building.workItemIds?.push(task.id)
  if (task.runId && !building.runIds?.includes(task.runId)) building.runIds?.push(task.runId)
  if (!building.workStatuses?.includes(task.status)) building.workStatuses?.push(task.status)
  if (!building.workSources?.includes(task.source)) building.workSources?.push(task.source)
}

function bindWork(sim: SimState, agent: Agent, task: RuntimeWorkItem) {
  const building = targetBuilding(sim, task)
  agent.workItemId = task.id
  agent.runId = task.runId
  agent.workStatus = task.status as WorkStatus
  agent.workSource = task.source
  agent.workSummary = task.summary
  agent.buildingModuleKey = task.buildingModuleKey
  agent.resolvedBuildingModuleKey = building?.moduleKey
  agent.purpose = `${task.title} · ${STATUS_COPY[task.status]}`

  if (!building) {
    parkRuntimeAgent(sim, agent)
    return
  }

  if (task.status === 'queued' || task.status === 'completed' || task.status === 'failed') {
    parkRuntimeAgent(sim, agent, building)
    return
  }

  if (agent.targetId !== building.id || (agent.state !== 'walking' && agent.state !== 'inside')) {
    routeAgentToBuilding(sim, agent, building)
  }
}

function parkInactiveRuntimeAgent(
  sim: SimState,
  agent: Agent,
  runtimeAgent: RuntimeAgent,
) {
  clearWork(agent)
  // Keep real identity available to the inspector without treating the
  // associated parent task as active visual work.
  agent.workItemId = runtimeAgent.workItemId
  agent.runId = runtimeAgent.runId
  agent.buildingModuleKey = runtimeAgent.buildingModuleKey
  agent.purpose = runtimeAgent.status === 'offline'
    ? '运行时离线'
    : runtimeAgent.workItemId
      ? '未处于执行状态 · 等待新任务'
      : '空闲 · 等待真实任务'
  parkRuntimeAgent(sim, agent)
}

function deactivateRuntimeMotion(
  sim: SimState,
  preserveTaskEvidence: boolean,
  message?: string,
) {
  if (message !== undefined) sim.runtimeMessage = message
  for (const agent of sim.agents) {
    if (agent.provenance === 'runtime') parkRuntimeAgent(sim, agent)
  }
  sim.agents = sim.agents.filter(agent => agent.provenance === 'ambient')
  if (!preserveTaskEvidence) {
    for (const building of sim.world.buildings) resetBuildingProjection(building)
    sim.runtimeUnlocatedWorkItemIds = []
  }
  sim.metrics.agentsOnline = sim.agents.length
}

/**
 * Reconcile one truthful runtime snapshot into the visual simulation.
 *
 * This is eventless by design: the runtime feed owns factual event copy. Calling
 * this function never fabricates arrivals, purposes, work IDs, or run IDs.
 */
export function applyRuntimeProjection(sim: SimState, projection: RuntimeProjection) {
  setRuntimeMode(sim, projection.mode)
  sim.runtimeObservedAt = projection.observedAt
  sim.runtimeTick = projection.tick
  sim.runtimeMessage = projection.message

  for (const building of sim.world.buildings) resetBuildingProjection(building)
  sim.runtimeUnlocatedWorkItemIds = []

  if (projection.mode !== 'live') {
    for (const agent of sim.agents) {
      if (agent.provenance === 'runtime') parkRuntimeAgent(sim, agent)
    }
    sim.agents = sim.agents.filter(agent => agent.provenance === 'ambient')
    sim.metrics.agentsOnline = sim.agents.length
    return
  }

  const spawnAnchor = sim.world.buildings.find(building => building.moduleKey === 'town-shell')
    ?? sim.world.buildings.find(building => building.isCivic)
  if (!spawnAnchor) return

  const roster = runtimeRoster(projection)
  const runtimeIds = new Set(roster.map(agent => agent.id))
  for (const agent of sim.agents) {
    if (
      agent.provenance === 'runtime'
      && agent.runtimeAgentId !== undefined
      && !runtimeIds.has(agent.runtimeAgentId)
    ) {
      parkRuntimeAgent(sim, agent)
    }
  }
  sim.agents = sim.agents.filter(
    agent => agent.provenance === 'ambient'
      || (agent.runtimeAgentId !== undefined && runtimeIds.has(agent.runtimeAgentId)),
  )

  for (const task of projection.tasks) {
    const building = targetBuilding(sim, task)
    if (building) {
      projectTaskOntoBuilding(building, task)
    } else {
      sim.runtimeUnlocatedWorkItemIds.push(task.id)
    }
  }

  for (const runtimeAgent of roster) {
    let agent = sim.agents.find(item => item.runtimeAgentId === runtimeAgent.id)
    if (!agent) {
      agent = makeRuntimeAgent(sim, runtimeAgent, spawnAnchor)
      sim.agents.push(agent)
    }
    agent.name = runtimeAgent.name
    agent.role = runtimeAgent.role
    agent.runtimeAgentId = runtimeAgent.id
    agent.runtimeStatus = runtimeAgent.status
    agent.provenance = 'runtime'

    const work = canRouteRuntimeAgent(runtimeAgent)
      ? workForAgent(runtimeAgent, projection.tasks)
      : undefined
    if (work) {
      bindWork(sim, agent, work)
    } else {
      parkInactiveRuntimeAgent(sim, agent, runtimeAgent)
    }
  }

  sim.metrics.agentsOnline = roster.filter(agent => agent.status !== 'offline').length
}

/**
 * Reconcile browser transport truth into the visual simulation.
 *
 * A retained live projection remains useful evidence in stale/error phases,
 * but it must never keep map actors moving or occupying buildings.
 */
export function applyRuntimeClientState(
  sim: SimState,
  state: Pick<
    RuntimeProjectionState,
    'phase' | 'projection' | 'error'
  >,
) {
  if (state.phase === 'live' && state.projection?.mode === 'live') {
    applyRuntimeProjection(sim, state.projection)
    return
  }

  const preserveTaskEvidence = (
    (
      state.phase === 'stale' ||
      state.phase === 'error' ||
      state.phase === 'unavailable'
    )
    && state.projection?.mode === 'live'
  )
  sim.runtimeMode = 'unavailable'
  deactivateRuntimeMotion(
    sim,
    preserveTaskEvidence,
    state.error ?? state.projection?.message,
  )
}

export function setRuntimeMode(
  sim: SimState,
  mode: RuntimeProjection['mode'] | 'demo',
  message?: string,
) {
  const enteringLive = mode === 'live' && sim.runtimeMode !== 'live'
  sim.runtimeMode = mode
  if (message !== undefined) sim.runtimeMessage = message

  if (mode === 'live') {
    if (enteringLive) sim.events = []
    for (const agent of sim.agents) {
      if (agent.provenance === 'ambient' && agent.role !== 'resident') {
        parkRuntimeAgent(sim, agent)
        agent.purpose = '环境角色 · 实时模式已暂停'
      }
    }
  } else {
    deactivateRuntimeMotion(sim, false, message)
  }
}

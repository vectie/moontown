import assert from 'node:assert/strict'
import test from 'node:test'
import type {
  RuntimeAgent,
  RuntimeProjection,
  RuntimeWorkItem,
} from '../runtime/types'
import {
  applyRuntimeClientState,
  applyRuntimeProjection,
} from './runtime_projection'
import { createSim, updateSim } from './sim'
import { createWorld } from './world'

function runtimeAgent(overrides: Partial<RuntimeAgent> = {}): RuntimeAgent {
  return {
    id: 'worker-real-17',
    name: 'Worker 17',
    role: 'worker',
    status: 'assigned',
    workItemId: 'work-real-42',
    ...overrides,
  }
}

function workItem(overrides: Partial<RuntimeWorkItem> = {}): RuntimeWorkItem {
  return {
    id: 'work-real-42',
    title: 'Compile the release evidence',
    status: 'assigned',
    buildingModuleKey: 'energy-lab',
    agentId: 'worker-real-17',
    runId: 'run-real-9',
    artifacts: [],
    source: 'operator-request',
    ...overrides,
  }
}

function projection(
  agents: RuntimeAgent[],
  tasks: RuntimeWorkItem[],
  overrides: Partial<RuntimeProjection> = {},
): RuntimeProjection {
  return {
    schema: 'moontown.energy-valley.runtime.v1',
    mode: 'live',
    observedAt: '2026-07-28T10:00:00Z',
    tick: 8,
    agents,
    tasks,
    ...overrides,
  }
}

test('real work and agent IDs determine the visual route and building projection', () => {
  const sim = createSim(createWorld(20260728))
  const task = workItem()
  applyRuntimeProjection(sim, projection([runtimeAgent()], [task]))

  const visual = sim.agents.find(agent => agent.runtimeAgentId === 'worker-real-17')
  const lab = sim.world.buildings.find(building => building.moduleKey === 'energy-lab')
  assert.ok(visual)
  assert.ok(lab)
  assert.equal(sim.runtimeMode, 'live')
  assert.equal(visual.provenance, 'runtime')
  assert.equal(visual.workItemId, 'work-real-42')
  assert.equal(visual.runId, 'run-real-9')
  assert.equal(visual.workStatus, 'assigned')
  assert.equal(visual.workSource, 'operator-request')
  assert.equal(visual.targetId, lab.id)
  assert.equal(visual.buildingModuleKey, 'energy-lab')
  assert.equal(visual.resolvedBuildingModuleKey, 'energy-lab')
  assert.match(visual.purpose, /^Compile the release evidence · /)
  assert.ok(visual.path.length > 1)
  assert.deepEqual(lab.workItemIds, ['work-real-42'])
  assert.deepEqual(lab.runIds, ['run-real-9'])
  assert.deepEqual(lab.workStatuses, ['assigned'])
  assert.deepEqual(lab.workSources, ['operator-request'])
})

test('an assigned work record can project its named agent before the roster catches up', () => {
  const sim = createSim(createWorld(24))
  applyRuntimeProjection(sim, projection([], [
    workItem({
      agentName: 'Keeper From Work Record',
      role: 'keeper',
    }),
  ]))

  const visual = sim.agents.find(agent => agent.runtimeAgentId === 'worker-real-17')
  assert.ok(visual)
  assert.equal(visual.name, 'Keeper From Work Record')
  assert.equal(visual.role, 'keeper')
  assert.equal(visual.workItemId, 'work-real-42')
  assert.equal(visual.targetId, sim.world.buildings.find(b => b.moduleKey === 'energy-lab')?.id)
})

test('running work enters its real building and stays there without ambient events', () => {
  const sim = createSim(createWorld(7))
  sim.weatherAuto = false
  sim.timeScale = 0
  applyRuntimeProjection(sim, projection(
    [runtimeAgent({ status: 'running' })],
    [workItem({ status: 'running' })],
  ))
  const visual = sim.agents.find(agent => agent.runtimeAgentId === 'worker-real-17')
  const lab = sim.world.buildings.find(building => building.moduleKey === 'energy-lab')
  assert.ok(visual)
  assert.ok(lab)
  sim.agents = sim.agents.filter(agent => agent.provenance === 'runtime')
  assert.equal(sim.events.length, 0)

  updateSim(sim, 120)
  assert.equal(visual.state, 'inside')
  assert.equal(visual.homeId, lab.id)
  assert.equal(visual.workStatus, 'running')
  assert.equal(lab.occupants, 1)

  const eventSeq = sim.eventSeq
  const purpose = visual.purpose
  updateSim(sim, 120)
  assert.equal(visual.state, 'inside')
  assert.equal(visual.purpose, purpose)
  assert.equal(sim.eventSeq, eventSeq)
  assert.equal(lab.occupants, 1)
})

test('review, blocked, failed, and completed remain truthful distinct states', () => {
  const statuses = ['waiting_review', 'blocked', 'failed', 'completed'] as const
  for (const status of statuses) {
    const sim = createSim(createWorld(31))
    applyRuntimeProjection(sim, projection(
      [runtimeAgent({ status: status === 'waiting_review' ? 'waiting' : status === 'failed' || status === 'completed' ? 'idle' : status })],
      [workItem({ status })],
    ))
    const visual = sim.agents.find(agent => agent.runtimeAgentId === 'worker-real-17')
    const lab = sim.world.buildings.find(b => b.moduleKey === 'energy-lab')
    assert.ok(visual)
    assert.ok(lab)
    if (status === 'failed' || status === 'completed') {
      assert.equal(visual.state, 'waiting')
      assert.equal(visual.targetId, undefined)
      assert.equal(visual.workStatus, undefined)
      assert.equal(visual.workItemId, 'work-real-42')
      assert.deepEqual(lab.workStatuses, [status])
    } else {
      assert.equal(visual.workStatus, status)
      assert.match(visual.purpose, new RegExp(workItem({ status }).title))
      assert.equal(visual.targetId, lab.id)
    }
  }
})

test('idle and offline collaborators retain identity but never bind or route to active parent work', () => {
  const sim = createSim(createWorld(314))
  sim.weatherAuto = false
  sim.timeScale = 0
  const task = workItem({ status: 'running' })
  applyRuntimeProjection(sim, projection([
    runtimeAgent({ status: 'running' }),
    runtimeAgent({
      id: 'completed-child',
      name: 'Completed Child',
      status: 'idle',
      workItemId: task.id,
      runId: 'child-run-complete',
    }),
    runtimeAgent({
      id: 'offline-child',
      name: 'Offline Child',
      status: 'offline',
      workItemId: task.id,
      runId: 'child-run-offline',
    }),
  ], [task]))

  const active = sim.agents.find(agent => agent.runtimeAgentId === 'worker-real-17')
  const completed = sim.agents.find(agent => agent.runtimeAgentId === 'completed-child')
  const offline = sim.agents.find(agent => agent.runtimeAgentId === 'offline-child')
  const lab = sim.world.buildings.find(building => building.moduleKey === 'energy-lab')
  assert.ok(active)
  assert.ok(completed)
  assert.ok(offline)
  assert.ok(lab)

  assert.equal(active.targetId, lab.id)
  assert.equal(active.workStatus, 'running')
  for (const [agent, runId] of [
    [completed, 'child-run-complete'],
    [offline, 'child-run-offline'],
  ] as const) {
    assert.equal(agent.state, 'waiting')
    assert.equal(agent.targetId, undefined)
    assert.deepEqual(agent.path, [])
    assert.equal(agent.workStatus, undefined)
    assert.equal(agent.workItemId, task.id)
    assert.equal(agent.runId, runId)
  }

  updateSim(sim, 120)
  assert.equal(active.state, 'inside')
  assert.equal(completed.state, 'waiting')
  assert.equal(offline.state, 'waiting')
  assert.equal(lab.occupants, 1)
})

test('non-live phases stop real motion while preserving retained live evidence', () => {
  for (const phase of ['stale', 'error', 'unavailable'] as const) {
    const sim = createSim(createWorld(2718))
    sim.weatherAuto = false
    sim.timeScale = 0
    const live = projection(
      [runtimeAgent({ status: 'running' })],
      [workItem({ status: 'running' })],
    )
    applyRuntimeClientState(sim, {
      phase: 'live',
      projection: live,
    })
    updateSim(sim, 120)
    const lab = sim.world.buildings.find(building => building.moduleKey === 'energy-lab')
    assert.ok(lab)
    assert.equal(lab.occupants, 1)
    assert.deepEqual(lab.workItemIds, ['work-real-42'])

    const retained = {
      phase,
      projection: live,
      error: phase === 'error' ? 'transport failed' : undefined,
    }
    applyRuntimeClientState(sim, retained)

    assert.equal(retained.phase, phase)
    assert.equal(sim.runtimeMode, 'unavailable')
    assert.equal(sim.agents.some(agent => agent.provenance === 'runtime'), false)
    assert.equal(lab.occupants, 0)
    assert.deepEqual(lab.workItemIds, ['work-real-42'])
    assert.deepEqual(lab.workStatuses, ['running'])
    updateSim(sim, 120)
    assert.equal(
      lab.occupants,
      sim.agents.filter(agent =>
        agent.provenance === 'ambient'
        && agent.state === 'inside'
        && agent.homeId === lab.id,
      ).length,
    )
  }
})

test('an unavailable projection removes motion and clears no-longer-current task evidence', () => {
  const sim = createSim(createWorld(1618))
  const live = projection([runtimeAgent()], [workItem()])
  applyRuntimeClientState(sim, { phase: 'live', projection: live })
  const lab = sim.world.buildings.find(building => building.moduleKey === 'energy-lab')
  assert.ok(lab)
  assert.deepEqual(lab.workItemIds, ['work-real-42'])

  applyRuntimeClientState(sim, {
    phase: 'unavailable',
    projection: projection([], [], {
      mode: 'unavailable',
      message: 'runtime absent',
    }),
  })

  assert.equal(sim.runtimeMode, 'unavailable')
  assert.equal(sim.agents.some(agent => agent.provenance === 'runtime'), false)
  assert.deepEqual(lab.workItemIds, [])
  assert.deepEqual(lab.workStatuses, [])
})

test('unmapped physical and unknown modules remain listed but never invent a destination', () => {
  for (const buildingModuleKey of ['physical-bridge', 'module-not-on-this-map']) {
    const sim = createSim(createWorld(99))
    const task = workItem({
      buildingModuleKey,
      source: 'standing-goal',
    })
    applyRuntimeProjection(sim, projection([runtimeAgent()], [task]))

    const visual = sim.agents.find(agent => agent.runtimeAgentId === 'worker-real-17')
    const hall = sim.world.buildings.find(building => building.moduleKey === 'town-shell')
    assert.ok(visual)
    assert.ok(hall)
    assert.equal(visual.state, 'waiting')
    assert.equal(visual.targetId, undefined)
    assert.equal(visual.buildingModuleKey, buildingModuleKey)
    assert.equal(visual.resolvedBuildingModuleKey, undefined)
    assert.equal(visual.workSource, 'standing-goal')
    assert.deepEqual(sim.runtimeUnlocatedWorkItemIds, ['work-real-42'])
    assert.deepEqual(hall.workItemIds, [])
  }
})

test('live idle agents never invent a task, destination, purpose, or event', () => {
  const sim = createSim(createWorld(123))
  sim.weatherAuto = false
  sim.timeScale = 0
  applyRuntimeProjection(sim, projection([
    runtimeAgent({
      status: 'idle',
      workItemId: undefined,
      runId: undefined,
    }),
  ], []))

  const visual = sim.agents.find(agent => agent.runtimeAgentId === 'worker-real-17')
  assert.ok(visual)
  assert.equal(visual.state, 'waiting')
  assert.equal(visual.targetId, undefined)
  assert.equal(visual.workItemId, undefined)
  assert.equal(visual.runId, undefined)
  assert.equal(visual.workStatus, undefined)
  assert.equal(visual.purpose, '空闲 · 等待真实任务')
  assert.equal(sim.events.length, 0)

  updateSim(sim, 1)
  assert.equal(visual.state, 'waiting')
  assert.equal(visual.targetId, undefined)
  assert.equal(visual.workItemId, undefined)
  assert.equal(sim.events.length, 0)

  for (const ambient of sim.agents.filter(agent => agent.provenance === 'ambient' && agent.role !== 'resident')) {
    assert.equal(ambient.state, 'waiting')
    assert.equal(ambient.workItemId, undefined)
    assert.equal(ambient.purpose, '环境角色 · 实时模式已暂停')
  }
})

test('unavailable mode removes stale runtime agents and returns to ambient simulation', () => {
  const sim = createSim(createWorld(456))
  applyRuntimeProjection(sim, projection([runtimeAgent()], [workItem()]))
  applyRuntimeProjection(sim, projection([], [], {
    mode: 'unavailable',
    message: 'runtime endpoint unavailable',
  }))

  assert.equal(sim.runtimeMode, 'unavailable')
  assert.equal(sim.runtimeMessage, 'runtime endpoint unavailable')
  assert.equal(sim.agents.some(agent => agent.provenance === 'runtime'), false)
  assert.equal(
    sim.world.buildings.some(building => (building.workItemIds?.length ?? 0) > 0),
    false,
  )
})

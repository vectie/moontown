import assert from 'node:assert/strict'
import {
  mkdir,
  mkdtemp,
  symlink,
  writeFile,
} from 'node:fs/promises'
import os from 'node:os'
import path from 'node:path'
import test from 'node:test'
import {
  ENERGY_VALLEY_RUNTIME_SCHEMA,
  loadEnergyValleyRuntimeProjection,
} from './vite_energy_valley_runtime.js'

const OBSERVED_AT = '2026-07-28T00:00:00.000Z'
const MISSING_OBSERVED_AT = '1970-01-01T00:00:00.000Z'

async function fixtureRoot({ heartbeatMs = Date.parse(OBSERVED_AT) } = {}) {
  const root = await mkdtemp(path.join(os.tmpdir(), 'moontown-energy-runtime-'))
  await mkdir(path.join(root, 'watchers'), { recursive: true })
  await mkdir(path.join(root, 'operator-requests'), { recursive: true })
  if (heartbeatMs !== null) {
    await writeJson(path.join(root, 'daemon-runtime.json'), {
      status: 'running',
      last_heartbeat_ms: String(heartbeatMs),
      last_tick_finished_ms: '0',
    })
  }
  return root
}

async function writeJson(filename, value) {
  await mkdir(path.dirname(filename), { recursive: true })
  await writeFile(filename, JSON.stringify(value), 'utf8')
}

async function writeJsonl(filename, rows) {
  await mkdir(path.dirname(filename), { recursive: true })
  await writeFile(
    filename,
    rows.map(row => JSON.stringify(row)).join('\n') + '\n',
    'utf8',
  )
}

test('missing runtime state is explicitly unavailable and empty', async () => {
  const root = await fixtureRoot()
  const projection = await loadEnergyValleyRuntimeProjection({
    stateRoot: path.join(root, 'missing'),
    observedAt: OBSERVED_AT,
  })

  assert.deepEqual(projection, {
    schema: ENERGY_VALLEY_RUNTIME_SCHEMA,
    mode: 'unavailable',
    observedAt: MISSING_OBSERVED_AT,
    tasks: [],
    agents: [],
    message: 'MoonTown runtime state is unavailable.',
  })
})

test('durable daemon heartbeat controls freshness instead of request time', async () => {
  const heartbeatMs = Date.parse('2026-07-27T23:00:00.000Z')
  const tickFinishedMs = Date.parse('2026-07-27T23:01:00.000Z')
  const root = await fixtureRoot({ heartbeatMs })
  await writeJson(path.join(root, 'daemon-runtime.json'), {
    status: 'running',
    last_heartbeat_ms: String(heartbeatMs),
    last_tick_finished_ms: String(tickFinishedMs),
  })
  await writeJsonl(
    path.join(root, 'operator-requests/requests.jsonl'),
    [{
      id: 'operator-stale',
      title: 'Queued without a fresh executor',
      prompt: 'Wait for the daemon.',
      target_book_id: 'research-opc',
      status: 'accepted',
    }],
  )

  const projection = await loadEnergyValleyRuntimeProjection({
    stateRoot: root,
    observedAt: '2099-01-01T00:00:00.000Z',
  })

  assert.equal(projection.mode, 'live')
  assert.equal(projection.observedAt, '2026-07-27T23:01:00.000Z')
  assert.equal(projection.tasks[0].id, 'operator-stale')
})

test('operator ledger without durable executor time remains immediately stale', async () => {
  const root = await fixtureRoot({ heartbeatMs: null })
  await writeJsonl(
    path.join(root, 'operator-requests/requests.jsonl'),
    [{
      id: 'operator-no-heartbeat',
      title: 'Queued request',
      prompt: 'Do not claim a fresh executor.',
      target_book_id: 'research-opc',
      status: 'accepted',
    }],
  )

  const projection = await loadEnergyValleyRuntimeProjection({
    stateRoot: root,
  })

  assert.equal(projection.mode, 'live')
  assert.equal(projection.observedAt, MISSING_OBSERVED_AT)
  assert.equal(projection.tasks[0].status, 'queued')
})

test('stopped heartbeat alone cannot make queued operator work fresh', async () => {
  const root = await fixtureRoot({ heartbeatMs: null })
  await writeJson(path.join(root, 'daemon-runtime.json'), {
    status: 'stopped',
    last_heartbeat_ms: String(Date.parse(OBSERVED_AT)),
    last_tick_finished_ms: '0',
  })
  await writeJsonl(
    path.join(root, 'operator-requests/requests.jsonl'),
    [{
      id: 'operator-stopped',
      title: 'Queued request',
      prompt: 'Wait for a running executor.',
      target_book_id: 'research-opc',
      status: 'accepted',
    }],
  )

  const projection = await loadEnergyValleyRuntimeProjection({
    stateRoot: root,
  })

  assert.equal(projection.mode, 'live')
  assert.equal(projection.observedAt, MISSING_OBSERVED_AT)
})

test('town task and execution project real worker lifecycle and authored building', async () => {
  const root = await fixtureRoot()
  await writeJson(path.join(root, 'daemon.json'), {
    daemon_id: 'mayor',
    tick_sequence: 42,
  })
  await writeJson(path.join(root, 'town.json'), {
    town: {
      workers: [{
        id: 'keeper-policy',
        name: 'Policy Keeper',
        book_id: 'wenyu-policy-hall',
        role: 'MemoryKeeper',
        status: 'Running',
      }],
      tasks: [{
        id: 'task-policy',
        book_id: 'wenyu-policy-hall',
        title: 'Review subsidy evidence',
        prompt: 'Verify the cited policy.',
        status: 'Running',
      }],
      executions: [{
        task_id: 'task-policy',
        book_id: 'wenyu-policy-hall',
        packet_path: '/runtime/packets/task-policy.json',
        run_id: 'run-policy',
        assigned_worker_id: 'keeper-policy',
        status: 'ReviewQueued',
        summary: 'Evidence is ready for operator review.',
        heartbeat_tick: 42,
      }],
    },
    event_count: 0,
  })

  const projection = await loadEnergyValleyRuntimeProjection({
    stateRoot: root,
    booksRootPath: path.join(root, 'books'),
    observedAt: OBSERVED_AT,
  })

  assert.equal(projection.mode, 'live')
  assert.equal(projection.tick, 42)
  assert.deepEqual(projection.tasks, [{
    id: 'task-policy',
    title: 'Review subsidy evidence',
    status: 'waiting_review',
    buildingModuleKey: 'policy-hall',
    artifacts: ['/runtime/packets/task-policy.json'],
    source: 'town-runtime',
    agentId: 'keeper-policy',
    agentName: 'Policy Keeper',
    role: 'keeper',
    runId: 'run-policy',
    bookId: 'wenyu-policy-hall',
    summary: 'Evidence is ready for operator review.',
  }])
  assert.deepEqual(projection.agents, [{
    id: 'keeper-policy',
    name: 'Policy Keeper',
    role: 'keeper',
    status: 'waiting',
    buildingModuleKey: 'policy-hall',
    workItemId: 'task-policy',
    runId: 'run-policy',
  }])
})

test('building aliases match the procedural Energy Valley module keys', async () => {
  const root = await fixtureRoot()
  await writeJson(path.join(root, 'town.json'), {
    town: {
      workers: [],
      tasks: [
        {
          id: 'vitality',
          book_id: 'wenyu-vitality-dashboard',
          title: 'Refresh vitality',
          status: 'Pending',
        },
        {
          id: 'story',
          book_id: 'wenyu-broadcast-tower',
          title: 'Draft story',
          status: 'Pending',
        },
        {
          id: 'research',
          book_id: 'research-ai-agents',
          title: 'Research agents',
          status: 'Running',
        },
        {
          id: 'dynamic-research',
          book_id: 'research-agent-work-projection',
          title: 'Research agent work projection',
          status: 'Pending',
        },
        {
          id: 'bridge',
          book_id: 'wenyu-physical-bridge',
          title: 'Inspect bridge',
          status: 'Blocked',
        },
      ],
      executions: [],
    },
  })

  const projection = await loadEnergyValleyRuntimeProjection({
    stateRoot: root,
    observedAt: OBSERVED_AT,
  })
  assert.deepEqual(
    projection.tasks.map(task => [task.id, task.buildingModuleKey]),
    [
      ['vitality', 'vitality-tower'],
      ['story', 'story-radar'],
      ['research', 'energy-lab'],
      ['dynamic-research', 'energy-lab'],
      ['bridge', 'physical-bridge'],
    ],
  )
})

test('work without a book remains unlocated instead of falling back to town hall', async () => {
  const root = await fixtureRoot()
  await writeJson(path.join(root, 'town.json'), {
    town: {
      workers: [],
      tasks: [
        {
          id: 'unlocated-work',
          title: 'Investigate an unscoped request',
          status: 'Pending',
        },
      ],
      executions: [],
    },
  })

  const projection = await loadEnergyValleyRuntimeProjection({
    stateRoot: root,
    observedAt: OBSERVED_AT,
  })

  assert.equal(projection.tasks[0].buildingModuleKey, 'unlocated')
})

test('watcher, standing-goal, and operator ledgers remain truthful without duplicates', async () => {
  const root = await fixtureRoot()
  await writeJson(path.join(root, 'daemon.json'), { tick_sequence: 50 })
  await writeJson(path.join(root, 'standing-goals.json'), [
    {
      id: 'watch-opc',
      title: 'Watch OPC evidence',
      prompt: 'Check approved sources.',
      target_book_id: 'research-opc',
      next_due_tick: 80,
      enabled: true,
    },
    {
      id: 'watch-hardware',
      title: 'Watch hardware',
      prompt: 'Check hardware sources.',
      target_book_id: 'research-ai-hardware',
      next_due_tick: 20,
      enabled: true,
    },
  ])
  await writeJsonl(path.join(root, 'watchers/watch-opc.jsonl'), [
    {
      goal_id: 'watch-opc',
      tick: 40,
      target_book_id: 'research-opc',
      decision: 'NoChange',
      detail: 'standing_goal_decision: no_change',
      task_id: 'standing-watch-opc-tick-40',
      run_id: 'run-opc',
    },
  ])
  await writeJsonl(
    path.join(root, 'operator-requests/requests.jsonl'),
    [
      {
        id: 'operator-opc',
        standing_goal_id: 'watch-opc',
        title: 'Watch OPC evidence',
        target_book_id: 'research-opc',
        status: 'accepted',
      },
      {
        id: 'operator-policy',
        title: 'One-off policy request',
        prompt: 'Review the application.',
        target_book_id: 'wenyu-policy-hall',
        status: 'accepted',
        created_at: OBSERVED_AT,
      },
    ],
  )

  const projection = await loadEnergyValleyRuntimeProjection({
    stateRoot: root,
    observedAt: OBSERVED_AT,
  })

  assert.deepEqual(
    projection.tasks.map(task => [task.source, task.id, task.status]),
    [
      ['watcher', 'standing-watch-opc-tick-40', 'completed'],
      ['standing-goal', 'standing-goal:watch-hardware', 'queued'],
      ['operator-request', 'operator-policy', 'queued'],
    ],
  )
  assert.equal(projection.tasks[0].buildingModuleKey, 'energy-lab')
  assert.equal(projection.tasks[1].buildingModuleKey, 'energy-lab')
  assert.equal(projection.tasks[2].buildingModuleKey, 'policy-hall')
})

test('missing or unknown watcher decisions never fabricate completion', async () => {
  const root = await fixtureRoot()
  await writeJsonl(path.join(root, 'watchers/watch-unknown.jsonl'), [
    {
      goal_id: 'watch-unknown',
      tick: 1,
      target_book_id: 'research-opc',
      task_id: 'watch-unknown-task',
    },
  ])
  await writeJsonl(path.join(root, 'watchers/watch-invalid.jsonl'), [
    {
      goal_id: 'watch-invalid',
      tick: 1,
      target_book_id: 'research-opc',
      task_id: 'watch-invalid-task',
      decision: 'UnexpectedDecision',
    },
  ])

  const projection = await loadEnergyValleyRuntimeProjection({
    stateRoot: root,
  })

  assert.deepEqual(
    projection.tasks.map(task => [task.id, task.status]).sort(),
    [
      ['watch-invalid-task', 'blocked'],
      ['watch-unknown-task', 'blocked'],
    ],
  )
})

test('operator request, standing goal, watcher, and town task share stable correlation', async () => {
  const root = await fixtureRoot()
  await writeJson(path.join(root, 'daemon.json'), { tick_sequence: 12 })
  await writeJson(path.join(root, 'standing-goals.json'), [{
    id: 'watch-opc',
    title: 'Watch OPC evidence',
    target_book_id: 'research-opc',
    next_due_tick: 72,
    enabled: true,
  }])
  await writeJsonl(
    path.join(root, 'operator-requests/requests.jsonl'),
    [{
      id: 'operator-123',
      standing_goal_id: 'watch-opc',
      title: 'Watch OPC evidence',
      target_book_id: 'research-opc',
      status: 'accepted',
    }],
  )
  await writeJsonl(path.join(root, 'watchers/watch-opc.jsonl'), [{
    goal_id: 'watch-opc',
    tick: 12,
    target_book_id: 'research-opc',
    decision: 'Update',
    task_id: 'standing-watch-watch-opc-tick-12',
    run_id: 'run-opc',
    detail: [
      'checked_sources_count: 9',
      'new_sources_found: 3',
      'accepted_facts_count: 4',
      'rejected_facts_count: 2',
      'wiki_pages_changed_count: 2',
      'book_changed: yes',
    ].join('\n'),
  }])
  await writeJson(path.join(root, 'town.json'), {
    town: {
      workers: [],
      tasks: [{
        id: 'standing-watch-watch-opc-tick-12',
        book_id: 'research-opc',
        title: 'Watch OPC evidence',
        status: 'Done',
      }],
      executions: [{
        task_id: 'standing-watch-watch-opc-tick-12',
        book_id: 'research-opc',
        run_id: 'run-opc',
        status: 'Completed',
        heartbeat_tick: 12,
      }],
    },
  })

  const projection = await loadEnergyValleyRuntimeProjection({
    stateRoot: root,
    booksRootPath: path.join(root, 'books'),
    observedAt: OBSERVED_AT,
  })

  assert.equal(projection.tasks.length, 1)
  assert.deepEqual(
    {
      id: projection.tasks[0].id,
      requestId: projection.tasks[0].requestId,
      standingGoalId: projection.tasks[0].standingGoalId,
      correlationId: projection.tasks[0].correlationId,
      progress: projection.tasks[0].progress,
    },
    {
      id: 'standing-watch-watch-opc-tick-12',
      requestId: 'operator-123',
      standingGoalId: 'watch-opc',
      correlationId: 'operator-123',
      progress: {
        checkedSources: 9,
        newSources: 3,
        acceptedFacts: 4,
        rejectedFacts: 2,
        pagesChanged: 2,
        bookChanged: true,
      },
    },
  )
})

test('transport completion never hides deferred or explicitly failed work outcomes', async () => {
  const root = await fixtureRoot()
  await writeJson(path.join(root, 'town.json'), {
    town: {
      workers: [],
      tasks: [
        {
          id: 'deferred-task',
          title: 'Deferred import',
          status: 'Done',
        },
        {
          id: 'planning-failed-task',
          title: 'Failed planning',
          status: 'Done',
        },
      ],
      executions: [
        {
          task_id: 'deferred-task',
          status: 'Completed',
          result_decision: 'deferred-transient-infrastructure',
          request_id: 'persisted-request',
          standing_goal_id: 'persisted-goal',
          summary: 'Transport completed without starting durable work.',
        },
        {
          task_id: 'planning-failed-task',
          status: 'Completed',
          summary: 'MoonClaw planning failed before execution.',
        },
      ],
    },
  })

  const projection = await loadEnergyValleyRuntimeProjection({
    stateRoot: root,
    observedAt: OBSERVED_AT,
  })

  assert.deepEqual(
    projection.tasks.map(task => [task.id, task.status]),
    [
      ['deferred-task', 'blocked'],
      ['planning-failed-task', 'failed'],
    ],
  )
  assert.equal(projection.tasks[0].requestId, 'persisted-request')
  assert.equal(projection.tasks[0].standingGoalId, 'persisted-goal')
  assert.equal(projection.tasks[0].correlationId, 'persisted-request')
})

test('latest watcher decision overrides transport lifecycle on the represented town task', async () => {
  const root = await fixtureRoot()
  await writeJson(path.join(root, 'standing-goals.json'), [{
    id: 'watch-import',
    title: 'Watch import',
    target_book_id: 'research-opc',
    enabled: true,
    next_due_tick: 60,
  }])
  await writeJson(path.join(root, 'town.json'), {
    town: {
      workers: [],
      tasks: [{
        id: 'standing-watch-watch-import-tick-10',
        book_id: 'research-opc',
        title: 'Watch import',
        status: 'Assigned',
      }],
      executions: [{
        task_id: 'standing-watch-watch-import-tick-10',
        book_id: 'research-opc',
        run_id: 'run-import',
        status: 'ProposalImported',
      }],
    },
  })
  await writeJsonl(path.join(root, 'watchers/watch-import.jsonl'), [{
    goal_id: 'watch-import',
    task_id: 'standing-watch-watch-import-tick-10',
    run_id: 'run-import',
    target_book_id: 'research-opc',
    decision: 'Deferred',
    detail: [
      'standing_goal_decision: deferred',
      'checked_sources_count: 0',
      'book_changed: no',
      'Detached import receipt recorded a transient infrastructure error.',
    ].join('\n'),
  }])

  const projection = await loadEnergyValleyRuntimeProjection({
    stateRoot: root,
    observedAt: OBSERVED_AT,
  })

  assert.equal(projection.tasks.length, 1)
  assert.equal(projection.tasks[0].status, 'blocked')
  assert.match(projection.tasks[0].summary, /standing_goal_decision: deferred/)
  assert.deepEqual(projection.tasks[0].progress, {
    checkedSources: 0,
    bookChanged: false,
  })
})

test('detached standing watch waiting for its receipt remains in flight', async () => {
  const root = await fixtureRoot()
  await writeJson(path.join(root, 'standing-goals.json'), [{
    id: 'watch-import',
    title: 'Watch import',
    target_book_id: 'research-opc',
    enabled: true,
    next_due_tick: 60,
  }])
  await writeJson(path.join(root, 'town.json'), {
    town: {
      workers: [],
      tasks: [{
        id: 'standing-watch-watch-import-tick-10',
        book_id: 'research-opc',
        title: 'Watch import',
        status: 'Assigned',
      }],
      executions: [{
        task_id: 'standing-watch-watch-import-tick-10',
        book_id: 'research-opc',
        status: 'ProposalImported',
      }],
    },
  })
  await writeJsonl(path.join(root, 'watchers/watch-import.jsonl'), [{
    goal_id: 'watch-import',
    task_id: 'standing-watch-watch-import-tick-10',
    target_book_id: 'research-opc',
    decision: 'Deferred',
    detail: 'Launched detached MoonClaw import; waiting for receipt /tmp/run.json.',
  }])

  const projection = await loadEnergyValleyRuntimeProjection({
    stateRoot: root,
    observedAt: OBSERVED_AT,
  })

  assert.equal(projection.tasks[0].status, 'assigned')
})

test('transient infrastructure cannot masquerade as a no-change completion', async () => {
  const root = await fixtureRoot()
  await writeJson(path.join(root, 'town.json'), {
    town: {
      workers: [],
      tasks: [{
        id: 'standing-watch-watch-import-tick-10',
        book_id: 'research-opc',
        title: 'Watch import',
        status: 'Done',
      }],
      executions: [{
        task_id: 'standing-watch-watch-import-tick-10',
        book_id: 'research-opc',
        status: 'Completed',
      }],
    },
  })
  await writeJsonl(path.join(root, 'watchers/watch-import.jsonl'), [{
    goal_id: 'watch-import',
    task_id: 'standing-watch-watch-import-tick-10',
    target_book_id: 'research-opc',
    decision: 'NoChange',
    detail: [
      'Compiler failed before research began.',
      'keeper_auto_triage: transient_infrastructure_contention',
      'checked_sources_count: 0',
      'book_changed: no',
    ].join('\n'),
  }])

  const projection = await loadEnergyValleyRuntimeProjection({
    stateRoot: root,
    observedAt: OBSERVED_AT,
  })

  assert.equal(projection.tasks[0].status, 'blocked')
  assert.match(projection.tasks[0].summary, /Compiler failed/)
})

test('result links expose only verified known files under the configured books root', async () => {
  const root = await fixtureRoot()
  const booksRoot = path.join(root, 'books')
  const bookRoot = path.join(booksRoot, 'research opc')
  await writeJson(path.join(root, 'town.json'), {
    town: {
      workers: [],
      tasks: [{
        id: 'task-results',
        book_id: 'research opc',
        title: 'Review results',
        status: 'Done',
      }],
      executions: [{
        task_id: 'task-results',
        book_id: 'research opc',
        artifacts: [
          '/private/runtime/raw-report.md',
          '../../outside.html',
        ],
        status: 'Completed',
      }],
    },
  })
  await mkdir(path.join(bookRoot, 'book/synthesis'), { recursive: true })
  await mkdir(path.join(bookRoot, 'book/site/generated'), { recursive: true })
  await mkdir(path.join(bookRoot, 'raw'), { recursive: true })
  await writeFile(
    path.join(bookRoot, 'book/synthesis/report.html'),
    '<h1>Report</h1>',
    'utf8',
  )
  await writeFile(
    path.join(bookRoot, 'book/synthesis/evidence.html'),
    '<h1>Evidence</h1>',
    'utf8',
  )
  await writeFile(
    path.join(bookRoot, 'book/site/generated/index.html'),
    '<h1>Site</h1>',
    'utf8',
  )
  await writeFile(
    path.join(bookRoot, 'raw/private.html'),
    '<h1>Private</h1>',
    'utf8',
  )

  const projection = await loadEnergyValleyRuntimeProjection({
    stateRoot: root,
    booksRootPath: booksRoot,
    observedAt: OBSERVED_AT,
  })

  assert.deepEqual(projection.tasks[0].resultLinks, [
    {
      label: 'Current book report',
      url: '/book-output/research%20opc/book/synthesis/report.html',
      kind: 'report',
    },
    {
      label: 'Current book evidence',
      url: '/book-output/research%20opc/book/synthesis/evidence.html',
      kind: 'evidence',
    },
    {
      label: 'Current book site',
      url: '/book-output/research%20opc/book/site/generated/index.html',
      kind: 'site',
    },
  ])
  assert.equal(
    projection.tasks[0].resultLinks.some(link =>
      link.url.includes('raw') || link.url.includes('private')),
    false,
  )
})

test('current-book result links appear only for review or completed work', async () => {
  const root = await fixtureRoot()
  const booksRoot = path.join(root, 'books')
  const reportPath = path.join(
    booksRoot,
    'research-opc/book/synthesis/report.html',
  )
  await writeJson(path.join(root, 'town.json'), {
    town: {
      workers: [],
      tasks: [
        { id: 'queued', book_id: 'research-opc', status: 'Pending' },
        { id: 'running', book_id: 'research-opc', status: 'Running' },
        { id: 'blocked', book_id: 'research-opc', status: 'Blocked' },
        { id: 'failed', book_id: 'research-opc', status: 'Failed' },
        { id: 'review', book_id: 'research-opc', status: 'Running' },
        { id: 'completed', book_id: 'research-opc', status: 'Done' },
      ],
      executions: [
        { task_id: 'review', status: 'ReviewQueued' },
        { task_id: 'completed', status: 'Completed' },
      ],
    },
  })
  await mkdir(path.dirname(reportPath), { recursive: true })
  await writeFile(reportPath, '<h1>Current report</h1>', 'utf8')

  const projection = await loadEnergyValleyRuntimeProjection({
    stateRoot: root,
    booksRootPath: booksRoot,
  })
  const resultKinds = Object.fromEntries(
    projection.tasks.map(task => [
      task.id,
      task.resultLinks?.map(link => link.kind) || [],
    ]),
  )

  assert.deepEqual(resultKinds, {
    queued: [],
    running: [],
    blocked: [],
    failed: [],
    review: ['report'],
    completed: ['report'],
  })
})

test('result links reject files symlinked from another book', async () => {
  const root = await fixtureRoot()
  const booksRoot = path.join(root, 'books')
  const bookRoot = path.join(booksRoot, 'research-opc')
  const siblingReport = path.join(
    booksRoot,
    'research-sibling/book/synthesis/report.html',
  )
  await writeJson(path.join(root, 'town.json'), {
    town: {
      workers: [],
      tasks: [{
        id: 'completed',
        book_id: 'research-opc',
        status: 'Done',
      }],
      executions: [{ task_id: 'completed', status: 'Completed' }],
    },
  })
  await mkdir(path.dirname(siblingReport), { recursive: true })
  await mkdir(path.join(bookRoot, 'book/synthesis'), { recursive: true })
  await writeFile(siblingReport, '<h1>Sibling report</h1>', 'utf8')
  await symlink(
    siblingReport,
    path.join(bookRoot, 'book/synthesis/report.html'),
  )

  const projection = await loadEnergyValleyRuntimeProjection({
    stateRoot: root,
    booksRootPath: booksRoot,
  })

  assert.equal(projection.tasks[0].resultLinks, undefined)
})

test('persisted child runs attach collaboration and truthful child agents', async () => {
  const root = await fixtureRoot()
  const booksRoot = path.join(root, 'books')
  const parentRun = path.join(
    booksRoot,
    'research-opc/.moonsuite/products/moonclaw/jobs/runs/run-parent',
  )
  await writeJson(path.join(root, 'town.json'), {
    town: {
      workers: [],
      tasks: [{
        id: 'task-collaboration',
        book_id: 'research-opc',
        title: 'Collaborative research',
        status: 'Running',
      }],
      executions: [{
        task_id: 'task-collaboration',
        book_id: 'research-opc',
        run_id: 'run-parent',
        status: 'Running',
      }],
    },
  })
  await writeJson(path.join(parentRun, 'meta.json'), {
    id: 'run-parent',
    status: 'Running',
  })
  await writeJsonl(path.join(parentRun, 'events.jsonl'), [
    {
      event_type: 'child_run.started',
      timestamp: 100,
      data: {
        child_run_id: 'run-child',
        child_family: 'wiki_gather_worker',
      },
    },
  ])

  const projection = await loadEnergyValleyRuntimeProjection({
    stateRoot: root,
    booksRootPath: booksRoot,
    observedAt: OBSERVED_AT,
  })

  assert.deepEqual(projection.tasks[0].collaboration, {
    mode: 'unknown',
    participants: [{
      runId: 'run-child',
      parentRunId: 'run-parent',
      family: 'wiki_gather_worker',
      status: 'running',
      startedAt: 100,
      artifacts: [],
    }],
  })
  assert.deepEqual(projection.agents, [{
    id: 'moonclaw:run-child',
    name: 'wiki_gather_worker',
    role: 'worker',
    status: 'running',
    buildingModuleKey: 'energy-lab',
    workItemId: 'task-collaboration',
    runId: 'run-child',
  }])
})

test('invalid progress and unsafe book ids do not fabricate optional runtime fields', async () => {
  const root = await fixtureRoot()
  const booksRoot = path.join(root, 'books')
  await writeJson(path.join(root, 'standing-goals.json'), [{
    id: 'unsafe-watch',
    target_book_id: '../outside',
    enabled: true,
    next_due_tick: 20,
  }])
  await writeJsonl(path.join(root, 'watchers/unsafe-watch.jsonl'), [{
    goal_id: 'unsafe-watch',
    target_book_id: '../outside',
    task_id: 'unsafe-task',
    decision: 'NoChange',
    detail: [
      'checked_sources_count: not-a-count',
      'accepted_facts_count: -1',
      'book_changed: perhaps',
    ].join('\n'),
  }])
  await mkdir(path.join(root, 'outside/book/synthesis'), { recursive: true })
  await writeFile(
    path.join(root, 'outside/book/synthesis/report.html'),
    '<h1>Outside</h1>',
    'utf8',
  )

  const projection = await loadEnergyValleyRuntimeProjection({
    stateRoot: root,
    booksRootPath: booksRoot,
    observedAt: OBSERVED_AT,
  })

  assert.equal(projection.tasks[0].progress, undefined)
  assert.equal(projection.tasks[0].resultLinks, undefined)
})

test('invalid snapshot does not fabricate live work', async () => {
  const root = await fixtureRoot({ heartbeatMs: null })
  await writeFile(path.join(root, 'town.json'), '{invalid', 'utf8')
  const projection = await loadEnergyValleyRuntimeProjection({
    stateRoot: root,
    observedAt: OBSERVED_AT,
  })
  assert.equal(projection.mode, 'unavailable')
  assert.deepEqual(projection.tasks, [])
  assert.deepEqual(projection.agents, [])
})

import assert from 'node:assert/strict'
import {
  mkdir,
  mkdtemp,
  realpath,
  symlink,
  writeFile,
} from 'node:fs/promises'
import os from 'node:os'
import path from 'node:path'
import test from 'node:test'
import { loadEnergyValleyCollaboration } from './vite_energy_valley_collaboration.js'

async function fixture() {
  const root = await mkdtemp(path.join(os.tmpdir(), 'moontown-collaboration-'))
  const booksRootPath = path.join(root, 'books')
  await mkdir(booksRootPath, { recursive: true })
  return { root, booksRootPath }
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

function task(overrides = {}) {
  return {
    id: 'task-research',
    bookId: 'research-agent-work',
    runId: 'run-parent',
    buildingModuleKey: 'energy-lab',
    ...overrides,
  }
}

function runDir(booksRootPath, bookId, runId, legacy = false) {
  const jobs = legacy
    ? path.join(booksRootPath, bookId, 'moonclaw-jobs')
    : path.join(
        booksRootPath,
        bookId,
        '.moonsuite/products/moonclaw/jobs',
      )
  return legacy ? path.join(jobs, runId) : path.join(jobs, 'runs', runId)
}

test('persisted parent events and child metadata prove distinct sequential collaborators', async () => {
  const { booksRootPath } = await fixture()
  const parent = runDir(booksRootPath, 'research-agent-work', 'run-parent')
  const gather = runDir(booksRootPath, 'research-agent-work', 'run-gather')
  const review = runDir(booksRootPath, 'research-agent-work', 'run-review')
  await writeJson(path.join(parent, 'meta.json'), {
    id: 'run-parent',
    status: 'Succeeded',
  })
  await writeJson(path.join(gather, 'meta.json'), {
    id: 'run-gather',
    parent_run_id: 'run-parent',
    parent_step_id: 'gather_authoritative_evidence',
    status: 'Succeeded',
    started_at: 100,
    finished_at: 180,
  })
  await writeJson(path.join(review, 'meta.json'), {
    id: 'run-review',
    parent_run_id: 'run-parent',
    parent_step_id: 'review_revisions',
    status: 'Succeeded',
    started_at: 200,
    finished_at: 260,
  })
  await writeJsonl(path.join(parent, 'events.jsonl'), [
    {
      event_type: 'child_run.started',
      timestamp: 100,
      data: {
        child_run_id: 'run-gather',
        child_family: 'wiki_gather_worker',
      },
    },
    {
      event_type: 'child_run.succeeded',
      timestamp: 180,
      data: {
        child_run_id: 'run-gather',
        child_family: 'wiki_gather_worker',
      },
    },
    {
      event_type: 'child_run.started',
      timestamp: 200,
      data: {
        child_run_id: 'run-review',
        child_family: 'wiki_review_worker',
      },
    },
    {
      event_type: 'child_run.succeeded',
      timestamp: 260,
      data: {
        child_run_id: 'run-review',
        child_family: 'wiki_review_worker',
      },
    },
  ])
  await writeFile(
    path.join(booksRootPath, 'research-agent-work', 'raw-evidence.md'),
    '# Evidence',
    'utf8',
  )
  await writeJson(path.join(gather, 'result.json'), {
    artifacts: ['raw-evidence.md', 'missing-claim.md'],
  })

  const result = await loadEnergyValleyCollaboration({
    tasks: [task()],
    booksRootPath,
  })

  assert.equal(result.byTaskId['task-research'].mode, 'sequential')
  assert.deepEqual(result.byTaskId['task-research'].participants, [
    {
      runId: 'run-gather',
      parentRunId: 'run-parent',
      family: 'wiki_gather_worker',
      status: 'completed',
      startedAt: 100,
      completedAt: 180,
      artifacts: ['raw-evidence.md'],
    },
    {
      runId: 'run-review',
      parentRunId: 'run-parent',
      family: 'wiki_review_worker',
      status: 'completed',
      startedAt: 200,
      completedAt: 260,
      artifacts: [],
    },
  ])
  assert.deepEqual(result.agents, [
    {
      id: 'moonclaw:run-gather',
      name: 'wiki_gather_worker',
      role: 'worker',
      status: 'idle',
      buildingModuleKey: 'energy-lab',
      workItemId: 'task-research',
      runId: 'run-gather',
    },
    {
      id: 'moonclaw:run-review',
      name: 'wiki_review_worker',
      role: 'worker',
      status: 'idle',
      buildingModuleKey: 'energy-lab',
      workItemId: 'task-research',
      runId: 'run-review',
    },
  ])
})

test('overflowed negative runtime timestamps do not invalidate collaboration', async () => {
  const { booksRootPath } = await fixture()
  const parent = runDir(booksRootPath, 'research-agent-work', 'run-parent')
  const child = runDir(booksRootPath, 'research-agent-work', 'run-child')
  await writeJson(path.join(parent, 'meta.json'), {
    id: 'run-parent',
    status: 'Failed',
  })
  await writeJson(path.join(child, 'meta.json'), {
    id: 'run-child',
    parent_run_id: 'run-parent',
    status: 'Failed',
    started_at: -1494752574,
    finished_at: -1494748500,
  })
  await writeJsonl(path.join(parent, 'events.jsonl'), [{
    event_type: 'child_run.failed',
    timestamp: -1494748500,
    data: {
      child_run_id: 'run-child',
      child_family: 'extension',
    },
  }])

  const result = await loadEnergyValleyCollaboration({
    tasks: [task()],
    booksRootPath,
  })

  assert.deepEqual(result.byTaskId['task-research'].participants, [{
    runId: 'run-child',
    parentRunId: 'run-parent',
    family: 'extension',
    status: 'failed',
    artifacts: [],
  }])
})

test('discovers real child workspaces nested below the top-level run', async () => {
  const { root, booksRootPath } = await fixture()
  const jobs = path.join(root, '.moonsuite/products/moonclaw/jobs')
  const parentStore = path.join(jobs, 'runs', 'run-parent')
  const parentWorkspace = path.join(jobs, 'run-parent')
  const childWorkspace = path.join(
    parentWorkspace,
    'moonclaw-subjobs',
    'run-gather',
  )
  await writeJson(path.join(parentStore, 'meta.json'), {
    id: 'run-parent',
    status: 'Succeeded',
    workspace_dir: parentWorkspace,
  })
  await writeJson(path.join(parentWorkspace, 'run.json'), {
    run_id: 'run-parent',
    workspace_dir: parentWorkspace,
  })
  await writeJson(path.join(childWorkspace, 'run.json'), {
    run_id: 'run-gather',
    parent_run_id: 'run-parent',
    workspace_dir: childWorkspace,
  })
  await writeJsonl(path.join(parentStore, 'events.jsonl'), [
    {
      event_type: 'child_run.started',
      timestamp: 100,
      data: {
        child_run_id: 'run-gather',
        child_family: 'wiki_gather_worker',
      },
    },
    {
      event_type: 'child_run.succeeded',
      timestamp: 200,
      data: {
        child_run_id: 'run-gather',
        child_family: 'wiki_gather_worker',
      },
    },
  ])
  await writeJson(path.join(childWorkspace, 'result.json'), {
    artifacts: ['evidence.md', 'missing.md'],
  })
  await writeFile(path.join(childWorkspace, 'evidence.md'), 'persisted', 'utf8')

  const result = await loadEnergyValleyCollaboration({
    tasks: [task()],
    booksRootPath,
  })

  assert.deepEqual(result.byTaskId['task-research'].participants, [{
    runId: 'run-gather',
    parentRunId: 'run-parent',
    family: 'wiki_gather_worker',
    status: 'completed',
    artifacts: ['evidence.md'],
    startedAt: 100,
    completedAt: 200,
  }])
  assert.deepEqual(result.agents.map(agent => agent.id), [
    'moonclaw:run-gather',
  ])
})

test('actual overlapping timestamps are required to label collaboration parallel', async () => {
  const { booksRootPath } = await fixture()
  const parent = runDir(
    booksRootPath,
    'research-agent-work',
    'run-parent',
    true,
  )
  await writeJson(path.join(parent, 'run.json'), {
    run_id: 'run-parent',
    status: 'Running',
  })
  await writeJsonl(path.join(parent, 'events.jsonl'), [
    {
      type: 'child_run.started',
      timestamp: '2026-07-28T10:00:00Z',
      data: {
        childRunId: 'run-a',
        childFamily: 'wiki_gather_worker',
      },
    },
    {
      type: 'child_run.started',
      timestamp: '2026-07-28T10:01:00Z',
      data: {
        childRunId: 'run-b',
        childFamily: 'wiki_review_worker',
      },
    },
    {
      type: 'child_run.succeeded',
      timestamp: '2026-07-28T10:02:00Z',
      data: {
        childRunId: 'run-a',
        childFamily: 'wiki_gather_worker',
      },
    },
    {
      type: 'child_run.succeeded',
      timestamp: '2026-07-28T10:03:00Z',
      data: {
        childRunId: 'run-b',
        childFamily: 'wiki_review_worker',
      },
    },
  ])

  const result = await loadEnergyValleyCollaboration({
    tasks: [task()],
    booksRootPath,
  })
  assert.equal(result.byTaskId['task-research'].mode, 'parallel')
  assert.equal(result.byTaskId['task-research'].participants.length, 2)
})

test('incomplete timestamps preserve collaboration as unknown', async () => {
  const { booksRootPath } = await fixture()
  const parent = runDir(booksRootPath, 'research-agent-work', 'run-parent')
  await writeJson(path.join(parent, 'meta.json'), {
    id: 'run-parent',
    status: 'Running',
  })
  await writeJsonl(path.join(parent, 'events.jsonl'), [
    {
      event_type: 'child_run.started',
      timestamp: 100,
      data: {
        child_run_id: 'run-a',
        child_family: 'wiki_gather_worker',
      },
    },
    {
      event_type: 'child_run.started',
      timestamp: 200,
      data: {
        child_run_id: 'run-b',
        child_family: 'wiki_review_worker',
      },
    },
  ])

  const result = await loadEnergyValleyCollaboration({
    tasks: [task()],
    booksRootPath,
  })
  assert.equal(result.byTaskId['task-research'].mode, 'unknown')
})

test('missing or corrupt parent state is unavailable and emits no agents', async () => {
  const { booksRootPath } = await fixture()
  const corrupt = runDir(booksRootPath, 'research-agent-work', 'run-parent')
  await mkdir(corrupt, { recursive: true })
  await writeFile(path.join(corrupt, 'meta.json'), '{not json', 'utf8')
  await writeJsonl(path.join(corrupt, 'events.jsonl'), [{
    event_type: 'child_run.succeeded',
    data: {
      child_run_id: 'run-fabricated',
      child_family: 'wiki_gather_worker',
    },
  }])

  const result = await loadEnergyValleyCollaboration({
    tasks: [task(), task({ id: 'missing', runId: 'run-missing' })],
    booksRootPath,
  })
  assert.deepEqual(result, { agents: [], byTaskId: {} })
})

test('unrelated child records and unanchored event claims never fabricate collaborators', async () => {
  const { booksRootPath } = await fixture()
  const parent = runDir(booksRootPath, 'research-agent-work', 'run-parent')
  const unrelated = runDir(
    booksRootPath,
    'research-agent-work',
    'run-unrelated',
  )
  await writeJson(path.join(parent, 'meta.json'), {
    id: 'run-parent',
    status: 'Succeeded',
  })
  await writeJson(path.join(unrelated, 'meta.json'), {
    id: 'run-unrelated',
    parent_run_id: 'some-other-parent',
    family: 'wiki_gather_worker',
    status: 'Succeeded',
  })
  await writeJsonl(path.join(parent, 'events.jsonl'), [
    {
      event_type: 'child_run.succeeded',
      timestamp: 100,
      data: {
        child_run_id: '../escape',
        child_family: 'wiki_gather_worker',
      },
    },
    {
      event_type: 'step.succeeded',
      timestamp: 110,
      data: {
        child_run_id: 'not-a-child-event',
        child_family: 'wiki_review_worker',
      },
    },
  ])

  const result = await loadEnergyValleyCollaboration({
    tasks: [task()],
    booksRootPath,
  })
  assert.deepEqual(result, { agents: [], byTaskId: {} })
})

test('persisted terminal event wins over stale non-terminal child metadata', async () => {
  const { booksRootPath } = await fixture()
  const parent = runDir(booksRootPath, 'research-agent-work', 'run-parent')
  const child = runDir(booksRootPath, 'research-agent-work', 'run-review')
  await writeJson(path.join(parent, 'meta.json'), {
    id: 'run-parent',
    status: 'Running',
  })
  await writeJson(path.join(child, 'meta.json'), {
    id: 'run-review',
    parent_run_id: 'run-parent',
    status: 'Running',
    started_at: 10,
  })
  await writeJsonl(path.join(parent, 'events.jsonl'), [
    {
      event_type: 'child_run.started',
      timestamp: 10,
      data: {
        child_run_id: 'run-review',
        child_family: 'wiki_review_worker',
      },
    },
    {
      event_type: 'child_run.succeeded',
      timestamp: 20,
      data: {
        child_run_id: 'run-review',
        child_family: 'wiki_review_worker',
      },
    },
  ])

  const result = await loadEnergyValleyCollaboration({
    tasks: [{
      id: 'task-1',
      bookId: 'research-agent-work',
      runId: 'run-parent',
      buildingModuleKey: 'energy-lab',
    }],
    booksRootPath,
  })

  assert.equal(result.byTaskId['task-1'].participants[0].status, 'completed')
  assert.equal(result.agents[0].status, 'idle')
})

test('merges active durable ArtifactRecords for the exact child run', async () => {
  const { root, booksRootPath } = await fixture()
  const jobs = path.join(root, '.moonsuite/products/moonclaw/jobs')
  const parent = path.join(jobs, 'runs', 'run-parent')
  const child = path.join(jobs, 'runs', 'run-review')
  const indexedArtifactPath = path.join(
    jobs,
    'artifacts',
    'artifact-report',
    'report.md',
  )
  const recordArtifactPath = path.join(
    jobs,
    'artifacts',
    'artifact-result',
    'result.json',
  )
  const archivedArtifactPath = path.join(
    jobs,
    'artifacts',
    'artifact-archived',
    'old.md',
  )
  const unrelatedArtifactPath = path.join(
    jobs,
    'artifacts',
    'artifact-unrelated',
    'other.md',
  )
  const outsidePath = path.join(root, 'outside.md')
  const symlinkArtifactPath = path.join(
    jobs,
    'artifacts',
    'artifact-symlink',
    'linked.md',
  )
  await writeJson(path.join(parent, 'meta.json'), {
    id: 'run-parent',
    status: 'Succeeded',
  })
  await writeJson(path.join(child, 'meta.json'), {
    id: 'run-review',
    parent_run_id: 'run-parent',
    status: 'Succeeded',
    started_at: 10,
    finished_at: 20,
  })
  await writeJsonl(path.join(parent, 'events.jsonl'), [
    {
      event_type: 'child_run.started',
      timestamp: 10,
      data: {
        child_run_id: 'run-review',
        child_family: 'wiki_review_worker',
      },
    },
    {
      event_type: 'child_run.succeeded',
      timestamp: 20,
      data: {
        child_run_id: 'run-review',
        child_family: 'wiki_review_worker',
      },
    },
  ])
  await writeJson(path.join(child, 'result.json'), {
    report_artifact_id: 'artifact-report',
    result_artifact_id: 'artifact-result',
  })
  for (const filename of [
    indexedArtifactPath,
    recordArtifactPath,
    archivedArtifactPath,
    unrelatedArtifactPath,
    outsidePath,
  ]) {
    await mkdir(path.dirname(filename), { recursive: true })
    await writeFile(filename, 'persisted', 'utf8')
  }
  await mkdir(path.dirname(symlinkArtifactPath), { recursive: true })
  await symlink(outsidePath, symlinkArtifactPath)
  const artifactRecord = (overrides = {}) => ({
    id: 'artifact-report',
    run_id: 'run-review',
    job_id: 'job.review',
    artifact_type: 'analysis.report',
    logical_key: null,
    version: 1,
    status: 'Active',
    path: indexedArtifactPath,
    content_type: 'text/markdown',
    metadata: {},
    created_at: 20,
    archived_at: null,
    scope: ['job'],
    ...overrides,
  })
  await writeJson(path.join(jobs, 'index', 'artifacts.json'), {
    artifacts: [
      artifactRecord(),
      artifactRecord({
        id: 'artifact-archived',
        status: 'Archived',
        path: archivedArtifactPath,
      }),
      artifactRecord({
        id: 'artifact-unrelated',
        run_id: 'run-someone-else',
        path: unrelatedArtifactPath,
      }),
      artifactRecord({
        id: 'artifact-missing',
        path: path.join(
          jobs,
          'artifacts',
          'artifact-missing',
          'missing.md',
        ),
      }),
      artifactRecord({
        id: 'artifact-outside',
        path: outsidePath,
      }),
      artifactRecord({
        id: 'artifact-symlink',
        path: symlinkArtifactPath,
      }),
    ],
  })
  await writeJson(
    path.join(jobs, 'artifacts', 'artifact-result', 'record.json'),
    artifactRecord({
      id: 'artifact-result',
      artifact_type: 'analysis.result',
      path: recordArtifactPath,
      content_type: 'application/json',
    }),
  )

  const result = await loadEnergyValleyCollaboration({
    tasks: [task()],
    booksRootPath,
  })

  assert.deepEqual(
    result.byTaskId['task-research'].participants[0].artifacts,
    [
      await realpath(indexedArtifactPath),
      await realpath(recordArtifactPath),
    ],
  )
})

test('terminal parent does not project a child with only stale started state', async () => {
  const { booksRootPath } = await fixture()
  const parent = runDir(booksRootPath, 'research-agent-work', 'run-parent')
  const child = runDir(booksRootPath, 'research-agent-work', 'run-review')
  await writeJson(path.join(parent, 'meta.json'), {
    id: 'run-parent',
    status: 'Succeeded',
    finished_at: 30,
  })
  await writeJson(path.join(child, 'meta.json'), {
    id: 'run-review',
    parent_run_id: 'run-parent',
    status: 'Running',
    started_at: 10,
  })
  await writeJsonl(path.join(parent, 'events.jsonl'), [{
    event_type: 'child_run.started',
    timestamp: 10,
    data: {
      child_run_id: 'run-review',
      child_family: 'wiki_review_worker',
    },
  }])

  const result = await loadEnergyValleyCollaboration({
    tasks: [task()],
    booksRootPath,
  })

  assert.deepEqual(result, { agents: [], byTaskId: {} })
})

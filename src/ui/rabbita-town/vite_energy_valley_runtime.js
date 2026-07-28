import { existsSync } from 'node:fs'
import { readdir, readFile, realpath, stat } from 'node:fs/promises'
import path from 'node:path'
import {
  booksRootPath,
  daemonRuntimePath,
  daemonSnapshotPath,
  operatorRequestLedgerPath,
  publicAssetRootPath,
  standingGoalsPath,
  townSnapshotPath,
  watcherDir,
} from './vite_server_paths.js'
import { sendJson } from './vite_server_io.js'
import { loadEnergyValleyCollaboration } from './vite_energy_valley_collaboration.js'

export const ENERGY_VALLEY_RUNTIME_SCHEMA =
  'moontown.energy-valley.runtime.v1'

const MODULE_MANIFEST_PATH = path.join(
  publicAssetRootPath,
  'tilemap/modules/wenyu-town-modules.json',
)

const MODULE_KEY_ALIASES = new Map([
  ['vitality-dashboard', 'vitality-tower'],
  ['broadcast-tower', 'story-radar'],
  ['research-embodied-robotics', 'energy-lab'],
  ['research-ai-agents', 'energy-lab'],
  ['research-opc', 'energy-lab'],
  ['research-llm-training', 'energy-lab'],
  ['research-ai-hardware', 'energy-lab'],
])

const TERMINAL_WORK_STATUSES = new Set(['completed', 'failed'])
const RESULT_LINK_STATUSES = new Set(['completed', 'waiting_review'])
const MISSING_DURABLE_OBSERVATION = '1970-01-01T00:00:00.000Z'

const RESULT_LINK_CANDIDATES = [
  {
    kind: 'report',
    label: 'Current book report',
    paths: ['book/synthesis/report.html', 'book/synthesis/overview.html'],
  },
  {
    kind: 'evidence',
    label: 'Current book evidence',
    paths: ['book/synthesis/evidence.html'],
  },
  {
    kind: 'review',
    label: 'Current book review',
    paths: ['book/reviews/pending.html'],
  },
  {
    kind: 'site',
    label: 'Current book site',
    paths: [
      'book/site/generated/index.html',
      'book/Home.html',
      'book/index.html',
    ],
  },
]

function cleanString(value) {
  const text = typeof value === 'string' ? value.trim() : ''
  return text || undefined
}

function cleanStringArray(value) {
  if (!Array.isArray(value)) return []
  return [...new Set(value.map(cleanString).filter(Boolean))]
}

function enumKey(value) {
  return String(value || '').replace(/[^a-z0-9]/gi, '').toLowerCase()
}

function valueArray(value) {
  return Array.isArray(value) ? value : []
}

function runtimeTick(value) {
  return typeof value === 'number'
    && Number.isSafeInteger(value)
    && value >= 0
    ? value
    : undefined
}

function durableTimestampMs(value) {
  const timestamp = typeof value === 'number'
    ? value
    : typeof value === 'string' && /^\d+$/.test(value.trim())
      ? Number(value.trim())
      : undefined
  if (
    typeof timestamp !== 'number'
    || !Number.isSafeInteger(timestamp)
    || timestamp <= 0
  ) {
    return undefined
  }
  const date = new Date(timestamp)
  return Number.isFinite(date.getTime()) ? timestamp : undefined
}

function durableObservedAt(daemonRuntime) {
  const runtimeStatus = enumKey(daemonRuntime?.status)
  const heartbeat = (
    runtimeStatus === 'running'
    || runtimeStatus === 'starting'
    || runtimeStatus === 'supervising'
  )
    ? durableTimestampMs(daemonRuntime?.last_heartbeat_ms)
    : undefined
  const timestamps = [
    heartbeat,
    durableTimestampMs(daemonRuntime?.last_tick_finished_ms),
  ].filter(value => value !== undefined)
  if (timestamps.length === 0) return MISSING_DURABLE_OBSERVATION
  return new Date(Math.max(...timestamps)).toISOString()
}

function nonNegativeInteger(value) {
  const number = typeof value === 'number'
    ? value
    : typeof value === 'string' && /^\d+$/.test(value.trim())
      ? Number(value.trim())
      : undefined
  return typeof number === 'number'
    && Number.isSafeInteger(number)
    && number >= 0
    ? number
    : undefined
}

function detailValue(row, key) {
  if (row?.[key] !== undefined && row?.[key] !== null) {
    return row[key]
  }
  const detail = cleanString(row?.detail)
  if (!detail) return undefined
  const escaped = key.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  return detail.match(
    new RegExp(`(?:^|\\n)\\s*${escaped}\\s*[:=]\\s*([^\\n]+)`, 'i'),
  )?.[1]?.trim()
}

function watcherProgress(row) {
  const progress = {}
  const checkedSources = nonNegativeInteger(
    detailValue(row, 'checked_sources_count'),
  )
  const newSources = nonNegativeInteger(
    detailValue(row, 'new_sources_found')
      ?? detailValue(row, 'new_source_count'),
  )
  const acceptedFacts = nonNegativeInteger(
    detailValue(row, 'accepted_facts_count'),
  )
  const rejectedFacts = nonNegativeInteger(
    detailValue(row, 'rejected_facts_count'),
  )
  const pagesChanged = nonNegativeInteger(
    detailValue(row, 'wiki_pages_changed_count'),
  )
  const bookChangedValue = detailValue(row, 'book_changed')
  const bookChangedKey = enumKey(bookChangedValue)
  const bookChanged = typeof bookChangedValue === 'boolean'
    ? bookChangedValue
    : ['yes', 'true', '1'].includes(bookChangedKey)
      ? true
      : ['no', 'false', '0'].includes(bookChangedKey)
        ? false
        : undefined

  if (checkedSources !== undefined) progress.checkedSources = checkedSources
  if (newSources !== undefined) progress.newSources = newSources
  if (acceptedFacts !== undefined) progress.acceptedFacts = acceptedFacts
  if (rejectedFacts !== undefined) progress.rejectedFacts = rejectedFacts
  if (pagesChanged !== undefined) progress.pagesChanged = pagesChanged
  if (bookChanged !== undefined) progress.bookChanged = bookChanged
  return Object.keys(progress).length > 0 ? progress : undefined
}

function safeBookSegment(value) {
  const bookId = cleanString(value)
  if (
    !bookId
    || bookId === '.'
    || bookId === '..'
    || bookId !== path.basename(bookId)
    || bookId.includes('/')
    || bookId.includes('\\')
  ) {
    return undefined
  }
  return bookId
}

function encodedRelativeUrlPath(relativePath) {
  return relativePath.split('/').map(encodeURIComponent).join('/')
}

async function resultLinksForBook(bookIdValue, rootPath) {
  const bookId = safeBookSegment(bookIdValue)
  if (!bookId || !existsSync(rootPath)) return []

  const lexicalBookRoot = path.resolve(rootPath, bookId)
  if (!lexicalBookRoot.startsWith(`${path.resolve(rootPath)}${path.sep}`)) {
    return []
  }
  let realRoot
  let realBookRoot
  try {
    realRoot = await realpath(rootPath)
    realBookRoot = await realpath(lexicalBookRoot)
  } catch {
    return []
  }
  if (
    realBookRoot !== path.resolve(realRoot, bookId)
    || !realBookRoot.startsWith(`${realRoot}${path.sep}`)
  ) {
    return []
  }

  const links = []
  for (const candidate of RESULT_LINK_CANDIDATES) {
    for (const relativePath of candidate.paths) {
      const pathname = path.resolve(lexicalBookRoot, relativePath)
      if (!pathname.startsWith(`${lexicalBookRoot}${path.sep}`)) continue
      try {
        const [realPath, fileStat] = await Promise.all([
          realpath(pathname),
          stat(pathname),
        ])
        if (
          !fileStat.isFile()
          || (
            realPath !== realBookRoot
            && !realPath.startsWith(`${realBookRoot}${path.sep}`)
          )
        ) {
          continue
        }
        links.push({
          label: candidate.label,
          url: `/book-output/${encodeURIComponent(bookId)}/${encodedRelativeUrlPath(relativePath)}`,
          kind: candidate.kind,
        })
        break
      } catch {
        // A missing, unreadable, or transient output is not a result link.
      }
    }
  }
  return links
}

async function readJson(pathname) {
  if (!existsSync(pathname)) return { found: false, value: undefined }
  try {
    return {
      found: true,
      value: JSON.parse(await readFile(pathname, 'utf8')),
    }
  } catch {
    return { found: false, value: undefined }
  }
}

async function readJsonl(pathname) {
  if (!existsSync(pathname)) return { found: false, value: [] }
  try {
    const lines = (await readFile(pathname, 'utf8'))
      .split('\n')
      .map(line => line.trim())
      .filter(Boolean)
    let invalid = false
    const rows = lines
      .map(line => {
        try {
          return JSON.parse(line)
        } catch {
          invalid = true
          return undefined
        }
      })
      .filter(Boolean)
    return { found: !invalid, value: invalid ? [] : rows }
  } catch {
    return { found: false, value: [] }
  }
}

async function readWatcherRows(directory) {
  if (!existsSync(directory)) return { found: false, value: [] }
  try {
    const entries = await readdir(directory, { withFileTypes: true })
    const rows = []
    let found = false
    for (const entry of entries) {
      if (!entry.isFile() || !entry.name.endsWith('.jsonl')) continue
      const ledger = await readJsonl(path.join(directory, entry.name))
      found ||= ledger.found
      const fallbackGoalId = entry.name.replace(/\.jsonl$/, '')
      for (const row of ledger.value) {
        rows.push({
          ...row,
          goal_id: cleanString(row?.goal_id) || fallbackGoalId,
        })
      }
    }
    return { found, value: rows }
  } catch {
    return { found: false, value: [] }
  }
}

function townFromSnapshot(value) {
  const town = value && typeof value === 'object' ? value.town : undefined
  if (
    town
    && typeof town === 'object'
    && Array.isArray(town.workers)
    && Array.isArray(town.tasks)
    && Array.isArray(town.executions)
  ) {
    return town
  }
  return undefined
}

function executionOutcomeStatus(execution) {
  const decisionKey = enumKey(
    execution?.result_decision
      ?? execution?.resultDecision
      ?? execution?.decision,
  )
  if (
    decisionKey.includes('deferred')
    || decisionKey.includes('transientinfrastructure')
  ) {
    return 'blocked'
  }
  if (
    decisionKey === 'failed'
    || decisionKey === 'failure'
    || decisionKey === 'rejected'
  ) {
    return 'failed'
  }

  const summary = cleanString(execution?.summary)?.toLowerCase() || ''
  if (
    /(?:standing_goal_decision|keeper_auto_triage)\s*[:=]\s*deferred/.test(
      summary,
    )
    || summary.includes('deferred-transient-infrastructure')
  ) {
    return 'blocked'
  }
  if (summary.includes('planning failed')) return 'failed'
  return undefined
}

function taskStatus(taskValue, execution) {
  const outcomeStatus = executionOutcomeStatus(execution)
  if (outcomeStatus) return outcomeStatus

  switch (enumKey(execution?.status)) {
    case 'packetready':
    case 'proposalimported':
    case 'runconfirmed':
      return 'assigned'
    case 'running':
    case 'awaitingpersistence':
      return 'running'
    case 'reviewqueued':
      return 'waiting_review'
    case 'completed':
      return 'completed'
    case 'stale':
      return 'blocked'
    case 'failed':
      return 'failed'
    default:
      break
  }

  switch (enumKey(taskValue)) {
    case 'assigned':
      return 'assigned'
    case 'running':
      return 'running'
    case 'blocked':
      return 'blocked'
    case 'done':
    case 'completed':
      return 'completed'
    case 'failed':
      return 'failed'
    case 'pending':
    case 'planned':
    default:
      return 'queued'
  }
}

function watcherStatus(decision, detail) {
  if (
    cleanString(detail)
      ?.toLowerCase()
      .includes('keeper_auto_triage: transient_infrastructure_contention')
  ) {
    return 'blocked'
  }
  switch (enumKey(decision)) {
    case 'needsreview':
      return 'waiting_review'
    case 'failed':
      return 'failed'
    case 'deferred':
      return cleanString(detail)?.toLowerCase().includes('waiting for receipt')
        ? 'assigned'
        : 'blocked'
    case 'update':
    case 'nochange':
      return 'completed'
    default:
      return 'blocked'
  }
}

function watcherSummary(row) {
  const detail = cleanString(row?.detail)
  switch (enumKey(row?.decision)) {
    case 'deferred':
      return detail ? `Standing watch deferred. ${detail}` : 'Standing watch deferred.'
    case 'failed':
      return detail ? `Standing watch failed. ${detail}` : 'Standing watch failed.'
    case 'needsreview':
      return detail
        ? `Standing watch needs review. ${detail}`
        : 'Standing watch needs review.'
    default:
      return detail
  }
}

function operatorStatus(status) {
  switch (enumKey(status)) {
    case 'failed':
    case 'rejected':
      return 'failed'
    case 'completed':
    case 'done':
      return 'completed'
    case 'blocked':
      return 'blocked'
    default:
      return 'queued'
  }
}

function workerRole(role) {
  switch (enumKey(role)) {
    case 'mayor':
      return 'mayor'
    case 'keeper':
    case 'memorykeeper':
      return 'keeper'
    default:
      return 'worker'
  }
}

function workerStatus(status) {
  switch (enumKey(status)) {
    case 'running':
      return 'running'
    case 'waiting':
      return 'waiting'
    case 'blocked':
      return 'blocked'
    case 'offline':
      return 'offline'
    case 'idle':
    default:
      return 'idle'
  }
}

async function loadBuildingModuleResolver(moduleManifestPath) {
  const manifest = await readJson(moduleManifestPath)
  const byBook = new Map()
  for (const module of valueArray(manifest.value?.modules)) {
    const bookId = cleanString(module?.book_id)
    const moduleId = cleanString(module?.id)
    if (module?.enabled !== false && bookId && moduleId) {
      byBook.set(bookId, moduleId)
    }
  }

  return bookId => {
    const normalizedBookId = cleanString(bookId)
    if (!normalizedBookId) return 'unlocated'
    const manifestModuleId = byBook.get(normalizedBookId)
    if (manifestModuleId) {
      return MODULE_KEY_ALIASES.get(manifestModuleId) || manifestModuleId
    }
    const fallbackId = normalizedBookId.replace(/^wenyu-/, '')
    const explicitAlias = MODULE_KEY_ALIASES.get(fallbackId)
    if (explicitAlias) return explicitAlias
    if (normalizedBookId.startsWith('research-')) return 'energy-lab'
    return fallbackId
  }
}

function latestExecutions(executions) {
  const byTask = new Map()
  for (const execution of valueArray(executions)) {
    const taskId = cleanString(execution?.task_id)
    if (!taskId) continue
    const previous = byTask.get(taskId)
    const previousTick = Number(previous?.heartbeat_tick || 0)
    const nextTick = Number(execution?.heartbeat_tick || 0)
    if (!previous || nextTick >= previousTick) byTask.set(taskId, execution)
  }
  return byTask
}

function workItemFromTown(task, execution, resolveBuilding, workerById) {
  const id = cleanString(task?.id) || cleanString(execution?.task_id)
  if (!id) return undefined
  const bookId = cleanString(task?.book_id) || cleanString(execution?.book_id)
  const agentId = cleanString(execution?.assigned_worker_id)
  const worker = agentId ? workerById.get(agentId) : undefined
  const item = {
    id,
    title: cleanString(task?.title) || id,
    status: taskStatus(task?.status, execution),
    buildingModuleKey: resolveBuilding(bookId),
    artifacts: cleanStringArray([
      ...valueArray(execution?.artifacts),
      execution?.packet_path,
    ]),
    source: 'town-runtime',
  }
  if (agentId) item.agentId = agentId
  const agentName = cleanString(worker?.name)
  if (agentName) item.agentName = agentName
  const role = cleanString(worker?.role) || cleanString(task?.required_role)
  if (role) item.role = workerRole(role)
  const runId = cleanString(execution?.run_id)
  if (runId) item.runId = runId
  if (bookId) item.bookId = bookId
  const summary = cleanString(execution?.summary) || cleanString(task?.prompt)
  if (summary) item.summary = summary
  const requestId = cleanString(execution?.request_id)
    || cleanString(task?.request_id)
  if (requestId) item.requestId = requestId
  const standingGoalId = cleanString(execution?.standing_goal_id)
    || cleanString(execution?.goal_id)
    || cleanString(task?.standing_goal_id)
    || cleanString(task?.goal_id)
  if (standingGoalId) item.standingGoalId = standingGoalId
  const correlationId = cleanString(execution?.correlation_id)
    || cleanString(task?.correlation_id)
  if (correlationId) item.correlationId = correlationId
  return item
}

function townWorkItems(town, resolveBuilding) {
  const workers = valueArray(town?.workers)
  const workerById = new Map(
    workers
      .map(worker => [cleanString(worker?.id), worker])
      .filter(([id]) => id),
  )
  const executions = latestExecutions(town?.executions)
  const items = []
  const knownTaskIds = new Set()

  for (const task of valueArray(town?.tasks)) {
    const taskId = cleanString(task?.id)
    if (!taskId) continue
    knownTaskIds.add(taskId)
    const item = workItemFromTown(
      task,
      executions.get(taskId),
      resolveBuilding,
      workerById,
    )
    if (item) items.push(item)
  }

  for (const [taskId, execution] of executions) {
    if (knownTaskIds.has(taskId)) continue
    const item = workItemFromTown(
      { id: taskId, title: taskId, book_id: execution?.book_id },
      execution,
      resolveBuilding,
      workerById,
    )
    if (item) items.push(item)
  }
  return items
}

function latestWatcherRows(rows) {
  const latest = new Map()
  for (let index = 0; index < rows.length; index += 1) {
    const row = rows[index]
    const goalId = cleanString(row?.goal_id)
    if (!goalId) continue
    const previous = latest.get(goalId)
    const tick = Number(row?.tick || 0)
    if (!previous || tick > previous.tick || (tick === previous.tick && index > previous.index)) {
      latest.set(goalId, { row, tick, index })
    }
  }
  return [...latest.values()].map(entry => entry.row)
}

function watcherWorkItem(row, goal, resolveBuilding) {
  const goalId = cleanString(row?.goal_id)
  if (!goalId) return undefined
  const bookId = cleanString(row?.target_book_id)
    || cleanString(goal?.target_book_id)
  const item = {
    id: cleanString(row?.task_id) || `watcher:${goalId}`,
    title: cleanString(goal?.title) || `Standing watch · ${goalId}`,
    status: watcherStatus(row?.decision, row?.detail),
    buildingModuleKey: resolveBuilding(bookId),
    artifacts: cleanStringArray(row?.artifacts),
    source: 'watcher',
  }
  const runId = cleanString(row?.run_id)
  if (runId) item.runId = runId
  if (bookId) item.bookId = bookId
  const summary = watcherSummary(row)
  if (summary) item.summary = summary
  item.standingGoalId = goalId
  const progress = watcherProgress(row)
  if (progress) item.progress = progress
  return item
}

function standingGoalWorkItem(goal, resolveBuilding) {
  const id = cleanString(goal?.id)
  if (!id || goal?.enabled === false) return undefined
  const bookId = cleanString(goal?.target_book_id)
  const item = {
    id: `standing-goal:${id}`,
    title: cleanString(goal?.title) || id,
    status: 'queued',
    buildingModuleKey: resolveBuilding(bookId),
    artifacts: [],
    source: 'standing-goal',
  }
  if (bookId) item.bookId = bookId
  const summary = cleanString(goal?.prompt)
  if (summary) item.summary = summary
  item.standingGoalId = id
  return item
}

function operatorRequestWorkItem(request, resolveBuilding) {
  const id = cleanString(request?.id)
  if (!id) return undefined
  const bookId = cleanString(request?.target_book_id)
  const item = {
    id,
    title: cleanString(request?.title) || id,
    status: operatorStatus(request?.status),
    buildingModuleKey: resolveBuilding(bookId),
    artifacts: [],
    source: 'operator-request',
  }
  if (bookId) item.bookId = bookId
  const summary = cleanString(request?.prompt)
  if (summary) item.summary = summary
  const updatedAt = cleanString(request?.updated_at)
    || cleanString(request?.created_at)
  if (updatedAt) item.updatedAt = updatedAt
  item.requestId = id
  const standingGoalId = cleanString(request?.standing_goal_id)
  if (standingGoalId) item.standingGoalId = standingGoalId
  return item
}

function latestRequestsByGoal(rows) {
  const latest = new Map()
  for (const row of rows) {
    const goalId = cleanString(row?.standing_goal_id)
    const requestId = cleanString(row?.id)
    if (goalId && requestId) latest.set(goalId, row)
  }
  return latest
}

function goalIdFromStandingWatchTaskId(taskId, goalIds) {
  const normalizedTaskId = cleanString(taskId)
  if (!normalizedTaskId) return undefined
  return goalIds
    .filter(goalId =>
      normalizedTaskId.match(
        new RegExp(
          `^standing-watch-${goalId.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}-tick-\\d+$`,
        ),
      ))
    .sort((left, right) => right.length - left.length)[0]
}

function correlateTask(item, goalIds, requestsByGoal) {
  const standingGoalId = cleanString(item.standingGoalId)
    || goalIdFromStandingWatchTaskId(item.id, goalIds)
  if (standingGoalId) item.standingGoalId = standingGoalId

  const explicitRequestId = cleanString(item.requestId)
  const linkedRequest = standingGoalId
    ? requestsByGoal.get(standingGoalId)
    : undefined
  const requestId = explicitRequestId || cleanString(linkedRequest?.id)
  if (requestId) item.requestId = requestId

  if (!item.correlationId) {
    if (requestId) item.correlationId = requestId
    else if (standingGoalId) {
      item.correlationId = `standing-goal:${standingGoalId}`
    }
  }
}

async function attachResultLinks(tasks, rootPath) {
  const linksByBook = new Map()
  await Promise.all(tasks.map(async item => {
    if (!RESULT_LINK_STATUSES.has(item.status)) return
    const bookId = cleanString(item.bookId)
    if (!bookId || linksByBook.has(bookId)) return
    const promise = resultLinksForBook(bookId, rootPath)
    linksByBook.set(bookId, promise)
    await promise
  }))
  await Promise.all(tasks.map(async item => {
    if (!RESULT_LINK_STATUSES.has(item.status)) return
    const bookId = cleanString(item.bookId)
    if (!bookId) return
    const resultLinks = await linksByBook.get(bookId)
    if (resultLinks?.length) item.resultLinks = resultLinks
  }))
}

function townAgents(town, tasks, resolveBuilding) {
  const workByAgent = new Map()
  for (const task of tasks) {
    if (!task.agentId || TERMINAL_WORK_STATUSES.has(task.status)) continue
    const current = workByAgent.get(task.agentId)
    const rank = {
      blocked: 5,
      waiting_review: 4,
      running: 3,
      assigned: 2,
      queued: 1,
    }
    if (!current || (rank[task.status] || 0) > (rank[current.status] || 0)) {
      workByAgent.set(task.agentId, task)
    }
  }

  return valueArray(town?.workers).flatMap(worker => {
    const id = cleanString(worker?.id)
    const name = cleanString(worker?.name)
    if (!id || !name) return []
    const work = workByAgent.get(id)
    const agent = {
      id,
      name,
      role: workerRole(worker?.role),
      status: workerStatus(worker?.status),
    }
    if (work) {
      agent.buildingModuleKey = work.buildingModuleKey
      agent.workItemId = work.id
      if (work.runId) agent.runId = work.runId
      if (work.status === 'assigned' && agent.status === 'idle') {
        agent.status = 'assigned'
      } else if (work.status === 'waiting_review') {
        agent.status = 'waiting'
      } else if (work.status === 'blocked') {
        agent.status = 'blocked'
      }
    } else {
      agent.buildingModuleKey = resolveBuilding(worker?.book_id)
    }
    return [agent]
  })
}

function activeTownTaskForGoal(tasks, goalId) {
  return tasks.some(task =>
    task.source === 'town-runtime'
    && !TERMINAL_WORK_STATUSES.has(task.status)
    && (
      cleanString(task.standingGoalId) === goalId
      || goalIdFromStandingWatchTaskId(task.id, [goalId]) === goalId
    ))
}

export async function loadEnergyValleyRuntimeProjection(options = {}) {
  const stateRoot = options.stateRoot
  const paths = stateRoot
    ? {
        town: path.join(stateRoot, 'town.json'),
        daemon: path.join(stateRoot, 'daemon.json'),
        daemonRuntime: path.join(stateRoot, 'daemon-runtime.json'),
        standingGoals: path.join(stateRoot, 'standing-goals.json'),
        watchers: path.join(stateRoot, 'watchers'),
        operatorRequests: path.join(
          stateRoot,
          'operator-requests/requests.jsonl',
        ),
      }
    : {
        town: townSnapshotPath,
        daemon: daemonSnapshotPath,
        daemonRuntime: daemonRuntimePath,
        standingGoals: standingGoalsPath,
        watchers: watcherDir,
        operatorRequests: operatorRequestLedgerPath,
      }
  const moduleManifestPath = options.moduleManifestPath || MODULE_MANIFEST_PATH
  const resultBooksRootPath = options.booksRootPath || booksRootPath

  const [
    townSnapshot,
    daemon,
    daemonRuntime,
    standingGoals,
    watchers,
    operatorRequests,
  ] =
    await Promise.all([
      readJson(paths.town),
      readJson(paths.daemon),
      readJson(paths.daemonRuntime),
      readJson(paths.standingGoals),
      readWatcherRows(paths.watchers),
      readJsonl(paths.operatorRequests),
    ])
  const observedAt = durableObservedAt(daemonRuntime.value)
  const sourceFound = (
    townSnapshot.found
    && Boolean(townFromSnapshot(townSnapshot.value))
  ) || (
    daemon.found
    && runtimeTick(daemon.value?.tick_sequence) !== undefined
  ) || (
    standingGoals.found
    && Array.isArray(standingGoals.value)
  )
    || (
      daemonRuntime.found
      && observedAt !== MISSING_DURABLE_OBSERVATION
    )
    || watchers.found
    || operatorRequests.found
  if (!sourceFound) {
    return {
      schema: ENERGY_VALLEY_RUNTIME_SCHEMA,
      mode: 'unavailable',
      observedAt,
      tasks: [],
      agents: [],
      message: 'MoonTown runtime state is unavailable.',
    }
  }

  const resolveBuilding = await loadBuildingModuleResolver(moduleManifestPath)
  const town = townFromSnapshot(townSnapshot.value)
  const tasks = townWorkItems(town, resolveBuilding)
  const goals = valueArray(standingGoals.value)
  const goalsById = new Map(
    goals
      .map(goal => [cleanString(goal?.id), goal])
      .filter(([id]) => id),
  )
  const requestsByGoal = latestRequestsByGoal(operatorRequests.value)
  const representedWatcherGoals = new Set()

  for (const row of latestWatcherRows(watchers.value)) {
    const goalId = cleanString(row?.goal_id)
    const taskId = cleanString(row?.task_id)
    if (!goalId) continue
    representedWatcherGoals.add(goalId)
    const representedTask = taskId
      ? tasks.find(task => task.id === taskId)
      : undefined
    if (representedTask) {
      representedTask.standingGoalId = goalId
      representedTask.status = watcherStatus(row?.decision, row?.detail)
      const summary = watcherSummary(row)
      if (summary) representedTask.summary = summary
      const watcherRunId = cleanString(row?.run_id)
      if (watcherRunId) representedTask.runId = watcherRunId
      const watcherArtifacts = cleanStringArray(row?.artifacts)
      if (watcherArtifacts.length) {
        representedTask.artifacts = cleanStringArray([
          ...representedTask.artifacts,
          ...watcherArtifacts,
        ])
      }
      const progress = watcherProgress(row)
      if (progress) representedTask.progress = progress
      continue
    }
    const item = watcherWorkItem(row, goalsById.get(goalId), resolveBuilding)
    if (item) tasks.push(item)
  }

  for (const goal of goals) {
    const goalId = cleanString(goal?.id)
    if (!goalId || goal?.enabled === false) continue
    if (activeTownTaskForGoal(tasks, goalId)) continue
    const latestWatcher = representedWatcherGoals.has(goalId)
    const tick = runtimeTick(daemon.value?.tick_sequence)
    const nextDueTick = runtimeTick(goal?.next_due_tick)
    if (
      latestWatcher
      && tick !== undefined
      && nextDueTick !== undefined
      && nextDueTick > tick
    ) {
      continue
    }
    const item = standingGoalWorkItem(goal, resolveBuilding)
    if (item) tasks.push(item)
  }

  const standingGoalIds = new Set(
    goals.map(goal => cleanString(goal?.id)).filter(Boolean),
  )
  for (const request of operatorRequests.value) {
    const goalId = cleanString(request?.standing_goal_id)
    if (goalId && standingGoalIds.has(goalId)) continue
    const item = operatorRequestWorkItem(request, resolveBuilding)
    if (item) tasks.push(item)
  }

  const goalIds = [...goalsById.keys()]
  for (const task of tasks) {
    correlateTask(task, goalIds, requestsByGoal)
  }
  await attachResultLinks(tasks, resultBooksRootPath)

  const collaboration = await loadEnergyValleyCollaboration({
    tasks,
    booksRootPath: resultBooksRootPath,
  })
  for (const task of tasks) {
    const taskCollaboration = collaboration.byTaskId[task.id]
    if (taskCollaboration) task.collaboration = taskCollaboration
  }
  const agentsById = new Map()
  for (const agent of [
    ...townAgents(town, tasks, resolveBuilding),
    ...collaboration.agents,
  ]) {
    if (!agentsById.has(agent.id)) agentsById.set(agent.id, agent)
  }
  const agents = [...agentsById.values()]
  const projection = {
    schema: ENERGY_VALLEY_RUNTIME_SCHEMA,
    mode: 'live',
    observedAt,
    tasks,
    agents,
  }
  const tick = runtimeTick(daemon.value?.tick_sequence)
  if (tick !== undefined) projection.tick = tick
  if (!town) {
    projection.message =
      'Runtime ledgers are available, but the town worker snapshot is unavailable.'
  }
  return projection
}

export async function handleEnergyValleyRuntimeRequest(req, res) {
  if (req.method && req.method !== 'GET' && req.method !== 'HEAD') {
    sendJson(res, { error: 'GET required' }, 405)
    return
  }
  res.setHeader('Cache-Control', 'no-store')
  try {
    const projection = await loadEnergyValleyRuntimeProjection()
    if (req.method === 'HEAD') {
      res.statusCode = 200
      res.setHeader('Content-Type', 'application/json')
      res.end()
      return
    }
    sendJson(res, projection)
  } catch (error) {
    sendJson(res, {
      schema: ENERGY_VALLEY_RUNTIME_SCHEMA,
      mode: 'unavailable',
      observedAt: new Date().toISOString(),
      tasks: [],
      agents: [],
      message: `MoonTown runtime projection failed: ${String(error?.message || error)}`,
    })
  }
}

import { readdir, readFile, realpath, stat } from 'node:fs/promises'
import path from 'node:path'

const TERMINAL_EVENT_STATUS = new Map([
  ['childrunsucceeded', 'completed'],
  ['childrunfailed', 'failed'],
  ['childruncancelled', 'blocked'],
])

function cleanString(value) {
  return typeof value === 'string' && value.trim() ? value.trim() : undefined
}

function safeSegment(value) {
  const text = cleanString(value)
  return text && text !== '.' && text !== '..' && !text.includes('/')
    && !text.includes('\\')
    ? text
    : undefined
}

function enumKey(value) {
  if (typeof value === 'string') return value.toLowerCase().replace(/[^a-z0-9]/g, '')
  if (value && typeof value === 'object') {
    const key = Object.keys(value)[0]
    return key ? key.toLowerCase().replace(/[^a-z0-9]/g, '') : ''
  }
  return ''
}

function workStatus(value) {
  switch (enumKey(value)) {
    case 'pending':
    case 'confirmed':
    case 'runconfirmed':
      return 'assigned'
    case 'running':
      return 'running'
    case 'waiting':
    case 'waitingforinput':
      return 'waiting_review'
    case 'succeeded':
    case 'completed':
      return 'completed'
    case 'failed':
      return 'failed'
    case 'cancelled':
    case 'blocked':
      return 'blocked'
    default:
      return undefined
  }
}

function agentStatus(value) {
  switch (workStatus(value)) {
    case 'assigned': return 'assigned'
    case 'running': return 'running'
    case 'waiting_review': return 'waiting'
    case 'completed': return 'idle'
    case 'failed':
    case 'blocked':
      return 'blocked'
    default:
      return undefined
  }
}

function isTerminalWorkStatus(value) {
  return value === 'completed' || value === 'failed' || value === 'blocked'
}

function familyFrom(value) {
  return cleanString(
    value?.family
      ?? value?.child_family
      ?? value?.childFamily
      ?? value?.profile
      ?? value?.profile_id
      ?? value?.profileId
      ?? value?.suggested_family
      ?? value?.suggestedFamily
      ?? value?.metadata?.family
      ?? value?.metadata?.profile
      ?? value?.metadata?.profile_id,
  )
}

function provableRole(family, meta) {
  const declared = enumKey(
    meta?.role
      ?? meta?.worker_role
      ?? meta?.workerRole
      ?? meta?.metadata?.role
      ?? meta?.metadata?.worker_role,
  )
  if (declared === 'worker') return 'worker'
  if (declared === 'keeper' || declared === 'controller') return 'keeper'
  const key = enumKey(family)
  if (key.includes('worker')) return 'worker'
  if (key.includes('keeper') || key.includes('controller')) return 'keeper'
  return undefined
}

function runIdentity(meta) {
  return cleanString(meta?.id ?? meta?.run_id ?? meta?.runId)
}

function parentIdentity(meta) {
  return cleanString(meta?.parent_run_id ?? meta?.parentRunId)
}

function timestamp(value) {
  if (
    typeof value === 'number'
    && Number.isFinite(value)
    && value >= 0
  ) {
    return value
  }
  const text = cleanString(value)
  if (!text) return undefined
  const numeric = Number(text)
  if (Number.isFinite(numeric) && numeric < 0) return undefined
  return text
}

function comparableTime(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return value
  const text = cleanString(value)
  if (!text) return undefined
  const numeric = Number(text)
  if (Number.isFinite(numeric)) return numeric
  const parsed = Date.parse(text)
  return Number.isFinite(parsed) ? parsed : undefined
}

async function readJson(filePath) {
  try {
    const value = JSON.parse(await readFile(filePath, 'utf8'))
    return value && typeof value === 'object' ? value : undefined
  } catch {
    return undefined
  }
}

async function readJsonl(filePath) {
  try {
    const rows = []
    for (const line of (await readFile(filePath, 'utf8')).split(/\r?\n/)) {
      if (!line.trim()) continue
      try {
        const row = JSON.parse(line)
        if (row && typeof row === 'object') rows.push(row)
      } catch {
        // One corrupt event must not erase other persisted evidence.
      }
    }
    return rows
  } catch {
    return []
  }
}

function isWithin(root, candidate) {
  const resolvedRoot = path.resolve(root)
  const resolved = path.resolve(candidate)
  return resolved === resolvedRoot || resolved.startsWith(`${resolvedRoot}${path.sep}`)
}

async function canonicalExistingFile(candidate, allowedRoots) {
  let canonicalCandidate
  try {
    canonicalCandidate = await realpath(candidate)
    if (!(await stat(canonicalCandidate)).isFile()) return undefined
  } catch {
    return undefined
  }
  for (const root of allowedRoots) {
    let canonicalRoot
    try {
      canonicalRoot = await realpath(root)
    } catch {
      canonicalRoot = path.resolve(root)
    }
    if (isWithin(canonicalRoot, canonicalCandidate)) return canonicalCandidate
  }
  return undefined
}

function jobRootCandidates(booksRootPath, bookId) {
  const booksRoot = path.resolve(booksRootPath)
  const bookRoot = path.resolve(booksRoot, bookId)
  if (!isWithin(booksRoot, bookRoot)) return []
  const suiteRoot = path.dirname(booksRoot)
  return [...new Set([
    path.join(bookRoot, '.moonsuite/products/moonclaw/jobs'),
    path.join(bookRoot, '.moonclaw/jobs'),
    path.join(bookRoot, 'moonclaw-jobs'),
    path.join(bookRoot, '.moontown/moonclaw-jobs'),
    path.join(booksRoot, '.moonsuite/products/moonclaw/jobs'),
    path.join(suiteRoot, '.moonsuite/products/moonclaw/jobs'),
  ].map(candidate => path.resolve(candidate)))]
}

function runDirCandidates(jobRoot, runId) {
  return [
    path.join(jobRoot, 'runs', runId),
    path.join(jobRoot, runId),
  ]
}

async function readRunMeta(runDir) {
  for (const name of ['meta.json', 'run.json']) {
    const meta = await readJson(path.join(runDir, name))
    if (meta) return meta
  }
  return undefined
}

async function findAnchoredStore(booksRootPath, task) {
  const bookId = safeSegment(task?.bookId)
  const runId = safeSegment(task?.runId)
  if (!bookId || !runId) return undefined
  for (const jobRoot of jobRootCandidates(booksRootPath, bookId)) {
    for (const runDir of runDirCandidates(jobRoot, runId)) {
      const meta = await readRunMeta(runDir)
      if (runIdentity(meta) === runId) {
        const parentRunDirs = [runDir]
        const parentMetas = [meta]
        for (const candidate of runDirCandidates(jobRoot, runId)) {
          if (candidate === runDir) continue
          const candidateMeta = await readRunMeta(candidate)
          if (runIdentity(candidateMeta) === runId) {
            parentRunDirs.push(candidate)
            parentMetas.push(candidateMeta)
          }
        }
        const workspaceDir = cleanString(meta?.workspace_dir ?? meta?.workspaceDir)
        if (
          workspaceDir
          && isWithin(path.dirname(path.resolve(booksRootPath)), workspaceDir)
        ) {
          const workspaceMeta = await readRunMeta(workspaceDir)
          if (runIdentity(workspaceMeta) === runId) {
            parentRunDirs.push(path.resolve(workspaceDir))
            parentMetas.push(workspaceMeta)
          }
        }
        return {
          bookRoot: path.resolve(booksRootPath, bookId),
          jobRoot,
          parentDir: runDir,
          parentRunDirs: [...new Set(parentRunDirs)],
          parentMeta: meta,
          parentMetas,
        }
      }
    }
  }
  return undefined
}

async function childMetaRecords(jobRoot, parentRunDirs, parentRunId) {
  const records = []
  const seen = new Set()
  const childRoots = [
    path.join(jobRoot, 'runs'),
    jobRoot,
    ...parentRunDirs.map(parentDir =>
      path.join(parentDir, 'moonclaw-subjobs')
    ),
  ]
  for (const runsRoot of childRoots) {
    let entries
    try {
      entries = await readdir(runsRoot, { withFileTypes: true })
    } catch {
      continue
    }
    for (const entry of entries) {
      if (!entry.isDirectory() || !safeSegment(entry.name)) continue
      const runDir = path.join(runsRoot, entry.name)
      if (seen.has(runDir)) continue
      seen.add(runDir)
      const meta = await readRunMeta(runDir)
      const runId = runIdentity(meta)
      if (!runId || parentIdentity(meta) !== parentRunId) continue
      records.push({ runId, runDir, meta })
    }
  }
  return records
}

function childEventEvidence(rows, parentRunId) {
  const evidence = new Map()
  for (const row of rows) {
    const eventKey = enumKey(row?.event_type ?? row?.eventType ?? row?.type ?? row?.kind)
    if (!eventKey.startsWith('childrun')) continue
    const data = row?.data && typeof row.data === 'object' ? row.data : {}
    const runId = cleanString(
      data.child_run_id ?? data.childRunId ?? row?.child_run_id ?? row?.childRunId,
    )
    if (!safeSegment(runId)) continue
    const current = evidence.get(runId) ?? {
      runId,
      parentRunId,
      artifacts: [],
    }
    const family = familyFrom(data) ?? familyFrom(row)
    if (family) current.family = family
    const at = timestamp(row?.timestamp ?? row?.timestamp_ms ?? row?.created_at ?? row?.createdAt)
    if (eventKey === 'childrunstarted') {
      current.startedAt = at ?? current.startedAt
      current.status = 'running'
    }
    const terminal = TERMINAL_EVENT_STATUS.get(eventKey)
    if (terminal) {
      current.completedAt = at ?? current.completedAt
      current.status = terminal
    }
    current.artifacts.push(...artifactClaims(row))
    evidence.set(runId, current)
  }
  return evidence
}

function artifactClaims(value, key = '') {
  if (!value || typeof value !== 'object') return []
  if (Array.isArray(value)) {
    if (key === 'artifacts' || key === 'artifactpaths') {
      return value.map(cleanString).filter(Boolean)
    }
    return value.flatMap(item => artifactClaims(item, key))
  }
  const claims = []
  for (const [childKey, child] of Object.entries(value)) {
    const normalized = enumKey(childKey)
    if (
      (normalized === 'artifacts' || normalized === 'artifactpaths')
      && Array.isArray(child)
    ) {
      claims.push(...child.map(cleanString).filter(Boolean))
    } else if (child && typeof child === 'object') {
      claims.push(...artifactClaims(child, normalized))
    }
  }
  return claims
}

async function outputArtifactClaims(runDir) {
  const claims = []
  for (const name of ['result.json', 'output.json']) {
    const value = await readJson(path.join(runDir, name))
    if (value) claims.push(...artifactClaims(value))
  }
  const outputsDir = path.join(runDir, 'outputs')
  let entries
  try {
    entries = await readdir(outputsDir, { withFileTypes: true })
  } catch {
    return claims
  }
  for (const entry of entries) {
    if (!entry.isFile() || path.extname(entry.name) !== '.json') continue
    const value = await readJson(path.join(outputsDir, entry.name))
    if (value) claims.push(...artifactClaims(value))
  }
  return claims
}

async function persistedArtifactRecords(jobRoot) {
  const records = new Map()
  const index = await readJson(path.join(jobRoot, 'index', 'artifacts.json'))
  if (Array.isArray(index?.artifacts)) {
    for (const record of index.artifacts) {
      const id = safeSegment(record?.id)
      if (id) records.set(id, record)
    }
  }

  const artifactsRoot = path.join(jobRoot, 'artifacts')
  let entries
  try {
    entries = await readdir(artifactsRoot, { withFileTypes: true })
  } catch {
    return records
  }
  for (const entry of entries) {
    const id = safeSegment(entry.name)
    if (!entry.isDirectory() || !id) continue
    const record = await readJson(
      path.join(artifactsRoot, id, 'record.json'),
    )
    if (safeSegment(record?.id) === id) records.set(id, record)
  }
  return records
}

async function persistedArtifactsByRun(jobRoot) {
  const byRunId = new Map()
  const seenByRunId = new Map()
  const records = await persistedArtifactRecords(jobRoot)
  for (const [id, record] of records) {
    const runId = cleanString(record?.run_id ?? record?.runId)
    if (!runId || enumKey(record?.status) !== 'active') continue
    const storedPath = cleanString(record?.path)
    if (!storedPath) continue
    const artifactRoot = path.join(jobRoot, 'artifacts', id)
    const candidates = path.isAbsolute(storedPath)
      ? [path.resolve(storedPath)]
      : [
          path.resolve(artifactRoot, storedPath),
          path.resolve(jobRoot, storedPath),
        ]
    for (const candidate of candidates) {
      if (!isWithin(artifactRoot, candidate)) continue
      const canonical = await canonicalExistingFile(candidate, [jobRoot])
      if (!canonical) continue
      const seen = seenByRunId.get(runId) ?? new Set()
      if (seen.has(canonical)) break
      seen.add(canonical)
      seenByRunId.set(runId, seen)
      const artifacts = byRunId.get(runId) ?? []
      artifacts.push(canonical)
      byRunId.set(runId, artifacts)
      break
    }
  }
  return byRunId
}

async function existingArtifacts(claims, bases, allowedRoots) {
  const existing = []
  const seen = new Set()
  for (const claim of claims) {
    const text = cleanString(claim)
    if (!text || seen.has(text)) continue
    for (const base of bases) {
      const candidate = path.isAbsolute(text) ? path.resolve(text) : path.resolve(base, text)
      if (!allowedRoots.some(root => isWithin(root, candidate))) continue
      if (await canonicalExistingFile(candidate, allowedRoots)) {
        seen.add(text)
        existing.push(text)
        break
      }
    }
  }
  return existing
}

function collaborationMode(participants) {
  if (participants.length < 2) return 'unknown'
  const intervals = participants.map(participant => ({
    start: comparableTime(participant.startedAt),
    end: comparableTime(participant.completedAt),
  }))
  for (let i = 0; i < intervals.length; i++) {
    const left = intervals[i]
    if (left.start === undefined || left.end === undefined) continue
    for (let j = i + 1; j < intervals.length; j++) {
      const right = intervals[j]
      if (right.start === undefined || right.end === undefined) continue
      if (left.start < right.end && right.start < left.end) return 'parallel'
    }
  }
  return intervals.every(interval =>
    interval.start !== undefined && interval.end !== undefined
  ) ? 'sequential' : 'unknown'
}

async function collaborationForTask(task, booksRootPath) {
  const anchored = await findAnchoredStore(booksRootPath, task)
  if (!anchored) return undefined
  const parentRunId = safeSegment(task.runId)
  const eventRows = (
    await Promise.all(
      anchored.parentRunDirs.map(parentDir =>
        readJsonl(path.join(parentDir, 'events.jsonl'))
      ),
    )
  ).flat()
  const evidence = childEventEvidence(eventRows, parentRunId)
  const childRecords = await childMetaRecords(
    anchored.jobRoot,
    anchored.parentRunDirs,
    parentRunId,
  )

  for (const record of childRecords) {
    const current = evidence.get(record.runId) ?? {
      runId: record.runId,
      parentRunId,
      artifacts: [],
    }
    current.meta = { ...current.meta, ...record.meta }
    current.runDir = record.runDir
    current.family = current.family ?? familyFrom(record.meta)
    const metaStatus = workStatus(record.meta?.status)
    if (
      metaStatus
      && (
        !current.status
        || isTerminalWorkStatus(metaStatus)
        || !isTerminalWorkStatus(current.status)
      )
    ) {
      current.status = metaStatus
    }
    current.startedAt = current.startedAt ?? timestamp(
      record.meta?.started_at ?? record.meta?.startedAt,
    )
    current.completedAt = current.completedAt ?? timestamp(
      record.meta?.finished_at
        ?? record.meta?.finishedAt
        ?? record.meta?.completed_at
        ?? record.meta?.completedAt,
    )
    current.artifacts.push(...artifactClaims(record.meta))
    evidence.set(record.runId, current)
  }

  const participants = []
  const agents = []
  const parentStatus = anchored.parentMetas
    .map(meta => workStatus(meta?.status))
    .find(status => isTerminalWorkStatus(status))
    ?? workStatus(anchored.parentMeta?.status)
  const persistedArtifacts = await persistedArtifactsByRun(anchored.jobRoot)
  for (const item of evidence.values()) {
    const family = cleanString(item.family)
    const status = item.status
    if (!family || !status) continue
    if (
      isTerminalWorkStatus(parentStatus)
      && !isTerminalWorkStatus(status)
    ) {
      // A terminal parent makes an unmatched child "started" event stale.
      // Without a terminal child record, its current lifecycle is unknowable.
      continue
    }
    const runDir = item.runDir
      ?? runDirCandidates(anchored.jobRoot, item.runId)[0]
    const workspaceDir = cleanString(item.meta?.workspace_dir ?? item.meta?.workspaceDir)
    const allowedRoots = [
      anchored.bookRoot,
      anchored.jobRoot,
      path.dirname(path.resolve(booksRootPath)),
    ]
    const bases = [
      ...(workspaceDir && allowedRoots.some(root => isWithin(root, workspaceDir))
        ? [workspaceDir]
        : []),
      anchored.bookRoot,
      runDir,
      anchored.jobRoot,
    ]
    const claims = [
      ...item.artifacts,
      ...(await outputArtifactClaims(runDir)),
    ]
    const artifacts = await existingArtifacts(claims, bases, allowedRoots)
    for (const artifact of persistedArtifacts.get(item.runId) ?? []) {
      if (!artifacts.includes(artifact)) artifacts.push(artifact)
    }
    const participant = {
      runId: item.runId,
      parentRunId,
      family,
      status,
      artifacts,
    }
    if (item.startedAt !== undefined) participant.startedAt = item.startedAt
    if (item.completedAt !== undefined) participant.completedAt = item.completedAt
    participants.push(participant)

    const role = provableRole(family, item.meta)
    const projectedStatus = agentStatus(status)
    if (role && projectedStatus) {
      agents.push({
        id: `moonclaw:${item.runId}`,
        name: family,
        role,
        status: projectedStatus,
        buildingModuleKey: task.buildingModuleKey,
        workItemId: task.id,
        runId: item.runId,
      })
    }
  }
  participants.sort((left, right) => {
    const leftStart = comparableTime(left.startedAt) ?? Number.MAX_SAFE_INTEGER
    const rightStart = comparableTime(right.startedAt) ?? Number.MAX_SAFE_INTEGER
    return leftStart - rightStart || left.runId.localeCompare(right.runId)
  })
  if (participants.length === 0) return undefined
  return {
    agents,
    collaboration: {
      mode: collaborationMode(participants),
      participants,
    },
  }
}

/**
 * Read persisted MoonClaw lineage for top-level MoonTown work.
 *
 * Child discovery is anchored by each task's real runId and a matching parent
 * meta record. Shared workItemId values are output correlation only.
 */
export async function loadEnergyValleyCollaboration({ tasks, booksRootPath }) {
  if (!Array.isArray(tasks) || !cleanString(booksRootPath)) {
    return { agents: [], byTaskId: {} }
  }
  const agents = new Map()
  const byTaskId = {}
  for (const task of tasks) {
    const taskId = cleanString(task?.id)
    if (!taskId) continue
    const result = await collaborationForTask(task, booksRootPath)
    if (!result) continue
    byTaskId[taskId] = result.collaboration
    for (const agent of result.agents) {
      if (!agents.has(agent.id)) agents.set(agent.id, agent)
    }
  }
  return { agents: [...agents.values()], byTaskId }
}

import {
  RUNTIME_PROJECTION_SCHEMA,
  type RuntimeAgent,
  type RuntimeAgentRole,
  type RuntimeAgentStatus,
  type RuntimeCollaboration,
  type RuntimeCollaborationMode,
  type RuntimeCollaborationParticipant,
  type RuntimeMode,
  type RuntimeParticipantStatus,
  type RuntimeProjection,
  type RuntimeResultLink,
  type RuntimeResultLinkKind,
  type RuntimeWorkItem,
  type RuntimeWorkProgress,
  type RuntimeWorkSource,
  type RuntimeWorkStatus,
} from './types'

const MODES = new Set<RuntimeMode>(['live', 'unavailable'])
const WORK_STATUSES = new Set<RuntimeWorkStatus>([
  'queued',
  'assigned',
  'running',
  'waiting_review',
  'completed',
  'failed',
  'blocked',
])
const AGENT_STATUSES = new Set<RuntimeAgentStatus>([
  'idle',
  'assigned',
  'running',
  'waiting',
  'blocked',
  'offline',
])
const WORK_SOURCES = new Set<RuntimeWorkSource>([
  'town-runtime',
  'standing-goal',
  'watcher',
  'operator-request',
])
const AGENT_ROLES = new Set<RuntimeAgentRole>(['mayor', 'keeper', 'worker'])
const COLLABORATION_MODES = new Set<RuntimeCollaborationMode>([
  'sequential',
  'parallel',
  'unknown',
])
const PARTICIPANT_STATUSES = new Set<RuntimeParticipantStatus>([
  ...WORK_STATUSES,
  'unknown',
])
const RESULT_LINK_KINDS = new Set<RuntimeResultLinkKind>([
  'report',
  'evidence',
  'review',
  'site',
])

export class RuntimeProjectionValidationError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'RuntimeProjectionValidationError'
  }
}

function record(value: unknown, path: string): Record<string, unknown> {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new RuntimeProjectionValidationError(`${path} must be an object`)
  }
  return value as Record<string, unknown>
}

function string(value: unknown, path: string, allowEmpty = false): string {
  if (typeof value !== 'string') {
    throw new RuntimeProjectionValidationError(`${path} must be a string`)
  }
  const normalized = value.trim()
  if (!allowEmpty && normalized.length === 0) {
    throw new RuntimeProjectionValidationError(`${path} must not be empty`)
  }
  return normalized
}

function optionalString(
  source: Record<string, unknown>,
  key: string,
  path: string,
): string | undefined {
  if (!(key in source)) return undefined
  return string(source[key], `${path}.${key}`)
}

function member<T extends string>(
  value: unknown,
  values: ReadonlySet<T>,
  path: string,
): T {
  if (typeof value !== 'string' || !values.has(value as T)) {
    throw new RuntimeProjectionValidationError(`${path} has an unknown value`)
  }
  return value as T
}

function stringArray(value: unknown, path: string): string[] {
  if (!Array.isArray(value)) {
    throw new RuntimeProjectionValidationError(`${path} must be an array`)
  }
  return value.map((item, index) => string(item, `${path}[${index}]`))
}

function optionalFiniteNumber(
  source: Record<string, unknown>,
  key: string,
  path: string,
): number | undefined {
  if (!(key in source)) return undefined
  const value = source[key]
  if (
    typeof value !== 'number' ||
    !Number.isFinite(value) ||
    value < 0
  ) {
    throw new RuntimeProjectionValidationError(
      `${path}.${key} must be a non-negative finite number`,
    )
  }
  return value
}

function optionalTimestamp(
  source: Record<string, unknown>,
  key: string,
  path: string,
): string | number | undefined {
  if (!(key in source)) return undefined
  const value = source[key]
  if (typeof value === 'string' && value.trim()) return value.trim()
  if (
    typeof value === 'number' &&
    Number.isFinite(value) &&
    value >= 0
  ) {
    return value
  }
  throw new RuntimeProjectionValidationError(
    `${path}.${key} must be a timestamp string or non-negative number`,
  )
}

function normalizeResultLink(value: unknown, index: number): RuntimeResultLink {
  const path = `resultLinks[${index}]`
  const source = record(value, path)
  const url = string(source.url, `${path}.url`)
  if (!url.startsWith('/book-output/')) {
    throw new RuntimeProjectionValidationError(
      `${path}.url must be a local /book-output/ path`,
    )
  }
  let decodedPath = url.split(/[?#]/, 1)[0]
  try {
    for (let index = 0; index < 4; index += 1) {
      const next = decodeURIComponent(decodedPath)
      if (next === decodedPath) break
      decodedPath = next
    }
  } catch {
    throw new RuntimeProjectionValidationError(
      `${path}.url contains invalid path encoding`,
    )
  }
  if (
    decodedPath.includes('\\') ||
    decodedPath.split('/').some(segment => segment === '..')
  ) {
    throw new RuntimeProjectionValidationError(
      `${path}.url must not escape the book output root`,
    )
  }
  let parsed: URL
  try {
    parsed = new URL(url, 'https://moontown.invalid/')
  } catch {
    throw new RuntimeProjectionValidationError(`${path}.url must be a safe URL`)
  }
  if (
    parsed.origin !== 'https://moontown.invalid' ||
    parsed.username ||
    parsed.password ||
    !parsed.pathname.startsWith('/book-output/')
  ) {
    throw new RuntimeProjectionValidationError(
      `${path}.url must be a same-origin /book-output/ path`,
    )
  }
  return {
    label: string(source.label, `${path}.label`),
    url,
    kind: member(source.kind, RESULT_LINK_KINDS, `${path}.kind`),
  }
}

function normalizeParticipant(
  value: unknown,
  index: number,
): RuntimeCollaborationParticipant {
  const path = `collaboration.participants[${index}]`
  const source = record(value, path)
  return {
    runId: string(source.runId, `${path}.runId`),
    parentRunId: optionalString(source, 'parentRunId', path),
    family: string(source.family, `${path}.family`),
    status: member(source.status, PARTICIPANT_STATUSES, `${path}.status`),
    startedAt: optionalTimestamp(source, 'startedAt', path),
    completedAt: optionalTimestamp(source, 'completedAt', path),
    artifacts: stringArray(source.artifacts, `${path}.artifacts`),
  }
}

function normalizeCollaboration(value: unknown): RuntimeCollaboration {
  const source = record(value, 'collaboration')
  return {
    mode: member(source.mode, COLLABORATION_MODES, 'collaboration.mode'),
    participants: array(
      source.participants,
      'collaboration.participants',
      normalizeParticipant,
    ),
  }
}

function normalizeProgress(value: unknown): RuntimeWorkProgress {
  const path = 'progress'
  const source = record(value, path)
  const bookChanged = source.bookChanged
  if (bookChanged !== undefined && typeof bookChanged !== 'boolean') {
    throw new RuntimeProjectionValidationError(
      'progress.bookChanged must be a boolean',
    )
  }
  return {
    checkedSources: optionalFiniteNumber(source, 'checkedSources', path),
    newSources: optionalFiniteNumber(source, 'newSources', path),
    acceptedFacts: optionalFiniteNumber(source, 'acceptedFacts', path),
    rejectedFacts: optionalFiniteNumber(source, 'rejectedFacts', path),
    pagesChanged: optionalFiniteNumber(source, 'pagesChanged', path),
    bookChanged,
  }
}

function normalizeWorkItem(value: unknown, index: number): RuntimeWorkItem {
  const path = `tasks[${index}]`
  const source = record(value, path)
  const role = source.role === undefined
    ? undefined
    : member(source.role, AGENT_ROLES, `${path}.role`)

  return {
    id: string(source.id, `${path}.id`),
    title: string(source.title, `${path}.title`),
    status: member(source.status, WORK_STATUSES, `${path}.status`),
    buildingModuleKey: string(
      source.buildingModuleKey,
      `${path}.buildingModuleKey`,
    ),
    agentId: optionalString(source, 'agentId', path),
    agentName: optionalString(source, 'agentName', path),
    role,
    runId: optionalString(source, 'runId', path),
    bookId: optionalString(source, 'bookId', path),
    summary: optionalString(source, 'summary', path),
    updatedAt: optionalString(source, 'updatedAt', path),
    requestId: optionalString(source, 'requestId', path),
    standingGoalId: optionalString(source, 'standingGoalId', path),
    correlationId: optionalString(source, 'correlationId', path),
    artifacts: stringArray(source.artifacts, `${path}.artifacts`),
    resultLinks: source.resultLinks === undefined
      ? undefined
      : array(source.resultLinks, `${path}.resultLinks`, normalizeResultLink),
    collaboration: source.collaboration === undefined
      ? undefined
      : normalizeCollaboration(source.collaboration),
    progress: source.progress === undefined
      ? undefined
      : normalizeProgress(source.progress),
    source: member(source.source, WORK_SOURCES, `${path}.source`),
  }
}

function normalizeAgent(value: unknown, index: number): RuntimeAgent {
  const path = `agents[${index}]`
  const source = record(value, path)
  return {
    id: string(source.id, `${path}.id`),
    name: string(source.name, `${path}.name`),
    role: member(source.role, AGENT_ROLES, `${path}.role`),
    status: member(source.status, AGENT_STATUSES, `${path}.status`),
    buildingModuleKey: optionalString(source, 'buildingModuleKey', path),
    workItemId: optionalString(source, 'workItemId', path),
    runId: optionalString(source, 'runId', path),
  }
}

function array<T>(
  value: unknown,
  path: string,
  normalize: (item: unknown, index: number) => T,
): T[] {
  if (!Array.isArray(value)) {
    throw new RuntimeProjectionValidationError(`${path} must be an array`)
  }
  return value.map(normalize)
}

export function normalizeRuntimeProjection(value: unknown): RuntimeProjection {
  const source = record(value, 'runtime projection')
  if (source.schema !== RUNTIME_PROJECTION_SCHEMA) {
    throw new RuntimeProjectionValidationError(
      `runtime projection schema must be ${RUNTIME_PROJECTION_SCHEMA}`,
    )
  }

  const observedAt = string(source.observedAt, 'observedAt')
  const isoDateTime =
    /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$/
  if (!isoDateTime.test(observedAt) || !Number.isFinite(Date.parse(observedAt))) {
    throw new RuntimeProjectionValidationError(
      'observedAt must be an ISO date-time string',
    )
  }

  let tick: number | undefined
  if (source.tick !== undefined) {
    if (typeof source.tick !== 'number' || !Number.isFinite(source.tick)) {
      throw new RuntimeProjectionValidationError('tick must be a finite number')
    }
    tick = source.tick
  }

  return {
    schema: RUNTIME_PROJECTION_SCHEMA,
    mode: member(source.mode, MODES, 'mode'),
    observedAt,
    tick,
    tasks: array(source.tasks, 'tasks', normalizeWorkItem),
    agents: array(source.agents, 'agents', normalizeAgent),
    message: optionalString(source, 'message', 'runtime projection'),
  }
}

export const RUNTIME_PROJECTION_SCHEMA =
  'moontown.energy-valley.runtime.v1' as const

export type RuntimeMode = 'live' | 'unavailable'

export type RuntimeWorkStatus =
  | 'queued'
  | 'assigned'
  | 'running'
  | 'waiting_review'
  | 'completed'
  | 'failed'
  | 'blocked'

export type RuntimeAgentStatus =
  | 'idle'
  | 'assigned'
  | 'running'
  | 'waiting'
  | 'blocked'
  | 'offline'

export type RuntimeWorkSource =
  | 'town-runtime'
  | 'standing-goal'
  | 'watcher'
  | 'operator-request'

export type RuntimeAgentRole = 'mayor' | 'keeper' | 'worker'

export type RuntimeResultLinkKind = 'report' | 'evidence' | 'review' | 'site'

export interface RuntimeResultLink {
  label: string
  url: string
  kind: RuntimeResultLinkKind
}

export type RuntimeCollaborationMode = 'sequential' | 'parallel' | 'unknown'

export type RuntimeParticipantStatus =
  | RuntimeWorkStatus
  | 'unknown'

export type RuntimeTimestamp = string | number

export interface RuntimeCollaborationParticipant {
  runId: string
  parentRunId?: string
  family: string
  status: RuntimeParticipantStatus
  startedAt?: RuntimeTimestamp
  completedAt?: RuntimeTimestamp
  artifacts: string[]
}

export interface RuntimeCollaboration {
  mode: RuntimeCollaborationMode
  participants: RuntimeCollaborationParticipant[]
}

export interface RuntimeWorkProgress {
  checkedSources?: number
  newSources?: number
  acceptedFacts?: number
  rejectedFacts?: number
  pagesChanged?: number
  bookChanged?: boolean
}

export interface RuntimeWorkItem {
  id: string
  title: string
  status: RuntimeWorkStatus
  buildingModuleKey: string
  agentId?: string
  agentName?: string
  role?: RuntimeAgentRole
  runId?: string
  bookId?: string
  summary?: string
  updatedAt?: string
  requestId?: string
  standingGoalId?: string
  correlationId?: string
  artifacts: string[]
  resultLinks?: RuntimeResultLink[]
  collaboration?: RuntimeCollaboration
  progress?: RuntimeWorkProgress
  source: RuntimeWorkSource
}

export interface RuntimeAgent {
  id: string
  name: string
  role: RuntimeAgentRole
  status: RuntimeAgentStatus
  buildingModuleKey?: string
  workItemId?: string
  runId?: string
}

export interface RuntimeProjection {
  schema: typeof RUNTIME_PROJECTION_SCHEMA
  mode: RuntimeMode
  observedAt: string
  tick?: number
  tasks: RuntimeWorkItem[]
  agents: RuntimeAgent[]
  message?: string
}

export type RuntimeProjectionPhase =
  | 'loading'
  | 'live'
  | 'unavailable'
  | 'error'
  | 'stale'

export interface RuntimeProjectionState {
  phase: RuntimeProjectionPhase
  projection: RuntimeProjection | null
  error?: string
  lastUpdatedAt?: number
}

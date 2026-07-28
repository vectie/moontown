import type { RuntimeWorkItem } from './types'

export const OPERATOR_REQUEST_URL = '/api/operator-requests'

export const DEFAULT_OPERATOR_REQUEST = {
  title: '',
  prompt: '',
  targetBookId: 'research-agent-work-projection',
  cadenceTicks: 1_000_000,
  qualityThreshold: 85,
} satisfies OperatorRequestInput

export interface OperatorRequestInput {
  title: string
  prompt: string
  targetBookId: string
  cadenceTicks: number
  qualityThreshold: number
}

export interface AcceptedOperatorRequest {
  requestId: string
  standingGoalId: string
  status: 'accepted'
}

export interface SubmitOperatorRequestOptions {
  signal?: AbortSignal
  fetchFn?: typeof fetch
  url?: string
}

export function matchesAcceptedRequest(
  task: RuntimeWorkItem,
  accepted: AcceptedOperatorRequest,
): boolean {
  return task.requestId === accepted.requestId
    || task.standingGoalId === accepted.standingGoalId
    || task.correlationId === accepted.requestId
    || task.correlationId === accepted.standingGoalId
    || task.correlationId === `standing-goal:${accepted.standingGoalId}`
    || task.id === `standing-goal:${accepted.standingGoalId}`
}

function required(value: string, label: string): string {
  const normalized = value.trim()
  if (!normalized) throw new Error(`${label} is required.`)
  return normalized
}

function integerInRange(
  value: number,
  label: string,
  minimum: number,
  maximum: number,
): number {
  if (!Number.isSafeInteger(value) || value < minimum || value > maximum) {
    throw new Error(`${label} must be between ${minimum} and ${maximum}.`)
  }
  return value
}

function record(value: unknown): Record<string, unknown> {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new Error('The Mayor queue returned an invalid response.')
  }
  return value as Record<string, unknown>
}

function responseString(
  source: Record<string, unknown>,
  key: string,
): string {
  const value = source[key]
  if (typeof value !== 'string' || !value.trim()) {
    throw new Error('The Mayor queue returned an invalid response.')
  }
  return value.trim()
}

export async function submitOperatorRequest(
  input: OperatorRequestInput,
  options: SubmitOperatorRequestOptions = {},
): Promise<AcceptedOperatorRequest> {
  const title = required(input.title, 'Title')
  const prompt = required(input.prompt, 'Request')
  const targetBookId = required(input.targetBookId, 'Target book')
  const cadenceTicks = integerInRange(
    input.cadenceTicks,
    'Cadence',
    1,
    Number.MAX_SAFE_INTEGER,
  )
  const qualityThreshold = integerInRange(
    input.qualityThreshold,
    'Quality threshold',
    1,
    100,
  )
  const fetchFn = options.fetchFn ?? globalThis.fetch.bind(globalThis)
  const response = await fetchFn(options.url ?? OPERATOR_REQUEST_URL, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    credentials: 'same-origin',
    cache: 'no-store',
    signal: options.signal,
    body: JSON.stringify({
      title,
      prompt,
      target_book_id: targetBookId,
      cadence_ticks: cadenceTicks,
      quality_threshold: qualityThreshold,
    }),
  })

  let payload: unknown
  try {
    payload = await response.json()
  } catch {
    throw new Error(
      response.ok
        ? 'The Mayor queue returned invalid JSON.'
        : `The Mayor queue rejected the request (${response.status}).`,
    )
  }
  const source = record(payload)
  if (!response.ok || source.ok !== true) {
    const detail = typeof source.error === 'string' && source.error.trim()
      ? source.error.trim()
      : `The Mayor queue rejected the request (${response.status}).`
    throw new Error(detail)
  }
  if (source.status !== 'accepted') {
    throw new Error('The Mayor queue did not confirm an accepted request.')
  }
  return {
    requestId: responseString(source, 'request_id'),
    standingGoalId: responseString(source, 'standing_goal_id'),
    status: 'accepted',
  }
}

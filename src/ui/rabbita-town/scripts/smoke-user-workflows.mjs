import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import path from 'node:path'

const baseUrl = process.env.MOONTOWN_SMOKE_BASE_URL
const stateRoot = process.env.MOONTOWN_PRODUCT_STATE_ROOT

assert.ok(baseUrl, 'MOONTOWN_SMOKE_BASE_URL is required')
assert.ok(stateRoot, 'MOONTOWN_PRODUCT_STATE_ROOT is required')

async function postJson(route, body, headers = {}) {
  return fetch(new URL(route, baseUrl), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...headers },
    body: JSON.stringify(body),
  })
}

const suffix = process.env.MOONTOWN_SMOKE_SUFFIX || 'e2e'
const watchTitle = `E2E Standing Watch ${suffix}`
const watchResponse = await postJson('/api/operator-requests', {
  title: watchTitle,
  prompt: 'Track accepted product changes and preserve only evidence-backed updates.',
  target_book_id: `research-e2e-${suffix}`,
  cadence_ticks: 45,
  quality_threshold: 88,
})
assert.equal(watchResponse.status, 200)
const watchResult = await watchResponse.json()
assert.equal(watchResult.ok, true)

const standingGoals = JSON.parse(
  await readFile(path.join(stateRoot, 'standing-goals.json'), 'utf8'),
)
assert.ok(standingGoals.some(goal => goal.id === watchResult.standing_goal_id))

const operatorLedger = await readFile(
  path.join(stateRoot, 'operator-requests', 'requests.jsonl'),
  'utf8',
)
assert.match(operatorLedger, new RegExp(watchResult.request_id))

const bookTitle = `E2E Evidence Book ${suffix}`
const bookResponse = await postJson('/api/book-template-requests', {
  template_id: 'pdf-evidence-watch',
  title: bookTitle,
  book_id: `research-e2e-book-${suffix}`,
  purpose: 'Preserve accepted PDF evidence for the end-to-end workflow.',
  websites: ['https://example.org/reports'],
  cadence_ticks: 60,
  analysis_method: 'Compare claims against the current accepted baseline.',
})
assert.equal(bookResponse.status, 200)
const bookResult = await bookResponse.json()
assert.equal(bookResult.ok, true)

const bookLedger = JSON.parse(
  await readFile(path.join(stateRoot, 'book-template-requests.json'), 'utf8'),
)
assert.ok(bookLedger.requests.some(request => request.id === bookResult.request_id))
await readFile(path.join(stateRoot, bookResult.config_path), 'utf8')

const exposedLedger = await fetch(new URL('/book-template-requests.json', baseUrl))
assert.equal(exposedLedger.status, 200)
const exposedBookRequests = await exposedLedger.json()
assert.ok(exposedBookRequests.requests.some(request => request.id === bookResult.request_id))

const crossOrigin = await postJson('/api/operator-requests', {
  title: 'Rejected cross-origin request',
  prompt: 'This must not be persisted.',
}, { Origin: 'https://example.invalid' })
assert.equal(crossOrigin.status, 403)

console.log(JSON.stringify({
  watch_request_id: watchResult.request_id,
  standing_goal_id: watchResult.standing_goal_id,
  book_request_id: bookResult.request_id,
  persisted: true,
}))

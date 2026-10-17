import { captureSubject, subjectKey, assertCurrentSources } from './pack_candidate_sources.js'

export const QUESTION_PACKET_LIMIT = 128 * 1024
export const QUESTION_ROLES = Object.freeze(['supports', 'challenges', 'context'])
const contract = 'moontown.cross-pack-question-draft.v1'
const text = (value, max) => typeof value === 'string' && value.length <= max
const keyOf = source => subjectKey(source.pack_id, source.subject_ref)

function bounded(value) {
  const body = JSON.stringify(value, null, 2)
  if (new TextEncoder().encode(body + '\n').length > QUESTION_PACKET_LIMIT) throw Error('The complete question packet exceeds 128 KiB. Use fewer or shorter observations.')
  return body
}

// Reconstruct only the fields that the live projection capture owns. Imported
// snapshots are untrusted historical excerpts, never authority or instructions.
function sourceCopy(source) {
  if (!source || typeof source !== 'object') throw Error('Every row needs a captured observation.')
  return captureSubject({ pack_id: source.pack_id, product_id: source.product_id,
    version: source.pack_version, generated_at: source.captured_generated_at }, source)
}

function validateDraft(value) {
  if (!value || value.contract_id !== contract || value.accepted_knowledge !== false ||
      !text(value.question, 140) || !text(value.scope, 2000) || !text(value.rejection_test, 2000) ||
      !Array.isArray(value.rows) || value.rows.length > 12) throw Error('This is not a supported, bounded cross-pack question draft.')
  const seen = new Set()
  const rows = value.rows.map(row => {
    if (!row || !['', ...QUESTION_ROLES].includes(row.role) || !text(row.connection, 2000) || !text(row.conditions, 2000)) throw Error('A question row has an invalid role or oversized notes.')
    const source = sourceCopy(row.source), key = keyOf(source)
    if (seen.has(key)) throw Error('A question packet repeats the same pack observation.')
    seen.add(key)
    return { source, role: row.role, connection: row.connection, conditions: row.conditions }
  })
  const draft = { contract_id: contract, accepted_knowledge: false,
    question: value.question, scope: value.scope, rejection_test: value.rejection_test, rows }
  bounded(draft)
  return draft
}

export function newQuestionDraft() {
  return { contract_id: contract, accepted_knowledge: false, question: '', scope: '', rejection_test: '', rows: [] }
}

export function appendQuestionSources(draft, sources) {
  const next = validateDraft(draft), keys = new Set(next.rows.map(row => keyOf(row.source)))
  for (const input of sources) {
    const source = sourceCopy(input), key = keyOf(source)
    if (!keys.has(key)) {
      next.rows.push({ source, role: '', connection: '', conditions: '' })
      keys.add(key)
    }
  }
  return validateDraft(next)
}

export function serializeQuestionDraft(draft) { return bounded(validateDraft(draft)) + '\n' }

export function parseQuestionDraft(body) {
  if (typeof body !== 'string' || new TextEncoder().encode(body).length > QUESTION_PACKET_LIMIT) throw Error('Choose a question JSON file no larger than 128 KiB.')
  let value
  try { value = JSON.parse(body) } catch { throw Error('The question packet is not valid JSON.') }
  return validateDraft(value)
}

export function questionSourceGaps(draft, state) {
  return draft.rows.flatMap((row, index) => {
    try { assertCurrentSources([row.source], state); return [] }
    catch (error) { return [{ index, key: keyOf(row.source), message: error.message || 'Current source cannot be verified.' }] }
  })
}

export function refreshQuestionSource(draft, index, state) {
  const next = validateDraft(draft), old = next.rows[index]?.source
  if (!old) throw Error('Choose an existing question row.')
  const projections = state.projections.filter(item => item.pack_id === old.pack_id)
  if (projections.length !== 1 || !Array.isArray(projections[0].subjects)) throw Error('This source pack has no unambiguous current snapshot. Keep the gap or explicitly remove this row.')
  const matches = projections[0].subjects.filter(item => item.subject_ref === old.subject_ref)
  if (matches.length !== 1) throw Error('This observation is missing or ambiguous. Keep the gap or explicitly remove this row.')
  const source = captureSubject(projections[0], matches[0])
  assertCurrentSources([source], state)
  // Source changes invalidate interpretation. The operator must describe the
  // role, connection and conditions again after reading the replacement.
  next.rows[index] = { source, role: '', connection: '', conditions: '' }
  return validateDraft(next)
}

export function prepareCrossPackQuestion(draft, state) {
  const value = validateDraft(draft)
  if (value.rows.length < 2 || new Set(value.rows.map(row => row.source.pack_id)).size < 2) throw Error('Combine at least two observations from two distinct packs.')
  if (![value.question, value.scope, value.rejection_test].every(item => item.trim())) throw Error('Describe the question, scope and observable rejection test.')
  if (value.rows.some(row => !QUESTION_ROLES.includes(row.role) || !row.connection.trim() || !row.conditions.trim())) throw Error('Label every observation and explain its connection and date or conditions. Write unknown when a condition is not known.')
  if (questionSourceGaps(value, state).length) throw Error('Unresolved snapshot gaps remain. Review current observations or explicitly remove their rows; no candidate was prepared.')
  const sources = value.rows.map(row => structuredClone(row.source))
  const review = { contract_id: 'moontown.cross-pack-question.v1', accepted_knowledge: false,
    question: value.question.trim(), scope: value.scope.trim(), rejection_test: value.rejection_test.trim(),
    interpretation: 'Operator-labelled relationships; no inferred consensus, contradiction or pack endorsement.',
    observations: value.rows.map(row => ({ pack_id: row.source.pack_id, subject_ref: row.source.subject_ref,
      role: row.role, connection: row.connection.trim(), conditions: row.conditions.trim() })) }
  bounded({ sources, review })
  return { sources, review }
}

export function attachCrossPackQuestion(candidate, review, sources) {
  if (review?.contract_id !== 'moontown.cross-pack-question.v1' || review.accepted_knowledge !== false ||
      !Array.isArray(review.observations) || review.observations.length !== sources.length ||
      new Set(sources.map(source => source.pack_id)).size < 2 ||
      review.observations.some((row, index) => keyOf(row) !== keyOf(sources[index]))) throw Error('The cross-pack question does not match the selected candidate sources.')
  candidate.domain_payload.moontown_source_context.cross_pack_question = structuredClone(review)
  return candidate
}

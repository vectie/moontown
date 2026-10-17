import { captureSubject, subjectKey, assertCurrentSources } from './pack_candidate_sources.js'

export const BASELINE_LIMITS = Object.freeze({ packs: 128, subjects: 1000, bytes: 1024 * 1024, selected: 12 })
const contract = 'moontown.pack-observation-baseline.v1'
const fields = ['pack_version', 'schema_id', 'title', 'summary', 'lifecycle_state', 'evidence_refs']
const text = (value, max) => typeof value === 'string' && value.trim() && value.length <= max
const order = (a, b) => a < b ? -1 : a > b ? 1 : 0
const keyOf = source => subjectKey(source.pack_id, source.subject_ref)

function bounded(value) {
  const body = JSON.stringify(value, null, 2) + '\n'
  if (new TextEncoder().encode(body).length > BASELINE_LIMITS.bytes) throw Error('The complete baseline exceeds 1 MiB. Select fewer packs; no partial baseline was saved.')
  return body
}

function packCopy(value) {
  if (!value || !text(value.pack_id, 256) || !text(value.product_id, 256) || !text(value.version, 100) ||
      !text(value.generated_at, 100) || !Array.isArray(value.subjects) || value.subjects.length > BASELINE_LIMITS.subjects) {
    throw Error('Pack metadata or observations are missing or oversized.')
  }
  const seen = new Set()
  const subjects = value.subjects.map(subject => {
    const source = captureSubject(value, subject)
    if (seen.has(source.subject_ref)) throw Error('Pack observation identities are ambiguous.')
    seen.add(source.subject_ref)
    return source
  }).sort((a, b) => order(a.subject_ref, b.subject_ref))
  return { pack_id: value.pack_id, product_id: value.product_id, version: value.version,
    generated_at: value.generated_at, subjects }
}

function validated(value) {
  if (!value || value.contract_id !== contract || value.accepted_knowledge !== false || !text(value.label, 140) ||
      !text(value.saved_at, 100) || !Array.isArray(value.packs) || !value.packs.length || value.packs.length > BASELINE_LIMITS.packs) {
    throw Error('Choose a supported observation baseline with one to 128 packs and a label.')
  }
  const seen = new Set()
  const packs = value.packs.map(pack => {
    const copy = packCopy(pack)
    if (seen.has(copy.pack_id)) throw Error('The baseline repeats a pack identity.')
    seen.add(copy.pack_id)
    return copy
  }).sort((a, b) => order(a.pack_id, b.pack_id))
  if (packs.reduce((n, pack) => n + pack.subjects.length, 0) > BASELINE_LIMITS.subjects) throw Error('A baseline is limited to 1,000 observations; no subset was used.')
  const result = { contract_id: contract, accepted_knowledge: false, label: value.label, saved_at: value.saved_at, packs }
  bounded(result)
  return result
}

function checkState(state) {
  if (!state || ![state.capabilities, state.projections, state.lifecycles].every(items => Array.isArray(items) && items.length <= BASELINE_LIMITS.packs)) {
    throw Error('Comparison needs a bounded Pack Bridge snapshot of at most 128 packs.')
  }
  if (state.projections.reduce((n, pack) => n + (Array.isArray(pack?.subjects) ? pack.subjects.length : 0), 0) > BASELINE_LIMITS.subjects) {
    throw Error('Comparison is limited to 1,000 current observations; no partial scan was used.')
  }
}

function currentPack(state, id) {
  const projections = state.projections.filter(p => p?.pack_id === id)
  const capabilities = state.capabilities.filter(p => p?.pack_id === id)
  const lifecycles = state.lifecycles.filter(p => p?.pack_id === id)
  if (projections.length !== 1 || capabilities.length !== 1 || lifecycles.length !== 1 || lifecycles[0].stage !== 'projecting') {
    throw Error('No single active, projecting snapshot is available. Absence of observations is unknown.')
  }
  return packCopy(projections[0])
}

export function captureObservationBaseline(state, selectedPacks, label, savedAt = new Date().toISOString()) {
  checkState(state)
  const ids = [...selectedPacks]
  if (!ids.length || new Set(ids).size !== ids.length) throw Error('Select at least one distinct pack for the baseline.')
  return validated({ contract_id: contract, accepted_knowledge: false, label, saved_at: savedAt,
    packs: ids.map(id => {
      try { return currentPack(state, id) }
      catch (error) { throw Error(`${id}: ${error.message} Narrow the selected layers or repair the pack before saving.`) }
    }) })
}

export function serializeObservationBaseline(baseline) { return bounded(validated(baseline)) }

export function parseObservationBaseline(body) {
  if (typeof body !== 'string' || new TextEncoder().encode(body).length > BASELINE_LIMITS.bytes) throw Error('Choose a baseline JSON file no larger than 1 MiB.')
  let value
  try { value = JSON.parse(body) } catch { throw Error('The baseline file is not valid JSON.') }
  return validated(value)
}

export function compareObservationBaseline(input, state) {
  const baseline = validated(input)
  checkState(state)
  const rows = [], gaps = []
  let currentBytes = 0
  for (const previous of baseline.packs) {
    let current
    try {
      current = currentPack(state, previous.pack_id)
      if (current.product_id !== previous.product_id) throw Error('The product identity changed. Save a separate baseline after inspecting the replacement.')
    } catch (error) {
      gaps.push({ pack_id: previous.pack_id, message: error.message, previous })
      continue
    }
    currentBytes += new TextEncoder().encode(JSON.stringify(current)).length
    if (currentBytes > BASELINE_LIMITS.bytes) throw Error('Current comparison scope exceeds 1 MiB of normalized observations; no partial comparison was used.')
    const old = new Map(previous.subjects.map(source => [source.subject_ref, source]))
    const now = new Map(current.subjects.map(source => [source.subject_ref, source]))
    for (const ref of [...new Set([...old.keys(), ...now.keys()])].sort(order)) {
      const before = old.get(ref) || null, after = now.get(ref) || null
      const changedFields = before && after ? fields.filter(field => JSON.stringify(before[field]) !== JSON.stringify(after[field])) : []
      const status = !before ? 'newly-projected' : !after ? 'no-longer-projected' : changedFields.length ? 'changed' : 'unchanged'
      rows.push({ key: subjectKey(previous.pack_id, ref), status, changed_fields: changedFields, before, after })
    }
  }
  return { contract_id: 'moontown.pack-observation-comparison.v1', accepted_knowledge: false,
    label: baseline.label, saved_at: baseline.saved_at, scope_pack_ids: baseline.packs.map(p => p.pack_id),
    interpretation: 'Exact projected-field comparison within saved pack scope. Publisher timestamps alone are ignored. Not semantic importance, verified evidence bytes, removed knowledge or pack endorsement.',
    rows, gaps }
}

export function prepareObservationChanges(baseline, state, selectedKeys) {
  const comparison = compareObservationBaseline(baseline, state), keys = [...selectedKeys]
  if (!keys.length || keys.length > BASELINE_LIMITS.selected || new Set(keys).size !== keys.length) throw Error('Select one to twelve distinct new or changed observations.')
  const changes = keys.map(key => {
    const row = comparison.rows.find(row => row.key === key)
    if (!row || !['changed', 'newly-projected'].includes(row.status)) throw Error('A selected change is no longer available. Inspect the refreshed comparison and select it again.')
    return structuredClone(row)
  })
  const sources = changes.map(row => structuredClone(row.after))
  assertCurrentSources(sources, state)
  const review = { contract_id: 'moontown.observation-change-review.v1', accepted_knowledge: false,
    baseline_label: comparison.label, baseline_saved_at: comparison.saved_at, scope_pack_ids: comparison.scope_pack_ids,
    interpretation: comparison.interpretation, selected_changes: changes,
    omitted_change_count: comparison.rows.filter(row => row.status !== 'unchanged').length - changes.length,
    gaps: comparison.gaps.map(({ pack_id, message }) => ({ pack_id, message })) }
  return { sources, review }
}

export function attachObservationChanges(candidate, review, sources) {
  if (review?.contract_id !== 'moontown.observation-change-review.v1' || review.accepted_knowledge !== false ||
      !Array.isArray(review.selected_changes) || review.selected_changes.length !== sources.length ||
      review.selected_changes.some((row, i) => !['changed', 'newly-projected'].includes(row.status) ||
        !row.after || row.key !== keyOf(sources[i]) || JSON.stringify(row.after) !== JSON.stringify(sources[i]))) {
    throw Error('The change review does not match the selected candidate observations.')
  }
  candidate.domain_payload.moontown_source_context.observation_changes = structuredClone(review)
  return candidate
}

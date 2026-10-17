import { captureSubject, subjectKey } from './pack_candidate_sources.js'

export const MATERIAL_LIMITS = Object.freeze({ packs: 128, subjects: 1000, group: 128, shown: 40 })
const compare = (a, b) => a < b ? -1 : a > b ? 1 : 0
export const materialGroupKey = (packId, evidenceRef) => JSON.stringify([packId, evidenceRef])

// Paths belong to their publishing pack. Never join equal-looking paths across
// packs or treat reuse of one reference as independent corroboration.
export function discoverMaterialGroups(state, visiblePacks = null) {
  const { capabilities, projections, lifecycles } = state
  if (![capabilities, projections, lifecycles].every(Array.isArray) ||
      [capabilities, projections, lifecycles].some(items => items.length > MATERIAL_LIMITS.packs)) {
    throw Error('Shared-material discovery requires a bounded Pack Bridge snapshot (at most 128 packs).')
  }
  if (projections.reduce((n, p) => n + (Array.isArray(p.subjects) ? p.subjects.length : 0), 0) > MATERIAL_LIMITS.subjects) {
    throw Error('Shared-material discovery is limited to 1,000 projected observations; no partial scan was used.')
  }
  const groups = new Map()
  let skippedPacks = 0, skippedSubjects = 0, inspectedSubjects = 0
  for (const projection of projections) {
    const packId = projection?.pack_id
    if (visiblePacks && !visiblePacks.has(packId)) continue
    const active = capabilities.filter(item => item.pack_id === packId)
    const lifecycle = lifecycles.filter(item => item.pack_id === packId)
    if (projections.filter(item => item.pack_id === packId).length !== 1 || active.length !== 1 ||
        lifecycle.length !== 1 || lifecycle[0].stage !== 'projecting' || !Array.isArray(projection.subjects)) {
      skippedPacks++; continue
    }
    const identities = new Map()
    for (const subject of projection.subjects) identities.set(subject?.subject_ref, (identities.get(subject?.subject_ref) || 0) + 1)
    for (const subject of projection.subjects) {
      let source
      try {
        if (identities.get(subject?.subject_ref) !== 1) throw Error('Ambiguous observation')
        source = captureSubject(projection, subject)
      } catch { skippedSubjects++; continue }
      inspectedSubjects++
      for (const evidenceRef of source.evidence_refs) {
        const key = materialGroupKey(packId, evidenceRef)
        if (!groups.has(key)) groups.set(key, { key, pack_id: packId, evidence_ref: evidenceRef, sources: [] })
        groups.get(key).sources.push(source)
      }
    }
  }
  const recurring = [...groups.values()].filter(group => group.sources.length >= 2)
  for (const group of recurring) group.sources.sort((a, b) => compare(a.subject_ref, b.subject_ref))
  recurring.sort((a, b) => b.sources.length - a.sources.length || compare(a.key, b.key))
  return { groups: recurring, skippedPacks, skippedSubjects, inspectedSubjects }
}

// Publish time is provenance, not content. Bind all inspected fields and every
// member (including excluded members), independent of projection array order.
export function materialGroupSignature(group) {
  return JSON.stringify({ pack_id: group.pack_id, evidence_ref: group.evidence_ref,
    sources: group.sources.map(source => {
      const { captured_generated_at, ...content } = source
      return content
    }).sort((a, b) => compare(a.subject_ref, b.subject_ref)) })
}

async function groupDigest(group) {
  const bytes = new TextEncoder().encode(materialGroupSignature(group))
  const digest = await globalThis.crypto.subtle.digest('SHA-256', bytes)
  return [...new Uint8Array(digest)].map(byte => byte.toString(16).padStart(2, '0')).join('')
}

export async function reviewMaterialGroup(group, includedKeys, hypothesis) {
  if (!group || !Array.isArray(group.sources) || group.sources.length < 2 || group.sources.length > MATERIAL_LIMITS.group) {
    throw Error('Review requires a shared-material group of two to 128 observations.')
  }
  if (typeof hypothesis !== 'string' || !hypothesis.trim() || hypothesis.length > 2000) {
    throw Error('Describe a tentative pattern in at most 2,000 characters.')
  }
  const sources = group.sources.filter(source => includedKeys.has(subjectKey(source.pack_id, source.subject_ref)))
  if (sources.length < 2 || sources.length > 12 || sources.length !== includedKeys.size) {
    throw Error('Include between two and twelve observations from this group.')
  }
  const observed = group.sources.map(source => source.subject_ref)
  if (new Set(observed).size !== observed.length || group.sources.some(source => source.pack_id !== group.pack_id || !source.evidence_refs.includes(group.evidence_ref))) {
    throw Error('The group has ambiguous sources or an invalid shared-material link.')
  }
  const selected = sources.map(source => source.subject_ref)
  const review = {
    contract_id: 'moontown.shared-material-review.v1',
    method: 'same-pack-exact-evidence-reference',
    pack_id: group.pack_id,
    evidence_ref: group.evidence_ref,
    group_binding_sha256: await groupDigest(group),
    captured_generated_at: group.sources[0].captured_generated_at,
    observed_subject_refs: observed,
    included_subject_refs: selected,
    excluded_subject_refs: observed.filter(ref => !selected.includes(ref)),
    operator_hypothesis: hypothesis.trim(),
    independent_corroboration: false,
  }
  return { sources: structuredClone(sources), review }
}

export async function assertCurrentMaterialReview(review, state) {
  const key = materialGroupKey(review.pack_id, review.evidence_ref)
  const current = discoverMaterialGroups(state).groups.find(group => group.key === key)
  if (!current || await groupDigest(current) !== review.group_binding_sha256) {
    throw Error('The shared-material group changed, including its membership or excluded observations. Reopen Pack layers and review the current group before proposing.')
  }
}

export function attachMaterialReview(candidate, review, sources) {
  const refs = sources.map(source => source.subject_ref)
  if (review.contract_id !== 'moontown.shared-material-review.v1' ||
      review.method !== 'same-pack-exact-evidence-reference' ||
      !/^[a-f0-9]{64}$/.test(review.group_binding_sha256) ||
      review.independent_corroboration !== false ||
      JSON.stringify(refs) !== JSON.stringify(review.included_subject_refs) ||
      sources.length < 2 || sources.length > 12 ||
      sources.some(source => source.pack_id !== review.pack_id || !source.evidence_refs.includes(review.evidence_ref))) {
    throw Error('The reviewed group does not match the selected proposal sources.')
  }
  candidate.domain_payload.moontown_source_context.material_review = structuredClone(review)
  return candidate
}

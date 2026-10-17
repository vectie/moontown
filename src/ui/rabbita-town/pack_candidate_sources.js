// Bounded source selection for the existing pack-candidate intake contract.
// These are copied observations, not accepted knowledge or instructions.
const text = (value, maximum) => typeof value === 'string' && value.trim() && value.length <= maximum
const ref = value => text(value, 1024) && !value.startsWith('/') && !/[\\\x00-\x20\x7f]/.test(value) && value.split('/').every(part => part && part !== '.' && part !== '..')
export const subjectKey = (packId, subjectRef) => JSON.stringify([packId, subjectRef])

export function captureSubject(projection, subject) {
  if (!projection || !text(projection.pack_id, 256) || !text(projection.product_id, 256) || !text(projection.version, 100) || !text(projection.generated_at, 100) ||
      !subject || !ref(subject.subject_ref) || !text(subject.title, 4096) || !text(subject.summary, 16384) || !text(subject.schema_id, 256) || !text(subject.lifecycle_state, 256) ||
      !Array.isArray(subject.evidence_refs) || subject.evidence_refs.length > 100 || !subject.evidence_refs.every(ref) || new Set(subject.evidence_refs).size !== subject.evidence_refs.length) throw Error('This projected subject has missing or oversized source information.')
  return { pack_id: projection.pack_id, product_id: projection.product_id, pack_version: projection.version, captured_generated_at: projection.generated_at,
    subject_ref: subject.subject_ref, schema_id: subject.schema_id, title: subject.title, summary: subject.summary,
    lifecycle_state: subject.lifecycle_state, evidence_refs: [...subject.evidence_refs] }
}

export function assertCurrentSources(sources, state) {
  if (!Array.isArray(sources) || !sources.length || sources.length > 12) throw Error('Select between one and twelve projected subjects.')
  const keys = new Set()
  for (const source of sources) {
    const key = subjectKey(source.pack_id, source.subject_ref)
    if (keys.has(key)) throw Error('Duplicate selected subject.')
    keys.add(key)
    const projections = state.projections.filter(item => item.pack_id === source.pack_id)
    const active = state.capabilities.filter(item => item.pack_id === source.pack_id)
    const lifecycle = state.lifecycles.filter(item => item.pack_id === source.pack_id)
    if (projections.length !== 1 || active.length !== 1 || (lifecycle.length !== 1 || lifecycle[0].stage !== 'projecting')) throw Error('A selected source pack is unavailable or degraded. Reopen Pack layers and select current sources.')
    const matches = projections[0].subjects.filter(item => item.subject_ref === source.subject_ref)
    if (matches.length !== 1) throw Error('A selected source disappeared or is ambiguous. Select it again.')
    const current = captureSubject(projections[0], matches[0])
    // A new publish timestamp alone is not a changed observation. Keep the exact
    // original timestamp as historical provenance; compare the inspected fields.
    current.captured_generated_at = source.captured_generated_at
    if (JSON.stringify(current) !== JSON.stringify(source)) throw Error('Selected source content changed. Reopen Pack layers, reselect it and review your proposal.')
  }
}

export function sourceContext(sources, connections, uncertainty) {
  if (!text(uncertainty, 2000)) throw Error('Describe contrary evidence, uncertainty, or an observable reason to reject the idea.')
  if (!Array.isArray(connections) || connections.length !== sources.length || !connections.every(value => text(value, 2000))) throw Error('Explain how every selected subject contributes to the idea.')
  const context = { contract_id: 'moontown.source-linked-candidate.v1', authorship: 'Operator-authored proposal; selected packs have not endorsed it.',
    accepted_knowledge: false, genuine_emergence_verified: false, uncertainty,
    sources: sources.map((source, index) => ({ ...structuredClone(source), connection: connections[index] })) }
  if (new TextEncoder().encode(JSON.stringify(context)).length > 131072) throw Error('Source context exceeds 128 KiB. Select fewer or smaller subjects.')
  return context
}

export function attachSourceContext(candidate, sources, connections, uncertainty) {
  if (Object.hasOwn(candidate.domain_payload, 'moontown_source_context')) throw Error('The domain payload already contains the reserved moontown_source_context field.')
  const context = sourceContext(sources, connections, uncertainty)
  const refs = [...new Set([...sources.flatMap(source => source.evidence_refs), ...candidate.evidence_refs])]
  if (refs.length > 200 || !refs.every(ref)) throw Error('Candidate evidence references must be unique safe workspace-relative paths, at most 200.')
  return { ...candidate, claim_ceiling: 'research-evidence', evidence_refs: refs,
    domain_payload: { ...candidate.domain_payload, moontown_source_context: context } }
}

// Match desktop_server.reject_unsafe_operator_write's complete body limit.
// Measure the exact serialized envelope, including JSON syntax and UTF-8 bytes.
export const CANDIDATE_BODY_LIMIT = 128 * 1024
export function serializeCandidate(candidate) {
  const body = JSON.stringify(candidate)
  if (new TextEncoder().encode(body).length > CANDIDATE_BODY_LIMIT) throw Error('Candidate exceeds the native 128 KiB request limit including source context and JSON overhead. Reduce the payload or select fewer sources.')
  return body
}

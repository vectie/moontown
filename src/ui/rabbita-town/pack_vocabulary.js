import { captureSubject, subjectKey } from './pack_candidate_sources.js'

export const VOCABULARY_LIMITS = Object.freeze({ packs: 128, subjects: 1000, bytes: 1048576, lensBytes: 65536, terms: 12, wordLength: 100, selected: 12, page: 20, suggestions: 40 })
const compare = (a, b) => a < b ? -1 : a > b ? 1 : 0
const bytes = value => new TextEncoder().encode(value).length
const allowedWordLength = value => typeof value === 'string' && value.length > 0 && value.length <= VOCABULARY_LIMITS.wordLength
const stop = new Set('a an and are as at be been being but by can could did do does for from had has have he her here hers him his how i if in into is it its may might more most my no not of on one or our ours out over she should so some than that the their theirs them then there these they this those through to too under up us was we were what when where which who why will with would you your yours'.split(' '))
export const VOCABULARY_METHOD = 'nfkc-lowercase-unicode-word-runs-v1'
export const VOCABULARY_INTERPRETATION = 'Shared words are navigation hints, not semantic similarity, independent corroboration, agreement or contradiction. Exact excerpts and pack-relative sources require operator review.'

// Unicode letters/marks/numbers form whole words; punctuation is a boundary.
// No stemming, accent folding, translations or language-specific segmentation.
export function vocabularyWords(value) {
  return [...new Set(value.normalize('NFKC').toLowerCase().match(/[\p{L}\p{N}][\p{L}\p{M}\p{N}]*/gu) || [])]
}

export function vocabularyTerms(values, maximum = VOCABULARY_LIMITS.terms) {
  if (!Array.isArray(values) || values.length > maximum) throw Error(`Use at most ${maximum} comma-separated words.`)
  const terms = values.map(value => {
    if (!allowedWordLength(value) || !value.trim()) throw Error('Each word must contain one to 100 characters.')
    const normalized = value.trim().normalize('NFKC').toLowerCase()
    if (!allowedWordLength(normalized)) throw Error('Each word must contain one to 100 characters after normalization.')
    if (vocabularyWords(normalized).length !== 1 || vocabularyWords(normalized)[0] !== normalized) throw Error('Enter individual whole words separated by commas, not phrases or punctuation.')
    return normalized
  })
  return [...new Set(terms)].sort(compare)
}

export function normalizeVocabularyLens(value) {
  if (!value || value.contract_id !== 'moontown.vocabulary-lens.v1' || value.accepted_knowledge !== false || value.method !== VOCABULARY_METHOD ||
      typeof value.label !== 'string' || !value.label.trim() || value.label.length > 140 || !['any', 'all'].includes(value.mode) ||
      !Array.isArray(value.scope_pack_ids) || !value.scope_pack_ids.length || value.scope_pack_ids.length > VOCABULARY_LIMITS.packs ||
      value.scope_pack_ids.some(id => typeof id !== 'string' || !id.trim() || id.length > 256) || new Set(value.scope_pack_ids).size !== value.scope_pack_ids.length) {
    throw Error('Invalid vocabulary lens: name a bounded pack scope, ANY/ALL mode and unaccepted lexical method.')
  }
  return { contract_id: value.contract_id, method: VOCABULARY_METHOD, accepted_knowledge: false, label: value.label.trim(),
    scope_pack_ids: [...value.scope_pack_ids].sort(compare), mode: value.mode, terms: vocabularyTerms(value.terms), ignored_suggestions: vocabularyTerms(value.ignored_suggestions, 100) }
}

export function serializeVocabularyLens(value) {
  const body = JSON.stringify(normalizeVocabularyLens(value), null, 2) + '\n'
  if (bytes(body) > VOCABULARY_LIMITS.lensBytes) throw Error('The complete lens exceeds 64 KiB.')
  return body
}

export function parseVocabularyLens(body) {
  if (typeof body !== 'string' || bytes(body) > VOCABULARY_LIMITS.lensBytes) throw Error('Choose lens JSON no larger than 64 KiB.')
  return normalizeVocabularyLens(JSON.parse(body))
}

export function discoverVocabulary(state, lensValue) {
  const lens = normalizeVocabularyLens(lensValue)
  if (!state || ![state.capabilities, state.projections, state.lifecycles].every(items => Array.isArray(items) && items.length <= VOCABULARY_LIMITS.packs)) throw Error('Vocabulary discovery needs a bounded snapshot of at most 128 packs.')
  if (state.projections.reduce((n, p) => n + (Array.isArray(p?.subjects) ? p.subjects.length : 0), 0) > VOCABULARY_LIMITS.subjects) throw Error('Vocabulary discovery is limited to 1,000 observations; no partial scan was used.')
  const sources = [], gaps = []
  for (const pack_id of lens.scope_pack_ids) {
    const projections = state.projections.filter(p => p?.pack_id === pack_id)
    const capabilities = state.capabilities.filter(p => p?.pack_id === pack_id)
    const lifecycles = state.lifecycles.filter(p => p?.pack_id === pack_id)
    try {
      if (projections.length !== 1 || capabilities.length !== 1 || lifecycles.length !== 1 || lifecycles[0].stage !== 'projecting' || !Array.isArray(projections[0].subjects)) throw Error('Missing, ambiguous or unavailable active projection.')
      const observations = projections[0].subjects.map(subject => captureSubject(projections[0], subject))
      if (new Set(observations.map(s => s.subject_ref)).size !== observations.length) throw Error('Duplicate observation identity.')
      sources.push(...observations)
    } catch (error) { gaps.push({ pack_id, message: error.message }) }
  }
  sources.sort((a, b) => compare(subjectKey(a.pack_id, a.subject_ref), subjectKey(b.pack_id, b.subject_ref)))
  if (bytes(JSON.stringify({ sources, gaps })) > VOCABULARY_LIMITS.bytes) throw Error('The complete discovery scope exceeds 1 MiB; narrow the selected layers. No partial results were used.')
  const index = new Map(), rows = []
  for (const source of sources) {
    const words = new Set(vocabularyWords(`${source.title}\n${source.summary}`))
    for (const word of words) {
      if (!index.has(word)) index.set(word, { term: word, packs: new Set(), observation_count: 0 })
      const entry = index.get(word); entry.packs.add(source.pack_id); entry.observation_count++
    }
    const matched_terms = lens.terms.filter(term => words.has(term))
    if (lens.terms.length && (lens.mode === 'any' ? matched_terms.length > 0 : matched_terms.length === lens.terms.length)) rows.push({ key: subjectKey(source.pack_id, source.subject_ref), source, matched_terms })
  }
  const ignored = new Set(lens.ignored_suggestions)
  const suggestions = [...index.values()].filter(item => item.packs.size >= 2 && allowedWordLength(item.term) && [...item.term].length >= 3 && /\p{L}/u.test(item.term) && !stop.has(item.term) && !ignored.has(item.term))
    .map(item => ({ term: item.term, pack_ids: [...item.packs].sort(compare), observation_count: item.observation_count }))
    .sort((a, b) => b.pack_ids.length - a.pack_ids.length || b.observation_count - a.observation_count || compare(a.term, b.term))
  return { contract_id: 'moontown.vocabulary-discovery.v1', accepted_knowledge: false, interpretation: VOCABULARY_INTERPRETATION, lens,
    inspected_observation_count: sources.length, matching_pack_count: new Set(rows.map(row => row.source.pack_id)).size,
    suggestions, rows, gaps }
}

export function serializeVocabularyDiscovery(report) {
  const body = JSON.stringify(report, null, 2) + '\n'
  if (bytes(body) > 4 * VOCABULARY_LIMITS.bytes) throw Error('Discovery export exceeds 4 MiB; narrow the pack scope.')
  return body
}

export function prepareVocabularyReview(state, lens, selectedKeys, hypothesis) {
  const report = discoverVocabulary(state, lens), keys = new Set(selectedKeys)
  const rows = report.rows.filter(row => keys.has(row.key))
  if (rows.length < 2 || rows.length > VOCABULARY_LIMITS.selected || rows.length !== keys.size || new Set(rows.map(row => row.source.pack_id)).size < 2) throw Error('Select two to twelve matching observations spanning at least two packs.')
  if (typeof hypothesis !== 'string' || !hypothesis.trim() || hypothesis.length > 2000) throw Error('Explain the tentative connection in at most 2,000 characters.')
  return { sources: structuredClone(rows.map(row => row.source)), review: {
    contract_id: 'moontown.vocabulary-review.v1', accepted_knowledge: false, interpretation: VOCABULARY_INTERPRETATION,
    lens: report.lens, operator_hypothesis: hypothesis.trim(), inspected_observation_count: report.inspected_observation_count,
    matching_observation_count: report.rows.length, omitted_match_count: report.rows.length - rows.length, gaps: report.gaps,
    selected_matches: rows.map(row => ({ pack_id: row.source.pack_id, subject_ref: row.source.subject_ref, matched_terms: row.matched_terms })),
  } }
}

export function attachVocabularyReview(candidate, review, sources) {
  const lens = normalizeVocabularyLens(review.lens)
  const matches = sources.map(source => ({ pack_id: source.pack_id, subject_ref: source.subject_ref,
    matched_terms: lens.terms.filter(term => vocabularyWords(`${source.title}\n${source.summary}`).includes(term)) }))
  if (review.contract_id !== 'moontown.vocabulary-review.v1' || review.accepted_knowledge !== false || review.interpretation !== VOCABULARY_INTERPRETATION ||
      sources.length < 2 || sources.length > 12 || new Set(sources.map(source => source.pack_id)).size < 2 ||
      matches.some(row => !lens.scope_pack_ids.includes(row.pack_id) || !row.matched_terms.length || (lens.mode === 'all' && row.matched_terms.length !== lens.terms.length)) ||
      JSON.stringify(matches) !== JSON.stringify(review.selected_matches)) throw Error('The vocabulary review does not match the selected sources.')
  candidate.domain_payload.moontown_source_context.vocabulary_discovery = structuredClone(review)
  return candidate
}

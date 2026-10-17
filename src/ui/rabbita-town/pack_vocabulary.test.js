import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile, writeFile } from 'node:fs/promises'
import { vocabularyWords, vocabularyTerms, VOCABULARY_METHOD, discoverVocabulary, serializeVocabularyLens,
  parseVocabularyLens, serializeVocabularyDiscovery, prepareVocabularyReview, attachVocabularyReview } from './pack_vocabulary.js'
import { createVocabularyExplorer } from './pack_vocabulary_explorer.js'
import { candidateDialog, installPackBridgePanel } from './pack_bridge_panel.js'
import { subjectKey } from './pack_candidate_sources.js'

function subject(id, summary) {
  return { subject_ref: `observations/${id}.json`, schema_id: 'fixture-draft', title: `${id} signal`, summary,
    lifecycle_state: 'draft', evidence_refs: [`evidence/${id}.json`], operation_ids: ['fixture.inspect'],
    attention: 'review', place_refs: [], related_refs: [], workflow_refs: [], run_refs: [], domain_payload: {} }
}
function stateOf() {
  return { capabilities: ['bridge-fixture', 'second-fixture'].map(pack_id => ({ pack_id, intake_operation_ids: ['fixture.candidate.intake'] })),
    lifecycles: ['bridge-fixture', 'second-fixture'].map(pack_id => ({ pack_id, stage: 'projecting' })), candidates: [],
    projections: ['bridge-fixture', 'second-fixture'].map((pack_id, i) => ({ contract_id: 'moontown.pack-projection.v1', pack_id,
      product_id: pack_id, version: '1.0.0', generated_at: '2026-10-13T08:00:00Z', subjects: i === 0
        ? [subject('interviews', 'Customers request spreadsheet export for monthly reporting.'), subject('cost', 'Export pricing remains an open question.')]
        : [subject('field-notes', 'Researchers manually export spreadsheet data after field visits.'), subject('shipping', 'Shipping is unrelated to this reporting question.')] })) }
}
function lens(terms = ['export']) { return { contract_id: 'moontown.vocabulary-lens.v1', method: VOCABULARY_METHOD, accepted_knowledge: false,
  label: 'A shared export need?', scope_pack_ids: ['bridge-fixture', 'second-fixture'], mode: 'any', terms, ignored_suggestions: ['signal'] } }
const keys = [subjectKey('bridge-fixture', 'observations/interviews.json'), subjectKey('second-fixture', 'observations/field-notes.json')]
const wire = state => ({ ...state, projections: { projections: state.projections } })
const reply = value => ({ ok: true, json: async () => value })

test('Unicode whole-word matching normalizes compatible forms and accents without substring or stemming', () => {
  assert.deepEqual(vocabularyWords('CAFÉ Cafe\u0301 ＥＸＰＯＲＴ export-ready 北京 数据 Ελληνικά Пример 123'), ['café', 'export', 'ready', '北京', '数据', 'ελληνικά', 'пример', '123'])
  assert.deepEqual(vocabularyTerms(['EXPORT', 'export', 'ＣＡＦÉ']), ['café', 'export'])
  const state = stateOf(); state.projections[0].subjects[0].summary = 'Cafe\u0301 export-ready importing exports'
  assert.equal(discoverVocabulary(state, lens(['café'])).rows.length, 1)
  assert.equal(discoverVocabulary(state, lens(['port'])).rows.length, 0)
  assert.equal(discoverVocabulary(state, lens(['import'])).rows.length, 0)
  assert.throws(() => vocabularyTerms(['two words']), /individual whole words/)
})

test('ranked suggestions discover distinct-path cross-pack vocabulary and count each observation only once', () => {
  const state = stateOf(), original = JSON.stringify(state)
  state.projections[0].subjects[0].summary += ' Export EXPORT the and 123.'
  state.projections[1].subjects[0].summary += ' the and 123.'
  const saved = JSON.stringify(state)
  const report = discoverVocabulary(state, lens())
  assert.equal(JSON.stringify(state), saved)
  const term = report.suggestions.find(s => s.term === 'export')
  assert.equal(term.pack_ids.length, 2); assert.equal(term.observation_count, 3)
  assert.ok(!report.suggestions.some(s => ['the', 'and', '123', 'signal'].includes(s.term)))
  assert.deepEqual(report.rows[0].source.evidence_refs, ['evidence/cost.json'])
  const stable = discoverVocabulary(stateOf(), lens()); assert.equal(JSON.stringify(stateOf()), original)
  const reordered = stateOf(); reordered.projections.reverse(); reordered.projections.forEach(p => p.subjects.reverse())
  assert.deepEqual(discoverVocabulary(reordered, lens()), stable)
})

test('ANY is a union and ALL requires every word in each observation; explicit stop words remain searchable', () => {
  const any = discoverVocabulary(stateOf(), { ...lens(['export', 'spreadsheet']), mode: 'any' })
  const all = discoverVocabulary(stateOf(), { ...lens(['export', 'spreadsheet']), mode: 'all' })
  assert.equal(any.rows.length, 3); assert.equal(all.rows.length, 2)
  assert.equal(discoverVocabulary(stateOf(), lens(['for'])).rows.length, 1)
  assert.equal(discoverVocabulary(stateOf(), lens([])).rows.length, 0)
})

test('every suggestion obeys lens word bounds before and after Unicode normalization and roundtrips', () => {
  const state = stateOf(), boundary = 'x'.repeat(100), oversized = 'y'.repeat(101)
  const acceptedLigatures = '\ufb03'.repeat(33), oversizedLigatures = '\ufb03'.repeat(34)
  const summary = `${boundary} ${oversized} ${acceptedLigatures} ${oversizedLigatures} export`
  state.projections.forEach(p => { p.subjects[0].summary = summary })
  const report = discoverVocabulary(state, lens([])), terms = report.suggestions.map(row => row.term)
  assert.ok(terms.includes(boundary)); assert.ok(terms.includes('ffi'.repeat(33)))
  assert.ok(!terms.includes(oversized)); assert.ok(!terms.includes('ffi'.repeat(34)))
  for (const term of terms) {
    const selected = parseVocabularyLens(serializeVocabularyLens(lens([term])))
    assert.deepEqual(selected.terms, [term])
    assert.ok(discoverVocabulary(state, selected).rows.length >= 2)
  }
  assert.deepEqual(vocabularyTerms([acceptedLigatures]), ['ffi'.repeat(33)])
  assert.throws(() => vocabularyTerms([oversized]), /100 characters/)
  assert.throws(() => vocabularyTerms([oversizedLigatures]), /after normalization/)
  assert.throws(() => parseVocabularyLens(JSON.stringify({ ...lens(), ignored_suggestions: [oversizedLigatures] })), /after normalization/)
  assert.equal(discoverVocabulary(state, lens(['export'])).rows[1].source.summary, summary)
})

test('lens roundtrip preserves editable scope and word semantics and strips unknown claims', () => {
  const restored = parseVocabularyLens(serializeVocabularyLens({ ...lens(['EXPORT']), extra: 'discard' }))
  assert.deepEqual(restored, lens()); assert.equal(restored.extra, undefined)
  const foreign = { ...lens(), scope_pack_ids: ['not-installed'] }
  const report = discoverVocabulary(stateOf(), parseVocabularyLens(JSON.stringify(foreign)))
  assert.equal(report.gaps[0].pack_id, 'not-installed'); assert.equal(report.rows.length, 0)
  for (const value of [{ ...lens(), accepted_knowledge: true }, { ...lens(), method: 'semantic-embedding' }, { ...lens(), scope_pack_ids: [] },
    { ...lens(), scope_pack_ids: ['a', 'a'] }, { ...lens(), mode: 'maybe' }, { ...lens(), terms: ['word phrase'] },
    { ...lens(), terms: Array(13).fill('export') }, { ...lens(), ignored_suggestions: Array(101).fill('noise') }]) assert.throws(() => parseVocabularyLens(JSON.stringify(value)))
  assert.throws(() => parseVocabularyLens('{')); assert.throws(() => parseVocabularyLens('雪'.repeat(22000)), /64 KiB/)
})

test('malformed or unavailable scoped packs are named whole-pack gaps, never partial reassuring coverage', () => {
  for (const mutate of [s => s.projections.shift(), s => s.capabilities.shift(), s => s.lifecycles[0].stage = 'degraded',
    s => s.projections.push(s.projections[0]), s => s.capabilities.push(s.capabilities[0]), s => s.lifecycles.push(s.lifecycles[0]),
    s => s.projections[0].subjects[0].summary = '', s => s.projections[0].subjects.push(s.projections[0].subjects[0]),
    s => s.projections[0].subjects = null, s => s.projections[0].subjects[0].evidence_refs = ['../unsafe']]) {
    const state = stateOf(); mutate(state); const result = discoverVocabulary(state, lens())
    assert.equal(result.gaps.length, 1); assert.equal(result.gaps[0].pack_id, 'bridge-fixture')
    assert.ok(result.rows.every(row => row.source.pack_id === 'second-fixture'))
  }
  const excluded = { ...lens(), scope_pack_ids: ['second-fixture'] }, state = stateOf(); state.projections[0].subjects = null
  assert.equal(discoverVocabulary(state, excluded).gaps.length, 0)
})

test('discovery bounds fail the whole scan; empty available packs remain valid', () => {
  const state = stateOf(); state.projections[0].subjects = []
  assert.equal(discoverVocabulary(state, lens()).gaps.length, 0)
  state.capabilities = Array(129).fill(state.capabilities[0]); assert.throws(() => discoverVocabulary(state, lens()), /128/)
  const many = stateOf(); many.projections[0].subjects = Array.from({ length: 1001 }, (_, i) => subject(String(i), 'export'))
  assert.throws(() => discoverVocabulary(many, lens()), /1,000/)
  const huge = stateOf(); huge.projections[0].subjects = Array.from({ length: 70 }, (_, i) => subject(String(i), '雪'.repeat(16000)))
  assert.throws(() => discoverVocabulary(huge, lens()), /1 MiB/)
})

test('review preserves lens, exact matching words, omissions and named gaps without acceptance', () => {
  const scoped = { ...lens(), scope_pack_ids: [...lens().scope_pack_ids, 'unavailable-pack'] }
  const prepared = prepareVocabularyReview(stateOf(), scoped, keys, 'Explore whether these uses need the same workflow.')
  assert.equal(prepared.review.omitted_match_count, 1); assert.equal(prepared.review.gaps[0].pack_id, 'unavailable-pack')
  assert.deepEqual(prepared.review.selected_matches.map(s => s.matched_terms), [['export'], ['export']])
  const candidate = { domain_payload: { moontown_source_context: {} } }
  attachVocabularyReview(candidate, prepared.review, prepared.sources)
  assert.equal(candidate.domain_payload.moontown_source_context.vocabulary_discovery.accepted_knowledge, false)
  const invalid = structuredClone(prepared.sources); invalid[0].summary = 'No relevant word'; invalid[0].title = 'Unrelated'
  assert.throws(() => attachVocabularyReview(candidate, prepared.review, invalid), /does not match/)
  for (const selected of [[], ['missing'], [keys[0]], [keys[0], subjectKey('bridge-fixture', 'observations/cost.json')]]) assert.throws(() => prepareVocabularyReview(stateOf(), lens(), selected, 'Reason'), /two to twelve/)
  assert.throws(() => prepareVocabularyReview(stateOf(), lens(), keys, ''), /tentative/)
})

// Shipped handlers in a small event-DOM substitute, not a real browser claim.
function dom() {
  class Node {
    constructor(tag) { this.tagName = tag; this.children = []; this.events = {}; this.dataset = {}; this.value = ''; this.textContent = ''; this.disabled = false; this.open = false; this.files = [] }
    append(...nodes) { for (const node of nodes) { this.children.push(node); node.parent = this; if (this.tagName === 'select' && !this.value) this.value = node.value } }
    setAttribute(key, value) { this[key] = value }
    addEventListener(type, fn) { this.events[type] = fn }
    replaceChildren(...nodes) { this.children = []; this.append(...nodes) }
    remove() { if (this.parent) this.parent.children = this.parent.children.filter(n => n !== this) }
    showModal() { this.open = true }
    close() { this.open = false }
    click() { return this.fire('click') }
    async fire(type) { return this.events[type]?.({ target: this, preventDefault() {} }) }
  }
  const body = new Node('body'), all = (node = body) => [node, ...node.children.flatMap(child => all(child))]
  const document = { body, createElement: tag => new Node(tag), querySelector: () => all().find(n => n.dataset.packBridgePanel) }
  return { document, all, find: predicate => { const node = all().find(predicate); assert.ok(node, 'Missing control'); return node } }
}
function mount(d, options = {}, state = stateOf()) {
  const ui = createVocabularyExplorer({ onPropose() {}, resumePending: () => false, download() {}, ...options })
  d.document.body.append(ui.section); ui.refresh(state, new Set(['bridge-fixture', 'second-fixture'])); return ui
}
async function search(d, text = 'export') { const input = d.find(n => n.dataset.vocabularyTerms); input.value = text; await input.fire('input') }
async function select(d) { for (const key of keys) { const choose = d.find(n => n.dataset.vocabularyChoose === key); choose.checked = true; await choose.fire('change') } }
function fillCandidate(d) {
  d.find(n => n.placeholder === 'What emerged in MoonTown?').value = 'Investigate shared spreadsheet export friction'
  d.find(n => n.placeholder?.startsWith('Why this')).value = 'Check whether customer reporting and field research need a common export primitive.'
  d.all().filter(n => n.dataset.sourceConnection).forEach(n => n.value = 'The excerpt names spreadsheet export; compare dates and actual user needs before drawing a conclusion.')
  d.find(n => n.dataset.sourceUncertainty).value = 'Reject if these audiences need incompatible formats or the shared word hides different jobs.'
  d.find(n => n.spellcheck === false).value = '{"experiment_kind":"interview"}'
  return d.find(n => n.tagName === 'form')
}

test('actual mounted pack panel discovers different-path evidence, edits intake and emits native v1 envelope', async () => {
  const d = dom(), previousFetch = globalThis.fetch, previousDate = globalThis.Date; globalThis.document = d.document
  globalThis.Date = class extends previousDate { constructor(...args) { super(...(args.length ? args : ['2026-10-13T09:00:00Z'])) } static now() { return 1791882000000 } }
  const sent = [], state = stateOf(); globalThis.fetch = async (url, options) => { if (url.endsWith('candidates')) { sent.push(options.body); return reply({ receipt: { status: 'review-pending' } }) } return reply(wire(state)) }
  try {
    installPackBridgePanel(); await d.find(n => n.dataset.packBridgePanel === 'launch').fire('click')
    const label = d.find(n => n.dataset.vocabularyLabel); label.value = lens().label; await label.fire('input')
    const ignored = d.find(n => n.dataset.vocabularyIgnored); ignored.value = 'signal'; await ignored.fire('input')
    await d.find(n => n.dataset.vocabularySuggestion === 'export').fire('click'); await select(d)
    d.find(n => n.dataset.vocabularyHypothesis).value = 'Different domains describe manual spreadsheet exports.'
    await d.find(n => n.dataset.vocabularyContinue).fire('click')
    assert.equal(d.find(n => n.placeholder?.startsWith('Why this')).value, 'Different domains describe manual spreadsheet exports.')
    const form = fillCandidate(d); await form.fire('submit'); await form.fire('submit'); assert.equal(sent.length, 1)
    const candidate = JSON.parse(sent[0]), context = candidate.domain_payload.moontown_source_context
    assert.equal(context.vocabulary_discovery.omitted_match_count, 1); assert.equal(context.sources.length, 2)
    assert.notEqual(context.sources[0].evidence_refs[0], context.sources[1].evidence_refs[0]); assert.equal(context.accepted_knowledge, false)
    assert.equal(candidate.domain_payload.experiment_kind, 'interview'); assert.equal(candidate.intake_operation_id, 'fixture.candidate.intake')
    if (process.env.MOONTOWN_VOCABULARY_SAMPLES) {
      const root = process.env.MOONTOWN_VOCABULARY_SAMPLES
      await writeFile(`${root}/lens.json`, serializeVocabularyLens(lens()))
      await writeFile(`${root}/discovery.json`, serializeVocabularyDiscovery(discoverVocabulary(state, lens())))
      await writeFile(`${root}/current-snapshot.json`, JSON.stringify(wire(state), null, 2) + '\n')
      await writeFile(`${root}/candidate.json`, sent[0] + '\n')
    }
  } finally { globalThis.fetch = previousFetch; globalThis.Date = previousDate; delete globalThis.document }
})

test('mounted lens import is previewed, cancelable, explicitly applied and still editable against current sources', async () => {
  const d = dom(); globalThis.document = d.document
  try {
    mount(d); await search(d, 'shipping')
    const upload = d.find(n => n.dataset.vocabularyImport), body = serializeVocabularyLens(lens(['spreadsheet']))
    upload.files = [{ size: Buffer.byteLength(body), text: async () => body }]; await upload.fire('change')
    assert.equal(d.find(n => n.dataset.vocabularyTerms).value, 'shipping')
    const oldAccept = d.find(n => n.dataset.vocabularyAcceptImport)
    await d.find(n => n.dataset.vocabularyCancelImport).fire('click'); await oldAccept.fire('click')
    assert.equal(d.find(n => n.dataset.vocabularyTerms).value, 'shipping')
    await upload.fire('change'); await d.find(n => n.dataset.vocabularyAcceptImport).fire('click')
    assert.equal(d.all().filter(n => n.dataset.vocabularyChoose).length, 2)
    await search(d, 'export, spreadsheet'); const mode = d.find(n => n.dataset.vocabularyMode); mode.value = 'all'; await mode.fire('change')
    assert.equal(d.all().filter(n => n.dataset.vocabularyChoose).length, 2)
  } finally { delete globalThis.document }
})

test('late file reads and stale suggestion or selection controls cannot replace a newer lens', async () => {
  const d = dom(); globalThis.document = d.document
  try {
    mount(d); const oldSuggestion = d.find(n => n.dataset.vocabularySuggestion === 'export'), upload = d.find(n => n.dataset.vocabularyImport)
    let finish; upload.files = [{ size: 10, text: () => new Promise(resolve => { finish = resolve }) }]
    const pending = upload.fire('change'); await search(d, 'shipping'); finish(serializeVocabularyLens(lens()))
    await pending; await oldSuggestion.fire('click'); assert.equal(d.find(n => n.dataset.vocabularyTerms).value, 'shipping')
    assert.ok(!d.all().some(n => n.dataset.vocabularyAcceptImport))
    const stale = d.find(n => n.dataset.vocabularyChoose); await search(d, 'export'); stale.checked = true; await stale.fire('change')
    assert.equal(d.find(n => n.dataset.vocabularyContinue).disabled, true)
  } finally { delete globalThis.document }
})

test('scope remains explicit through layer changes; refresh invalidates selection and retains the editable lens', async () => {
  const d = dom(); globalThis.document = d.document
  try {
    const state = stateOf(), ui = mount(d, {}, state); await search(d); await select(d)
    ui.refresh(state, new Set(['bridge-fixture'])); assert.equal(d.find(n => n.dataset.vocabularyContinue).disabled, false)
    const current = stateOf(); current.projections[1].subjects[0].summary = 'Changed current observation'
    ui.refresh(current, new Set(['bridge-fixture'])); assert.equal(d.find(n => n.dataset.vocabularyContinue).disabled, true)
    assert.equal(d.find(n => n.dataset.vocabularyTerms).value, 'export')
    assert.equal(d.all().filter(n => n.dataset.vocabularyChoose).length, 2)
    await d.find(n => n.dataset.vocabularyScope).fire('click')
    assert.ok(d.all().some(n => n.textContent.startsWith('Lens scope: bridge-fixture.')))
  } finally { delete globalThis.document }
})

test('pagination retains selection and exports every match while query editing clears selection', async () => {
  const d = dom(); globalThis.document = d.document; const downloads = []
  try {
    const state = stateOf(); state.projections[0].subjects = Array.from({ length: 25 }, (_, i) => subject(`a-${String(i).padStart(2, '0')}`, 'Export observations'))
    mount(d, { download: (body, name) => downloads.push({ body, name }) }, state); await search(d)
    const first = d.find(n => n.dataset.vocabularyChoose); first.checked = true; await first.fire('change')
    await d.find(n => n.dataset.vocabularyNext).fire('click'); assert.equal(d.all().filter(n => n.dataset.vocabularyChoose).length, 6)
    await d.find(n => n.dataset.vocabularyPrevious).fire('click'); assert.equal(d.find(n => n.dataset.vocabularyChoose === first.dataset.vocabularyChoose).checked, true)
    await d.find(n => n.dataset.vocabularyReport).fire('click'); await d.find(n => n.dataset.vocabularyExport).fire('click')
    assert.equal(JSON.parse(downloads[0].body).rows.length, 26); assert.deepEqual(JSON.parse(downloads[1].body).terms, ['export'])
    await search(d, 'spreadsheet'); assert.equal(d.find(n => n.dataset.vocabularyContinue).disabled, true)
  } finally { delete globalThis.document }
})

test('changed, unavailable and removed current observations block candidate POST', async () => {
  for (const mutate of [s => s.projections[0].subjects[0].summary = 'changed', s => s.lifecycles[0].stage = 'failed', s => s.projections[0].subjects.shift()]) {
    const d = dom(); globalThis.document = d.document
    try {
      const prepared = prepareVocabularyReview(stateOf(), lens(), keys, 'Compare'), current = stateOf(); mutate(current); let posts = 0
      candidateDialog(stateOf(), () => {}, prepared.sources, { vocabularyReview: prepared.review, fetcher: async (url) => { if (url.endsWith('candidates')) posts++; return reply(wire(current)) } })
      await fillCandidate(d).fire('submit'); assert.equal(posts, 0)
      assert.ok(d.all().some(n => /changed|unavailable|disappeared/.test(n.textContent)))
    } finally { delete globalThis.document }
  }
})

test('timestamp-only republishing allows the original reviewed excerpts and exact lens to continue', async () => {
  const d = dom(); globalThis.document = d.document
  try {
    const prepared = prepareVocabularyReview(stateOf(), lens(), keys, 'Compare'), current = stateOf(), posts = []
    current.projections.forEach(p => p.generated_at = 'later-publisher-claim')
    candidateDialog(stateOf(), () => {}, prepared.sources, { vocabularyReview: prepared.review, fetcher: async (url, options) => {
      if (url.endsWith('candidates')) { posts.push(JSON.parse(options.body)); return reply({ receipt: { status: 'review-pending' } }) }
      return reply(wire(current))
    } })
    await fillCandidate(d).fire('submit'); assert.equal(posts.length, 1)
    assert.equal(posts[0].domain_payload.moontown_source_context.sources[0].captured_generated_at, '2026-10-13T08:00:00Z')
  } finally { delete globalThis.document }
})

test('uncertain candidate reopening and retry preserve identity and exact lexical context', async () => {
  const d = dom(), previousFetch = globalThis.fetch; globalThis.document = d.document
  const bodies = []; let first = true
  globalThis.fetch = async (url, options) => { if (url.endsWith('candidates')) { bodies.push(options.body); if (first) { first = false; throw Error('Lost response') } return reply({ receipt: { status: 'review-pending' } }) } return reply(wire(stateOf())) }
  try {
    installPackBridgePanel(); await d.find(n => n.dataset.packBridgePanel === 'launch').fire('click'); await search(d); await select(d)
    d.find(n => n.dataset.vocabularyHypothesis).value = 'Compare actual uses'; await d.find(n => n.dataset.vocabularyContinue).fire('click')
    const form = fillCandidate(d); await form.fire('submit'); d.find(n => n.tagName === 'dialog').close()
    await d.find(n => n.dataset.vocabularyContinue).fire('click'); assert.equal(d.find(n => n.tagName === 'dialog').open, true)
    await form.fire('submit'); assert.equal(bodies.length, 2); assert.equal(bodies[0], bodies[1])
  } finally { globalThis.fetch = previousFetch; delete globalThis.document }
})

test('literal source text stays text, and production assembly includes both explorer modules', async () => {
  const d = dom(); globalThis.document = d.document
  try {
    const state = stateOf(); state.projections[0].subjects[0].summary = '<img src=x onerror=alert(1)> export'
    mount(d, {}, state); await search(d)
    assert.ok(d.all().some(n => n.textContent === '<img src=x onerror=alert(1)> export'))
    assert.ok(d.all().every(n => n.innerHTML === undefined))
    for (const name of ['assemble-production-build.mjs', 'verify-production-build.mjs']) {
      const text = await readFile(new URL(`./scripts/${name}`, import.meta.url), 'utf8')
      assert.match(text, /'pack_vocabulary.js'/); assert.match(text, /'pack_vocabulary_explorer.js'/)
    }
  } finally { delete globalThis.document }
})

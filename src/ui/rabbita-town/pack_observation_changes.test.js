import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile, writeFile } from 'node:fs/promises'
import { captureObservationBaseline, serializeObservationBaseline, parseObservationBaseline, compareObservationBaseline,
  prepareObservationChanges, attachObservationChanges } from './pack_observation_changes.js'
import { createObservationChanges } from './pack_observation_review.js'
import { installPackBridgePanel } from './pack_bridge_panel.js'

function subject(id, summary = `Earlier ${id} observation`) {
  return { subject_ref: `observations/${id}.json`, schema_id: 'fixture-draft', title: `${id} signal`, summary,
    lifecycle_state: 'draft', evidence_refs: [`evidence/${id}.json`], operation_ids: ['fixture.inspect'],
    attention: 'review', place_refs: [], related_refs: [], workflow_refs: [], run_refs: [], domain_payload: {} }
}
function stateOf() {
  return { capabilities: ['bridge-fixture', 'second-fixture'].map(pack_id => ({ pack_id, intake_operation_ids: ['fixture.candidate.intake'] })),
    lifecycles: ['bridge-fixture', 'second-fixture'].map(pack_id => ({ pack_id, stage: 'projecting' })), candidates: [],
    projections: ['bridge-fixture', 'second-fixture'].map(pack_id => ({ contract_id: 'moontown.pack-projection.v1', pack_id,
      product_id: pack_id, version: '1.0.0', generated_at: '2026-10-12T12:00:00Z', subjects: [subject('demand'), subject('retention')] })) }
}
const capture = (state = stateOf()) => captureObservationBaseline(state, new Set(['bridge-fixture', 'second-fixture']), 'Monday field notes', '2026-10-12T13:00:00Z')
const wire = state => ({ ...state, projections: { projections: state.projections } })
const reply = state => ({ ok: true, json: async () => state })
function changedState() {
  const state = stateOf()
  state.projections.forEach(p => p.generated_at = '2026-10-13T08:00:00Z')
  state.projections[0].subjects[0].summary = 'Three interviewees now request a shared export.'
  state.projections[0].subjects.pop()
  state.projections[1].subjects.push(subject('export', 'A second domain reports repeated copy/paste into spreadsheets.'))
  return state
}

test('baseline roundtrip copies exact attributed observations and comparison finds new, changed and absent fields', () => {
  const before = stateOf(), baseline = capture(before), saved = JSON.stringify(before)
  const roundtrip = parseObservationBaseline(serializeObservationBaseline(baseline))
  assert.deepEqual(roundtrip, baseline)
  const report = compareObservationBaseline(roundtrip, changedState())
  assert.deepEqual(report.rows.map(row => row.status), ['changed', 'no-longer-projected', 'unchanged', 'newly-projected', 'unchanged'])
  assert.deepEqual(report.rows[0].changed_fields, ['summary'])
  assert.equal(report.rows[0].before.summary, 'Earlier demand observation')
  assert.equal(report.rows[0].after.summary, 'Three interviewees now request a shared export.')
  assert.equal(report.accepted_knowledge, false)
  assert.equal(JSON.stringify(before), saved)
  baseline.packs[0].subjects[0].summary = 'edited local copy'
  assert.equal(before.projections[0].subjects[0].summary, 'Earlier demand observation')
})

test('republication and source ordering alone stay quiet; each inspected field change remains explicit', () => {
  const baseline = capture(), current = stateOf()
  current.projections.reverse(); current.projections.forEach(p => { p.generated_at = 'later'; p.subjects.reverse() })
  assert.ok(compareObservationBaseline(baseline, current).rows.every(row => row.status === 'unchanged'))
  for (const [field, value] of [['title', 'new title'], ['schema_id', 'new-schema'], ['lifecycle_state', 'reviewed'], ['evidence_refs', ['evidence/new.json']]]) {
    const changed = stateOf(); changed.projections[0].subjects[0][field] = value
    assert.deepEqual(compareObservationBaseline(baseline, changed).rows[0].changed_fields, [field])
  }
  const upgraded = stateOf(); upgraded.projections[0].version = '2.0.0'
  assert.deepEqual(compareObservationBaseline(baseline, upgraded).rows[0].changed_fields, ['pack_version'])
})

test('pack scope is explicit, including empty packs; a newly available pack is not silently added', () => {
  const state = stateOf(); state.projections[0].subjects = []
  const baseline = captureObservationBaseline(state, new Set(['bridge-fixture']), 'Empty selected lane')
  const report = compareObservationBaseline(baseline, stateOf())
  assert.deepEqual(report.scope_pack_ids, ['bridge-fixture'])
  assert.equal(report.rows.length, 2); assert.ok(report.rows.every(row => row.status === 'newly-projected'))
})

test('missing, degraded, duplicated, malformed and replacement packs are named gaps, never mass removals', () => {
  for (const mutate of [s => s.projections.shift(), s => s.capabilities.shift(), s => s.lifecycles[0].stage = 'failed',
    s => s.projections.push(s.projections[0]), s => s.capabilities.push(s.capabilities[0]), s => s.lifecycles.push(s.lifecycles[0]),
    s => s.projections[0].subjects.push(s.projections[0].subjects[0]), s => s.projections[0].subjects[0].summary = '',
    s => s.projections[0].subjects = null, s => s.projections[0].product_id = 'replacement']) {
    const state = stateOf(); mutate(state)
    const result = compareObservationBaseline(capture(), state)
    assert.equal(result.gaps.length, 1); assert.equal(result.gaps[0].pack_id, 'bridge-fixture')
    assert.equal(result.gaps[0].previous.subjects.length, 2)
    assert.ok(result.rows.every(row => row.after?.pack_id !== 'bridge-fixture'))
  }
})

test('baseline imports reject oversized, malformed, duplicate, unsafe and partial inputs', () => {
  for (const body of ['{', 'x'.repeat(1048577), JSON.stringify({ ...capture(), accepted_knowledge: true })]) assert.throws(() => parseObservationBaseline(body))
  for (const mutate of [b => b.packs.push(b.packs[0]), b => b.packs[0].subjects.push(b.packs[0].subjects[0]),
    b => b.packs[0].subjects[0].subject_ref = '../escape', b => b.packs[0].subjects[0].evidence_refs = ['https://example.com/a'],
    b => b.label = '', b => b.packs = [], b => b.saved_at = 'x'.repeat(101)]) {
    const value = capture(); mutate(value); assert.throws(() => parseObservationBaseline(JSON.stringify(value)))
  }
  assert.throws(() => captureObservationBaseline(stateOf(), new Set(), 'none'))
  const broken = stateOf(); broken.lifecycles[0].stage = 'degraded'
  assert.throws(() => capture(broken), /repair the pack/)
  const huge = stateOf(); huge.projections[0].subjects = Array.from({ length: 1001 }, (_, i) => subject(String(i)))
  assert.throws(() => capture(huge), /1,000/)
  const large = stateOf(); large.projections[0].subjects = Array.from({ length: 70 }, (_, i) => subject(String(i), '雪'.repeat(16000)))
  assert.throws(() => capture(large), /1 MiB/)
  assert.throws(() => compareObservationBaseline(capture(), large), /Current comparison scope exceeds 1 MiB/)
})

test('change selection carries before/after provenance and named gaps without accepting knowledge', () => {
  const state = changedState(), baseline = capture()
  state.lifecycles[1].stage = 'degraded'
  const report = compareObservationBaseline(baseline, state)
  const result = prepareObservationChanges(baseline, state, new Set([report.rows[0].key]))
  assert.equal(result.sources.length, 1); assert.equal(result.review.gaps.length, 1)
  assert.equal(result.review.omitted_change_count, 1)
  assert.equal(result.review.selected_changes[0].before.summary, 'Earlier demand observation')
  const candidate = { domain_payload: { moontown_source_context: {} } }
  attachObservationChanges(candidate, result.review, result.sources)
  assert.equal(candidate.domain_payload.moontown_source_context.observation_changes.accepted_knowledge, false)
  assert.throws(() => attachObservationChanges(candidate, result.review, []), /does not match/)
  result.sources[0].summary = 'changed after preparation'
  assert.throws(() => attachObservationChanges(candidate, result.review, result.sources), /does not match/)
})

test('unchanged, absent, missing and oversized selections cannot become current candidate sources', () => {
  const baseline = capture(), state = changedState(), report = compareObservationBaseline(baseline, state)
  for (const keys of [[], ['unknown'], [report.rows[1].key], [report.rows[2].key], Array(13).fill(report.rows[0].key)]) {
    assert.throws(() => prepareObservationChanges(baseline, state, keys))
  }
})

// Mounted event DOM substitute. This exercises shipped controls and fetches;
// actual browser layout, download confirmation and accessibility stay unrun.
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
function panel(d, options = {}) {
  const result = createObservationChanges({ onPropose() {}, resumePending: () => false, download() {}, ...options })
  d.document.body.append(result.section); result.refresh(stateOf(), new Set(['bridge-fixture', 'second-fixture']))
  return result
}
async function importBaseline(d, baseline = capture()) {
  const upload = d.find(n => n.dataset.observationImport)
  const body = serializeObservationBaseline(baseline)
  upload.files = [{ size: Buffer.byteLength(body), text: async () => body }]
  await upload.fire('change'); await d.find(n => n.dataset.observationAcceptImport).fire('click')
}
function fillCandidate(d) {
  d.find(n => n.placeholder === 'What emerged in MoonTown?').value = 'Test a shared export workflow'
  d.find(n => n.placeholder?.startsWith('Why this')).value = 'Two locally changed signals suggest an interview, not a product commitment.'
  d.all().filter(n => n.dataset.sourceConnection).forEach(n => n.value = 'Ask whether the changed workflow recurs under the same conditions.')
  d.find(n => n.dataset.sourceUncertainty).value = 'Reject if matched interviews show this was temporary reporting noise.'
  d.find(n => n.spellcheck === false).value = '{"experiment_kind":"interview"}'
  return d.find(n => n.tagName === 'form')
}

test('mounted actual panel imports baseline, explores changes and submits exact editable v1 envelope', async () => {
  const d = dom(), oldFetch = globalThis.fetch, oldDate = globalThis.Date
  globalThis.document = d.document
  globalThis.Date = class extends oldDate { constructor(...args) { super(...(args.length ? args : ['2026-10-13T08:30:00Z'])) } static now() { return 1791880200000 } }
  const current = changedState(), sent = [], baseline = capture()
  globalThis.fetch = async (url, options) => {
    if (url.endsWith('candidates')) { sent.push(options.body); return reply({ receipt: { status: 'review-pending' } }) }
    return reply(wire(current))
  }
  try {
    installPackBridgePanel(); await d.find(n => n.dataset.packBridgePanel === 'launch').fire('click')
    await importBaseline(d, baseline)
    assert.ok(d.all().some(n => n.textContent === 'Earlier demand observation'))
    const choices = d.all().filter(n => n.dataset.observationChoose)
    assert.equal(choices.length, 2)
    for (const choose of choices) { choose.checked = true; await choose.fire('change') }
    await d.find(n => n.dataset.observationContinue).fire('click')
    assert.equal(d.all().filter(n => n.dataset.sourceConnection).length, 2)
    const form = fillCandidate(d); await form.fire('submit'); await form.fire('submit')
    assert.equal(sent.length, 1)
    const candidate = JSON.parse(sent[0]), context = candidate.domain_payload.moontown_source_context
    assert.equal(candidate.intake_operation_id, 'fixture.candidate.intake')
    assert.equal(candidate.domain_payload.experiment_kind, 'interview')
    assert.equal(context.observation_changes.selected_changes[0].before.summary, 'Earlier demand observation')
    assert.equal(context.observation_changes.selected_changes[1].status, 'newly-projected')
    assert.equal(context.observation_changes.omitted_change_count, 1)
    assert.equal(context.accepted_knowledge, false)
    if (process.env.MOONTOWN_CHANGE_SAMPLES) {
      const root = process.env.MOONTOWN_CHANGE_SAMPLES
      await writeFile(`${root}/baseline.json`, serializeObservationBaseline(baseline))
      await writeFile(`${root}/current-snapshot.json`, JSON.stringify(wire(current), null, 2) + '\n')
      await writeFile(`${root}/comparison.json`, JSON.stringify(compareObservationBaseline(baseline, current), null, 2) + '\n')
      await writeFile(`${root}/candidate.json`, sent[0] + '\n')
    }
  } finally { globalThis.fetch = oldFetch; globalThis.Date = oldDate; delete globalThis.document }
})

test('capture downloads explicit selected scope; refresh retains baseline and clears inspected selections', async () => {
  const d = dom(); globalThis.document = d.document; const downloads = []
  try {
    const ui = panel(d, { download: (body, name) => downloads.push({ body, name }) })
    await d.find(n => n.dataset.observationCapture).fire('click')
    assert.equal(downloads.length, 1); assert.equal(parseObservationBaseline(downloads[0].body).packs.length, 2)
    ui.refresh(changedState(), new Set(['bridge-fixture']))
    const choose = d.find(n => n.dataset.observationChoose); choose.checked = true; await choose.fire('change')
    assert.equal(d.find(n => n.dataset.observationContinue).disabled, false)
    const staleChoose = choose
    ui.refresh(changedState(), new Set(['bridge-fixture']))
    staleChoose.checked = true; await staleChoose.fire('change')
    assert.equal(d.find(n => n.dataset.observationContinue).disabled, true)
    await d.find(n => n.dataset.observationExport).fire('click')
    assert.equal(downloads[1].body, downloads[0].body)
    await d.find(n => n.dataset.observationReport).fire('click')
    assert.equal(JSON.parse(downloads[2].body).scope_pack_ids.length, 2)
  } finally { delete globalThis.document }
})

test('import requires explicit replacement; cancel, late reads and obsolete buttons cannot replace retained baseline', async () => {
  const d = dom(); globalThis.document = d.document; const downloads = []
  try {
    panel(d, { download: body => downloads.push(body) }); await importBaseline(d)
    const upload = d.find(n => n.dataset.observationImport)
    let release; upload.files = [{ size: 10, text: () => new Promise(resolve => release = resolve) }]
    const pending = upload.fire('change')
    const newer = capture(); newer.label = 'Newer baseline'
    upload.files = [{ size: 10, text: async () => serializeObservationBaseline(newer) }]
    await upload.fire('change'); const obsolete = d.find(n => n.dataset.observationAcceptImport)
    await d.find(n => n.textContent === 'Cancel baseline import').fire('click')
    await obsolete.fire('click')
    release(serializeObservationBaseline(newer)); await pending
    assert.equal(d.all().filter(n => n.dataset.observationAcceptImport).length, 0)
    await d.find(n => n.dataset.observationExport).fire('click')
    assert.equal(parseObservationBaseline(downloads[0]).label, 'Monday field notes')
  } finally { delete globalThis.document }
})

test('replacement invalidates an unresolved import and file read failures leave historical baseline intact', async () => {
  const d = dom(); globalThis.document = d.document; const downloads = []
  try {
    panel(d, { download: body => downloads.push(body) }); await importBaseline(d)
    const upload = d.find(n => n.dataset.observationImport)
    let release; upload.files = [{ size: 10, text: () => new Promise(resolve => release = resolve) }]
    const pending = upload.fire('change')
    d.find(n => n.dataset.observationLabel).value = 'Explicit new baseline'
    await d.find(n => n.dataset.observationCapture).fire('click')
    release(serializeObservationBaseline(capture())); await pending
    assert.equal(d.all().filter(n => n.dataset.observationAcceptImport).length, 0)
    upload.files = [{ size: 1048577, text: async () => { throw Error('Must not read oversized file') } }]; await upload.fire('change')
    upload.files = [{ size: 10, text: async () => { throw Error('Read interrupted') } }]; await upload.fire('change')
    await d.find(n => n.dataset.observationExport).fire('click')
    assert.equal(parseObservationBaseline(downloads.at(-1)).label, 'Explicit new baseline')
  } finally { delete globalThis.document }
})

test('search, change types and pagination retain selection without silently truncating discovery', async () => {
  const d = dom(); globalThis.document = d.document
  try {
    const ui = panel(d); await importBaseline(d)
    const current = changedState(); current.projections[1].subjects.push(...Array.from({ length: 30 }, (_, i) => subject(`extra-${i}`)))
    ui.refresh(current, new Set(['bridge-fixture', 'second-fixture']))
    assert.equal(d.all().filter(n => n.dataset.observationRow).length, 20)
    const chosen = d.find(n => n.dataset.observationChoose); chosen.checked = true; await chosen.fire('change')
    await d.find(n => n.dataset.observationNext).fire('click')
    assert.equal(d.all().filter(n => n.dataset.observationRow).length, 13)
    const filter = d.find(n => n.dataset.observationFilter); filter.value = 'no-longer-projected'; await filter.fire('change')
    assert.equal(d.all().filter(n => n.dataset.observationRow).length, 1)
    assert.equal(d.all().filter(n => n.dataset.observationChoose).length, 0)
    filter.value = 'changes'; await filter.fire('change')
    const search = d.find(n => n.dataset.observationSearch); search.value = 'copy/paste'; await search.fire('input')
    assert.equal(d.all().filter(n => n.dataset.observationRow).length, 1)
    assert.match(d.find(n => n.dataset.observationContinue).textContent, /1 change/)
  } finally { delete globalThis.document }
})

test('unavailable refreshed snapshot shows gaps and blocks prior selection; literal input never becomes HTML', async () => {
  const d = dom(); globalThis.document = d.document
  try {
    const ui = panel(d); const baseline = capture(); baseline.label = '<script>untrusted</script>'
    await importBaseline(d, baseline); ui.refresh(changedState(), new Set(['bridge-fixture']))
    const choose = d.find(n => n.dataset.observationChoose); choose.checked = true; await choose.fire('change')
    ui.refresh({ capabilities: [], lifecycles: [], projections: [] }, new Set())
    assert.equal(d.find(n => n.dataset.observationContinue).disabled, true)
    assert.ok(d.all().some(n => n.textContent.includes('2 unavailable pack(s)')))
    assert.ok(d.all().some(n => n.textContent.includes('<script>untrusted</script>')))
    assert.ok(d.all().every(n => n.innerHTML === undefined))
  } finally { delete globalThis.document }
})

test('existing uncertain candidate resumes instead of routing a second set of changes', async () => {
  const d = dom(); globalThis.document = d.document; let calls = 0, resumes = 0
  try {
    const ui = panel(d, { onPropose: () => calls++, resumePending: () => { resumes++; return true } })
    await importBaseline(d); ui.refresh(changedState(), new Set(['bridge-fixture']))
    const choose = d.find(n => n.dataset.observationChoose); choose.checked = true; await choose.fire('change')
    await d.find(n => n.dataset.observationContinue).fire('click')
    assert.equal(calls, 0); assert.equal(resumes, 1)
  } finally { delete globalThis.document }
})

test('native preflight refuses a changed selected observation before sending its historical comparison', async () => {
  const d = dom(), oldFetch = globalThis.fetch; globalThis.document = d.document
  let current = changedState(), posts = 0
  globalThis.fetch = async url => { if (url.endsWith('candidates')) posts++; return reply(wire(current)) }
  try {
    installPackBridgePanel(); await d.find(n => n.dataset.packBridgePanel === 'launch').fire('click'); await importBaseline(d)
    const choose = d.find(n => n.dataset.observationChoose); choose.checked = true; await choose.fire('change')
    await d.find(n => n.dataset.observationContinue).fire('click')
    current = changedState(); current.projections[0].subjects[0].summary = 'Changed while composing'
    await fillCandidate(d).fire('submit')
    assert.equal(posts, 0); assert.ok(d.all().some(n => n.textContent.includes('source content changed')))
  } finally { globalThis.fetch = oldFetch; delete globalThis.document }
})

test('both production assembly and delivery verification include the new entrypoint modules', async () => {
  for (const name of ['assemble-production-build.mjs', 'verify-production-build.mjs']) {
    const text = await readFile(new URL(`./scripts/${name}`, import.meta.url), 'utf8')
    assert.match(text, /'pack_observation_changes.js'/); assert.match(text, /'pack_observation_review.js'/)
  }
})

test('change-history overhead participates in the native whole-envelope limit before any POST', async () => {
  const d = dom(), oldFetch = globalThis.fetch; globalThis.document = d.document
  const old = stateOf(); old.projections[0].subjects = Array.from({ length: 3 }, (_, i) => subject(`large-${i}`, '雪'.repeat(16000)))
  const baseline = capture(old), current = structuredClone(old)
  current.projections[0].subjects.forEach(s => s.summary = 'A short current observation')
  let calls = 0
  globalThis.fetch = async () => { calls++; return reply(wire(current)) }
  try {
    installPackBridgePanel(); await d.find(n => n.dataset.packBridgePanel === 'launch').fire('click'); await importBaseline(d, baseline)
    for (const choose of d.all().filter(n => n.dataset.observationChoose)) { choose.checked = true; await choose.fire('change') }
    await d.find(n => n.dataset.observationContinue).fire('click')
    const loadedCalls = calls; await fillCandidate(d).fire('submit')
    assert.equal(calls, loadedCalls)
    assert.ok(d.all().some(n => n.textContent.includes('native 128 KiB request limit')))
    assert.equal(d.find(n => n.type === 'submit').disabled, false)
  } finally { globalThis.fetch = oldFetch; delete globalThis.document }
})

test('selection limit prevents silently choosing more than twelve and failed downloads preserve baseline', async () => {
  const d = dom(); globalThis.document = d.document; let failDownload = false, retained = ''
  try {
    const ui = panel(d, { download: body => { if (failDownload) throw Error('Download unavailable'); retained = body } })
    await importBaseline(d)
    const current = changedState(); current.projections[1].subjects.push(...Array.from({ length: 14 }, (_, i) => subject(`added-${i}`)))
    ui.refresh(current, new Set(['bridge-fixture']))
    for (const choose of d.all().filter(n => n.dataset.observationChoose)) { choose.checked = true; await choose.fire('change') }
    assert.equal(d.all().filter(n => n.dataset.observationChoose && n.checked).length, 12)
    failDownload = true; d.find(n => n.dataset.observationLabel).value = 'Would replace'
    await d.find(n => n.dataset.observationCapture).fire('click')
    failDownload = false; await d.find(n => n.dataset.observationExport).fire('click')
    assert.equal(parseObservationBaseline(retained).label, 'Monday field notes')
  } finally { delete globalThis.document }
})

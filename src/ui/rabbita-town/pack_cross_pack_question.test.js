import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { captureSubject } from './pack_candidate_sources.js'
import { newQuestionDraft, appendQuestionSources, serializeQuestionDraft, parseQuestionDraft,
  questionSourceGaps, refreshQuestionSource, prepareCrossPackQuestion, attachCrossPackQuestion } from './pack_cross_pack_question.js'
import { createCrossPackQuestion } from './pack_question_composer.js'
import { installPackBridgePanel } from './pack_bridge_panel.js'

function makeState() {
  return { capabilities: ['one', 'two'].map(id => ({ pack_id: id, display_name: id, intake_operation_ids: ['intake'] })),
    lifecycles: ['one', 'two'].map(id => ({ pack_id: id, stage: 'projecting' })), candidates: [],
    projections: ['one', 'two'].map(id => ({ pack_id: id, product_id: id, version: '1.0.0', generated_at: '2026-10-13',
      subjects: [{ subject_ref: 'observations/signal.json', schema_id: 'observation.v1', title: `${id} signal`,
        summary: `<script>${id} literal source</script>`, lifecycle_state: 'pending', evidence_refs: ['evidence/shared.json'], operation_ids: [] }] })) }
}
const sourcesOf = state => state.projections.map(p => captureSubject(p, p.subjects[0]))
const wire = state => ({ ...state, projections: { projections: state.projections } })
const reply = value => ({ ok: true, json: async () => value })
function completeDraft(state = makeState()) {
  const draft = appendQuestionSources(newQuestionDraft(), sourcesOf(state))
  draft.question = 'Could different contexts explain the recurring signal?'
  draft.scope = 'Compare the two local observations before proposing a narrow experiment.'
  draft.rejection_test = 'Reject if the owners show the same effect under matched conditions.'
  draft.rows.forEach((row, index) => Object.assign(row, { role: index ? 'challenges' : 'supports',
    connection: `An operator interpretation of source ${index + 1}`, conditions: index ? 'Date unknown; population B' : 'October; population A' }))
  return draft
}

test('cross-pack question retains exact namespaced observations and all operator labels without merging equal evidence paths', () => {
  const state = makeState(), before = JSON.stringify(state), draft = completeDraft(state)
  const prepared = prepareCrossPackQuestion(draft, state)
  assert.equal(JSON.stringify(state), before)
  assert.deepEqual(prepared.sources.map(s => s.pack_id), ['one', 'two'])
  assert.equal(prepared.sources[0].summary, '<script>one literal source</script>')
  assert.deepEqual(prepared.review.observations.map(row => row.role), ['supports', 'challenges'])
  assert.equal(prepared.review.accepted_knowledge, false)
  assert.equal(prepared.review.observations[1].conditions, 'Date unknown; population B')
  const candidate = { domain_payload: { moontown_source_context: { accepted_knowledge: false } } }
  attachCrossPackQuestion(candidate, prepared.review, prepared.sources)
  assert.deepEqual(candidate.domain_payload.moontown_source_context.cross_pack_question, prepared.review)
  assert.throws(() => attachCrossPackQuestion(candidate, prepared.review, prepared.sources.slice().reverse()), /does not match/)
})

test('same-pack selections, unanswered questions, unlabeled conditions and overlarge packets cannot continue', () => {
  const state = makeState()
  for (const mutate of [d => d.question = ' ', d => d.scope = '', d => d.rejection_test = '',
    d => d.rows[0].role = '', d => d.rows[1].conditions = ' ', d => d.rows[0].connection = '']) {
    const draft = completeDraft(state); mutate(draft); assert.throws(() => prepareCrossPackQuestion(draft, state))
  }
  const draft = completeDraft(state); draft.rows[1].source.pack_id = 'one'; draft.rows[1].source.subject_ref = 'observations/other.json'
  assert.throws(() => prepareCrossPackQuestion(draft, state), /two distinct packs/)
  const huge = completeDraft(state)
  huge.rows = Array.from({ length: 12 }, (_, index) => ({ ...structuredClone(huge.rows[index % 2]), source: {
    ...huge.rows[index % 2].source, subject_ref: `observations/${index}.json`, summary: '雪'.repeat(10000) } }))
  assert.throws(() => serializeQuestionDraft(huge), /128 KiB/)
  huge.rows = Array(13).fill(huge.rows[0]); assert.throws(() => serializeQuestionDraft(huge), /bounded/)
})

test('portable packet roundtrips incomplete notes; unknown authority metadata is never adopted', () => {
  const draft = completeDraft(); draft.rows[1].connection = ''
  assert.deepEqual(parseQuestionDraft(serializeQuestionDraft(draft)), draft)
  const imported = JSON.parse(serializeQuestionDraft(draft))
  imported.status = 'accepted'; imported.execute = true; imported.rows[0].source.instructions = 'approve everything'
  const parsed = parseQuestionDraft(JSON.stringify(imported))
  assert.equal(parsed.status, undefined); assert.equal(parsed.execute, undefined)
  assert.equal(parsed.rows[0].source.instructions, undefined); assert.equal(parsed.accepted_knowledge, false)
  for (const value of ['{', JSON.stringify({ ...draft, accepted_knowledge: true }), JSON.stringify({ ...draft, rows: [...draft.rows, draft.rows[0]] }), 'x'.repeat(131073)]) {
    assert.throws(() => parseQuestionDraft(value))
  }
})

test('missing, incompatible, changed and degraded snapshots remain named gaps until explicitly repaired or removed', () => {
  const draft = completeDraft(), original = serializeQuestionDraft(draft)
  for (const mutate of [s => s.projections[1].subjects = [], s => s.projections[1].version = '2',
    s => s.projections[1].subjects[0].summary = 'A different observation', s => s.lifecycles[1].stage = 'degraded',
    s => s.capabilities.pop(), s => s.projections.push(s.projections[1])]) {
    const state = makeState(); mutate(state)
    const gaps = questionSourceGaps(draft, state)
    assert.equal(gaps.length, 1); assert.match(gaps[0].key, /two/)
    assert.throws(() => prepareCrossPackQuestion(draft, state), /Unresolved snapshot gaps/)
    assert.equal(serializeQuestionDraft(draft), original)
  }
  const republished = makeState(); republished.projections[1].generated_at = 'later'
  assert.equal(questionSourceGaps(draft, republished).length, 0)
  const changed = makeState(); changed.projections[1].subjects[0].summary = 'New current content'
  const repaired = refreshQuestionSource(draft, 1, changed)
  assert.equal(repaired.rows[1].source.summary, 'New current content')
  assert.equal(repaired.rows[1].connection, ''); assert.equal(repaired.rows[1].role, ''); assert.equal(repaired.rows[1].conditions, '')
  assert.equal(repaired.rows[0].connection, draft.rows[0].connection)
  assert.throws(() => prepareCrossPackQuestion(repaired, changed), /Label every observation/)
  const missing = makeState(); missing.projections.pop()
  assert.throws(() => refreshQuestionSource(draft, 1, missing), /no unambiguous current snapshot/)
})

test('appending individual selections keeps previous work and never silently replaces historical observations', () => {
  const draft = completeDraft(), sources = sourcesOf(makeState())
  sources[0].summary = 'Changed selection'
  const next = appendQuestionSources(draft, sources)
  assert.deepEqual(next, draft)
  sources[0].subject_ref = 'observations/second.json'
  const expanded = appendQuestionSources(draft, sources)
  assert.equal(expanded.rows.length, 3); assert.equal(expanded.rows[2].role, '')
  assert.equal(expanded.question, draft.question)
})

// Runs actual mounted builders/handlers with a minimal event DOM, not a browser.
function dom() {
  class Node {
    constructor(tag) { this.tagName = tag; this.children = []; this.events = {}; this.dataset = {}; this.value = ''; this.textContent = ''; this.disabled = false; this.open = false; this.checked = false }
    append(...nodes) { for (const node of nodes) { this.children.push(node); node.parent = this; if (this.tagName === 'select' && !this.value) this.value = node.value } }
    replaceChildren(...nodes) { this.children = []; this.append(...nodes) }
    setAttribute(name, value) { this[name] = value }
    addEventListener(type, fn) { this.events[type] = fn }
    remove() { if (this.parent) this.parent.children = this.parent.children.filter(node => node !== this) }
    showModal() { this.open = true }
    close() { this.open = false }
    async fire(type) { return this.events[type]?.({ target: this, preventDefault() {} }) }
  }
  const body = new Node('body'), all = (node = body) => [node, ...node.children.flatMap(child => all(child))]
  return { all, find(predicate) { const node = all().find(predicate); assert.ok(node, 'Missing control'); return node },
    document: { body, createElement: tag => new Node(tag), querySelector: selector => selector === '[data-pack-bridge-panel]' ? all().find(n => n.dataset.packBridgePanel) : null } }
}
async function fillQuestion(d) {
  const values = completeDraft()
  for (const [flag, value] of [['questionText', values.question], ['questionScope', values.scope], ['questionRejection', values.rejection_test]]) {
    const node = d.find(n => n.dataset[flag]); node.value = value; await node.fire('input')
  }
  for (let index = 0; index < 2; index++) for (const [flag, field] of [['questionRole', 'role'], ['questionConnection', 'connection'], ['questionConditions', 'conditions']]) {
    const node = d.find(n => n.dataset[flag] === String(index)); node.value = values.rows[index][field]; await node.fire(flag === 'questionRole' ? 'change' : 'input')
  }
}
const questionForm = d => d.find(n => n.tagName === 'form' && d.all(n).some(c => c.dataset.questionText))
const candidateForm = d => d.find(n => n.tagName === 'form' && d.all(n).some(c => c.dataset.sourceUncertainty))

async function mounted(run, customFetch = null) {
  const d = dom(), state = makeState(), posts = [], oldDocument = globalThis.document, oldFetch = globalThis.fetch
  globalThis.document = d.document
  globalThis.fetch = async (url, options) => {
    if (url.endsWith('candidates')) posts.push(options.body)
    if (customFetch) return customFetch(url, options, state, posts)
    return reply(url.endsWith('candidates') ? { receipt: { status: 'review-pending' } } : wire(state))
  }
  try {
    installPackBridgePanel(); await d.find(n => n.dataset.packBridgePanel === 'launch').fire('click')
    for (const node of d.all().filter(n => n.dataset.sourceSubject)) { node.checked = true; await node.fire('change') }
    await run(d, state, posts)
  } finally { globalThis.document = oldDocument; globalThis.fetch = oldFetch }
}

test('mounted selection → scoped cross-pack question → editable intake → exact pending-review POST', async () => {
  await mounted(async (d, state, posts) => {
    await d.find(n => n.dataset.questionLaunch).fire('click'); await fillQuestion(d)
    const form = questionForm(d); await form.fire('submit'); await form.fire('submit')
    assert.equal(posts.length, 0); assert.equal(d.all().filter(n => n.dataset.sourceUncertainty).length, 1)
    assert.equal(d.find(n => n.placeholder === 'What emerged in MoonTown?').value, completeDraft().question)
    assert.equal(d.find(n => n.dataset.sourceUncertainty).value, completeDraft().rejection_test)
    d.find(n => n.placeholder?.startsWith('Why this')).value = 'A refined intake rationale'
    d.find(n => n.tagName === 'textarea' && n.spellcheck === false).value = '{"experiment_kind":"interview"}'
    await candidateForm(d).fire('submit')
    assert.equal(posts.length, 1)
    const sent = JSON.parse(posts[0]), context = sent.domain_payload.moontown_source_context
    assert.equal(sent.claim_ceiling, 'research-evidence'); assert.equal(sent.rationale, 'A refined intake rationale')
    assert.equal(sent.domain_payload.experiment_kind, 'interview'); assert.equal(context.accepted_knowledge, false)
    assert.deepEqual(context.sources.map(source => source.pack_id), ['one', 'two'])
    assert.equal(context.cross_pack_question.observations[1].role, 'challenges')
    assert.equal(context.cross_pack_question.scope, completeDraft().scope)
    assert.ok(d.all().some(n => n.textContent === '<script>two literal source</script>'))
  })
})

test('download, page-reload import preview and explicit replacement resume all notes without network effects', async () => {
  const old = globalThis.document, saved = [], proposed = []
  try {
    let d = dom(); globalThis.document = d.document
    let composer = createCrossPackQuestion({ resumePending: () => false, getSelected: () => sourcesOf(makeState()), onPropose: value => proposed.push(value), download: body => saved.push(body) })
    d.document.body.append(composer.section); composer.refresh(makeState())
    await d.find(n => n.dataset.questionLaunch).fire('click'); await fillQuestion(d)
    await d.find(n => n.dataset.questionExport).fire('click'); assert.equal(saved.length, 1)
    d = dom(); globalThis.document = d.document
    composer = createCrossPackQuestion({ resumePending: () => false, getSelected: () => [], onPropose: value => proposed.push(value) })
    d.document.body.append(composer.section); composer.refresh(makeState())
    const upload = d.find(n => n.dataset.questionImport)
    upload.files = [{ size: Buffer.byteLength(saved[0]), text: async () => saved[0] }]
    await upload.fire('change'); assert.equal(d.all().filter(n => n.tagName === 'dialog').length, 0)
    await d.find(n => n.dataset.questionReplace).fire('click')
    assert.equal(d.find(n => n.dataset.questionText).value, completeDraft().question)
    assert.equal(d.find(n => n.dataset.questionConditions === '1').value, 'Date unknown; population B')
    await questionForm(d).fire('submit'); assert.equal(proposed.length, 1)
  } finally { globalThis.document = old }
})

test('changed imported source stays visible as a gap; rereading clears only its labels and blocks until reinterpreted', async () => {
  await mounted(async (d, state, posts) => {
    const packet = serializeQuestionDraft(completeDraft())
    state.projections[1].subjects[0].summary = 'Changed after saved draft'
    await d.find(n => n.dataset.packBridgePanel === 'launch').fire('click')
    const upload = d.find(n => n.dataset.questionImport); upload.files = [{ size: packet.length, text: async () => packet }]
    await upload.fire('change'); await d.find(n => n.dataset.questionReplace).fire('click')
    assert.equal(d.find(n => n.dataset.questionContinue).disabled, true)
    assert.ok(d.all().some(n => n.textContent === '<script>two literal source</script>'))
    await questionForm(d).fire('submit'); assert.equal(posts.length, 0)
    await d.find(n => n.dataset.questionRefreshSource === '1').fire('click')
    assert.ok(d.all().some(n => n.textContent === 'Changed after saved draft'))
    assert.equal(d.find(n => n.dataset.questionConnection === '1').value, '')
    assert.equal(d.find(n => n.dataset.questionConnection === '0').value, completeDraft().rows[0].connection)
    await questionForm(d).fire('submit'); assert.equal(d.all().filter(n => n.dataset.sourceUncertainty).length, 0)
  })
})

test('missing source retains excerpt and notes across refresh; explicit removal still requires two distinct packs', async () => {
  await mounted(async (d, state, posts) => {
    await d.find(n => n.dataset.questionLaunch).fire('click'); await fillQuestion(d)
    state.projections[1].subjects = []
    await d.find(n => n.dataset.packBridgePanel === 'launch').fire('click')
    assert.equal(d.find(n => n.dataset.questionContinue).disabled, true)
    assert.equal(d.find(n => n.dataset.questionConnection === '1').value, completeDraft().rows[1].connection)
    await d.find(n => n.dataset.questionRefreshSource === '1').fire('click')
    assert.ok(d.all().some(n => n.textContent.includes('missing or ambiguous')))
    await d.find(n => n.dataset.questionRemove === '1').fire('click')
    await questionForm(d).fire('submit')
    assert.ok(d.all().some(n => n.textContent.includes('two distinct packs'))); assert.equal(posts.length, 0)
  })
})

test('cancel and layer filtering preserve question edits; repeated selections do not duplicate rows', async () => {
  await mounted(async (d, state, posts) => {
    await d.find(n => n.dataset.questionLaunch).fire('click'); await fillQuestion(d)
    await d.find(n => n.textContent === '保留并关闭').fire('click')
    const filter = d.find(n => n.type === 'checkbox' && !n.dataset.sourceSubject)
    filter.checked = false; await filter.fire('change')
    await d.find(n => n.dataset.questionLaunch).fire('click')
    assert.equal(d.all().filter(n => n.dataset.questionRow !== undefined).length, 2)
    assert.equal(d.find(n => n.dataset.questionScope).value, completeDraft().scope)
    assert.equal(posts.length, 0)
  })
})

test('final source preflight still rejects a change after the question was copied into intake', async () => {
  await mounted(async (d, state, posts) => {
    await d.find(n => n.dataset.questionLaunch).fire('click'); await fillQuestion(d); await questionForm(d).fire('submit')
    state.projections[1].version = '2'
    await candidateForm(d).fire('submit'); assert.equal(posts.length, 0)
    assert.ok(d.all().some(n => n.textContent.includes('source content changed')))
  })
})

test('unknown submission resumes the exact candidate from question/import controls and retries identical bytes', async () => {
  await mounted(async (d, state, posts) => {
    await d.find(n => n.dataset.questionLaunch).fire('click'); await fillQuestion(d); await questionForm(d).fire('submit')
    const form = candidateForm(d); await form.fire('submit'); assert.equal(posts.length, 1)
    const candidate = d.find(n => n.dataset.candidatePending === 'true'); candidate.close()
    await d.find(n => n.dataset.questionLaunch).fire('click'); assert.equal(candidate.open, true)
    const upload = d.find(n => n.dataset.questionImport); let read = false
    upload.files = [{ size: 1, text: async () => { read = true; return '{}' } }]
    await upload.fire('change'); assert.equal(read, false)
    state.projections[1].subjects = []; await form.fire('submit')
    assert.equal(posts.length, 2); assert.equal(posts[0], posts[1])
  }, async (url, options, state, posts) => {
    if (!url.endsWith('candidates')) return reply(wire(state))
    if (posts.length === 1) throw Error('Lost response')
    return reply({ receipt: { status: 'review-pending' } })
  })
})

test('invalid import cannot replace the current question and oversized files are not read', async () => {
  await mounted(async (d, state, posts) => {
    await d.find(n => n.dataset.questionLaunch).fire('click'); await fillQuestion(d)
    await d.find(n => n.textContent === '保留并关闭').fire('click')
    const upload = d.find(n => n.dataset.questionImport); let read = false
    upload.files = [{ size: 131073, text: async () => { read = true; return '{}' } }]
    await upload.fire('change'); assert.equal(read, false)
    upload.files = [{ size: 1, text: async () => '{' }]; await upload.fire('change')
    assert.equal(d.all().filter(n => n.dataset.questionReplace).length, 0)
    await d.find(n => n.dataset.questionLaunch).fire('click')
    assert.equal(d.find(n => n.dataset.questionText).value, completeDraft().question); assert.equal(posts.length, 0)
  })
})

test('production assembly and verification both include the actual question modules', async () => {
  for (const file of ['./scripts/assemble-production-build.mjs', './scripts/verify-production-build.mjs']) {
    const source = await readFile(new URL(file, import.meta.url), 'utf8')
    assert.match(source, /'pack_cross_pack_question.js'/); assert.match(source, /'pack_question_composer.js'/)
  }
})

test('detached remove cannot delete the observation that moved into its old index', async () => {
  await mounted(async d => {
    await d.find(n => n.dataset.questionLaunch).fire('click'); await fillQuestion(d)
    const remove = d.find(n => n.dataset.questionRemove === '0')
    await remove.fire('click'); await remove.fire('click')
    assert.equal(d.all().filter(n => n.dataset.questionRow !== undefined).length, 1)
    assert.ok(d.all().some(n => n.textContent === 'two: two signal'))
  })
})

test('discarded import replacement cannot overwrite newer local question edits', async () => {
  await mounted(async d => {
    const draft = completeDraft(); draft.question = 'Discarded imported question'
    const body = serializeQuestionDraft(draft), upload = d.find(n => n.dataset.questionImport)
    upload.files = [{ size: body.length, text: async () => body }]; await upload.fire('change')
    const replace = d.find(n => n.dataset.questionReplace)
    await d.find(n => n.textContent === '取消导入').fire('click')
    await d.find(n => n.dataset.questionLaunch).fire('click'); await fillQuestion(d)
    await replace.fire('click')
    assert.equal(d.find(n => n.dataset.questionText).value, completeDraft().question)
  })
})

test('a closed question form cannot open intake through a retained submit callback', async () => {
  await mounted(async d => {
    await d.find(n => n.dataset.questionLaunch).fire('click'); await fillQuestion(d)
    const form = questionForm(d)
    await d.find(n => n.textContent === '保留并关闭').fire('click')
    await form.fire('submit')
    assert.equal(d.all().filter(n => n.dataset.sourceUncertainty).length, 0)
  })
})

test('row input callbacks from an earlier render cannot change the currently displayed notes', async () => {
  await mounted(async d => {
    await d.find(n => n.dataset.questionLaunch).fire('click'); await fillQuestion(d)
    const connection = d.find(n => n.dataset.questionConnection === '0'), role = d.find(n => n.dataset.questionRole === '0')
    await d.find(n => n.dataset.packBridgePanel === 'launch').fire('click')
    connection.value = 'Detached stale edit'; await connection.fire('input')
    role.value = 'context'; await role.fire('change')
    await d.find(n => n.textContent === '保留并关闭').fire('click')
    await d.find(n => n.dataset.questionLaunch).fire('click')
    assert.equal(d.find(n => n.dataset.questionConnection === '0').value, completeDraft().rows[0].connection)
    assert.equal(d.find(n => n.dataset.questionRole === '0').value, 'supports')
  })
})

test('old dialog controls cannot close, export, overwrite or submit a newer editing session', async () => {
  await mounted(async d => {
    await d.find(n => n.dataset.questionLaunch).fire('click'); await fillQuestion(d)
    const oldForm = questionForm(d), oldClose = d.find(n => n.textContent === '保留并关闭'), oldSave = d.find(n => n.dataset.questionExport)
    await oldClose.fire('click'); await d.find(n => n.dataset.questionLaunch).fire('click')
    const current = d.find(n => n.tagName === 'dialog' && n.open)
    d.find(n => n.dataset.questionText).value = 'New session question'
    await oldClose.fire('click'); await oldSave.fire('click'); await oldForm.fire('submit')
    assert.equal(current.open, true); assert.equal(d.all().filter(n => n.dataset.sourceUncertainty).length, 0)
    await d.find(n => n.textContent === '保留并关闭').fire('click')
    await d.find(n => n.dataset.questionLaunch).fire('click')
    assert.equal(d.find(n => n.dataset.questionText).value, 'New session question')
  })
})

test('replacement and discard controls from an old import cannot affect a newer preview', async () => {
  await mounted(async d => {
    const upload = d.find(n => n.dataset.questionImport), first = completeDraft(), second = completeDraft()
    first.question = 'First import'; second.question = 'Second import'
    const firstBody = serializeQuestionDraft(first), secondBody = serializeQuestionDraft(second)
    upload.files = [{ size: firstBody.length, text: async () => firstBody }]; await upload.fire('change')
    const replace = d.find(n => n.dataset.questionReplace), discard = d.find(n => n.textContent === '取消导入')
    upload.files = [{ size: secondBody.length, text: async () => secondBody }]; await upload.fire('change')
    await replace.fire('click'); await discard.fire('click')
    assert.equal(d.all().filter(n => n.tagName === 'dialog').length, 0)
    await d.find(n => n.dataset.questionReplace).fire('click')
    assert.equal(d.find(n => n.dataset.questionText).value, 'Second import')
  })
})

test('a late import read cannot restore an obsolete preview after local editing starts', async () => {
  await mounted(async d => {
    let resolve
    const wait = new Promise(done => { resolve = done }), body = serializeQuestionDraft(completeDraft())
    const upload = d.find(n => n.dataset.questionImport)
    upload.files = [{ size: body.length, text: async () => wait }]
    const loading = upload.fire('change')
    await d.find(n => n.dataset.questionLaunch).fire('click'); await fillQuestion(d)
    d.find(n => n.dataset.questionText).value = 'Local editing wins'
    resolve(body); await loading
    assert.equal(d.all().filter(n => n.dataset.questionReplace).length, 0)
    assert.equal(d.find(n => n.dataset.questionText).value, 'Local editing wins')
  })
})

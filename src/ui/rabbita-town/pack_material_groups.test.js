import test from 'node:test'
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { subjectKey } from './pack_candidate_sources.js'
import { discoverMaterialGroups, materialGroupSignature, reviewMaterialGroup, assertCurrentMaterialReview, attachMaterialReview } from './pack_material_groups.js'
import { installPackBridgePanel } from './pack_bridge_panel.js'

function makeState() {
  return {
    capabilities: ['one', 'two'].map(id => ({ pack_id: id, display_name: id, intake_operation_ids: ['intake'] })),
    lifecycles: ['one', 'two'].map(id => ({ pack_id: id, stage: 'projecting' })), candidates: [],
    projections: ['one', 'two'].map(id => ({ pack_id: id, product_id: id, version: '1.0.0', generated_at: '2026-10-13',
      subjects: ['a', 'b', 'c'].map(ref => ({ subject_ref: `subjects/${ref}.json`, schema_id: 'observation.v1',
        title: `${id} observation ${ref}`, summary: `<script>${id} exact observation ${ref}</script>`, lifecycle_state: 'pending',
        evidence_refs: ['materials/shared.txt', `materials/${ref}.txt`], operation_ids: [] })) })),
  }
}
const groupOf = state => discoverMaterialGroups(state).groups.find(group => group.pack_id === 'one')
const selected = group => new Set(group.sources.slice(0, 2).map(source => subjectKey(source.pack_id, source.subject_ref)))
const wire = state => ({ ...state, projections: { projections: state.projections } })
const reply = value => ({ ok: true, json: async () => value })

test('discovery groups exact pack-relative material, never equal paths in different packs or transitive relations', () => {
  const state = makeState(), before = JSON.stringify(state)
  const result = discoverMaterialGroups(state)
  assert.equal(result.groups.length, 2)
  for (const group of result.groups) {
    assert.equal(group.sources.length, 3)
    assert.ok(group.sources.every(source => source.pack_id === group.pack_id))
    assert.equal(group.evidence_ref, 'materials/shared.txt')
  }
  assert.equal(JSON.stringify(state), before)
  assert.equal(discoverMaterialGroups(state, new Set(['two'])).groups[0].pack_id, 'two')
  state.projections.reverse(); state.projections.forEach(p => p.subjects.reverse())
  assert.deepEqual(discoverMaterialGroups(state).groups, result.groups)
  const chain = makeState(); chain.projections[0].subjects[0].evidence_refs = ['left.txt']
  chain.projections[0].subjects[1].evidence_refs = ['left.txt', 'right.txt']
  chain.projections[0].subjects[2].evidence_refs = ['right.txt']
  assert.deepEqual(discoverMaterialGroups(chain, new Set(['one'])).groups.map(g => g.sources.length), [2, 2])
})

test('malformed, ambiguous and unavailable observations are skipped visibly; oversized scans fail without partial groups', () => {
  const invalid = makeState(); invalid.projections[0].subjects[2].evidence_refs = ['../unsafe']
  let result = discoverMaterialGroups(invalid)
  assert.equal(result.skippedSubjects, 1); assert.equal(result.groups[0].pack_id, 'two')
  const duplicate = makeState(); duplicate.projections[0].subjects.push(duplicate.projections[0].subjects[0])
  result = discoverMaterialGroups(duplicate); assert.equal(result.skippedSubjects, 2)
  assert.equal(result.groups.find(g => g.pack_id === 'one').sources.length, 2)
  for (const mutate of [s => s.lifecycles[0].stage = 'degraded', s => s.capabilities.shift(), s => s.projections.push(s.projections[0])]) {
    const state = makeState(); mutate(state)
    assert.ok(discoverMaterialGroups(state).groups.every(g => g.pack_id !== 'one'))
    assert.ok(discoverMaterialGroups(state).skippedPacks > 0)
  }
  const huge = makeState(); huge.projections[0].subjects = Array(1001).fill(huge.projections[0].subjects[0])
  assert.throws(() => discoverMaterialGroups(huge), /no partial scan/)
  huge.projections = Array(129).fill(makeState().projections[0])
  assert.throws(() => discoverMaterialGroups(huge), /128 packs/)
})

test('review separates operator hypothesis, keeps exclusions and binds every original observation', async () => {
  const state = makeState(), group = groupOf(state)
  const prepared = await reviewMaterialGroup(group, selected(group), '  Repeated friction might suggest a new research question  ')
  assert.equal(prepared.review.operator_hypothesis, 'Repeated friction might suggest a new research question')
  assert.equal(prepared.review.independent_corroboration, false)
  assert.deepEqual(prepared.review.excluded_subject_refs, ['subjects/c.json'])
  assert.equal(prepared.sources[0].summary, '<script>one exact observation a</script>')
  assert.match(prepared.review.group_binding_sha256, /^[a-f0-9]{64}$/)
  await assertCurrentMaterialReview(prepared.review, state)
  const republished = makeState(); republished.projections[0].generated_at = 'later'; republished.projections[0].subjects.reverse()
  assert.equal(materialGroupSignature(groupOf(republished)), materialGroupSignature(group))
  await assertCurrentMaterialReview(prepared.review, republished)
  for (const mutate of [s => s.projections[0].subjects[2].summary = 'Excluded observation changed',
    s => s.projections[0].subjects.pop(), s => s.projections[0].subjects.push({ ...s.projections[0].subjects[2], subject_ref: 'subjects/new.json' }),
    s => s.projections[0].version = '2', s => s.lifecycles[0].stage = 'degraded']) {
    const changed = makeState(); mutate(changed)
    await assert.rejects(assertCurrentMaterialReview(prepared.review, changed), /group changed/)
  }
})

test('review rejects blank/oversized hypotheses and invalid selections instead of choosing sources for the operator', async () => {
  const group = groupOf(makeState())
  for (const hypothesis of ['', ' ', 'x'.repeat(2001)]) await assert.rejects(reviewMaterialGroup(group, selected(group), hypothesis), /tentative pattern/)
  for (const keys of [new Set(), new Set([subjectKey('one', 'subjects/a.json')]), new Set([...selected(group), 'unknown'])]) {
    await assert.rejects(reviewMaterialGroup(group, keys, 'Pattern'), /two and twelve/)
  }
  const prepared = await reviewMaterialGroup(group, selected(group), 'Pattern')
  const candidate = { domain_payload: { moontown_source_context: {} } }
  attachMaterialReview(candidate, prepared.review, prepared.sources)
  assert.deepEqual(candidate.domain_payload.moontown_source_context.material_review, prepared.review)
  assert.throws(() => attachMaterialReview(candidate, prepared.review, prepared.sources.slice(0, 1)), /does not match/)
})

// Minimal event DOM executes shipped builders and handlers. It is not a real
// browser and makes no claim about pixels, focus trapping or accessibility.
function dom() {
  class Node {
    constructor(tag) { this.tagName = tag; this.children = []; this.events = {}; this.dataset = {}; this.value = ''; this.textContent = ''; this.disabled = false; this.checked = false; this.open = false; this.hidden = false }
    append(...nodes) { for (const node of nodes) { this.children.push(node); node.parent = this; if (this.tagName === 'select' && !this.value) this.value = node.value } }
    replaceChildren(...nodes) { this.children = []; this.append(...nodes) }
    addEventListener(type, fn) { this.events[type] = fn }
    setAttribute(name, value) { this[name] = value }
    remove() { if (this.parent) this.parent.children = this.parent.children.filter(n => n !== this) }
    showModal() { this.open = true }
    close() { this.open = false }
    async fire(type) { const event = { target: this, prevented: false, preventDefault() { this.prevented = true } }; await this.events[type]?.(event); return event }
  }
  const body = new Node('body'), all = (node = body) => [node, ...node.children.flatMap(child => all(child))]
  const find = predicate => { const node = all().find(predicate); assert.ok(node, 'Missing control'); return node }
  return { all, find, document: { body, createElement: tag => new Node(tag), querySelector: selector => selector === '[data-pack-bridge-panel]' ? all().find(n => n.dataset.packBridgePanel) : null } }
}
async function mounted(run, fetcher = null) {
  const d = dom(), state = makeState(), oldDocument = globalThis.document, oldFetch = globalThis.fetch, posts = []
  globalThis.document = d.document
  globalThis.fetch = async (url, opts) => {
    if (url.endsWith('candidates')) posts.push(opts.body)
    if (fetcher) return fetcher(url, opts, state, posts)
    return reply(url.endsWith('candidates') ? { receipt: { status: 'review-pending' } } : wire(state))
  }
  try { installPackBridgePanel(); await d.find(n => n.dataset.packBridgePanel === 'launch').fire('click'); await run(d, state, posts) }
  finally { globalThis.document = oldDocument; globalThis.fetch = oldFetch }
}
async function openReview(d) { await d.find(n => n.dataset.materialGroup?.startsWith('["one",')).fire('click') }
async function chooseTwo(d) {
  for (const node of d.all().filter(n => n.dataset.materialSource).slice(0, 2)) { node.checked = true; await node.fire('change') }
  const hypothesis = d.find(n => n.dataset.materialHypothesis); hypothesis.value = 'Test whether repeated friction signals an unmet need'; await hypothesis.fire('input')
}
async function continueReview(d) { await d.find(n => n.tagName === 'form' && d.all(n).some(c => c.dataset.materialHypothesis)).fire('submit') }
function fillCandidate(d) {
  d.find(n => n.placeholder === 'What emerged in MoonTown?').value = 'A tentative domain question'
  for (const node of d.all().filter(n => n.dataset.sourceConnection)) node.value = 'This observation contributes a distinct question about the shared material'
  d.find(n => n.dataset.sourceUncertainty).value = 'Reject if the shared material describes unrelated contexts'
  return d.find(n => n.tagName === 'form' && d.all(n).some(c => c.dataset.sourceUncertainty))
}

test('mounted discovery → explicit group review → editable candidate → native submission preserves the inspected material and exclusions', async () => {
  await mounted(async (d, state, posts) => {
    await openReview(d); assert.equal(d.all().filter(n => n.dataset.materialSource && n.checked).length, 0)
    await chooseTwo(d); await continueReview(d)
    assert.equal(posts.length, 0)
    assert.ok(d.all().some(n => n.textContent === '<script>one exact observation a</script>'))
    assert.equal(d.find(n => n.placeholder?.startsWith('Why this')).value, 'Test whether repeated friction signals an unmet need')
    const form = fillCandidate(d); await form.fire('submit'); await form.fire('submit')
    assert.equal(posts.length, 1)
    const candidate = JSON.parse(posts[0]), context = candidate.domain_payload.moontown_source_context
    assert.equal(candidate.contract_id, 'moontown.pack-candidate-intake.v1')
    assert.equal(context.accepted_knowledge, false); assert.equal(context.sources.length, 2)
    assert.deepEqual(context.material_review.excluded_subject_refs, ['subjects/c.json'])
    assert.deepEqual(context.material_review.observed_subject_refs, ['subjects/a.json', 'subjects/b.json', 'subjects/c.json'])
    assert.equal(context.material_review.operator_hypothesis, 'Test whether repeated friction signals an unmet need')
  })
})

test('cancel, filter, refresh and reopen preserve the explicit include/exclude choices and unsent hypothesis', async () => {
  await mounted(async (d, state, posts) => {
    await openReview(d); await chooseTwo(d); await d.find(n => n.textContent === 'Cancel review').fire('click')
    const filter = d.find(n => n.type === 'checkbox' && !n.dataset.materialSource && !n.dataset.sourceSubject)
    filter.checked = false; await filter.fire('change'); filter.checked = true; await filter.fire('change')
    await d.find(n => n.dataset.packBridgePanel === 'launch').fire('click')
    await openReview(d)
    assert.equal(d.all().filter(n => n.dataset.materialSource && n.checked).length, 2)
    assert.equal(d.find(n => n.dataset.materialHypothesis).value, 'Test whether repeated friction signals an unmet need')
    assert.equal(d.all().find(n => n.dataset.materialSource?.includes('subjects/c.json')).checked, false)
    assert.equal(posts.length, 0)
  })
})

test('changed group requires explicit re-review after refresh, retains old choices, and excludes new observations', async () => {
  await mounted(async (d, state, posts) => {
    await openReview(d); await chooseTwo(d); await d.find(n => n.textContent === 'Cancel review').fire('click')
    state.projections[0].subjects[2].summary = 'Changed excluded observation'
    state.projections[0].subjects.push({ ...state.projections[0].subjects[2], subject_ref: 'subjects/new.json', title: 'New observation' })
    await d.find(n => n.dataset.packBridgePanel === 'launch').fire('click'); await openReview(d)
    assert.equal(d.find(n => n.textContent === 'Continue to proposal').disabled, true)
    await continueReview(d); assert.equal(d.all().filter(n => n.dataset.sourceConnection).length, 0)
    await d.find(n => n.textContent === 'Review current group').fire('click')
    assert.equal(d.all().filter(n => n.dataset.materialSource).length, 4)
    assert.equal(d.all().filter(n => n.dataset.materialSource && n.checked).length, 2)
    assert.equal(d.find(n => n.dataset.materialSource?.includes('subjects/new.json')).checked, false)
    await continueReview(d); await fillCandidate(d).fire('submit')
    const review = JSON.parse(posts[0]).domain_payload.moontown_source_context.material_review
    assert.deepEqual(review.excluded_subject_refs, ['subjects/c.json', 'subjects/new.json'])
  })
})

test('invalid review, repeated continue, Escape and cancel do not submit or create duplicate composers', async () => {
  await mounted(async (d, state, posts) => {
    await openReview(d); await continueReview(d)
    assert.ok(d.all().some(n => n.textContent.includes('Describe a tentative pattern')))
    await chooseTwo(d)
    const form = d.find(n => n.tagName === 'form')
    const first = form.fire('submit'), second = form.fire('submit')
    await Promise.all([first, second])
    assert.equal(d.all().filter(n => n.dataset.sourceUncertainty).length, 1)
    assert.equal(posts.length, 0)
    await d.find(n => n.tagName === 'dialog').fire('cancel')
    assert.equal(posts.length, 0)
  })
})

test('final preflight rejects changes to excluded members, group membership and degraded groups with zero POSTs', async () => {
  for (const mutate of [s => s.projections[0].subjects[2].summary = 'Changed',
    s => s.projections[0].subjects.push({ ...s.projections[0].subjects[2], subject_ref: 'subjects/new.json' }),
    s => s.lifecycles[0].stage = 'degraded']) {
    await mounted(async (d, state, posts) => {
      await openReview(d); await chooseTwo(d); await continueReview(d); mutate(state)
      await fillCandidate(d).fire('submit')
      assert.equal(posts.length, 0)
      assert.ok(d.all().some(n => /group changed|unavailable or degraded/.test(n.textContent)))
      assert.equal(d.find(n => n.dataset.sourceUncertainty).disabled, false)
    })
  }
})

test('uncertain candidate resumes instead of opening another group; retry keeps exact body even after group changes', async () => {
  await mounted(async (d, state, posts) => {
    await openReview(d); await chooseTwo(d); await continueReview(d); const form = fillCandidate(d)
    await form.fire('submit'); assert.equal(posts.length, 1)
    const dialog = d.find(n => n.tagName === 'dialog'); dialog.close()
    state.projections[0].subjects[2].summary = 'Changed after attempted POST'
    await openReview(d)
    assert.equal(dialog.open, true); assert.equal(d.all().filter(n => n.dataset.materialHypothesis).length, 0)
    await form.fire('submit'); assert.equal(posts.length, 2); assert.equal(posts[0], posts[1])
  }, async (url, opts, state, posts) => {
    if (!url.endsWith('candidates')) return reply(wire(state))
    if (posts.length === 1) throw Error('Lost response')
    return reply({ receipt: { status: 'review-pending' } })
  })
})

test('production build declares both discovery modules and preserves native source-linked payload handling', async () => {
  for (const file of ['./scripts/assemble-production-build.mjs', './scripts/verify-production-build.mjs']) {
    const source = await readFile(new URL(file, import.meta.url), 'utf8')
    assert.match(source, /'pack_material_groups.js'/); assert.match(source, /'pack_material_review.js'/)
  }
})

test('a preflight in progress retains the same candidate dialog when another group is clicked', async () => {
  let release, hold = false
  const wait = new Promise(resolve => { release = resolve })
  await mounted(async (d, state, posts) => {
    await openReview(d); await chooseTwo(d); await continueReview(d)
    const dialog = d.find(n => n.tagName === 'dialog'), form = fillCandidate(d)
    hold = true
    const active = form.fire('submit')
    assert.equal(dialog.dataset.candidateBusy, 'true')
    await openReview(d)
    assert.equal(d.all().filter(n => n.tagName === 'dialog').length, 1)
    assert.equal(d.all().filter(n => n.dataset.materialHypothesis).length, 0)
    const escape = await dialog.fire('cancel'); assert.equal(escape.prevented, true)
    release(); await active; assert.equal(posts.length, 1)
  }, async (url, opts, state) => {
    if (!url.endsWith('candidates') && hold) await wait
    return reply(url.endsWith('candidates') ? { receipt: { status: 'review-pending' } } : wire(state))
  })
})

test('newer refresh wins; a late earlier response cannot replace current group observations', async () => {
  let releaseOld, gets = 0
  const wait = new Promise(resolve => { releaseOld = resolve })
  await mounted(async (d, state) => {
    const launch = d.find(n => n.dataset.packBridgePanel === 'launch')
    const oldRefresh = launch.fire('click')
    state.projections[0].subjects[0].title = 'Current generation title'
    await launch.fire('click'); releaseOld(); await oldRefresh
    await openReview(d)
    assert.ok(d.all().some(n => n.textContent === 'Include Current generation title'))
  }, async (url, opts, state) => {
    gets++
    const snapshot = structuredClone(wire(state))
    if (gets === 2) await wait
    return reply(snapshot)
  })
})

test('source limits require explicit narrowing and do not silently choose twelve from a large group', async () => {
  const state = makeState()
  state.projections[0].subjects = Array.from({ length: 13 }, (_, i) => ({ ...state.projections[0].subjects[0], subject_ref: `subjects/${i}.json` }))
  const group = groupOf(state)
  await assert.rejects(reviewMaterialGroup(group, new Set(group.sources.map(s => subjectKey(s.pack_id, s.subject_ref))), 'Pattern'), /two and twelve/)
  state.projections[0].subjects = Array.from({ length: 129 }, (_, i) => ({ ...state.projections[0].subjects[0], subject_ref: `subjects/${i}.json` }))
  await assert.rejects(reviewMaterialGroup(groupOf(state), new Set(), 'Pattern'), /two to 128/)
  await mounted(async (d, current, posts) => {
    current.projections[0].subjects = structuredClone(state.projections[0].subjects)
    await d.find(n => n.dataset.packBridgePanel === 'launch').fire('click')
    const review = d.find(n => n.dataset.materialGroup?.startsWith('["one",'))
    assert.equal(review.disabled, true); await review.fire('click')
    assert.equal(d.all().filter(n => n.tagName === 'dialog').length, 0)
    assert.equal(posts.length, 0)
  })
})

test('an unavailable refresh keeps a retained review blocked until the current group can be inspected', async () => {
  let fail = false
  await mounted(async (d, state, posts) => {
    await openReview(d); await chooseTwo(d)
    fail = true; await d.find(n => n.dataset.packBridgePanel === 'launch').fire('click')
    await continueReview(d)
    assert.equal(d.find(n => n.textContent === 'Continue to proposal').disabled, true)
    assert.equal(posts.length, 0)
    assert.equal(d.all().filter(n => n.dataset.materialSource && n.checked).length, 2)
    fail = false; await d.find(n => n.dataset.packBridgePanel === 'launch').fire('click')
    await continueReview(d)
    assert.equal(d.all().filter(n => n.dataset.sourceConnection).length, 2)
  }, async (url, opts, state) => { if (fail) throw Error('Offline'); return reply(wire(state)) })
})

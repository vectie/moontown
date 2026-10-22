import { captureSubject, subjectKey, assertCurrentSources, attachSourceContext, serializeCandidate } from './pack_candidate_sources.js'
import { assertCurrentMaterialReview, attachMaterialReview } from './pack_material_groups.js'
import { createMaterialDiscovery } from './pack_material_review.js'
import { attachCrossPackQuestion } from './pack_cross_pack_question.js'
import { createCrossPackQuestion } from './pack_question_composer.js'
import { attachObservationChanges } from './pack_observation_changes.js'
import { createObservationChanges } from './pack_observation_review.js'
import { attachVocabularyReview } from './pack_vocabulary.js'
import { createVocabularyExplorer } from './pack_vocabulary_explorer.js'
const SNAPSHOT_URL = '/api/pack-bridge'
const CANDIDATE_URL = '/api/pack-bridge/candidates'

function element(tag, className = '', text = '') {
  const node = document.createElement(tag)
  if (className) node.className = className
  if (text) node.textContent = text
  return node
}

function slug(value) {
  return String(value || '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 72) || 'candidate'
}

function bridgeState(snapshot) {
  return {
    capabilities: Array.isArray(snapshot?.capabilities) ? snapshot.capabilities : [],
    lifecycles: Array.isArray(snapshot?.lifecycles) ? snapshot.lifecycles : [],
    candidates: Array.isArray(snapshot?.candidates) ? snapshot.candidates : [],
    projections: Array.isArray(snapshot?.projections?.projections)
      ? snapshot.projections.projections
      : [],
  }
}

async function fetchSnapshot() {
  const response = await fetch(SNAPSHOT_URL, { cache: 'no-store' })
  if (!response.ok) throw new Error(`Pack Bridge unavailable (${response.status})`)
  return bridgeState(await response.json())
}

function lifecycleFor(state, packId) {
  return state.lifecycles.find(item => item.pack_id === packId) || null
}

function projectionFor(state, packId) {
  return state.projections.find(item => item.pack_id === packId) || null
}

function packOperationHref(packId, subjectRef, operationId) {
  const query = new URLSearchParams({
    subject: subjectRef,
    operation: operationId,
    source: 'moontown-pack-bridge',
  })
  return `/pack-apps/${encodeURIComponent(packId)}/?${query.toString()}`
}

function packFilter(capability, selected, onChange) {
  const label = element('label', 'pack-layer-filter')
  const input = document.createElement('input')
  input.type = 'checkbox'
  input.checked = selected.has(capability.pack_id)
  input.addEventListener('change', () => onChange(capability.pack_id, input.checked))
  label.append(input, element('span', '', capability.display_name || capability.pack_id))
  return label
}

function subjectCard(pack, subject, status, selected, onSelect) {
  const card = element('article', 'pack-layer-subject')
  card.dataset.packId = pack.pack_id
  card.dataset.subjectRef = subject.subject_ref
  const heading = element('header', 'pack-layer-subject-head')
  const identity = element('div')
  identity.append(
    element('small', '', pack.display_name || pack.pack_id),
    element('h3', '', subject.title || subject.subject_ref),
  )
  const attention = element(
    'span',
    `pack-layer-attention ${subject.attention || 'notice'}`,
    subject.attention || 'notice',
  )
  heading.append(identity, attention)
  card.append(heading)
  card.append(element('p', 'pack-layer-summary', subject.summary || 'No summary.'))
  const choose = element('input')
  choose.type = 'checkbox'
  choose.checked = selected
  choose.dataset.sourceSubject = subjectKey(pack.pack_id, subject.subject_ref)
  choose.addEventListener('change', () => onSelect(choose))
  const sourceLabel = element('label', 'pack-layer-filter')
  sourceLabel.append(choose, element('span', '', 'Use as proposal source'))
  card.append(sourceLabel)
  const meta = element('div', 'pack-layer-meta')
  meta.append(
    element('span', '', subject.schema_id || 'domain-record'),
    element('span', '', subject.lifecycle_state || 'unknown'),
    element('span', '', `${subject.evidence_refs?.length || 0} evidence`),
  )
  card.append(meta)
  if (Array.isArray(subject.operation_ids) && subject.operation_ids.length) {
    const actions = element('div', 'pack-layer-actions')
    subject.operation_ids.forEach(operationId => {
      const action = element('a', 'pack-layer-action', operationId)
      action.href = packOperationHref(
        pack.pack_id,
        subject.subject_ref,
        operationId,
      )
      action.dataset.packOperation = operationId
      action.addEventListener('click', () => {
        status.textContent = `Opening ${operationId} in ${pack.display_name || pack.pack_id}. The pack’s reviewed workflow retains authority.`
      })
      actions.append(action)
    })
    card.append(actions)
  }
  return card
}

function candidateRow(receipt) {
  const row = element('li', 'pack-candidate-row')
  const copy = element('div')
  copy.append(
    element('strong', '', receipt.candidate_ref),
    element('small', '', `${receipt.pack_id} · ${receipt.operation_id}`),
  )
  row.append(copy, element('span', `candidate-status ${receipt.status}`, receipt.status))
  return row
}

export function candidateDialog(state, onSubmitted, sources = [], { fetcher = fetch, materialReview = null, questionReview = null, changeReview = null, vocabularyReview = null } = {}) {
  let busy = false, pending = null, completed = false
  const controls = []
  const dialog = element('dialog', 'pack-candidate-dialog')
  const form = element('form', 'pack-candidate-form')
  form.method = 'dialog'
  const heading = element('header')
  const headingCopy = element('div')
  headingCopy.append(
    element('small', '', 'Bottom-up promotion'),
    element('h2', '', 'Propose to a domain pack'),
  )
  const close = element('button', 'pack-dialog-close', 'Close')
  close.type = 'button'
  close.addEventListener('click', () => { if (!busy) dialog.close() })
  dialog.addEventListener('cancel', event => { if (busy) event.preventDefault() })
  heading.append(headingCopy, close)

  const packSelect = document.createElement('select')
  packSelect.required = true
  state.capabilities
    .filter(capability => capability.intake_operation_ids?.length)
    .forEach(capability => {
      capability.intake_operation_ids.forEach(operationId => {
        const option = document.createElement('option')
        option.value = `${capability.pack_id}\n${operationId}`
        option.textContent = `${capability.display_name || capability.pack_id} · ${operationId}`
        packSelect.append(option)
      })
    })
  const title = document.createElement('input')
  title.required = true
  title.maxLength = 140
  title.placeholder = 'What emerged in MoonTown?'
  if (questionReview) title.value = questionReview.question
  const rationale = document.createElement('textarea')
  rationale.required = true
  rationale.maxLength = 2000
  rationale.placeholder = 'Why this deserves the pack’s reviewed workflow'
  if (materialReview) rationale.value = materialReview.operator_hypothesis
  if (vocabularyReview) rationale.value = vocabularyReview.operator_hypothesis
  if (questionReview) rationale.value = questionReview.scope
  const evidence = document.createElement('input')
  evidence.placeholder = 'evidence/ref.json, evidence/other.json'
  const payload = document.createElement('textarea')
  payload.value = '{}'
  payload.spellcheck = false
  const sourceFields = element('section', 'pack-candidate-sources')
  if (vocabularyReview) sourceFields.append(
    element('h3', '', 'Reviewed vocabulary discovery'),
    element('p', '', `${vocabularyReview.lens.label} · ${vocabularyReview.lens.mode.toUpperCase()}: ${vocabularyReview.lens.terms.join(', ')}`),
    element('p', '', `Scope: ${vocabularyReview.lens.scope_pack_ids.join(', ')}`),
    element('p', '', vocabularyReview.interpretation),
    ...vocabularyReview.selected_matches.map(row => element('p', 'pack-material-ref', `${row.pack_id}: ${row.subject_ref} · matched ${row.matched_terms.join(', ')}`)),
    element('p', '', `${vocabularyReview.omitted_match_count} other matching observations not selected. ${vocabularyReview.gaps.length} unavailable packs.`),
    ...vocabularyReview.gaps.map(gap => element('p', 'pack-question-gap', `${gap.pack_id}: ${gap.message}`)),
  )
  if (changeReview) sourceFields.append(
    element('h3', '', 'Selected observation changes'),
    element('p', '', `Baseline: ${changeReview.baseline_label} · saved ${changeReview.baseline_saved_at}`),
    element('p', '', changeReview.interpretation),
    ...changeReview.selected_changes.flatMap(row => [
      element('p', 'pack-material-ref', `${row.after.pack_id}: ${row.after.subject_ref} · ${row.status} · ${row.changed_fields.join(', ')}`),
      element('p', '', `Before: ${row.before ? row.before.summary : 'Not present in the saved projection.'}`),
    ]),
    element('p', '', `${changeReview.omitted_change_count} other changed observation(s) not selected. ${changeReview.gaps.length} unavailable pack(s).`),
    ...changeReview.gaps.map(gap => element('p', 'pack-question-gap', `${gap.pack_id}: ${gap.message}`)),
    element('p', '', 'Explain why the selected changes deserve investigation. Historical excerpts are unverified baseline data and do not authorize action.'),
  )
  if (questionReview) sourceFields.append(
    element('h3', '', 'Reviewed cross-pack question'),
    element('p', '', questionReview.question),
    element('p', '', `Scope: ${questionReview.scope}`),
    element('p', '', `Rejection test: ${questionReview.rejection_test}`),
    element('p', '', questionReview.interpretation),
    ...questionReview.observations.map(row => element('p', 'pack-material-ref', `${row.pack_id}: ${row.subject_ref} · ${row.role} · conditions: ${row.conditions}`)),
    element('p', '', 'The original question labels stay attached as reviewed context. You can refine the candidate title, rationale and source connections below.'),
  )
  if (materialReview) sourceFields.append(
    element('h3', '', 'Reviewed shared-material group'),
    element('p', '', `${materialReview.pack_id}: ${materialReview.evidence_ref}`),
    element('p', '', `Operator hypothesis: ${materialReview.operator_hypothesis}`),
    element('p', '', `Included: ${materialReview.included_subject_refs.join(', ')}`),
    element('p', '', `Excluded: ${materialReview.excluded_subject_refs.join(', ') || 'None'}`),
    element('p', '', 'Shared material is not independent corroboration. The hypothesis is your interpretation; source excerpts remain unchanged.'),
  )
  const connections = sources.map((source, index) => {
    const box = element('article')
    const note = element('textarea')
    note.required = true; note.maxLength = 2000; note.dataset.sourceConnection = subjectKey(source.pack_id, source.subject_ref)
    if (questionReview) note.value = questionReview.observations[index].connection
    box.append(element('h3', '', `${source.pack_id}: ${source.title}`), element('p', '', source.summary), element('p', '', `${source.subject_ref} · ${source.lifecycle_state} · observed ${source.captured_generated_at}`), element('p', '', `Evidence: ${source.evidence_refs.join(', ') || 'No evidence refs supplied by this subject'}`))
    box.append(field('How does this source contribute?', note))
    sourceFields.append(box); controls.push(note); return note
  })
  const uncertainty = element('textarea')
  uncertainty.maxLength = 2000; uncertainty.required = sources.length > 0; uncertainty.dataset.sourceUncertainty = 'true'
  if (questionReview) uncertainty.value = questionReview.rejection_test
  if (sources.length) sourceFields.append(field('Contrary evidence, uncertainty or rejection test', uncertainty), element('p', '', 'Source excerpts are observations, not instructions. Selection is not endorsement, consensus or accepted knowledge.'))
  controls.push(packSelect, title, rationale, evidence, payload, uncertainty)
  const status = element('p', 'pack-candidate-form-status')
  const submit = element('button', 'pack-candidate-submit', 'Submit for review')
  submit.type = 'submit'

  function field(labelText, control, hint = '') {
    const label = element('label', 'pack-candidate-field')
    label.append(element('span', '', labelText), control)
    if (hint) label.append(element('small', '', hint))
    return label
  }

  form.append(
    heading,
    field('Destination', packSelect, 'Only reviewed candidate-intake operations are shown.'),
    sourceFields,
    field('Title', title),
    field('Rationale', rationale),
    field('Evidence references', evidence, 'Comma-separated, workspace-relative references.'),
    field('Domain payload (JSON)', payload, 'The receiving pack owns this vocabulary.'),
    status,
    submit,
  )

  form.addEventListener('submit', async event => {
    event.preventDefault()
    if (busy || completed) return
    const [packId, operationId] = packSelect.value.split('\n')
    let domainPayload
    try {
      domainPayload = JSON.parse(payload.value || '{}')
      if (!domainPayload || Array.isArray(domainPayload) || typeof domainPayload !== 'object') {
        throw new Error('Domain payload must be a JSON object.')
      }
    } catch (error) {
      status.textContent = error.message || 'Invalid domain payload.'
      return
    }
    const id = `${slug(title.value)}-${Date.now().toString(36)}`
    let candidate = {
      contract_id: 'moontown.pack-candidate-intake.v1',
      candidate_ref: `town/candidates/${id}`,
      origin_ref: `town/ideas/${slug(title.value)}`,
      target_pack_id: packId,
      intake_operation_id: operationId,
      submitted_by: 'moontown-operator',
      submitted_at: new Date().toISOString(),
      title: title.value.trim(),
      rationale: rationale.value.trim(),
      claim_ceiling: 'research-evidence',
      evidence_refs: evidence.value.split(',').map(item => item.trim()).filter(Boolean),
      domain_payload: domainPayload,
    }
    if (!pending) {
      try {
        if (!title.value.trim() || !rationale.value.trim() || !packId || !operationId) throw Error('Choose a destination and describe the idea and rationale.')
        if (sources.length) candidate = attachSourceContext(candidate, sources, connections.map(control => control.value), uncertainty.value)
        if (materialReview) candidate = attachMaterialReview(candidate, materialReview, sources)
        if (questionReview) candidate = attachCrossPackQuestion(candidate, questionReview, sources)
        if (changeReview) candidate = attachObservationChanges(candidate, changeReview, sources)
        if (vocabularyReview) candidate = attachVocabularyReview(candidate, vocabularyReview, sources)
        serializeCandidate(candidate)
      } catch (error) { status.textContent = error.message; return }
    } else candidate = pending
    busy = true
    dialog.dataset.candidateBusy = 'true'
    controls.forEach(control => { control.disabled = true })
    submit.disabled = true
    status.textContent = 'Routing candidate…'
    try {
      if (!pending && sources.length) {
        const check = await fetcher(SNAPSHOT_URL, { cache: 'no-store' })
        if (!check.ok) throw Error('Could not recheck the selected sources. No candidate was sent.')
        const current = bridgeState(await check.json())
        assertCurrentSources(sources, current)
        if (materialReview) await assertCurrentMaterialReview(materialReview, current)
        if (!current.capabilities.some(item => item.pack_id === candidate.target_pack_id && item.intake_operation_ids?.includes(candidate.intake_operation_id))) throw Error('The selected destination is no longer available.')
      }
      pending = candidate
      dialog.dataset.candidatePending = 'true'
      const response = await fetcher(CANDIDATE_URL, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: serializeCandidate(candidate),
      })
      const result = await response.json()
      // This exact native guard response is returned before intake is invoked.
      // It is definite nonacceptance, unlike a generic 409 or lost response.
      if (response.status === 413 && result.error === 'request body too large') {
        pending = null
        dialog.dataset.candidatePending = 'false'
        throw Error('The native request-size guard rejected this candidate before intake. Reduce its content and submit again.')
      }
      if (!response.ok) throw new Error(result.error || 'Candidate routing failed.')
      completed = true
      dialog.dataset.candidatePending = 'false'
      status.textContent = `Routed as ${result.receipt?.status || 'submitted'}; no downstream action was authorized.`
      try { await onSubmitted() } catch { status.textContent += ' Refresh Pack layers to view the saved receipt.' }
    } catch (error) {
      status.textContent = (error.message || String(error)) + (pending ? ' The same candidate is retained; retry to reconcile. Do not submit a new copy while its outcome is unknown.' : '')
    } finally {
      busy = false
      dialog.dataset.candidateBusy = 'false'
      submit.disabled = completed
      submit.textContent = completed ? 'Candidate routed' : pending ? 'Retry same candidate' : 'Submit for review'
      controls.forEach(control => { control.disabled = Boolean(pending) })
    }
  })
  dialog.append(form)
  document.body.append(dialog)
  return dialog
}

export function installPackBridgePanel() {
  if (document.querySelector('[data-pack-bridge-panel]')) return
  const launch = element('button', 'pack-bridge-launch', '')
  launch.title = '扩展工具（高级）'
  launch.setAttribute('aria-label', '扩展工具（高级）')
  launch.innerHTML = '<svg aria-hidden="true" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M4 3v6m0 6v6M12 3v12m0 4v2M20 3v2m0 6v10M1 9h6v6H1zM9 15h6v4H9zM17 5h6v6h-6z"/></svg>'
  launch.type = 'button'
  launch.dataset.packBridgePanel = 'launch'
  const panel = element('aside', 'pack-bridge-panel')
  panel.dataset.packBridgePanel = 'panel'
  panel.hidden = true
  const header = element('header', 'pack-bridge-header')
  const headerCopy = element('div')
  headerCopy.append(element('small', '', 'Pack Bridge'), element('h2', '', 'Domain layers'))
  const close = element('button', 'pack-bridge-close', 'Close')
  close.type = 'button'
  header.append(headerCopy, close)
  const status = element('p', 'pack-bridge-status', 'Open to load active pack projections.')
  const filters = element('div', 'pack-layer-filters')
  const subjects = element('section', 'pack-layer-subjects')
  const candidatesHeading = element('header', 'pack-candidates-heading')
  candidatesHeading.append(element('h3', '', 'Candidate flow'))
  const propose = element('button', 'pack-candidate-open', 'Propose to pack')
  propose.type = 'button'
  candidatesHeading.append(propose)
  const candidates = element('ul', 'pack-candidate-list')
  panel.append(header, status, filters, subjects, candidatesHeading, candidates)
  document.body.append(launch, panel)

  let state = bridgeState(null)
  const selected = new Set()
  const proposalSources = new Map()
  let selectionInitialized = false
  let dialog = null
  let refreshGeneration = 0

  function resumePending() {
    if (dialog?.dataset.candidatePending === 'true' || dialog?.dataset.candidateBusy === 'true') {
      if (!dialog.open) dialog.showModal()
      return true
    }
    return false
  }

  function openCandidate(sources, options = {}) {
    if (resumePending()) return
    dialog?.remove()
    dialog = candidateDialog(state, refresh, sources, options)
    dialog.showModal()
  }

  const discovery = createMaterialDiscovery({
    resumePending,
    onPropose: ({ sources, review }) => openCandidate(sources, { materialReview: review }),
  })
  const questionComposer = createCrossPackQuestion({
    resumePending,
    getSelected: () => [...proposalSources.values()],
    onPropose: ({ sources, review }) => openCandidate(sources, { questionReview: review }),
  })
  const changes = createObservationChanges({
    resumePending,
    onPropose: ({ sources, review }) => openCandidate(sources, { changeReview: review }),
  })
  const vocabulary = createVocabularyExplorer({
    resumePending,
    onPropose: ({ sources, review }) => openCandidate(sources, { vocabularyReview: review }),
  })
  panel.replaceChildren(header, status, filters, vocabulary.section, changes.section, questionComposer.section, discovery.section, subjects, candidatesHeading, candidates)

  function render() {
    filters.replaceChildren()
    if (!selectionInitialized) {
      state.capabilities.forEach(capability => selected.add(capability.pack_id))
      selectionInitialized = true
    }
    state.capabilities.forEach(capability => {
      filters.append(packFilter(capability, selected, (packId, enabled) => {
        if (enabled) selected.add(packId)
        else selected.delete(packId)
        render()
      }))
    })
    discovery.refresh(state, selected)
    questionComposer.refresh(state)
    changes.refresh(state, selected)
    vocabulary.refresh(state, selected)
    subjects.replaceChildren()
    let count = 0
    state.capabilities.forEach(capability => {
      if (!selected.has(capability.pack_id)) return
      const projection = projectionFor(state, capability.pack_id)
      ;(projection?.subjects || []).forEach(subject => {
        subjects.append(subjectCard(capability, subject, status, proposalSources.has(subjectKey(capability.pack_id, subject.subject_ref)), choose => {
          const key = subjectKey(capability.pack_id, subject.subject_ref)
          if (!choose.checked) proposalSources.delete(key)
          else { try { if (proposalSources.size >= 12) throw Error('Choose at most twelve subjects.'); proposalSources.set(key, captureSubject(projection, subject)) } catch (error) { choose.checked = false; status.textContent = error.message; return } }
          propose.textContent = proposalSources.size ? `Propose from ${proposalSources.size} source(s)` : 'Propose to pack'
        }))
        count += 1
      })
    })
    if (!count) {
      subjects.append(element('p', 'pack-layer-empty', 'No projected subjects from the selected active packs.'))
    }
    candidates.replaceChildren(...state.candidates.slice(-8).reverse().map(candidateRow))
    const projecting = state.lifecycles.filter(item => item.stage === 'projecting').length
    status.textContent = `${state.capabilities.length} bridge-ready pack(s) · ${count} visible subject(s) · ${projecting} projecting`
    propose.textContent = proposalSources.size ? `Propose from ${proposalSources.size} source(s)` : 'Propose to pack'
    propose.disabled = !state.capabilities.some(item => item.intake_operation_ids?.length)
  }

  async function refresh() {
    const generation = ++refreshGeneration
    status.textContent = 'Refreshing pack lifecycle…'
    try {
      const snapshot = await fetchSnapshot()
      if (generation !== refreshGeneration) return
      state = snapshot
      proposalSources.clear()
      render()
    } catch (error) {
      if (generation !== refreshGeneration) return
      state = bridgeState(null)
      discovery.refresh(state, selected)
      questionComposer.refresh(state)
      changes.refresh(state, selected)
      vocabulary.refresh(state, selected)
      propose.disabled = true
      status.textContent = error.message || String(error)
      subjects.replaceChildren(element('p', 'pack-layer-empty', 'Pack Bridge is not available in this runtime.'))
    }
  }

  launch.addEventListener('click', async () => {
    panel.hidden = false
    launch.hidden = true
    close.focus?.()
    await refresh()
  })
  close.addEventListener('click', () => {
    panel.hidden = true
    launch.hidden = false
    const origin = document.querySelector('#town-pack-tools-open') || launch
    origin.focus?.()
  })
  propose.addEventListener('click', () => {
    openCandidate([...proposalSources.values()])
  })
}

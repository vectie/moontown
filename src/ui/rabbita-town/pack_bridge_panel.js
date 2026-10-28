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

// platform-base.js normally rewrites app-owned root requests. Resolve the same
// trusted mount explicitly too, including embedded Pack apps. Already-prefixed
// URLs are left alone by that transport wrapper, so they are never doubled.
export function packProductPath(route) {
  const base = String(globalThis.__MOONTOWN_BASE_PATH || '').replace(/\/$/, '')
  const prefix = '/pack-apps/moontown'
  const pathname = String(globalThis.location?.pathname || '/')
  const mount = base || (pathname === prefix || pathname.startsWith(`${prefix}/`) ? prefix : '')
  return `${mount}/${String(route).replace(/^\/+/, '')}`
}

function element(tag, className = '', text = '') {
  const node = document.createElement(tag)
  if (className) node.className = className
  if (text) node.textContent = text
  return node
}

function advanced(label, ...children) {
  const details = element('details', 'town-advanced')
  const summary = element('summary', '', `高级 · ${label}`)
  details.append(summary, ...children)
  return details
}

function hostedTown() {
  return globalThis.__MOONTOWN_PUBLIC_PLATFORM === true ||
    /^\/moontown(?:\/|$)/.test(globalThis.__MOONTOWN_BASE_PATH || '')
}

function bridgeAccessError(status) {
  const error = new Error(`Pack Bridge unavailable (${status})`)
  error.status = status
  return error
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
  const response = await fetch(packProductPath(SNAPSHOT_URL), { cache: 'no-store', credentials: 'same-origin' })
  if (!response.ok) throw bridgeAccessError(response.status)
  const snapshot = await response.json()
  // A login HTML fallback or unrelated API response must not activate empty
  // authoring forms. Native routing remains the authorization authority.
  if (!Array.isArray(snapshot?.capabilities) || !Array.isArray(snapshot?.lifecycles) ||
      !Array.isArray(snapshot?.projections?.projections)) throw bridgeAccessError('invalid-response')
  return bridgeState(snapshot)
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
  card.append(element('p', 'pack-layer-summary', subject.summary || '暂无摘要。'))
  const choose = element('input')
  choose.type = 'checkbox'
  choose.checked = selected
  choose.dataset.sourceSubject = subjectKey(pack.pack_id, subject.subject_ref)
  choose.addEventListener('change', () => onSelect(choose))
  const sourceLabel = element('label', 'pack-layer-filter')
  sourceLabel.append(choose, element('span', '', '选作资料'))
  card.append(sourceLabel)
  const meta = element('div', 'pack-layer-meta')
  meta.append(
    element('span', '', subject.schema_id || 'domain-record'),
    element('span', '', subject.lifecycle_state || 'unknown'),
    element('span', '', `${subject.evidence_refs?.length || 0} evidence`),
  )
  const provenance = advanced('来源详情', meta)
  card.append(provenance)
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
    provenance.append(actions)
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
    element('small', '', '2 · 提出问题 → 3 · 提交审阅'),
    element('h2', '', '整理问题与资料'),
  )
  const close = element('button', 'pack-dialog-close', '关闭')
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
    box.append(field('这份资料与问题有什么关系？', note))
    sourceFields.append(box); controls.push(note); return note
  })
  const uncertainty = element('textarea')
  uncertainty.maxLength = 2000; uncertainty.required = sources.length > 0; uncertainty.dataset.sourceUncertainty = 'true'
  if (questionReview) uncertainty.value = questionReview.rejection_test
  if (sources.length) sourceFields.append(field('疑点或反证', uncertainty), element('p', '', '引用只是待核实的观察，不代表认可或已接受的知识。'))
  controls.push(packSelect, title, rationale, evidence, payload, uncertainty)
  const status = element('p', 'pack-candidate-form-status')
  const submit = element('button', 'pack-candidate-submit', '提交审阅')
  submit.type = 'submit'

  function field(labelText, control, hint = '') {
    const label = element('label', 'pack-candidate-field')
    label.append(element('span', '', labelText), control)
    if (hint) label.append(element('small', '', hint))
    return label
  }

  const technical = advanced('补充引用与领域参数',
    field('Evidence references', evidence, 'Comma-separated, workspace-relative references.'),
    field('Domain payload (JSON)', payload, 'The receiving pack owns this vocabulary.'),
  )
  form.append(
    heading,
    field('交给哪个领域审阅？', packSelect),
    sourceFields,
    field('问题', title),
    field('为什么值得研究？', rationale),
    technical,
    element('p', 'pack-layer-summary', '提交后进入领域审阅，不会执行操作或自动接受知识。'),
    status,
    submit,
  )

  form.addEventListener('submit', async event => {
    event.preventDefault()
    if (busy || completed) return
    if (globalThis.__MOONTOWN_PUBLIC_PLATFORM === true ||
        (hostedTown() && globalThis.__MOONTOWN_SCOPE_READY === false)) {
      status.textContent = '当前是公共展示或账户尚未就绪。请从账户门户进入已授权工作区；没有发送候选。'
      return
    }
    const [packId, operationId] = packSelect.value.split('\n')
    let domainPayload
    try {
      domainPayload = JSON.parse(payload.value || '{}')
      if (!domainPayload || Array.isArray(domainPayload) || typeof domainPayload !== 'object') {
        throw new Error('Domain payload must be a JSON object.')
      }
    } catch (error) {
      technical.open = true
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
    status.textContent = '正在提交审阅…'
    try {
      if (!pending && sources.length) {
        const check = await fetcher(packProductPath(SNAPSHOT_URL), { cache: 'no-store', credentials: 'same-origin' })
        if (!check.ok) throw Error('Could not recheck the selected sources. No candidate was sent.')
        const current = bridgeState(await check.json())
        assertCurrentSources(sources, current)
        if (materialReview) await assertCurrentMaterialReview(materialReview, current)
        if (!current.capabilities.some(item => item.pack_id === candidate.target_pack_id && item.intake_operation_ids?.includes(candidate.intake_operation_id))) throw Error('The selected destination is no longer available.')
      }
      pending = candidate
      dialog.dataset.candidatePending = 'true'
      const response = await fetcher(packProductPath(CANDIDATE_URL), {
        method: 'POST',
        credentials: 'same-origin',
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
      submit.textContent = completed ? '已提交审阅' : pending ? '核对并重试' : '提交审阅'
      controls.forEach(control => { control.disabled = Boolean(pending) || completed })
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
  headerCopy.append(element('small', '', '研究资料'), element('h2', '', '领域资料'))
  const close = element('button', 'pack-bridge-close', '关闭')
  close.type = 'button'
  header.append(headerCopy, close)
  const status = element('p', 'pack-bridge-status', '打开后检查当前工作区的资料连接。')
  status.setAttribute('role', 'status')
  status.setAttribute('aria-live', 'polite')
  const empty = element('section', 'pack-layer-empty')
  empty.dataset.packBridgeEmpty = 'true'
  const workspace = element('div')
  workspace.dataset.packBridgeWorkspace = 'true'
  workspace.hidden = true
  const filters = element('div', 'pack-layer-filters')
  const subjects = element('section', 'pack-layer-subjects')
  const candidatesHeading = element('header', 'pack-candidates-heading')
  candidatesHeading.append(element('h3', '', '最近提交'))
  const propose = element('button', 'pack-candidate-open', '整理问题')
  propose.type = 'button'
  const candidates = element('ul', 'pack-candidate-list')
  const manual = element('div')
  manual.append(element('p', 'pack-layer-summary', '选择要引用的资料，再整理问题。提交只进入审阅，不自动执行。'), subjects, propose)
  const modeLabel = element('label', 'pack-candidate-field')
  const mode = element('select')
  mode.dataset.packDiscoveryMode = 'true'
  mode.setAttribute('aria-label', '选择资料方式')
  for (const [value, label] of [['browse', '浏览资料'], ['vocabulary', '相关词'], ['changes', '查看变化'], ['shared', '相同来源'], ['question', '跨领域问题']]) {
    const option = element('option', '', label); option.value = value; mode.append(option)
  }
  mode.value = 'browse'
  modeLabel.append(element('span', '', '1 · 选择资料'), mode)
  const modeContent = element('div')
  const submitted = advanced('提交记录', candidatesHeading, candidates)
  const noIntake = element('p', 'pack-layer-summary')
  noIntake.hidden = true
  workspace.append(modeLabel, advanced('资料范围', filters), noIntake, modeContent, submitted)
  panel.append(header, status, empty, workspace)
  document.body.append(launch, panel)

  let state = bridgeState(null)
  const selected = new Set()
  const proposalSources = new Map()
  let selectionInitialized = false
  let dialog = null
  let refreshGeneration = 0
  let ready = false
  let explorers = null
  const modes = new Map()

  function resumePending() {
    if (dialog?.dataset.candidatePending === 'true' || dialog?.dataset.candidateBusy === 'true') {
      if (!dialog.open) dialog.showModal()
      return true
    }
    return false
  }

  function openCandidate(sources, options = {}) {
    if (resumePending()) return
    if (!ready || globalThis.__MOONTOWN_PUBLIC_PLATFORM === true) return
    if (!state.capabilities.some(item => item.intake_operation_ids?.length)) {
      status.textContent = '资料可浏览，但当前工作区尚无可接收建议的审阅入口。'
      return
    }
    dialog?.remove()
    dialog = candidateDialog(state, refresh, sources, options)
    dialog.showModal()
  }

  function ensureExplorers() {
    if (explorers) return
    const discovery = createMaterialDiscovery({ resumePending, onPropose: ({ sources, review }) => openCandidate(sources, { materialReview: review }) })
    const questionComposer = createCrossPackQuestion({ resumePending, getSelected: () => [...proposalSources.values()], onPropose: ({ sources, review }) => openCandidate(sources, { questionReview: review }) })
    const changes = createObservationChanges({ resumePending, onPropose: ({ sources, review }) => openCandidate(sources, { changeReview: review }) })
    const vocabulary = createVocabularyExplorer({ resumePending, onPropose: ({ sources, review }) => openCandidate(sources, { vocabularyReview: review }) })
    explorers = { discovery, questionComposer, changes, vocabulary }
    // Unstyled wrappers own visibility so grid rules on the existing sections
    // cannot override the hidden attribute. Keep drafts mounted across modes.
    for (const [key, section] of [['browse', manual], ['vocabulary', vocabulary.section], ['changes', changes.section], ['shared', discovery.section], ['question', questionComposer.section]]) {
      const wrapper = element('div'); wrapper.dataset.packDiscoveryPane = key
      wrapper.append(section); modes.set(key, wrapper); modeContent.append(wrapper)
    }
    selectMode()
  }

  function selectMode() {
    for (const [key, wrapper] of modes) wrapper.hidden = key !== mode.value
  }
  mode.addEventListener('change', selectMode)

  function refreshExplorers() {
    if (!explorers) return
    explorers.discovery.refresh(state, selected)
    explorers.questionComposer.refresh(state)
    explorers.changes.refresh(state, selected)
    explorers.vocabulary.refresh(state, selected)
  }

  function unavailable(kind, detail = '') {
    ready = false
    workspace.hidden = true
    empty.hidden = false
    state = bridgeState(null)
    proposalSources.clear()
    // Retained drafts must observe the outage too; no stale open dialog can
    // treat its last successful projection as current after a failed refresh.
    refreshExplorers()
    const copy = {
      public: ['公共小镇仅供浏览', '领域资料与提问需要在已授权的个人工作区中使用。登录账户不代表工作区已连接。'],
      auth: ['请先确认工作区访问权限', '登录已过期或当前账户无权读取这里的领域资料。登录后仍需进入已授权工作区。'],
      scope: ['账户连接尚未就绪', '请重新载入页面，或从账户门户进入已授权工作区。'],
      missing: ['当前工作区尚未连接领域资料', '资料服务未启用。请进入已配置的工作区；此处没有可提交的操作。'],
      empty: ['还没有已连接的领域资料', '当前工作区没有可用的领域模块。连接完成后可在这里选择资料、提出问题。'],
      offline: ['暂时无法读取领域资料', '已有草稿仍保留在本页。连接恢复后重试，不会自动发送。'],
    }[kind]
    status.textContent = copy[0]
    empty.replaceChildren(element('p', 'pack-layer-summary', copy[1]))
    if (hostedTown()) {
      // /user/ is the deployed same-origin account portal, not a promise that
      // login provisions or authorizes a private workspace.
      const account = element('a', 'pack-layer-action', '打开账户门户')
      account.href = '/user/'; account.dataset.packAccountLink = 'true'
      empty.append(account)
    }
    if (kind !== 'public') {
      const retry = element('button', 'pack-candidate-open', kind === 'scope' ? '重新载入' : '重试连接')
      retry.type = 'button'; retry.dataset.packBridgeRetry = 'true'
      retry.addEventListener('click', () => kind === 'scope' ? globalThis.location?.reload() : refresh())
      empty.append(retry)
    }
    if (detail) empty.append(advanced('连接详情', element('p', '', detail)))
  }

  function render() {
    ensureExplorers()
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
    refreshExplorers()
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
          propose.textContent = proposalSources.size ? `整理问题 · ${proposalSources.size} 份资料` : '整理问题'
        }))
        count += 1
      })
    })
    if (!count) {
      subjects.append(element('p', 'pack-layer-empty', '所选领域还没有可浏览的资料。'))
    }
    candidates.replaceChildren(...state.candidates.slice(-8).reverse().map(candidateRow))
    const projecting = state.lifecycles.filter(item => item.stage === 'projecting').length
    status.textContent = `${state.capabilities.length} 个领域 · ${count} 条资料 · ${projecting} 个已连接`
    propose.textContent = proposalSources.size ? `整理问题 · ${proposalSources.size} 份资料` : '整理问题'
    propose.disabled = !state.capabilities.some(item => item.intake_operation_ids?.length)
    noIntake.hidden = !propose.disabled
    noIntake.textContent = '当前领域仅提供资料浏览，尚无可接收建议的审阅入口。'
    ready = true
    empty.hidden = true
    workspace.hidden = false
    selectMode()
  }

  async function refresh() {
    const generation = ++refreshGeneration
    if (globalThis.__MOONTOWN_PUBLIC_PLATFORM === true) { unavailable('public'); return }
    if (hostedTown() && globalThis.__MOONTOWN_SCOPE_READY === false) { unavailable('scope'); return }
    status.textContent = '正在检查资料连接…'
    ready = false
    workspace.hidden = true
    empty.hidden = true
    try {
      const snapshot = await fetchSnapshot()
      if (generation !== refreshGeneration) return
      state = snapshot
      proposalSources.clear()
      if (!state.capabilities.length) { unavailable('empty'); return }
      render()
    } catch (error) {
      if (generation !== refreshGeneration) return
      unavailable(error.status === 401 || error.status === 403 ? 'auth' : error.status === 404 ? 'missing' : 'offline', error.message || String(error))
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
    const origin = document.querySelector('#account-pack-tools-open') || document.querySelector('#town-pack-tools-open') || launch
    origin.focus?.()
  })
  propose.addEventListener('click', () => {
    openCandidate([...proposalSources.values()])
  })
}

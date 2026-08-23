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

function subjectCard(pack, subject, status) {
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

function candidateDialog(state, onSubmitted) {
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
  close.addEventListener('click', () => dialog.close())
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
  const rationale = document.createElement('textarea')
  rationale.required = true
  rationale.maxLength = 2000
  rationale.placeholder = 'Why this deserves the pack’s reviewed workflow'
  const evidence = document.createElement('input')
  evidence.placeholder = 'evidence/ref.json, evidence/other.json'
  const payload = document.createElement('textarea')
  payload.value = '{}'
  payload.spellcheck = false
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
    field('Title', title),
    field('Rationale', rationale),
    field('Evidence references', evidence, 'Comma-separated, workspace-relative references.'),
    field('Domain payload (JSON)', payload, 'The receiving pack owns this vocabulary.'),
    status,
    submit,
  )

  form.addEventListener('submit', async event => {
    event.preventDefault()
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
    const candidate = {
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
    submit.disabled = true
    status.textContent = 'Routing candidate…'
    try {
      const response = await fetch(CANDIDATE_URL, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify(candidate),
      })
      const result = await response.json()
      if (!response.ok) throw new Error(result.error || 'Candidate routing failed.')
      status.textContent = `Routed as ${result.receipt?.status || 'submitted'}; no downstream action was authorized.`
      await onSubmitted()
    } catch (error) {
      status.textContent = error.message || String(error)
    } finally {
      submit.disabled = false
    }
  })
  dialog.append(form)
  document.body.append(dialog)
  return dialog
}

export function installPackBridgePanel() {
  if (document.querySelector('[data-pack-bridge-panel]')) return
  const launch = element('button', 'pack-bridge-launch', 'Pack layers')
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
  let selectionInitialized = false
  let dialog = null

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
    subjects.replaceChildren()
    let count = 0
    state.capabilities.forEach(capability => {
      if (!selected.has(capability.pack_id)) return
      const projection = projectionFor(state, capability.pack_id)
      ;(projection?.subjects || []).forEach(subject => {
        subjects.append(subjectCard(capability, subject, status))
        count += 1
      })
    })
    if (!count) {
      subjects.append(element('p', 'pack-layer-empty', 'No projected subjects from the selected active packs.'))
    }
    candidates.replaceChildren(...state.candidates.slice(-8).reverse().map(candidateRow))
    const projecting = state.lifecycles.filter(item => item.stage === 'projecting').length
    status.textContent = `${state.capabilities.length} bridge-ready pack(s) · ${count} visible subject(s) · ${projecting} projecting`
    propose.disabled = !state.capabilities.some(item => item.intake_operation_ids?.length)
  }

  async function refresh() {
    status.textContent = 'Refreshing pack lifecycle…'
    try {
      state = await fetchSnapshot()
      render()
    } catch (error) {
      status.textContent = error.message || String(error)
      subjects.replaceChildren(element('p', 'pack-layer-empty', 'Pack Bridge is not available in this runtime.'))
    }
  }

  launch.addEventListener('click', async () => {
    panel.hidden = false
    launch.hidden = true
    await refresh()
  })
  close.addEventListener('click', () => {
    panel.hidden = true
    launch.hidden = false
  })
  propose.addEventListener('click', () => {
    dialog?.remove()
    dialog = candidateDialog(state, refresh)
    dialog.showModal()
  })
}

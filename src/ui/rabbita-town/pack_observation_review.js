import { BASELINE_LIMITS, captureObservationBaseline, serializeObservationBaseline, parseObservationBaseline,
  compareObservationBaseline, prepareObservationChanges } from './pack_observation_changes.js'

function element(tag, className = '', text = '') {
  const node = document.createElement(tag)
  node.className = className; node.textContent = text
  return node
}

function field(label, control) {
  const node = element('label', 'pack-candidate-field')
  node.append(element('span', '', label), control)
  return node
}

function downloadFile(body, name) {
  const url = URL.createObjectURL(new Blob([body], { type: 'application/json' }))
  const link = element('a')
  link.href = url; link.download = name; document.body.append(link)
  try { link.click() } finally { link.remove(); setTimeout(() => URL.revokeObjectURL(url), 1000) }
}

export function createObservationChanges({ onPropose, resumePending, download = downloadFile }) {
  const section = element('section', 'pack-observation-section')
  section.dataset.observationChanges = 'true'
  const label = element('input'); label.maxLength = 140; label.value = 'My observation baseline'; label.dataset.observationLabel = 'true'
  const capture = element('button', 'pack-candidate-open', 'Save selected layers as baseline'); capture.type = 'button'; capture.dataset.observationCapture = 'true'
  const save = element('button', 'pack-candidate-open', 'Download retained baseline'); save.type = 'button'; save.dataset.observationExport = 'true'
  const upload = element('input'); upload.type = 'file'; upload.accept = '.json,application/json'; upload.dataset.observationImport = 'true'
  const preview = element('div'), summary = element('p', 'pack-layer-summary'), rows = element('div', 'pack-observation-rows')
  const search = element('input'); search.type = 'search'; search.dataset.observationSearch = 'true'
  const filter = element('select'); filter.dataset.observationFilter = 'true'
  for (const [value, name] of [['changes', 'All changed observations'], ['changed', 'Changed fields'], ['newly-projected', 'Newly projected'], ['no-longer-projected', 'No longer projected'], ['unchanged', 'Unchanged']]) {
    const option = element('option', '', name); option.value = value; filter.append(option)
  }
  filter.value = 'changes'
  const previous = element('button', 'pack-candidate-open', 'Previous changes'), next = element('button', 'pack-candidate-open', 'Next changes')
  previous.type = next.type = 'button'; previous.dataset.observationPrevious = 'true'; next.dataset.observationNext = 'true'
  const pageStatus = element('span'), pages = element('div', 'pack-layer-actions')
  pages.append(previous, pageStatus, next)
  const proceed = element('button', 'pack-candidate-submit', 'Continue selected changes to intake'); proceed.type = 'button'; proceed.dataset.observationContinue = 'true'
  const report = element('button', 'pack-candidate-open', 'Download comparison'); report.type = 'button'; report.dataset.observationReport = 'true'
  const status = element('p', 'pack-candidate-form-status'); status.setAttribute('role', 'status')
  section.append(element('h3', '', 'What changed since your last visit?'),
    element('p', 'pack-layer-summary', 'Save a baseline of the selected pack layers, then compare later projections. Files stay local until you explicitly submit a candidate. A saved baseline keeps its original pack scope when layer filters change.'),
    field('Baseline label', label), capture, save, field('Import an earlier baseline (untrusted local JSON)', upload), preview,
    summary, field('Find an observation, pack or evidence reference', search), field('Show', filter), rows, pages, proceed, report, status)

  let baseline = null, state = null, selectedPacks = new Set(), comparison = null, page = 0, revision = 0, importGeneration = 0
  const selected = new Set()
  const pageSize = 20
  function invalidateImport() { importGeneration++; preview.replaceChildren(); upload.value = '' }
  function adopt(value) {
    baseline = value; selected.clear(); page = 0; label.value = value.label
    invalidateImport(); render()
  }
  function updateButton() {
    proceed.disabled = !selected.size || !comparison
    proceed.textContent = selected.size ? `Continue ${selected.size} change(s) to intake` : 'Continue selected changes to intake'
  }
  function render() {
    const rendered = ++revision
    rows.replaceChildren(); comparison = null
    save.disabled = !baseline; report.disabled = true
    capture.textContent = baseline ? 'Replace baseline with selected layers' : 'Save selected layers as baseline'
    if (!baseline) {
      summary.textContent = 'No baseline retained yet. Save selected layers, or import a baseline from an earlier visit.'
      previous.disabled = next.disabled = true; pageStatus.textContent = ''; updateButton(); return
    }
    try { comparison = compareObservationBaseline(baseline, state) }
    catch (error) { selected.clear(); summary.textContent = `Comparison unavailable: ${error.message}`; previous.disabled = next.disabled = true; pageStatus.textContent = ''; updateButton(); return }
    report.disabled = false
    const counts = new Map()
    for (const row of comparison.rows) counts.set(row.status, (counts.get(row.status) || 0) + 1)
    summary.textContent = `${baseline.label} · saved ${baseline.saved_at} · scope: ${comparison.scope_pack_ids.join(', ')} · ${counts.get('changed') || 0} changed · ${counts.get('newly-projected') || 0} new · ${counts.get('no-longer-projected') || 0} no longer projected · ${counts.get('unchanged') || 0} unchanged · ${comparison.gaps.length} unavailable pack(s)`
    for (const gap of comparison.gaps) rows.append(element('p', 'pack-question-gap', `${gap.pack_id}: ${gap.message} Historical observations are retained in the baseline; this is not a no-change result.`))
    const query = search.value.trim().toLowerCase()
    const matching = comparison.rows.filter(row => (filter.value === 'changes' ? row.status !== 'unchanged' : row.status === filter.value) &&
      (!query || JSON.stringify([row.before, row.after]).toLowerCase().includes(query)))
    page = Math.min(page, Math.max(0, Math.ceil(matching.length / pageSize) - 1))
    previous.disabled = page === 0; next.disabled = (page + 1) * pageSize >= matching.length
    pageStatus.textContent = `${matching.length ? page * pageSize + 1 : 0}–${Math.min((page + 1) * pageSize, matching.length)} of ${matching.length}`
    for (const row of matching.slice(page * pageSize, (page + 1) * pageSize)) {
      const source = row.after || row.before, card = element('article', 'pack-layer-subject')
      card.dataset.observationRow = row.key
      card.append(element('h4', '', `${source.pack_id}: ${source.title}`), element('p', 'pack-material-ref', `${row.status} · ${source.subject_ref}`))
      if (row.changed_fields.length) card.append(element('p', '', `Changed fields: ${row.changed_fields.join(', ')}`))
      for (const [name, snapshot] of [['Before', row.before], ['Current', row.after]]) {
        const box = element('section', 'pack-observation-excerpt')
        box.append(element('strong', '', name))
        if (snapshot) box.append(element('p', '', snapshot.title), element('p', '', snapshot.summary),
          element('p', 'pack-material-ref', `${snapshot.schema_id} · ${snapshot.lifecycle_state} · version ${snapshot.pack_version} · published ${snapshot.captured_generated_at}`),
          element('p', 'pack-material-ref', `Pack-relative evidence: ${snapshot.evidence_refs.join(', ') || 'None'}`))
        else box.append(element('p', '', name === 'Before' ? 'Not present in the saved projection.' : 'Not present in this current projection. This does not prove the source or knowledge was deleted.'))
        card.append(box)
      }
      if (['changed', 'newly-projected'].includes(row.status)) {
        const choose = element('input'); choose.type = 'checkbox'; choose.checked = selected.has(row.key); choose.dataset.observationChoose = row.key
        choose.addEventListener('change', () => {
          if (revision !== rendered) return
          if (!choose.checked) selected.delete(row.key)
          else if (selected.size < BASELINE_LIMITS.selected) selected.add(row.key)
          else { choose.checked = false; status.textContent = 'Choose at most twelve observations for one candidate.' }
          updateButton()
        })
        card.append(field('Use this current observation and its change history', choose))
      }
      rows.append(card)
    }
    if (!matching.length) rows.append(element('p', 'pack-layer-empty', comparison.gaps.length ? 'No matching comparable observations. Unavailable packs above still require attention.' : 'No observations match this view.'))
    updateButton()
  }

  capture.addEventListener('click', () => {
    try {
      const value = captureObservationBaseline(state, selectedPacks, label.value)
      download(serializeObservationBaseline(value), 'moontown-observation-baseline.json')
      adopt(value); status.textContent = 'Baseline retained and download requested. Keep the file to compare after a page restart.'
    } catch (error) { status.textContent = error.message }
  })
  save.addEventListener('click', () => {
    if (!baseline) return
    try { download(serializeObservationBaseline(baseline), 'moontown-observation-baseline.json'); status.textContent = 'Baseline download requested.' }
    catch (error) { status.textContent = error.message }
  })
  report.addEventListener('click', () => {
    if (!baseline) return
    try { download(JSON.stringify(compareObservationBaseline(baseline, state), null, 2) + '\n', 'moontown-observation-comparison.json'); status.textContent = 'Comparison download requested, including before/after snapshots and unavailable-pack gaps.' }
    catch (error) { status.textContent = error.message }
  })
  upload.addEventListener('change', async () => {
    const generation = ++importGeneration
    preview.replaceChildren()
    const file = upload.files?.[0]
    if (!file) return
    try {
      if (file.size > BASELINE_LIMITS.bytes) throw Error('Choose a baseline JSON file no larger than 1 MiB.')
      const value = parseObservationBaseline(await file.text())
      if (generation !== importGeneration) return
      const replace = element('button', 'pack-candidate-open', 'Use imported baseline'); replace.type = 'button'; replace.dataset.observationAcceptImport = 'true'
      const cancel = element('button', 'pack-candidate-open', 'Cancel baseline import'); cancel.type = 'button'
      preview.append(element('p', 'pack-question-gap', `Untrusted baseline: ${value.label} · saved ${value.saved_at} · ${value.packs.length} pack(s): ${value.packs.map(p => p.pack_id).join(', ')}. This replaces your local comparison baseline only.`), replace, cancel)
      replace.addEventListener('click', () => { if (generation !== importGeneration) return; adopt(value); status.textContent = 'Imported baseline loaded for comparison. Historical excerpts remain unverified operator-supplied data.' })
      cancel.addEventListener('click', () => { if (generation !== importGeneration) return; invalidateImport(); status.textContent = 'Import cancelled. The previous baseline is retained.' })
    } catch (error) { if (generation === importGeneration) status.textContent = error.message }
  })
  search.addEventListener('input', () => { page = 0; render() })
  filter.addEventListener('change', () => { page = 0; render() })
  previous.addEventListener('click', () => { if (previous.disabled) return; page--; render() })
  next.addEventListener('click', () => { if (next.disabled) return; page++; render() })
  proceed.addEventListener('click', () => {
    if (resumePending()) return
    if (!baseline || proceed.disabled) return
    try {
      const prepared = prepareObservationChanges(baseline, state, selected)
      onPropose(prepared)
      selected.clear(); render(); status.textContent = 'Change history opened in the editable candidate. Describe why it matters and what could disprove the idea before submitting.'
    } catch (error) { status.textContent = error.message }
  })
  render()
  return { section, refresh(nextState, visiblePacks) {
    if (state !== nextState) {
      if (selected.size) status.textContent = 'Projections refreshed. Re-read and select the changes again before continuing.'
      selected.clear()
    }
    state = nextState; selectedPacks = new Set(visiblePacks); render()
  } }
}

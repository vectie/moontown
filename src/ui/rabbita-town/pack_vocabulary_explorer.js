import { VOCABULARY_LIMITS, VOCABULARY_METHOD, VOCABULARY_INTERPRETATION, normalizeVocabularyLens,
  discoverVocabulary, serializeVocabularyLens, parseVocabularyLens, serializeVocabularyDiscovery, prepareVocabularyReview } from './pack_vocabulary.js'

function element(tag, text = '', className = '') {
  const node = document.createElement(tag); node.textContent = text; node.className = className; return node
}
function field(label, control) {
  const node = element('label', '', 'pack-candidate-field'); node.append(element('span', label), control); return node
}
function button(text, key) {
  const node = element('button', text, 'pack-candidate-open'); node.type = 'button'; node.dataset[key] = 'true'; return node
}
function downloadFile(body, name) {
  const url = URL.createObjectURL(new Blob([body], { type: 'application/json' })), link = element('a')
  link.href = url; link.download = name; document.body.append(link)
  try { link.click() } finally { link.remove(); setTimeout(() => URL.revokeObjectURL(url), 1000) }
}
const words = value => value.trim() ? value.split(',').map(part => part.trim()) : []

export function createVocabularyExplorer({ onPropose, resumePending, download = downloadFile }) {
  const section = element('section', '', 'pack-vocabulary-section'); section.dataset.vocabularyExplorer = 'true'
  const label = element('input'); label.maxLength = 140; label.value = 'Cross-pack vocabulary'; label.dataset.vocabularyLabel = 'true'
  const terms = element('input'); terms.maxLength = 1212; terms.dataset.vocabularyTerms = 'true'
  const ignored = element('input'); ignored.maxLength = 10100; ignored.dataset.vocabularyIgnored = 'true'
  const mode = element('select'); mode.dataset.vocabularyMode = 'true'
  for (const [value, text] of [['any', 'ANY word (union)'], ['all', 'ALL words in the same observation']]) { const option = element('option', text); option.value = value; mode.append(option) }
  mode.value = 'any'
  const useScope = button('Use selected layers for this lens', 'vocabularyScope')
  const suggestions = element('div', '', 'pack-layer-actions'), scope = element('p'), summary = element('p'), rows = element('div', '', 'pack-vocabulary-rows')
  const previous = button('Previous matches', 'vocabularyPrevious'), next = button('Next matches', 'vocabularyNext'), pageStatus = element('span')
  const hypothesis = element('textarea'); hypothesis.maxLength = 2000; hypothesis.dataset.vocabularyHypothesis = 'true'
  const proceed = button('Continue selected matches to intake', 'vocabularyContinue')
  const save = button('Download editable lens', 'vocabularyExport'), reportButton = button('Download discovery results', 'vocabularyReport')
  const upload = element('input'); upload.type = 'file'; upload.accept = '.json,application/json'; upload.dataset.vocabularyImport = 'true'
  const preview = element('div'), status = element('p', '', 'pack-candidate-form-status'); status.setAttribute('role', 'status')
  section.append(element('h3', 'Discover words connecting different packs'), element('p', VOCABULARY_INTERPRETATION),
    field('Lens name', label), scope, useScope, element('p', 'Suggested words occur in at least two scoped packs. English stop words, numeric-only and words shorter than three characters are omitted from suggestions, but can still be searched explicitly.'), suggestions,
    field('Whole words, separated by commas', terms), field('Match', mode), field('Hide noisy suggestions (comma-separated words)', ignored),
    element('p', 'Matching uses Unicode normalization and lowercase whole words in titles and summaries. Punctuation separates words. No stemming, translation, accent folding or language-specific word segmentation is performed.'),
    summary, rows, previous, pageStatus, next, field('What tentative connection deserves investigation?', hypothesis), proceed,
    save, reportButton, field('Import an editable lens (local JSON; does not contain source excerpts)', upload), preview, status)

  let state = null, selectedPacks = new Set(), scopeIds = [], initialized = false, report = null, page = 0, revision = 0, importGeneration = 0
  const selected = new Set()
  function lens() {
    return normalizeVocabularyLens({ contract_id: 'moontown.vocabulary-lens.v1', method: VOCABULARY_METHOD, accepted_knowledge: false,
      label: label.value, scope_pack_ids: scopeIds, terms: words(terms.value), mode: mode.value, ignored_suggestions: words(ignored.value) })
  }
  function invalidateImport() { importGeneration++; preview.replaceChildren(); upload.value = '' }
  function selectionChanged() {
    proceed.disabled = !report || selected.size < 2
    proceed.textContent = selected.size ? `Continue ${selected.size} match(es) to intake` : 'Continue selected matches to intake'
  }
  function render() {
    const rendered = ++revision
    report = null; rows.replaceChildren(); suggestions.replaceChildren(); save.disabled = reportButton.disabled = true
    scope.textContent = `Lens scope: ${scopeIds.join(', ') || 'No packs selected'}. Layer checkboxes change this scope only when you choose “Use selected layers”.`
    try { report = discoverVocabulary(state, lens()) }
    catch (error) { selected.clear(); summary.textContent = error.message; previous.disabled = next.disabled = true; pageStatus.textContent = ''; selectionChanged(); return }
    save.disabled = reportButton.disabled = false
    for (const item of report.suggestions.slice(0, VOCABULARY_LIMITS.suggestions)) {
      const choose = button(`${item.term} · ${item.pack_ids.length} packs · ${item.observation_count} observations`, 'vocabularySuggestion')
      choose.dataset.vocabularySuggestion = item.term
      choose.addEventListener('click', () => {
        if (rendered !== revision) return
        // Choosing a suggestion starts a one-word lens; the editable field can
        // combine it with more words under explicit ANY/ALL semantics.
        terms.value = item.term; selected.clear(); page = 0; invalidateImport(); render()
      })
      suggestions.append(choose)
    }
    if (!report.suggestions.length) suggestions.append(element('p', 'No suggested words span two available packs. Enter words directly or choose a wider scope.'))
    if (report.suggestions.length > VOCABULARY_LIMITS.suggestions) suggestions.append(element('p', `Showing the first 40 of ${report.suggestions.length} ranked words. Hide noisy suggestions to reveal more; the export includes all.`))
    summary.textContent = `${report.inspected_observation_count} inspected observations · ${report.rows.length} matches across ${report.matching_pack_count} packs · ${report.gaps.length} unavailable packs. ${report.lens.terms.length ? `Matching ${report.lens.mode.toUpperCase()}: ${report.lens.terms.join(', ')}.` : 'Choose a word above or enter your own.'}`
    for (const gap of report.gaps) rows.append(element('p', `${gap.pack_id}: ${gap.message} This is a coverage gap, not an absence of related observations.`, 'pack-question-gap'))
    page = Math.min(page, Math.max(0, Math.ceil(report.rows.length / VOCABULARY_LIMITS.page) - 1))
    previous.disabled = page === 0; next.disabled = (page + 1) * VOCABULARY_LIMITS.page >= report.rows.length
    pageStatus.textContent = `${report.rows.length ? page * VOCABULARY_LIMITS.page + 1 : 0}–${Math.min((page + 1) * VOCABULARY_LIMITS.page, report.rows.length)} of ${report.rows.length}`
    for (const row of report.rows.slice(page * VOCABULARY_LIMITS.page, (page + 1) * VOCABULARY_LIMITS.page)) {
      const source = row.source, card = element('article', '', 'pack-layer-subject'); card.dataset.vocabularyRow = row.key
      card.append(element('h4', `${source.pack_id}: ${source.title}`), element('p', source.summary),
        element('p', `Matched words: ${row.matched_terms.join(', ')}`),
        element('p', `${source.subject_ref} · ${source.schema_id} · ${source.lifecycle_state} · version ${source.pack_version} · published ${source.captured_generated_at}`, 'pack-material-ref'),
        element('p', `Pack-relative evidence: ${source.evidence_refs.join(', ') || 'None'}`, 'pack-material-ref'))
      const choose = element('input'); choose.type = 'checkbox'; choose.checked = selected.has(row.key); choose.dataset.vocabularyChoose = row.key
      choose.addEventListener('change', () => {
        if (rendered !== revision) return
        if (!choose.checked) selected.delete(row.key)
        else if (selected.size < VOCABULARY_LIMITS.selected) selected.add(row.key)
        else { choose.checked = false; status.textContent = 'Choose at most twelve observations.' }
        selectionChanged()
      })
      card.append(field('Investigate this observation', choose)); rows.append(card)
    }
    if (!report.rows.length && report.lens.terms.length) rows.append(element('p', 'No exact matches in available scoped observations. Try ANY, another whole word, or a wider scope. Unavailable packs above remain gaps.'))
    selectionChanged()
  }
  function editLens() { selected.clear(); page = 0; invalidateImport(); render() }
  terms.addEventListener('input', editLens); ignored.addEventListener('input', editLens); label.addEventListener('input', editLens); mode.addEventListener('change', editLens)
  useScope.addEventListener('click', () => { scopeIds = [...selectedPacks]; initialized = true; editLens() })
  previous.addEventListener('click', () => { if (!previous.disabled) { page--; render() } })
  next.addEventListener('click', () => { if (!next.disabled) { page++; render() } })
  save.addEventListener('click', () => {
    try { download(serializeVocabularyLens(lens()), 'moontown-vocabulary-lens.json'); status.textContent = 'Editable lens download requested. It contains scope and words, not saved source excerpts or an uncertain candidate identity.' }
    catch (error) { status.textContent = error.message }
  })
  reportButton.addEventListener('click', () => {
    try { download(serializeVocabularyDiscovery(discoverVocabulary(state, lens())), 'moontown-vocabulary-discovery.json'); status.textContent = 'Discovery download requested with all matching excerpts, ranked suggestions and named coverage gaps, including other result pages.' }
    catch (error) { status.textContent = error.message }
  })
  upload.addEventListener('change', async () => {
    const generation = ++importGeneration; preview.replaceChildren(); const file = upload.files?.[0]; if (!file) return
    try {
      if (file.size > VOCABULARY_LIMITS.lensBytes) throw Error('Choose lens JSON no larger than 64 KiB.')
      const value = parseVocabularyLens(await file.text())
      if (generation !== importGeneration) return
      const accept = button('Use imported lens', 'vocabularyAcceptImport'), cancel = button('Cancel lens import', 'vocabularyCancelImport')
      preview.append(element('p', `Imported settings: ${value.label} · ${value.mode.toUpperCase()} ${value.terms.join(', ') || '(no words yet)'} · packs: ${value.scope_pack_ids.join(', ')}. Applying replaces your local lens and selections; it searches current projections and does not restore historical excerpts or submit anything.`), accept, cancel)
      accept.addEventListener('click', () => {
        if (generation !== importGeneration) return
        label.value = value.label; terms.value = value.terms.join(', '); ignored.value = value.ignored_suggestions.join(', '); mode.value = value.mode
        scopeIds = value.scope_pack_ids; initialized = true; editLens(); status.textContent = 'Imported lens applied to current projections. Edit its words or scope and review the current excerpts before continuing.'
      })
      cancel.addEventListener('click', () => { if (generation === importGeneration) { invalidateImport(); status.textContent = 'Import cancelled; the current lens is retained.' } })
    } catch (error) { if (generation === importGeneration) status.textContent = error.message }
  })
  proceed.addEventListener('click', () => {
    if (resumePending() || proceed.disabled) return
    try { onPropose(prepareVocabularyReview(state, lens(), selected, hypothesis.value)); selected.clear(); render(); status.textContent = 'Opened editable candidate intake. Explain each source connection and a rejection test; submission remains explicit.' }
    catch (error) { status.textContent = error.message }
  })
  render()
  return { section, refresh(nextState, visiblePacks) {
    if (state !== nextState) { selected.clear(); if (state) status.textContent = 'Projections refreshed; inspect and select matching observations again.' }
    state = nextState; selectedPacks = new Set(visiblePacks)
    if (!initialized && selectedPacks.size) { scopeIds = [...selectedPacks]; initialized = true }
    render()
  } }
}

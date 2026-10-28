import { subjectKey } from './pack_candidate_sources.js'
import { discoverMaterialGroups, MATERIAL_LIMITS, materialGroupSignature, reviewMaterialGroup } from './pack_material_groups.js'

function element(tag, className = '', text = '') {
  const node = document.createElement(tag)
  node.className = className
  node.textContent = text
  return node
}

// Drafts stay local to this mounted panel. Cancel/refresh keep operator choices;
// reload recovery remains the native candidate mailbox's responsibility.
export function createMaterialDiscovery({ onPropose, resumePending }) {
  const section = element('section', 'pack-material-discovery')
  section.dataset.materialDiscovery = 'true'
  const drafts = new Map()
  let state = null, activeDialog = null

  function currentGroup(key) {
    return discoverMaterialGroups(state).groups.find(group => group.key === key)
  }

  function openReview(group) {
    if (resumePending()) return
    if (activeDialog?.open) return
    activeDialog?.remove()
    if (!drafts.has(group.key)) {
      if (drafts.size >= MATERIAL_LIMITS.shown) {
        section.append(element('p', 'pack-layer-empty', 'Forty local group reviews are already retained. Submit the needed proposals before reloading to clear unsent reviews.'))
        return
      }
      drafts.set(group.key, { group: structuredClone(group), included: new Set(), hypothesis: '' })
    }
    const draft = drafts.get(group.key)
    const dialog = element('dialog', 'pack-candidate-dialog pack-material-dialog')
    activeDialog = dialog
    const form = element('form', 'pack-candidate-form')
    const status = element('p', 'pack-candidate-form-status')
    status.setAttribute('role', 'status')
    const heading = element('h2', '', '核对共同来源')
    heading.id = 'pack-material-review-title'
    dialog.setAttribute('aria-labelledby', heading.id)
    const close = element('button', 'pack-dialog-close', '取消')
    close.type = 'button'
    const description = element('p', '', 'These observations reuse one pack-relative evidence reference. Read each excerpt and include two to twelve. Shared material is not independent corroboration.')
    const rows = element('section', 'pack-material-review-sources')
    const label = element('label', 'pack-candidate-field', '你的初步观察')
    const hypothesis = element('textarea')
    hypothesis.maxLength = 2000
    hypothesis.value = draft.hypothesis
    hypothesis.dataset.materialHypothesis = 'true'
    hypothesis.addEventListener('input', () => { draft.hypothesis = hypothesis.value })
    label.append(hypothesis)
    const update = element('button', 'pack-candidate-open', '重新核对资料')
    update.type = 'button'
    const proceed = element('button', 'pack-candidate-submit', '整理问题')
    proceed.type = 'submit'
    proceed.dataset.materialContinue = 'true'
    let busy = false, completed = false

    function stale() {
      try {
        const current = currentGroup(group.key)
        return !current || materialGroupSignature(current) !== materialGroupSignature(draft.group)
      } catch { return true }
    }

    function render() {
      rows.replaceChildren()
      for (const source of draft.group.sources) {
        const box = element('article', 'pack-layer-subject')
        const choice = element('input')
        choice.type = 'checkbox'
        const key = subjectKey(source.pack_id, source.subject_ref)
        choice.dataset.materialSource = key
        choice.checked = draft.included.has(key)
        choice.addEventListener('change', () => {
          if (busy) { choice.checked = draft.included.has(key); return }
          if (choice.checked) draft.included.add(key)
          else draft.included.delete(key)
          status.textContent = `${draft.included.size} included · ${draft.group.sources.length - draft.included.size} excluded`
        })
        const chooseLabel = element('label', 'pack-layer-filter')
        chooseLabel.append(choice, element('span', '', `Include ${source.title}`))
        box.append(chooseLabel, element('p', 'pack-layer-summary', source.summary),
          element('p', 'pack-material-ref', `${source.pack_id} · ${source.subject_ref} · ${source.lifecycle_state}`),
          element('p', 'pack-material-ref', `Observed ${source.captured_generated_at}; evidence: ${source.evidence_refs.join(', ')}`))
        rows.append(box)
      }
      const changed = stale()
      update.hidden = !changed
      proceed.disabled = changed || busy || completed
      status.textContent = changed
        ? 'This group changed or is unavailable. Your choices and hypothesis are retained. Review the current group; newly added observations start excluded.'
        : `${draft.included.size} included · ${draft.group.sources.length - draft.included.size} excluded. Continue opens an editable proposal; nothing is sent yet.`
    }

    update.addEventListener('click', () => {
      if (busy || completed) return
      try {
        const current = currentGroup(group.key)
        if (!current || current.sources.length > MATERIAL_LIMITS.group) throw Error('This group is unavailable for review. Refresh Pack layers after its sources are repaired.')
        draft.group = structuredClone(current)
        const available = new Set(current.sources.map(source => subjectKey(source.pack_id, source.subject_ref)))
        draft.included = new Set([...draft.included].filter(key => available.has(key)))
        render()
      } catch (error) { status.textContent = error.message }
    })
    close.addEventListener('click', () => { if (!busy) { draft.hypothesis = hypothesis.value; dialog.close() } })
    dialog.addEventListener('cancel', event => {
      if (busy) event.preventDefault()
      else draft.hypothesis = hypothesis.value
    })
    form.addEventListener('submit', async event => {
      event.preventDefault()
      if (busy || completed) return
      draft.hypothesis = hypothesis.value
      if (stale()) { render(); return }
      busy = true; proceed.disabled = true; hypothesis.disabled = true
      try {
        const prepared = await reviewMaterialGroup(draft.group, draft.included, draft.hypothesis)
        // A newer refresh may arrive while hashing. Do not route an old review.
        if (stale()) throw Error('The group changed while preparing the proposal. Review the current group first.')
        dialog.close()
        onPropose(prepared)
        completed = true
        dialog.remove()
      } catch (error) { status.textContent = error.message; if (!dialog.open) dialog.showModal() }
      finally { busy = false; proceed.disabled = completed || stale(); hypothesis.disabled = false }
    })
    form.append(heading, close, element('p', 'pack-material-ref', `${group.pack_id}: ${group.evidence_ref}`), description, rows, label, status, update, proceed)
    dialog.append(form)
    document.body.append(dialog)
    render()
    dialog.showModal()
  }

  function refresh(nextState, visiblePacks) {
    state = nextState
    section.replaceChildren(element('h3', '', '相同来源'),
      element('p', 'pack-layer-summary', 'Start with recurring local material. Each group contains observations from one pack citing the exact same evidence path.'))
    try {
      const result = discoverMaterialGroups(state, visiblePacks)
      const shown = result.groups.slice(0, MATERIAL_LIMITS.shown)
      section.append(element('p', 'pack-layer-summary', `${result.inspectedSubjects} observations inspected · ${result.groups.length} group(s) · ${result.skippedPacks} unavailable pack(s) and ${result.skippedSubjects} invalid/ambiguous observation(s) skipped`))
      if (!shown.length) section.append(element('p', 'pack-layer-empty', 'No repeated evidence references in the visible, valid observations. You can still select individual proposal sources below.'))
      for (const group of shown) {
        const card = element('article', 'pack-layer-subject')
        card.append(element('strong', '', `${group.sources.length} observations · ${group.pack_id}`),
          element('p', 'pack-material-ref', group.evidence_ref),
          element('p', 'pack-layer-summary', group.sources.slice(0, 3).map(source => source.title).join(' · ')))
        const review = element('button', 'pack-candidate-open', '查看共同来源')
        review.type = 'button'; review.dataset.materialGroup = group.key
        review.disabled = group.sources.length > MATERIAL_LIMITS.group
        review.addEventListener('click', () => { if (!review.disabled) openReview(group) })
        card.append(review)
        if (review.disabled) card.append(element('p', '', 'This group exceeds the 128-observation review limit; no subset was silently chosen.'))
        section.append(card)
      }
      if (result.groups.length > shown.length) section.append(element('p', '', `Showing the first ${MATERIAL_LIMITS.shown} groups by observation count, then pack/reference. Filter layers to narrow discovery.`))
    } catch (error) { section.append(element('p', 'pack-layer-empty', error.message)) }
  }

  return { section, refresh }
}

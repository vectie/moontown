import { QUESTION_PACKET_LIMIT, QUESTION_ROLES, newQuestionDraft, appendQuestionSources,
  serializeQuestionDraft, parseQuestionDraft, questionSourceGaps, refreshQuestionSource,
  prepareCrossPackQuestion } from './pack_cross_pack_question.js'

function element(tag, className = '', text = '') {
  const node = document.createElement(tag)
  node.className = className
  node.textContent = text
  return node
}

function field(text, control) {
  const label = element('label', 'pack-candidate-field')
  label.append(element('span', '', text), control)
  return label
}

export function downloadQuestionPacket(body) {
  const url = URL.createObjectURL(new Blob([body], { type: 'application/json' }))
  const link = element('a')
  link.href = url; link.download = 'moontown-cross-pack-question.json'
  document.body.append(link)
  try { link.click() } finally { link.remove(); setTimeout(() => URL.revokeObjectURL(url), 1000) }
}

// One local unsent question per mounted panel; the portable packet is the
// explicit restart path. It is not uploaded, posted, or auto-accepted on import.
export function createCrossPackQuestion({ onPropose, resumePending, getSelected, download = downloadQuestionPacket }) {
  const section = element('section', 'pack-question-section')
  section.dataset.crossPackQuestion = 'true'
  const launch = element('button', 'pack-candidate-open', '整理跨领域问题')
  launch.type = 'button'; launch.dataset.questionLaunch = 'true'
  const hint = element('p', 'pack-layer-summary', '先在“浏览资料”中选择至少两个领域的资料，再整理一个待审阅的问题。')
  const status = element('p', 'pack-candidate-form-status')
  status.setAttribute('role', 'status')
  const upload = element('input')
  upload.type = 'file'; upload.accept = '.json,application/json'; upload.dataset.questionImport = 'true'
  const pendingImport = element('div')
  const portable = element('details', 'town-advanced')
  portable.append(element('summary', '', '高级 · 恢复问题草稿'), field('载入已下载的草稿', upload))
  section.append(element('h3', '', '跨领域问题'), hint, launch, portable, pendingImport, status)
  let draft = newQuestionDraft(), state = null, dialog = null, updateOpen = null, importGeneration = 0

  function invalidateImport() {
    importGeneration++
    pendingImport.replaceChildren()
    upload.value = ''
  }

  function open() {
    if (resumePending()) return
    if (dialog?.open) return
    dialog?.remove()
    dialog = element('dialog', 'pack-candidate-dialog pack-question-dialog')
    const currentDialog = dialog
    const heading = element('h2', '', 'Compose a cross-pack question')
    heading.id = 'pack-cross-question-title'; dialog.setAttribute('aria-labelledby', heading.id)
    const form = element('form', 'pack-candidate-form')
    const question = element('input'), scope = element('textarea'), rejection = element('textarea')
    question.maxLength = 140; scope.maxLength = 2000; rejection.maxLength = 2000
    question.value = draft.question; scope.value = draft.scope; rejection.value = draft.rejection_test
    question.dataset.questionText = 'true'; scope.dataset.questionScope = 'true'; rejection.dataset.questionRejection = 'true'
    const rows = element('section', 'pack-question-rows')
    const feedback = element('p', 'pack-candidate-form-status'); feedback.setAttribute('role', 'status')
    const close = element('button', 'pack-dialog-close', '保留并关闭')
    close.type = 'button'
    const save = element('button', 'pack-candidate-open', '下载草稿')
    save.type = 'button'; save.dataset.questionExport = 'true'
    const proceed = element('button', 'pack-candidate-submit', '整理为建议')
    proceed.type = 'submit'; proceed.dataset.questionContinue = 'true'
    let continued = false, active = true, rowsRevision = 0
    const live = () => active && dialog === currentDialog && currentDialog.open && !continued

    function closeCurrent() {
      active = false
      currentDialog.close()
    }

    function capture() {
      if (!live()) return
      draft.question = question.value; draft.scope = scope.value; draft.rejection_test = rejection.value
    }

    function renderRows() {
      const revision = ++rowsRevision
      const gaps = questionSourceGaps(draft, state)
      rows.replaceChildren()
      draft.rows.forEach((row, index) => {
        const liveRow = () => live() && rowsRevision === revision && draft.rows[index] === row
        const source = row.source, box = element('article', 'pack-layer-subject')
        box.dataset.questionRow = String(index)
        box.append(element('h3', '', `${source.pack_id}: ${source.title}`), element('p', 'pack-layer-summary', source.summary),
          element('p', 'pack-material-ref', `${source.subject_ref} · ${source.lifecycle_state} · snapshot ${source.captured_generated_at} · version ${source.pack_version}`),
          element('p', 'pack-material-ref', `Pack-relative evidence: ${source.evidence_refs.join(', ') || 'None provided'}`))
        const gap = gaps.find(item => item.index === index)
        const freshness = element('p', gap ? 'pack-question-gap' : 'pack-layer-summary', gap ? `Unresolved snapshot gap: ${gap.message}` : 'Inspected excerpt matches the loaded current projection.')
        freshness.dataset.questionGap = gap ? String(index) : ''
        box.append(freshness)
        if (gap) {
          const reread = element('button', 'pack-candidate-open', '核对最新资料')
          reread.type = 'button'; reread.dataset.questionRefreshSource = String(index)
          reread.addEventListener('click', () => {
            if (!liveRow()) return
            capture()
            try { draft = refreshQuestionSource(draft, index, state); renderRows(); feedback.textContent = 'Current excerpt loaded. Its role, connection and conditions were cleared so you can review them again.' }
            catch (error) { feedback.textContent = error.message }
          })
          box.append(reread)
        }
        const role = element('select'); role.dataset.questionRole = String(index)
        for (const [value, label] of [['', 'Choose your interpretation'], ...QUESTION_ROLES.map(item => [item, item])]) {
          const option = element('option', '', label); option.value = value; role.append(option)
        }
        role.value = row.role
        role.addEventListener('change', () => { if (liveRow()) row.role = role.value })
        const connection = element('textarea'), conditions = element('textarea')
        connection.maxLength = 2000; conditions.maxLength = 2000
        connection.value = row.connection; conditions.value = row.conditions
        connection.dataset.questionConnection = String(index); conditions.dataset.questionConditions = String(index)
        connection.addEventListener('input', () => { if (liveRow()) row.connection = connection.value })
        conditions.addEventListener('input', () => { if (liveRow()) row.conditions = conditions.value })
        const remove = element('button', 'pack-candidate-open', '移除资料')
        remove.type = 'button'; remove.dataset.questionRemove = String(index)
        remove.addEventListener('click', () => {
          if (!liveRow()) return
          capture(); draft.rows.splice(index, 1); renderRows(); feedback.textContent = 'Observation explicitly removed from this question.'
        })
        box.append(field('与问题的关系', role), field('与问题有什么关系？', connection),
          field('日期、人群或适用条件（不清楚则填未知）', conditions), remove)
        rows.append(box)
      })
      proceed.disabled = gaps.length > 0 || continued
      const packs = new Set(draft.rows.map(row => row.source.pack_id)).size
      feedback.textContent = `${draft.rows.length} observation(s) from ${packs} pack(s) · ${gaps.length} unresolved snapshot gap(s). At least two packs are required.`
      if (!draft.rows.length) rows.append(element('p', 'pack-layer-empty', 'Select proposal sources in Pack layers, then reopen this composer to add them.'))
    }
    updateOpen = () => { if (live()) { capture(); renderRows() } }
    close.addEventListener('click', () => { if (live()) { capture(); closeCurrent() } })
    currentDialog.addEventListener('cancel', () => { if (live()) { capture(); closeCurrent() } })
    currentDialog.addEventListener('close', () => { active = false })
    save.addEventListener('click', () => {
      if (!live()) return
      capture()
      try { download(serializeQuestionDraft(draft)); feedback.textContent = 'Question packet downloaded with historical excerpts and your notes. Re-import checks current sources before intake.' }
      catch (error) { feedback.textContent = error.message }
    })
    form.addEventListener('submit', event => {
      event.preventDefault()
      if (!live()) return
      capture()
      try {
        const prepared = prepareCrossPackQuestion(draft, state)
        closeCurrent(); onPropose(prepared)
        continued = true; proceed.disabled = true
        status.textContent = 'Question copied into an editable intake candidate. Only its explicit Submit sends it; inspect Candidate flow before creating another copy.'
      } catch (error) { feedback.textContent = error.message; if (!currentDialog.open) { status.textContent = error.message; open() } }
    })
    form.append(heading, close, element('p', 'pack-layer-summary', 'Supporting, challenging and contextual are your labels. Different dates or conditions may explain apparent differences. No consensus, contradiction or accepted Book knowledge is inferred.'),
      field('你想研究什么问题？', question), field('范围与理由', scope), rows,
      field('什么证据会推翻这个想法？', rejection), feedback, save, proceed)
    dialog.append(form); document.body.append(dialog); renderRows(); dialog.showModal()
  }

  launch.addEventListener('click', () => {
    if (resumePending()) return
    if (dialog?.open) return
    invalidateImport()
    try { draft = appendQuestionSources(draft, getSelected()); open() }
    catch (error) { status.textContent = error.message }
  })
  upload.addEventListener('change', async () => {
    const file = upload.files?.[0]
    invalidateImport()
    const generation = importGeneration
    if (!file) return
    if (resumePending()) { upload.value = ''; return }
    if (dialog?.open) { status.textContent = 'Close the current question before importing a replacement.'; return }
    try {
      if (file.size > QUESTION_PACKET_LIMIT) throw Error('Choose a question JSON file no larger than 128 KiB.')
      const incoming = parseQuestionDraft(await file.text())
      if (generation !== importGeneration) return
      pendingImport.replaceChildren(element('p', 'pack-layer-summary', `Loaded ${incoming.rows.length} historical observation(s). Replacing affects only the unsent local question. Download that question first if you need it.`))
      const replace = element('button', 'pack-candidate-open', '替换本页草稿')
      replace.type = 'button'; replace.dataset.questionReplace = 'true'
      replace.addEventListener('click', () => {
        if (generation !== importGeneration || dialog?.open) return
        if (resumePending()) return
        invalidateImport()
        draft = incoming; dialog?.close(); open()
        status.textContent = 'Imported as an untrusted draft. Missing, incompatible or changed observations remain visible and block intake.'
      })
      const cancel = element('button', 'pack-candidate-open', '取消导入')
      cancel.type = 'button'; cancel.addEventListener('click', () => { if (generation === importGeneration) invalidateImport() })
      pendingImport.append(replace, cancel)
    } catch (error) { if (generation === importGeneration) { pendingImport.replaceChildren(); status.textContent = error.message } }
    finally { if (generation === importGeneration) upload.value = '' }
  })

  return { section, refresh(nextState) { state = nextState; updateOpen?.() } }
}

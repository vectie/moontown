// Contest Express extends the Challenge ledger with competition journeys.
export function safeExternalURL(value) {
  try { const url = new URL(value); return ['https:', 'http:'].includes(url.protocol) ? url.href : null } catch { return null }
}

export function filterFAQ(items, query) {
  const needle = query.trim().toLocaleLowerCase()
  return items.filter(item => `${item.category} ${item.question} ${item.answer}`.toLocaleLowerCase().includes(needle))
}

export function validateTracks(tracks) {
  if (!tracks.length) throw new Error('Add at least one competition track.')
  if (new Set(tracks.map(track => track.id)).size !== tracks.length) throw new Error('Every track needs a unique ID.')
  for (const track of tracks) {
    if (!/^[a-z0-9-]{1,64}$/.test(track.id) || !track.name.trim()) throw new Error('Each track needs a lowercase ID and name.')
    if (track.scoring_mode === 'metric') {
      if (!track.runner_key) throw new Error(`${track.name}: choose a registered benchmark runner.`)
      if (!track.metrics.length) throw new Error(`${track.name}: add at least one metric.`)
      if (new Set(track.metrics.map(metric => metric.id)).size !== track.metrics.length) throw new Error(`${track.name}: metric IDs must be unique.`)
      for (const metric of track.metrics) {
        if (!metric.id || !metric.label || !Number.isFinite(metric.baseline) || metric.baseline <= 0 || !Number.isFinite(metric.weight) || metric.weight <= 0) throw new Error(`${track.name}: metrics need a name, positive baseline, and positive weight.`)
      }
      for (const gate of track.gates) if (!track.metrics.some(metric => metric.id === gate.metric_id) || !Number.isFinite(gate.threshold)) throw new Error(`${track.name}: each qualification gate must reference a metric and threshold.`)
    }
  }
  return tracks
}

export function validateCompetitionCalendar(program, deadlineMs) {
  try { new Intl.DateTimeFormat('en', { timeZone: program.timezone }).format() } catch { throw new Error('Choose a valid IANA time zone, such as Asia/Shanghai or UTC.') }
  const open = Number(program.registration_open_ms), close = Number(program.registration_close_ms), submissions = Number(program.submission_open_ms), review = Number(program.review_close_ms), deadline = Number(deadlineMs)
  if (![open, close, submissions, review, deadline].every(Number.isFinite) || open > close || open > submissions || close > deadline || submissions >= deadline || review < deadline) throw new Error('Calendar order: registration opens before registration closes and submissions open; both close by the submission deadline; review closes after the deadline.')
  return program
}

export function parseCompetitionRubric(text, tracks) {
  if (!text.trim() && !tracks.some(track => track.scoring_mode === 'rubric')) return []
  const result = text.split('\n').map(line => line.trim()).filter(Boolean).map(line => {
    const [id, label, points, ...extra] = line.split('|').map(item => item.trim())
    if (extra.length || !/^[a-z0-9-]{1,64}$/.test(id || '') || !label || !/^[1-9]\d*$/.test(points || '')) throw new Error('Use id | Label | Max points for each rubric line.')
    return { id, label, max_points: Number(points) }
  })
  if (!result.length || new Set(result.map(item => item.id)).size !== result.length) throw new Error('Add unique rubric criteria for human review tracks.')
  return result
}

export function createEditorControl(document, key, value = '', options = {}) {
  const tag = options.choices ? 'select' : options.multiline ? 'textarea' : 'input'
  const control = document.createElement(tag)
  control.dataset.field = key
  if (tag === 'input') control.type = options.type || 'text'
  if (tag === 'select') for (const [id, title] of options.choices) {
    const option = document.createElement('option'); option.value = id; option.textContent = title; control.add(option)
  }
  if (tag === 'textarea') control.rows = 2
  if (options.required) control.required = true
  if (tag === 'input' && options.min !== undefined) control.min = options.min
  if (tag === 'input' && options.step) control.step = options.step
  if (tag !== 'select' && options.placeholder) control.placeholder = options.placeholder
  if (tag === 'input' && options.pattern) control.pattern = options.pattern
  if (tag !== 'select' && options.maxLength) control.maxLength = options.maxLength
  control.value = value
  return control
}

export function submissionStatus(submission, runs = [], evaluations = [], appeals = []) {
  const relevant = runs.filter(run => run.submission_id === submission.id)
  const latest = relevant[relevant.length - 1]
  const appeal = appeals.find(item => item.submission_id === submission.id && item.state === 'open')
  if (appeal) return 'Appeal open'
  if (latest?.state === 'approved' && latest.reason?.startsWith('Unranked: qualification gates failed')) return 'Approved · unranked'
  if (latest) return ({ queued: 'Queued', running: 'Running', failed: 'Run failed', review: 'Awaiting approval', approved: 'Approved · provisional', rejected: 'Rejected' })[latest.state] || latest.state
  return evaluations.some(item => item.submission_id === submission.id) ? 'Reviewed · provisional' : 'Awaiting review'
}

export function createCompetitionUI(context) {
  const { getState, getChallenge, getChallengeId, submit, showFeedback, setOptions, materialList, prettyTime, node, append, selectChallenge } = context
  const byId = id => document.getElementById(id)
  const list = value => value.split('\n').map(item => item.trim()).filter(Boolean)
  const uid = prefix => `${prefix}-${crypto.randomUUID()}`
  let currentTab = location.hash.slice(1) || 'challenge'
  let materialTeam = ''
  const form = byId('program-form')
  const fields = form.elements
  const program = () => getState()?.programs?.find(item => item.challenge_id === getChallengeId())
  const viewer = () => getState()?.viewer || { can_publish: true, can_evaluate: true, can_register_team: true, can_submit: true, local_operator: true }
  const actor = () => viewer().local_operator ? byId('evaluation-form').elements.reviewer.value.trim() || viewer().account_id || 'local-mayor' : viewer().account_id || byId('evaluation-form').elements.reviewer.value.trim() || 'local-mayor'
  const canReview = () => Boolean(viewer().can_evaluate && (!program() || program().evaluator_ids?.includes(viewer().local_operator ? actor() : viewer().account_id || 'local-mayor') || viewer().review_challenge_ids?.includes(getChallengeId())))
  const ownTeams = () => (getState()?.teams || []).filter(team => team.challenge_id === getChallengeId() && (team.is_member === true || team.members?.includes(viewer().account_id) || viewer().local_operator || !getState()?.viewer))
  const profile = team => getState()?.team_profiles?.find(item => item.team_id === team.id)

  function button(label, handler, style = 'button button-light') {
    const element = node('button', style, label); element.type = 'button'
    element.addEventListener('click', handler); return element
  }

  function externalLink(label, url) {
    const safe = safeExternalURL(url)
    if (!safe) return node('span', 'muted-note', label)
    const link = node('a', '', label); link.href = safe; link.target = '_blank'; link.rel = 'noopener noreferrer'; return link
  }

  function field(parent, key, label, value = '', options = {}) {
    const wrapper = node('label', '', label)
    const input = createEditorControl(document, key, value, options)
    wrapper.append(input); parent.append(wrapper); return input
  }

  function readRow(row) {
    const output = {}
    for (const input of row.querySelectorAll(':scope > label > [data-field], :scope > .editor-grid > label > [data-field]')) output[input.dataset.field] = input.type === 'number' ? Number(input.value) : input.value.trim()
    return output
  }

  function rowEditor(container, values, spec) {
    const row = node('div', 'editor-row')
    const grid = node('div', 'editor-grid')
    for (const [key, label, options] of spec) field(grid, key, label, values[key] ?? '', options || {})
    append(row, grid, button('Remove', () => row.remove(), 'text-button remove-row'))
    container.append(row); return row
  }

  const metricSpec = [['id', 'Metric ID', { required: true }], ['label', 'Metric label', { required: true }], ['unit', 'Unit', {}], ['direction', 'Ranking direction', { choices: [['min', 'Lower is better'], ['max', 'Higher is better']] }], ['baseline', 'Baseline', { type: 'number', min: '0.000001', step: 'any', required: true }], ['weight', 'Weight', { type: 'number', min: '0.000001', step: 'any', required: true }]]
  const gateSpec = [['id', 'Gate ID', { required: true }], ['label', 'Qualification rule', { required: true }], ['metric_id', 'Metric ID', { required: true }], ['comparison', 'Must be', { choices: [['gte', 'At least'], ['lte', 'At most']] }], ['threshold', 'Threshold', { type: 'number', step: 'any', required: true }]]
  const editorialSpecs = {
    prize: [['track_id', 'Track ID', { required: true }], ['place', 'Place', { required: true }], ['description', 'Prize', { required: true }]],
    partner: [['name', 'Partner name', { required: true }], ['url', 'Partner URL', { type: 'url', required: true }]],
    faq: [['category', 'Category', { required: true }], ['question', 'Question', { required: true }], ['answer', 'Answer', { required: true, multiline: true }]],
  }
  const editorId = { prize: 'prize-editors', partner: 'partner-editors', faq: 'faq-editors' }
  function updateRubricRequirement() {
    fields.rubric.required = [...byId('track-editors').querySelectorAll('[data-field="scoring_mode"]')].some(input => input.value === 'rubric')
  }

  function addTrack(value = {}) {
    const editor = node('fieldset', 'track-editor')
    append(editor, node('legend', '', value.name || 'Competition track'))
    const grid = node('div', 'editor-grid')
    field(grid, 'id', 'Track ID', value.id || '', { required: true, placeholder: 'voice-speed' })
    field(grid, 'name', 'Track name', value.name || '', { required: true })
    field(grid, 'description', 'Description & eligibility', value.description || '', { required: true, multiline: true })
    const mode = field(grid, 'scoring_mode', 'Evaluation', value.scoring_mode || 'rubric', { choices: [['rubric', 'Human rubric review'], ['metric', 'Measured benchmark + approval']] })
    field(grid, 'runner_key', 'Registered runner key', value.runner_key || '', { placeholder: 'Operator-configured runner name' })
    field(grid, 'required_materials', 'Required material kinds', (value.required_materials || ['source', 'report']).join('\n'), { multiline: true, placeholder: 'source\nreport\ncontainer' })
    editor.append(grid)
    const measured = node('div', 'metric-editor')
    const metrics = node('div', 'metric-rows'); const gates = node('div', 'gate-rows')
    append(measured, node('h4', '', 'Measured metrics'), metrics,
      button('Add metric', () => rowEditor(metrics, { direction: 'min', baseline: 1, weight: 1 }, metricSpec)),
      node('h4', '', 'Qualification gates'), gates, button('Add qualification gate', () => rowEditor(gates, {}, gateSpec)))
    for (const metric of value.metrics || []) rowEditor(metrics, metric, metricSpec)
    for (const gate of value.gates || []) rowEditor(gates, gate, gateSpec)
    const updateMode = () => { measured.hidden = mode.value !== 'metric'; for (const input of measured.querySelectorAll('input,select,textarea')) input.disabled = measured.hidden; updateRubricRequirement() }
    updateMode(); mode.addEventListener('change', updateMode)
    append(editor, measured, button('Remove track', () => { editor.remove(); updateRubricRequirement() }, 'text-button remove-row'))
    byId('track-editors').append(editor)
    updateRubricRequirement()
  }

  function tracksFromEditors() {
    return [...byId('track-editors').children].map(editor => {
      const track = readRow(editor)
      track.required_materials = list(track.required_materials)
      track.metrics = track.scoring_mode === 'metric' ? [...editor.querySelector('.metric-rows').children].map(readRow) : []
      track.gates = track.scoring_mode === 'metric' ? [...editor.querySelector('.gate-rows').children].map(readRow) : []
      if (track.scoring_mode === 'rubric') track.runner_key = ''
      return track
    })
  }

  function dateValue(value) {
    const millis = new Date(value).getTime()
    if (!Number.isFinite(millis)) throw new Error('Complete every calendar date.')
    return String(millis)
  }
  function localDate(value) {
    if (!Number(value)) return ''
    const date = new Date(Number(value)); return new Date(date.getTime() - date.getTimezoneOffset() * 60000).toISOString().slice(0, 16)
  }
  function collectProgram() {
    const challenge = getState()?.challenges?.find(item => item.id === fields.id.value.trim())
    const previous = getState()?.programs?.find(item => item.challenge_id === fields.id.value.trim())
    const tracks = validateTracks(tracksFromEditors())
    const brief = { id: fields.id.value.trim(), name: fields.name.value.trim(), topic: fields.topic.value.trim(),
      scope: fields.scope.value.trim(), possibility_wiki: fields.possibility_wiki.value.trim(),
      first_person_solution: fields.first_person_solution.value.trim(), deadline_ms: dateValue(fields.deadline_ms.value),
      benchmark_version: challenge?.benchmark_version || 1, benchmark_materials: list(fields.benchmark_materials.value),
      evaluation_materials: list(fields.evaluation_materials.value), rubric: parseCompetitionRubric(fields.rubric.value, tracks), published: challenge?.published || false }
    const record = { challenge_id: brief.id, state: previous?.state || 'draft', organizer: fields.organizer.value.trim(), timezone: fields.timezone.value.trim(),
      registration_open_ms: dateValue(fields.registration_open_ms.value), registration_close_ms: dateValue(fields.registration_close_ms.value),
      submission_open_ms: dateValue(fields.submission_open_ms.value), review_close_ms: dateValue(fields.review_close_ms.value),
      max_team_size: Number(fields.max_team_size.value), daily_submission_limit: Number(fields.daily_submission_limit.value),
      contact_url: fields.contact_url.value.trim(), tracks, evaluator_ids: list(fields.evaluator_ids.value),
      announcements: previous?.announcements || [],
      prizes: [...byId('prize-editors').children].map(readRow), partners: [...byId('partner-editors').children].map(readRow), faq: [...byId('faq-editors').children].map(readRow) }
    validateCompetitionCalendar(record, brief.deadline_ms)
    return { brief, program: record }
  }

  function loadBuilder(record, brief) {
    form.reset()
    for (const container of ['track-editors', 'prize-editors', 'partner-editors', 'faq-editors']) byId(container).replaceChildren()
    if (record && brief) {
      for (const key of ['id', 'name', 'topic', 'scope', 'possibility_wiki', 'first_person_solution']) fields[key].value = brief[key]
      for (const key of ['organizer', 'timezone', 'max_team_size', 'daily_submission_limit', 'contact_url']) fields[key].value = record[key]
      for (const key of ['registration_open_ms', 'registration_close_ms', 'submission_open_ms', 'review_close_ms']) fields[key].value = localDate(record[key])
      fields.deadline_ms.value = localDate(brief.deadline_ms)
      fields.benchmark_materials.value = (brief.benchmark_materials || []).join('\n')
      fields.evaluation_materials.value = (brief.evaluation_materials || []).join('\n')
      fields.rubric.value = (brief.rubric || []).map(item => `${item.id} | ${item.label} | ${item.max_points}`).join('\n')
      fields.evaluator_ids.value = (record.evaluator_ids || []).join('\n')
      for (const track of record.tracks) addTrack(track)
      if (!record.tracks.length) addTrack()
      for (const kind of Object.keys(editorialSpecs)) for (const item of record[{ prize: 'prizes', partner: 'partners', faq: 'faq' }[kind]] || []) rowEditor(byId(editorId[kind]), item, editorialSpecs[kind])
    } else addTrack()
    byId('program-preview').hidden = true
  }

  function switchTab(id, updateHash = true) {
    const tab = document.querySelector(`[data-tab="${id}"]`)
    if (!tab || tab.hidden) id = 'challenge'
    currentTab = id
    for (const button of document.querySelectorAll('[data-tab]')) {
      const selected = button.dataset.tab === id
      if (selected) button.setAttribute('aria-current', 'page'); else button.removeAttribute('aria-current')
      byId(button.dataset.tab).hidden = !selected
    }
    if (updateHash) history.replaceState(null, '', `#${id}`)
  }

  function renderPublic(record, brief) {
    byId('event-state').textContent = record ? ({ draft: 'Draft · visible to Mayor', open: 'Open competition', paused: 'Paused', evaluating: 'Evaluation period', final: 'Final results' }[record.state] || record.state) : brief ? 'Community challenge' : 'No competition selected'
    const calendar = byId('event-calendar'); calendar.replaceChildren()
    if (record) for (const [label, millis] of [['Registration opens', record.registration_open_ms], ['Registration closes', record.registration_close_ms], ['Submissions open', record.submission_open_ms], ['Submission deadline', brief?.deadline_ms], ['Review closes', record.review_close_ms]]) calendar.append(append(node('div', 'milestone'), node('strong', '', label), node('span', '', prettyTime(millis))))
    if (record) calendar.append(node('p', 'muted-note', `Calendar shown in your device time zone. Organizer time zone: ${record.timezone} (descriptive). Saved UTC timestamps determine competition windows. Daily submission quotas reset at 00:00 UTC.`))
    const prizes = byId('event-prizes'); prizes.replaceChildren()
    if (record) {
      prizes.append(node('h3', '', `Hosted by ${record.organizer}`))
      if (record.prizes?.length) prizes.append(node('h4', '', 'Prizes'), ...record.prizes.map(item => node('p', '', `${record.tracks.find(track => track.id === item.track_id)?.name || item.track_id} · ${item.place}: ${item.description}`)))
      if (record.partners?.length) prizes.append(node('h4', '', 'Partners'), ...record.partners.map(item => append(node('p'), externalLink(item.name, item.url))))
      if (record.contact_url) prizes.append(externalLink('Contact the organizers ↗', record.contact_url))
    }
    const tracks = byId('track-list'); tracks.replaceChildren()
    if (!record) tracks.append(node('p', 'empty-state', 'This community challenge uses the shared Mayor’s rubric.'))
    for (const track of record?.tracks || []) {
      const article = node('article', 'track-summary')
      append(article, node('p', 'eyebrow', track.scoring_mode === 'metric' ? 'Measured benchmark · reviewer approval' : 'Human rubric review'), node('h3', '', track.name), node('p', '', track.description), node('h4', '', 'Required submission materials'), materialList(track.required_materials))
      for (const metric of track.metrics || []) article.append(node('p', '', `${metric.label} (${metric.unit || 'value'}) · ${metric.direction === 'min' ? 'lower' : 'higher'} is better · baseline ${metric.baseline} · weight ${metric.weight}`))
      for (const gate of track.gates || []) article.append(node('p', 'qualification-rule', `${gate.label}: ${gate.metric_id} ${gate.comparison === 'gte' ? '≥' : '≤'} ${gate.threshold}`))
      tracks.append(article)
    }
    byId('policy-detail').replaceChildren(...(record ? [node('h3', '', 'Team & submission rules'), node('p', '', `One team per account in this competition. Up to ${record.max_team_size} members per team, with invitations approved by each member. Up to ${record.daily_submission_limit} submissions per team each day; the quota resets at 00:00 UTC. Each receipt records the benchmark version used.`), node('p', '', 'Measured results appear after a reviewer checks the evidence and approves them. Qualification gates must pass. Results remain provisional until the Mayor finalizes the event.')] : []))
    const stories = byId('story-list'); stories.replaceChildren()
    for (const item of [...(record?.announcements || [])].sort((a, b) => Number(b.published_ms) - Number(a.published_ms))) stories.append(append(node('article', 'story'), node('p', 'eyebrow', prettyTime(item.published_ms)), node('h3', '', item.title), node('p', 'preserve-text', item.body)))
    if (!stories.children.length) stories.append(node('p', 'empty-state', 'The Mayor’s updates and competition stories will appear here.'))
    renderFAQ()
  }

  function renderFAQ() {
    const target = byId('faq-list'); target.replaceChildren()
    const items = filterFAQ(program()?.faq || [], byId('faq-search').value)
    for (const item of items) {
      const details = node('details', 'faq-item')
      append(details, node('summary', '', item.question), node('p', 'eyebrow', item.category), node('p', 'preserve-text', item.answer)); target.append(details)
    }
    if (!items.length) target.append(node('p', 'empty-state', byId('faq-search').value ? 'No matching questions. Try another word or contact the organizers.' : 'No FAQ published yet. Check Tracks & rules for competition policies.'))
  }

  function renderBoard(record, brief) {
    const picker = byId('board-track'); picker.closest('label').hidden = !record
    if (!record || !brief) return
    setOptions(picker, record.tracks.map(track => [track.id, track.name]), 'Choose track')
    if (!picker.value) picker.value = record.tracks[0]?.id || ''
    const track = record.tracks.find(item => item.id === picker.value)
    const entries = getState()?.competition_boards?.[`${brief.id}:${picker.value}`] || []
    const target = byId('leaderboard-content'); target.replaceChildren(); target.className = 'card leaderboard-card'
    if (!entries.length) { target.append(node('p', 'empty-state', record.state === 'draft' ? 'The board opens after publication and approved reviews.' : 'No approved results for this track yet. Pending and failed runs never rank.')); return }
    const table = node('table'); const head = node('thead'); const body = node('tbody'); const row = node('tr')
    for (const title of ['Rank', 'Team', 'Score', ...(track?.metrics || []).map(metric => `${metric.label}${metric.unit ? ` (${metric.unit})` : ''}`), 'Status', 'Reviewed']) row.append(node('th', '', title))
    head.append(row)
    for (const entry of entries) {
      const tr = node('tr'); append(tr, node('td', 'rank-cell', `#${entry.rank}`), node('td', 'team-cell', entry.team_name), node('td', 'score-cell', Number(entry.score).toFixed(3)))
      for (const metric of track?.metrics || []) tr.append(node('td', '', String(entry.metrics?.find(item => item.metric_id === metric.id)?.value ?? '—')))
      append(tr, node('td', '', record.state === 'final' ? 'Final' : entry.status || 'Provisional'), node('td', '', prettyTime(entry.reviewed_ms)))
      body.append(tr)
    }
    append(table, node('caption', 'visually-hidden', `Champion Wall for ${track?.name || 'track'}`), head, body); target.append(table)
  }

  function addMaterial(value = {}) {
    return rowEditor(byId('package-materials'), value, [['kind', 'Material kind', { required: true, placeholder: 'source' }], ['url', 'Material URL', { type: 'url', required: true }], ['sha256', 'SHA-256 checksum', { required: true, pattern: '[a-fA-F0-9]{64}', maxLength: 64, placeholder: '64 hexadecimal characters from the exact file' }]])
  }
  function resetMaterials() {
    byId('package-materials').replaceChildren()
    const team = ownTeams().find(item => item.id === byId('submission-team').value)
    const track = program()?.tracks.find(item => item.id === profile(team || {})?.track_id)
    for (const kind of track?.required_materials || []) addMaterial({ kind })
  }
  function submissionPackage(submission) {
    const team = ownTeams().find(item => item.id === submission.team_id)
    return { submission_id: submission.id, track_id: profile(team || {})?.track_id || '', benchmark_version: getChallenge()?.benchmark_version || 1,
      materials: [...byId('package-materials').children].map(readRow) }
  }

  function renderInvites() {
    const target = byId('invitation-list'); target.replaceChildren()
    for (const invitation of getState()?.invitations || []) {
      const team = getState().teams.find(item => item.id === invitation.team_id)
      if (team && team.challenge_id !== getChallengeId()) continue
      const article = node('article', 'receipt')
      append(article, node('strong', '', `${team?.name || invitation.team_id} · invitation ${invitation.state}`), node('p', '', `Invitation for ${invitation.invitee_id}`))
      if (invitation.state === 'pending' && (invitation.invitee_id === viewer().account_id || viewer().local_operator)) for (const accept of [true, false]) article.append(button(accept ? 'Accept invitation' : 'Decline invitation', () => submit('respond-invitation', { invitation_id: invitation.id, member_id: viewer().account_id || invitation.invitee_id, accept }, 'team', accept ? 'Invitation accepted.' : 'Invitation declined.')))
      target.append(article)
    }
  }

  function renderTeamManagement() {
    if (!program()) return
    const target = byId('team-list'); target.replaceChildren()
    for (const team of ownTeams()) {
      const meta = profile(team); const captain = meta?.captain_id === viewer().account_id || viewer().local_operator
      const article = node('article', 'team-management')
      append(article, node('h3', '', team.name), node('p', '', `${program().tracks.find(track => track.id === meta?.track_id)?.name || meta?.track_id || ''} · ${meta?.affiliation || 'Independent'} · captain ${meta?.captain_id || ''}`))
      for (const member of team.members || []) {
        const line = append(node('p', 'member-line'), node('span', '', member))
        if (captain && member !== meta?.captain_id) line.append(button('Remove member', () => submit('remove-member', { team_id: team.id, captain_id: meta.captain_id, member_id: member }, 'team', 'Member removed.'), 'text-button'))
        article.append(line)
      }
      if (captain && program().state !== 'final') {
        const inviteForm = node('form', 'inline-form'); const input = field(inviteForm, 'invitee_id', 'Invite account', '', { required: true, placeholder: 'Member account ID' })
        const invite = node('button', 'button button-light', 'Send invitation'); invite.type = 'submit'; inviteForm.append(invite)
        inviteForm.addEventListener('submit', async event => { event.preventDefault(); if (await submit('invite-member', { id: uid('invitation'), team_id: team.id, inviter_id: meta.captain_id, invitee_id: input.value.trim() }, 'team', 'Invitation sent. The member can accept from their workbench.')) input.value = '' })
        article.append(inviteForm)
      }
      target.append(article)
    }
  }

  function renderReceipts() {
    const target = byId('own-submissions'); target.replaceChildren()
    const teamIds = new Set(ownTeams().map(team => team.id))
    const submissions = (getState()?.submissions || []).filter(item => item.challenge_id === getChallengeId() && teamIds.has(item.team_id))
    if (!submissions.length) { target.append(node('p', 'muted-note', 'Your submission versions and review feedback will appear here.')); return }
    target.append(node('h3', '', 'Your submission receipts'))
    for (const submission of [...submissions].reverse()) {
      const packageRecord = getState()?.submission_packages?.find(item => item.submission_id === submission.id)
      const runs = getState()?.benchmark_runs || []; const reviews = getState()?.evaluations || []; const appeals = getState()?.appeals || []
      const receipt = node('article', 'receipt')
      append(receipt, node('h4', '', `Version ${submission.version} · ${program()?.state === 'final' ? 'Final' : submissionStatus(submission, runs, reviews, appeals)}`), node('p', 'muted-note', `${prettyTime(submission.submitted_ms)} · benchmark v${packageRecord?.benchmark_version || getChallenge()?.benchmark_version} · ${submission.id}`), externalLink('Open submitted artifact ↗', submission.artifact_url), node('p', 'preserve-text', submission.first_person_solution))
      if (packageRecord) receipt.append(materialList(packageRecord.materials.map(item => item.url)))
      for (const review of reviews.filter(item => item.submission_id === submission.id)) {
        receipt.append(node('p', '', `Review: ${review.total} points · benchmark v${review.benchmark_version}`))
        for (const score of review.scores || []) receipt.append(node('p', '', `${score.criterion_id}: ${score.points} · ${score.evidence}`))
      }
      for (const run of runs.filter(item => item.submission_id === submission.id)) {
        receipt.append(node('p', '', `Benchmark ${run.state}${run.reason ? ` · ${run.reason}` : ''}`))
        for (const metric of run.metrics || []) receipt.append(node('p', '', `${metric.metric_id}: ${metric.value}`))
        if (run.evidence?.length) receipt.append(materialList(run.evidence))
      }
      for (const appeal of appeals.filter(item => item.submission_id === submission.id)) receipt.append(node('p', '', `Appeal ${appeal.state}: ${appeal.reason}${appeal.resolution ? ` · ${appeal.resolution}` : ''}`))
      if (program() && program().state !== 'final' && !appeals.some(item => item.submission_id === submission.id && item.state === 'open')) {
        const details = node('details'); details.append(node('summary', '', 'Ask for a review of this result'))
        const appealForm = node('form'); const reason = field(appealForm, 'reason', 'Reason & evidence', '', { required: true, multiline: true }); const open = node('button', 'button button-light', 'Open appeal'); open.type = 'submit'; appealForm.append(open)
        appealForm.addEventListener('submit', async event => { event.preventDefault(); await submit('open-appeal', { id: uid('appeal'), submission_id: submission.id, member_id: viewer().account_id || ownTeams().find(team => team.id === submission.team_id)?.members?.[0], reason: reason.value.trim() }, 'submission', 'Appeal recorded. The Mayor can respond from the review desk.') })
        details.append(appealForm); receipt.append(details)
      }
      target.append(receipt)
    }
  }

  function renderReviewQueue() {
    const target = byId('review-queue'); target.replaceChildren()
    const reviewer = canReview()
    if (!reviewer) { target.append(node('p', 'empty-state', 'Your account is not assigned to review this competition. Add the evaluator account in the Mayor’s competition builder.')); if (!viewer().can_publish) return }
    const submissions = (getState()?.submissions || []).filter(item => item.challenge_id === getChallengeId())
    if (!submissions.length) target.append(node('p', 'empty-state', 'No submissions waiting for review.'))
    for (const submission of [...submissions].reverse()) {
      const packageRecord = getState()?.submission_packages?.find(item => item.submission_id === submission.id)
      const track = program()?.tracks.find(item => item.id === packageRecord?.track_id)
      const row = node('article', 'review-item')
      append(row, node('h3', '', `${getState().teams.find(team => team.id === submission.team_id)?.name || submission.team_id} · version ${submission.version}`), node('p', 'eyebrow', `${track?.name || 'Shared rubric'} · benchmark v${packageRecord?.benchmark_version || getChallenge()?.benchmark_version}`), externalLink('Inspect artifact ↗', submission.artifact_url), node('p', 'preserve-text', submission.first_person_solution))
      if (packageRecord) for (const material of packageRecord.materials) row.append(append(node('p'), externalLink(`${material.kind} ↗`, material.url), node('small', 'muted-note', material.sha256 ? ` SHA-256 ${material.sha256}` : '')))
      if (reviewer && (!track || track.scoring_mode === 'rubric')) row.append(button('Review with rubric', () => { byId('evaluation-submission').value = submission.id; byId('evaluation-form').scrollIntoView({ block: 'start' }) }))
      const runs = (getState()?.benchmark_runs || []).filter(item => item.submission_id === submission.id)
      if (reviewer && track?.scoring_mode === 'metric' && program()?.state !== 'final' && !runs.length) row.append(button('Queue benchmark', () => submit('queue-benchmark', { id: uid('run'), submission_id: submission.id, reviewer_id: actor() }, 'review', 'Benchmark queued. The registered worker will run it; status updates here automatically.')))
      for (const run of runs) {
        const details = node('div', 'run-details')
        append(details, node('strong', '', `Run ${run.state}`), node('p', '', run.reason || ''))
        for (const metric of run.metrics || []) details.append(node('p', '', `${metric.metric_id}: ${metric.value}`))
        if (run.evidence?.length) details.append(materialList(run.evidence))
        const evidence = node('details'); append(evidence, node('summary', '', 'Evidence receipt'), node('p', 'muted-note preserve-text', `Run: ${run.id}\nWorker: ${run.worker_run_id || 'pending'}\nInput: ${run.input_hash || 'pending'}\nOutput: ${run.output_hash || 'pending'}\nBenchmark v${run.benchmark_version}`)); details.append(evidence)
        if (program()?.state !== 'final') {
          if (run.state === 'queued' || run.state === 'running') details.append(node('p', 'muted-note', run.state === 'queued' ? 'Waiting for the registered benchmark worker. This page updates automatically.' : 'Worker running. The evidence receipt will appear when it finishes.'))
          if (reviewer && run.state === 'failed') details.append(button('Retry benchmark', () => submit('retry-benchmark', { run_id: run.id }, 'review', 'Benchmark queued for retry.')))
          if (reviewer && run.state === 'review') {
            details.append(button('Approve measured result', () => submit('approve-benchmark', { run_id: run.id, reviewer_id: actor() }, 'review', 'Measured result approved. The Champion Wall has updated.')))
            details.append(button('Reject measured result', () => submit('reject-benchmark', { run_id: run.id, reviewer_id: actor() }, 'review', 'Measured result rejected. It will not rank on the Champion Wall.')))
          }
          if (viewer().can_publish && ['queued', 'running'].includes(run.state)) {
            const recovery = node('details'); recovery.append(node('summary', '', 'Recover an interrupted benchmark'))
            const recoveryForm = node('form'); const reason = field(recoveryForm, 'reason', 'Recovery reason', '', { required: true, multiline: true })
            const recover = node('button', 'button button-light', 'Record interruption'); recover.type = 'submit'; recoveryForm.append(recover)
            recoveryForm.addEventListener('submit', async event => { event.preventDefault(); await submit('recover-interrupted-benchmark', { run_id: run.id, reason: reason.value.trim() }, 'review', 'Interruption recorded. The failed attempt is preserved; a reviewer can retry it.') })
            append(recovery, node('p', 'muted-note', 'Explain why this queued or running attempt needs recovery. Its receipt stays in the event record.'), recoveryForm); details.append(recovery)
          }
        }
        row.append(details)
      }
      target.append(row)
    }
    for (const appeal of getState()?.appeals || []) {
      if (!submissions.some(item => item.id === appeal.submission_id)) continue
      const row = append(node('article', 'receipt'), node('h4', '', `Appeal · ${appeal.state}`), node('p', '', appeal.reason), node('p', '', appeal.resolution || ''))
      if (appeal.state === 'open' && viewer().can_resolve_appeal) {
        const resolveForm = node('form'); const resolution = field(resolveForm, 'resolution', 'Decision & explanation', '', { required: true, multiline: true }); const save = node('button', 'button button-light', 'Resolve appeal'); save.type = 'submit'; resolveForm.append(save)
        resolveForm.addEventListener('submit', async event => { event.preventDefault(); await submit('resolve-appeal', { appeal_id: appeal.id, resolution: resolution.value.trim() }, 'review', 'Appeal resolved.') }); row.append(resolveForm)
      }
      target.append(row)
    }
  }

  function renderControls() {
    const target = byId('program-controls'); target.replaceChildren()
    const record = program()
    if (!record) { target.append(node('p', '', 'Create a new competition draft below. Existing community challenges keep their original team and scoring workflow.')); return }
    append(target, node('h3', '', `${getChallenge()?.name} · ${record.state}`), node('p', 'card-intro', 'Review the saved brief in Overview and Tracks & rules. Publication opens the configured registration window. Finalization freezes results.'))
    const row = node('div', 'action-row')
    if (record.state === 'draft') {
      const missing = [...(getState()?.program_readiness?.[record.challenge_id] || [])]
      if (!record.evaluator_ids?.length) missing.push('Assign at least one evaluator account.')
      if (!record.tracks?.length) missing.push('Add a competition track.')
      if (!(getChallenge()?.benchmark_materials?.length && getChallenge()?.evaluation_materials?.length)) missing.push('Add benchmark materials and private evaluation guidance.')
      if (Number(record.registration_close_ms) <= Date.now() || Number(getChallenge()?.deadline_ms) <= Date.now()) missing.push('Set future registration and submission closing dates.')
      target.append(node('h4', '', 'Publication checklist'), node('p', '', missing.length ? missing.join(' ') : 'Brief, materials, tracks, evaluator roster and calendar are ready for publication.'))
      const publish = button('Publish competition', () => submit('publish-program', { challenge_id: record.challenge_id }, 'program', 'Competition published. Registration follows your calendar.'), 'button button-primary')
      publish.disabled = missing.length > 0; row.append(publish)
    }
    for (const [next, label] of record.state === 'open' ? [['paused', 'Pause competition'], ['evaluating', 'Enter evaluation period']] : record.state === 'paused' ? [['open', 'Resume competition'], ['evaluating', 'Enter evaluation period']] : record.state === 'evaluating' ? [['final', 'Finalize results']] : []) {
      const transitionForm = node('form', 'inline-form'); const reason = field(transitionForm, 'reason', `${label}: reason`, '', { required: true }); const change = node('button', 'button button-light', label); change.type = 'submit'; transitionForm.append(change)
      transitionForm.addEventListener('submit', async event => { event.preventDefault(); await submit('transition-program', { challenge_id: record.challenge_id, state: next, reason: reason.value.trim() }, 'program', `Competition is now ${next}.`) }); row.append(transitionForm)
    }
    target.append(row)
    target.append(button('Sync MoonBook & workspaces', () => submit('sync-workspaces', { challenge_id: record.challenge_id }, 'program', 'Sync attempt recorded. Inspect the workspace status below.')))
    const sync = getState()?.workspace_sync
    if (sync) target.append(node('p', sync.ready === false ? 'form-feedback is-error' : 'muted-note', typeof sync === 'string' ? sync : `${sync.message || 'Workspace synchronization receipt is available.'}${sync.ready ? ` · ${sync.book_count} books · revision ${sync.synced_revision}` : ''}`))
    const history = (getState()?.program_history || []).filter(item => item.challenge_id === record.challenge_id)
    if (history.length) {
      const details = node('details'); details.append(node('summary', '', 'Archived program revisions'))
      for (const item of history) details.append(node('p', 'muted-note', `Archived ${item.state} program · ${item.tracks?.length || 0} tracks · registration closes ${prettyTime(item.registration_close_ms)} · review closes ${prettyTime(item.review_close_ms)}`))
      target.append(details)
    }
    if (record.announcements?.length) {
      const timeline = node('details'); timeline.append(node('summary', '', 'Published updates & lifecycle receipts'))
      for (const item of [...record.announcements].reverse()) timeline.append(node('p', 'muted-note', `${prettyTime(item.published_ms)} · ${item.title}`), node('p', 'preserve-text', item.body))
      target.append(timeline)
    }
  }

  function render() {
    const state = getState(); const record = program(); const brief = getChallenge(); const access = viewer()
    byId('viewer-status').textContent = access.account_id ? `${access.role || 'Town member'} · ${access.account_id}` : access.local_operator || !state.viewer ? 'Local Mayor workspace' : 'Public visitor'
    for (const [tab, allowed] of [['teams', Boolean(access.can_register_team || access.can_submit || access.account_id)], ['reviews', Boolean(access.can_evaluate)], ['mayor', Boolean(access.can_publish)]]) document.querySelector(`[data-tab="${tab}"]`).hidden = !allowed
    switchTab(currentTab, false)
    const heroLink = document.querySelector('.hero-actions .button-primary')
    heroLink.textContent = access.can_submit || access.can_register_team ? 'Open my workbench' : 'Sign in to compete'; heroLink.href = access.can_submit || access.can_register_team ? '#teams' : '/contest-express/login'
    for (const element of document.querySelectorAll('.program-field')) element.hidden = !record
    byId('join-form').parentElement.hidden = Boolean(record) || !access.can_join_team
    const canParticipate = !record || (record.state === 'open' && Number(record.registration_open_ms) <= Date.now() && Number(record.registration_close_ms) >= Date.now())
    const canSubmit = !record || (record.state === 'open' && Number(record.submission_open_ms) <= Date.now() && Number(brief?.deadline_ms) >= Date.now())
    byId('team-form').parentElement.hidden = !access.can_register_team || Boolean(record && ownTeams().length && !access.local_operator)
    byId('team-form').querySelector('button[type="submit"]').disabled = !canParticipate || !brief
    byId('submission-form').querySelector('button[type="submit"]').disabled = !canSubmit || !ownTeams().length
    byId('participation-status').textContent = !brief ? 'Choose an open competition before creating a team.' : !access.account_id && !access.local_operator && state.viewer ? 'Sign in to register, accept invitations, and submit your work.' : record ? `${record.state === 'final' ? 'Final results are frozen.' : !canParticipate ? 'Team registration is outside its configured window.' : 'Registration is open.'} ${canSubmit ? 'Submissions are open.' : 'Submissions are currently closed.'}` : 'Register a team and submit your first person solution.'
    setOptions(byId('registration-track'), (record?.tracks || []).map(track => [track.id, track.name]), 'Choose a track')
    if (!byId('registration-track').value && record?.tracks.length === 1) byId('registration-track').value = record.tracks[0].id
    byId('registration-track').required = Boolean(record)
    const teamSelect = byId('submission-team'); if (!teamSelect.value && ownTeams().length === 1) teamSelect.value = ownTeams()[0].id
    if (materialTeam !== `${getChallengeId()}:${teamSelect.value}`) { materialTeam = `${getChallengeId()}:${teamSelect.value}`; resetMaterials() }
    renderPublic(record, brief); renderBoard(record, brief); renderInvites(); renderTeamManagement(); renderReceipts(); renderReviewQueue(); renderControls()
    byId('evaluation-form').parentElement.hidden = Boolean(record && (record.tracks.every(track => track.scoring_mode !== 'rubric') || byId('evaluation-submission').options.length <= 1))
    byId('evaluation-form').querySelector('button[type="submit"]').disabled = record?.state === 'final' || !brief || !canReview()
    if (access.account_id && (!access.local_operator || !byId('evaluation-form').elements.reviewer.value)) byId('evaluation-form').elements.reviewer.value = access.account_id
    byId('benchmark-form').querySelector('button[type="submit"]').disabled = record?.state === 'final' || !brief
    byId('load-program').disabled = !record || !brief
    if (!fields.evaluator_ids.value && !fields.id.value) fields.evaluator_ids.value = access.account_id || 'local-mayor'
  }

  document.querySelectorAll('[data-tab]').forEach(tab => tab.addEventListener('click', () => switchTab(tab.dataset.tab)))
  document.querySelectorAll('.hero-actions a[href^="#"]').forEach(link => link.addEventListener('click', event => { if (link.getAttribute('href').startsWith('#')) { event.preventDefault(); switchTab(link.hash.slice(1)) } }))
  window.addEventListener('hashchange', () => switchTab(location.hash.slice(1), false))
  byId('faq-search').addEventListener('input', renderFAQ)
  byId('evaluation-form').elements.reviewer.addEventListener('change', () => { renderReviewQueue(); byId('evaluation-form').querySelector('button[type="submit"]').disabled = !canReview() || program()?.state === 'final' })
  byId('board-track').addEventListener('change', () => renderBoard(program(), getChallenge()))
  byId('submission-team').addEventListener('change', resetMaterials)
  byId('add-material').addEventListener('click', () => addMaterial())
  byId('add-track').addEventListener('click', () => addTrack())
  document.querySelectorAll('[data-add-editor]').forEach(button => button.addEventListener('click', () => rowEditor(byId(editorId[button.dataset.addEditor]), {}, editorialSpecs[button.dataset.addEditor])))
  byId('load-program').addEventListener('click', () => { if (program()) loadBuilder(program(), getChallenge()) })
  byId('new-program').addEventListener('click', () => loadBuilder())
  byId('preview-program').addEventListener('click', () => {
    try {
      if (!form.reportValidity()) return
      const payload = collectProgram(); const target = byId('program-preview'); target.replaceChildren()
      append(target, node('p', 'eyebrow', 'Public preview · unsaved'), node('h3', '', payload.brief.name), node('p', '', payload.brief.topic), node('p', 'preserve-text', payload.brief.scope), node('p', '', `Hosted by ${payload.program.organizer} · ${payload.program.tracks.length} tracks · up to ${payload.program.max_team_size} members per team`), node('p', '', `Deadline ${prettyTime(payload.brief.deadline_ms)}`), node('h4', '', 'Possibility wiki'), node('p', 'preserve-text', payload.brief.possibility_wiki), node('h4', '', 'First person solution prompt'), node('p', 'preserve-text', payload.brief.first_person_solution), node('h4', '', 'Benchmark materials'), materialList(payload.brief.benchmark_materials))
      target.append(node('h4', '', 'Calendar & rules'), node('p', '', `Registration ${prettyTime(payload.program.registration_open_ms)} – ${prettyTime(payload.program.registration_close_ms)}. Submissions open ${prettyTime(payload.program.submission_open_ms)}. Review closes ${prettyTime(payload.program.review_close_ms)}. Up to ${payload.program.daily_submission_limit} submissions per team daily; quota resets at 00:00 UTC. Calendar shown in your device time zone; organizer time zone ${payload.program.timezone} is descriptive. Saved UTC timestamps determine competition windows.`))
      for (const track of payload.program.tracks) {
        target.append(node('h4', '', track.name), node('p', '', track.description), node('p', '', `Required materials: ${track.required_materials.join(', ') || 'None'}`))
        for (const metric of track.metrics) target.append(node('p', '', `${metric.label} · ${metric.unit} · ${metric.direction === 'min' ? 'lower' : 'higher'} is better · baseline ${metric.baseline} · weight ${metric.weight}`))
        for (const gate of track.gates) target.append(node('p', '', `${gate.label}: ${gate.metric_id} ${gate.comparison === 'gte' ? '≥' : '≤'} ${gate.threshold}`))
      }
      if (payload.program.prizes.length) target.append(node('h4', '', 'Prizes'), ...payload.program.prizes.map(item => node('p', '', `${item.track_id} · ${item.place}: ${item.description}`)))
      if (payload.program.partners.length) target.append(node('h4', '', 'Partners'), ...payload.program.partners.map(item => externalLink(item.name, item.url)))
      if (payload.program.faq.length) target.append(node('h4', '', 'FAQ'), ...payload.program.faq.flatMap(item => [node('strong', '', item.question), node('p', 'preserve-text', item.answer)]))
      target.hidden = false; target.scrollIntoView({ block: 'nearest' })
    } catch (error) { showFeedback('program', error.message, true) }
  })
  form.addEventListener('submit', async event => {
    event.preventDefault()
    try {
      const payload = collectProgram()
      if (await submit('save-program', payload, 'program', 'Draft / amendment saved. Preview the competition before publishing.')) selectChallenge(payload.brief.id)
    } catch (error) { showFeedback('program', error.message, true) }
  })
  byId('announcement-form').addEventListener('submit', async event => {
    event.preventDefault(); const form = event.currentTarget
    if (!program()) return showFeedback('announcement', 'Select a saved competition first.', true)
    if (await submit('announce', { challenge_id: getChallengeId(), id: uid('story'), title: form.elements.title.value.trim(), body: form.elements.body.value.trim() }, 'announcement', 'Update published to Stories & updates.')) form.reset()
  })
  loadBuilder()
  return { render, submissionPackage, resetMaterials }
}

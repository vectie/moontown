const API_URL = '/api/contest-express/hackathons'
const POLL_INTERVAL_MS = 5000

export function deriveLeaderboard(state, challengeId) {
  const challenge = state.challenges.find(item => item.id === challengeId)
  if (!challenge) return []
  const entries = []
  for (const team of state.teams.filter(item => item.challenge_id === challengeId)) {
    let best = null
    for (const submission of state.submissions.filter(item =>
      item.challenge_id === challengeId && item.team_id === team.id)) {
      let latest = null
      for (const evaluation of (state.evaluations || []).filter(item =>
        item.submission_id === submission.id &&
        item.benchmark_version === challenge.benchmark_version)) {
        if (!latest || Number(evaluation.evaluated_ms) >= Number(latest.evaluated_ms)) {
          latest = evaluation
        }
      }
      if (latest && (!best || latest.total > best.total ||
          (latest.total === best.total &&
            Number(latest.evaluated_ms) < Number(best.evaluated_ms)))) {
        best = { team_id: team.id, team_name: team.name,
          submission_id: submission.id, total: latest.total,
          evaluated_ms: latest.evaluated_ms }
      }
    }
    if (best) entries.push(best)
  }
  entries.sort((left, right) => right.total - left.total ||
    left.evaluated_ms - right.evaluated_ms ||
    left.team_id.localeCompare(right.team_id))
  return entries.map((entry, index) => ({ ...entry, rank: index + 1 }))
}

export function parseRubric(text) {
  const criteria = text.split('\n').map(line => line.trim()).filter(Boolean)
    .map(line => {
      const [id, label, points, ...extra] = line.split('|').map(part => part.trim())
      if (extra.length || !/^[a-z0-9-]{1,64}$/.test(id || '') ||
          !label || !/^[1-9]\d*$/.test(points || '')) {
        throw new Error('Use “id | Label | Max points” for every rubric line.')
      }
      return { id, label, max_points: Number(points) }
    })
  if (!criteria.length || new Set(criteria.map(item => item.id)).size !== criteria.length) {
    throw new Error('Add at least one criterion with a unique ID.')
  }
  return criteria
}

function lines(value) {
  return value.split('\n').map(item => item.trim()).filter(Boolean)
}

function rubricText(rubric) {
  return rubric.map(item => `${item.id} | ${item.label} | ${item.max_points}`).join('\n')
}

function node(tag, className, text) {
  const element = document.createElement(tag)
  if (className) element.className = className
  if (text !== undefined) element.textContent = text
  return element
}

function append(parent, ...children) {
  parent.append(...children)
  return parent
}

function materialList(items) {
  const list = node('ul', 'material-list')
  for (const item of items) {
    const row = node('li')
    let url
    try { url = new URL(item) } catch { /* Plain text material. */ }
    if (url && ['http:', 'https:'].includes(url.protocol)) {
      const link = node('a', '', item)
      link.href = url.href
      link.target = '_blank'
      link.rel = 'noopener noreferrer'
      row.append(link)
    } else {
      row.textContent = item
    }
    list.append(row)
  }
  return list
}

function labeledBlock(label, value) {
  return append(node('div', 'brief-block'), node('h4', '', label), node('p', '', value))
}

function prettyTime(milliseconds) {
  const date = new Date(Number(milliseconds))
  return Number.isNaN(date.valueOf()) ? 'Date unavailable' :
    new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(date)
}

async function apiGet() {
  const response = await fetch(API_URL, { cache: 'no-store', credentials: 'same-origin' })
  const data = await response.json()
  if (!response.ok) throw new Error(data.error || `Request failed (${response.status})`)
  return data
}

async function apiPost(action, payload) {
  const response = await fetch(API_URL, {
    method: 'POST', credentials: 'same-origin',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ action, payload }),
  })
  const data = await response.json()
  if (!response.ok) throw new Error(data.error || `Request failed (${response.status})`)
  return data
}

function init() {
  let state = null
  let challengeId = ''
  let renderedRubricKey = ''
  let benchmarkFormKey = ''
  let loading = false
  const byId = id => document.getElementById(id)
  const status = byId('sync-status')

  function selectedChallenge() {
    return state?.challenges.find(item => item.id === challengeId)
  }

  function showFeedback(id, message, error = false) {
    const element = byId(`${id}-feedback`)
    element.textContent = message
    element.classList.toggle('is-error', error)
  }

  function setOptions(select, options, placeholder) {
    const previous = select.value
    select.replaceChildren(new Option(placeholder, ''))
    for (const [value, label] of options) select.add(new Option(label, value))
    if (options.some(([value]) => value === previous)) select.value = previous
  }

  function renderChallenge(challenge) {
    const target = byId('challenge-detail')
    if (!challenge) {
      target.className = 'card empty-state'
      target.textContent = 'The Mayor has not published a challenge yet. Visit the Mayor desk to open one.'
      return
    }
    target.className = 'card brief-card'
    const header = append(node('div', 'brief-header'),
      append(node('div'), node('p', 'eyebrow', `Published · Benchmark v${challenge.benchmark_version}`),
        node('h3', '', challenge.name)),
      node('span', 'deadline', `Deadline · ${prettyTime(challenge.deadline_ms)}`))
    const grid = append(node('div', 'brief-grid'),
      labeledBlock('Mayor’s topic', challenge.topic),
      labeledBlock('Scope', challenge.scope),
      labeledBlock('Possibility wiki', challenge.possibility_wiki),
      labeledBlock('First person solution', challenge.first_person_solution))
    const materials = append(node('div', 'brief-materials'),
      append(node('div'), node('h4', '', 'Benchmark materials'), materialList(challenge.benchmark_materials || [])))
    if (challenge.evaluation_materials) {
      materials.append(append(node('div'), node('h4', '', 'Evaluation materials'),
        materialList(challenge.evaluation_materials)))
    }
    target.replaceChildren(header, grid, materials)
  }

  function renderLeaderboard(challenge) {
    const target = byId('leaderboard-content')
    byId('leaderboard-version').textContent = challenge ?
      `Benchmark v${challenge.benchmark_version} · revision ${state.revision}` : ''
    const entries = challenge ?
      (state.leaderboards?.[challenge.id] || deriveLeaderboard(state, challenge.id)) : []
    if (!entries.length) {
      target.className = 'card empty-state'
      target.textContent = challenge ?
        'No current benchmark scores yet. Reviews will appear here as soon as they are recorded.' :
        'The Champion Wall opens with the first published challenge.'
      return
    }
    target.className = 'card leaderboard-card'
    const table = node('table')
    const caption = node('caption', 'visually-hidden', `Leaderboard for ${challenge.name}`)
    const head = node('thead')
    const headRow = node('tr')
    for (const title of ['Rank', 'Team', 'Score', 'Reviewed']) headRow.append(node('th', '', title))
    head.append(headRow)
    const body = node('tbody')
    for (const entry of entries) {
      const row = node('tr')
      append(row, node('td', 'rank-cell', `#${entry.rank}`),
        node('td', 'team-cell', entry.team_name),
        node('td', 'score-cell', String(entry.total)),
        node('td', '', prettyTime(entry.evaluated_ms)))
      body.append(row)
    }
    table.append(caption, head, body)
    target.replaceChildren(table)
  }

  function renderTeams(challenge) {
    const teams = challenge ? state.teams.filter(item => item.challenge_id === challenge.id) : []
    const teamSelect = byId('submission-team')
    setOptions(teamSelect, teams.filter(team => team.is_member !== false)
      .map(team => [team.id, team.name]), 'Choose one of your registered teams')
    setOptions(byId('join-team'), teams.filter(team => team.is_member !== true)
      .map(team => [team.id, team.name]), 'Choose a team to join')
    const target = byId('team-list')
    if (!teams.length) {
      target.replaceChildren(node('p', 'muted-note', 'No teams have gathered for this challenge yet.'))
      return
    }
    target.replaceChildren(...teams.map(team => {
      const submissions = state.submissions.filter(item => item.team_id === team.id &&
        item.challenge_id === challenge.id)
      return append(node('article', 'team-chip'),
        node('strong', '', team.name),
        node('span', '', team.members ?
          `${team.members.join(' · ')} · ${submissions.length} submission${submissions.length === 1 ? '' : 's'}` :
          (team.is_member ? 'Your team' : 'Competing team')))
    }))
  }

  function renderReviews(challenge) {
    const submissions = challenge ? state.submissions.filter(item => item.challenge_id === challenge.id) : []
    setOptions(byId('evaluation-submission'), submissions.map(submission => {
      const team = state.teams.find(item => item.id === submission.team_id)
      return [submission.id, `${team?.name || submission.team_id} · version ${submission.version}`]
    }), 'Choose a submission')
    const materials = byId('review-materials')
    if (!challenge) {
      materials.className = 'empty-state'
      materials.textContent = 'Select a challenge to see its materials and scoring guide.'
    } else {
      materials.className = ''
      const guide = node('dl', 'rubric-guide')
      for (const criterion of challenge.rubric) {
        guide.append(node('dt', '', criterion.label), node('dd', '', `${criterion.max_points} points`))
      }
      materials.replaceChildren(node('p', 'eyebrow', `Benchmark v${challenge.benchmark_version}`),
        materialList(challenge.evaluation_materials || []), node('h4', '', 'Scoring guide'), guide)
    }
    const rubricKey = challenge ? `${challenge.id}:${challenge.benchmark_version}` : ''
    if (rubricKey === renderedRubricKey) return
    renderedRubricKey = rubricKey
    const fields = byId('score-fields')
    fields.replaceChildren()
    for (const criterion of challenge?.rubric || []) {
      const group = node('fieldset', 'score-group')
      const legend = node('legend', '', `${criterion.label} · ${criterion.max_points} points`)
      const pointsLabel = node('label', '', 'Points')
      const points = node('input')
      points.type = 'number'; points.min = '0'; points.max = String(criterion.max_points)
      points.step = '1'; points.required = true; points.name = `points-${criterion.id}`
      const evidenceLabel = node('label', '', 'Evidence')
      const evidence = node('textarea')
      evidence.name = `evidence-${criterion.id}`; evidence.rows = 2
      evidence.required = true; evidence.placeholder = 'What in the artifact supports this score?'
      append(group, legend, append(pointsLabel, points), append(evidenceLabel, evidence))
      fields.append(group)
    }
  }

  function renderBenchmarkForm(challenge) {
    const key = challenge ? `${challenge.id}:${challenge.benchmark_version}` : ''
    if (key === benchmarkFormKey) return
    benchmarkFormKey = key
    const form = byId('benchmark-form')
    form.elements.benchmark_materials.value = challenge?.benchmark_materials.join('\n') || ''
    form.elements.evaluation_materials.value = challenge?.evaluation_materials?.join('\n') || ''
    form.elements.rubric.value = challenge ? rubricText(challenge.rubric) : ''
  }

  function render() {
    const viewer = state.viewer || {
      can_publish: true, can_register_team: true, can_join_team: true,
      can_submit: true, can_evaluate: true,
    }
    byId('mayor').hidden = !viewer.can_publish
    byId('reviews').hidden = !viewer.can_evaluate
    document.querySelector('a[href="#mayor"]').hidden = !viewer.can_publish
    document.querySelector('a[href="#reviews"]').hidden = !viewer.can_evaluate
    byId('team-form').parentElement.hidden = !viewer.can_register_team
    byId('join-form').parentElement.hidden = !viewer.can_join_team
    byId('submission-form').parentElement.hidden = !viewer.can_submit
    const memberField = byId('team-form').elements.members
    memberField.closest('label').hidden = Boolean(state.viewer?.account_id)
    if (state.viewer?.account_id) memberField.value = state.viewer.account_id
    const joinMemberField = byId('join-form').elements.member_id
    joinMemberField.closest('label').hidden = Boolean(state.viewer?.account_id)
    if (state.viewer?.account_id) joinMemberField.value = state.viewer.account_id
    const challenges = state.challenges.filter(item => item.published !== false)
    if (!challenges.some(item => item.id === challengeId)) challengeId = challenges[0]?.id || ''
    const picker = byId('challenge-select')
    setOptions(picker, challenges.map(item => [item.id, item.name]), 'No published challenges')
    picker.value = challengeId
    picker.disabled = !challenges.length
    const challenge = selectedChallenge()
    renderChallenge(challenge)
    renderLeaderboard(challenge)
    renderTeams(challenge)
    renderReviews(challenge)
    renderBenchmarkForm(challenge)
  }

  async function refresh() {
    if (loading) return
    loading = true
    try {
      const next = await apiGet()
      if (!state || state.revision !== next.revision) {
        state = next
        render()
      }
      status.textContent = `Live · revision ${state.revision} · checked ${new Date().toLocaleTimeString()}`
      status.parentElement.classList.remove('is-offline')
    } catch (error) {
      status.textContent = `Could not connect: ${error.message}`
      status.parentElement.classList.add('is-offline')
    } finally {
      loading = false
    }
  }

  async function submit(action, payload, feedbackId, success) {
    try {
      state = await apiPost(action, payload)
      render()
      showFeedback(feedbackId, success)
      status.textContent = `Live · revision ${state.revision} · just updated`
      status.parentElement.classList.remove('is-offline')
      return true
    } catch (error) {
      showFeedback(feedbackId, error.message, true)
      return false
    }
  }

  byId('challenge-select').addEventListener('change', event => {
    challengeId = event.target.value
    render()
  })
  byId('refresh-button').addEventListener('click', refresh)

  byId('publish-form').addEventListener('submit', async event => {
    event.preventDefault()
    const form = event.currentTarget
    try {
      const deadline = new Date(form.elements.deadline.value).getTime()
      if (!Number.isFinite(deadline) || deadline <= Date.now()) {
        throw new Error('Choose a future submission deadline.')
      }
      const payload = {
        id: form.elements.id.value.trim(), name: form.elements.name.value.trim(),
        topic: form.elements.topic.value.trim(), scope: form.elements.scope.value.trim(),
        possibility_wiki: form.elements.possibility_wiki.value.trim(),
        first_person_solution: form.elements.first_person_solution.value.trim(),
        deadline_ms: String(deadline), benchmark_version: 1,
        benchmark_materials: lines(form.elements.benchmark_materials.value),
        evaluation_materials: lines(form.elements.evaluation_materials.value),
        rubric: parseRubric(form.elements.rubric.value), published: true,
      }
      if (await submit('publish', payload, 'publish', 'Challenge published. Teams can now join.')) {
        challengeId = payload.id; form.reset(); render()
      }
    } catch (error) { showFeedback('publish', error.message, true) }
  })

  byId('team-form').addEventListener('submit', async event => {
    event.preventDefault()
    const form = event.currentTarget
    if (!selectedChallenge()) return showFeedback('team', 'Choose a published challenge first.', true)
    const members = state.viewer?.account_id ?
      [state.viewer.account_id] : lines(form.elements.members.value)
    if (!members.length) return showFeedback('team', 'List at least one team member.', true)
    const payload = { id: form.elements.id.value.trim(), challenge_id: challengeId,
      name: form.elements.name.value.trim(), members }
    if (await submit('register-team', payload, 'team', 'Team registered. You can submit a solution now.')) {
      form.reset()
      if (state.viewer?.account_id) form.elements.members.value = state.viewer.account_id
      byId('submission-team').value = payload.id
    }
  })

  byId('join-form').addEventListener('submit', async event => {
    event.preventDefault()
    const form = event.currentTarget
    if (!selectedChallenge()) return showFeedback('join', 'Choose a published challenge first.', true)
    const payload = { team_id: form.elements.team_id.value,
      member_id: state.viewer?.account_id || form.elements.member_id.value.trim() }
    if (await submit('join-team', payload, 'join', 'You joined the team. You can now submit with them.')) {
      form.reset()
      if (state.viewer?.account_id) form.elements.member_id.value = state.viewer.account_id
      byId('submission-team').value = payload.team_id
    }
  })

  byId('submission-form').addEventListener('submit', async event => {
    event.preventDefault()
    const form = event.currentTarget
    if (!selectedChallenge()) return showFeedback('submission', 'Choose a published challenge first.', true)
    const payload = { id: `submission-${crypto.randomUUID()}`, challenge_id: challengeId,
      team_id: form.elements.team_id.value, version: 0,
      artifact_url: form.elements.artifact_url.value.trim(),
      first_person_solution: form.elements.first_person_solution.value.trim(), submitted_ms: '0' }
    if (await submit('submit', payload, 'submission', 'Solution submitted. It is ready for review.')) form.reset()
  })

  byId('evaluation-form').addEventListener('submit', async event => {
    event.preventDefault()
    const challenge = selectedChallenge()
    if (!challenge) return showFeedback('evaluation', 'Choose a published challenge first.', true)
    const form = event.currentTarget
    const scores = challenge.rubric.map(criterion => ({
      criterion_id: criterion.id,
      points: Number(form.elements[`points-${criterion.id}`].value),
      evidence: form.elements[`evidence-${criterion.id}`].value.trim(),
    }))
    const payload = { submission_id: form.elements.submission_id.value,
      benchmark_version: challenge.benchmark_version,
      reviewer: form.elements.reviewer.value.trim(), scores, total: 0, evaluated_ms: '0' }
    if (await submit('evaluate', payload, 'evaluation', 'Review recorded. The Champion Wall has updated.')) form.reset()
  })

  byId('benchmark-form').addEventListener('submit', async event => {
    event.preventDefault()
    const challenge = selectedChallenge()
    if (!challenge) return showFeedback('benchmark', 'Choose a published challenge first.', true)
    const form = event.currentTarget
    try {
      const payload = { challenge_id: challenge.id,
        benchmark_materials: lines(form.elements.benchmark_materials.value),
        evaluation_materials: lines(form.elements.evaluation_materials.value),
        rubric: parseRubric(form.elements.rubric.value) }
      await submit('revise-benchmark', payload, 'benchmark',
        `Benchmark v${challenge.benchmark_version + 1} published. The Champion Wall now uses this version.`)
    } catch (error) { showFeedback('benchmark', error.message, true) }
  })

  refresh()
  window.setInterval(() => { if (!document.hidden) refresh() }, POLL_INTERVAL_MS)
  document.addEventListener('visibilitychange', () => { if (!document.hidden) refresh() })
}

if (typeof document !== 'undefined') init()

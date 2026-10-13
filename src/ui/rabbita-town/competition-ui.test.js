import assert from 'node:assert/strict'
import test from 'node:test'
import { filterFAQ, validateTracks, validateCompetitionCalendar, parseCompetitionRubric, createEditorControl, safeExternalURL, submissionStatus } from './competition-ui.js'

const metricTrack = () => ({ id: 'speed', name: 'Speed', scoring_mode: 'metric', runner_key: 'voice-benchmark',
  metrics: [{ id: 'latency', label: 'Latency', unit: 'ms', direction: 'min', baseline: 100, weight: 1 }],
  gates: [{ id: 'latency-gate', label: 'Latency cap', metric_id: 'latency', comparison: 'lte', threshold: 200 }] })

test('competition builder rejects ambiguous tracks and unresolved qualification metrics', () => {
  assert.equal(validateTracks([metricTrack()])[0].metrics[0].direction, 'min')
  assert.throws(() => validateTracks([metricTrack(), metricTrack()]), /unique ID/)
  const invalid = metricTrack(); invalid.gates[0].metric_id = 'missing'
  assert.throws(() => validateTracks([invalid]), /reference a metric/)
  const noRunner = metricTrack(); noRunner.runner_key = ''
  assert.throws(() => validateTracks([noRunner]), /registered benchmark runner/)
  const zeroBaseline = metricTrack(); zeroBaseline.metrics[0].baseline = 0
  assert.throws(() => validateTracks([zeroBaseline]), /positive baseline/)
})

test('FAQ search includes categories and answers, with case insensitive matching', () => {
  const items = [{ category: 'Teams', question: 'How do I join?', answer: 'Accept an invitation.' }, { category: 'Judging', question: 'When?', answer: 'After the deadline.' }]
  assert.deepEqual(filterFAQ(items, 'INVITATION'), [items[0]])
  assert.deepEqual(filterFAQ(items, ' teams '), [items[0]])
  assert.deepEqual(filterFAQ(items, 'missing'), [])
})

test('artifact, partner and evidence links reject executable URL schemes', () => {
  assert.equal(safeExternalURL('javascript:alert(1)'), null)
  assert.equal(safeExternalURL('data:text/html,<script>'), null)
  assert.equal(safeExternalURL('https://example.org/source'), 'https://example.org/source')
})

test('submission receipts distinguish pending, failure, approval and appeal', () => {
  const submission = { id: 'solution-1' }
  assert.equal(submissionStatus(submission), 'Awaiting review')
  assert.equal(submissionStatus(submission, [{ submission_id: submission.id, state: 'failed' }]), 'Run failed')
  assert.equal(submissionStatus(submission, [{ submission_id: submission.id, state: 'approved' }]), 'Approved · provisional')
  assert.equal(submissionStatus(submission, [{ submission_id: submission.id, state: 'approved', reason: 'Unranked: qualification gates failed · quality 70 %; requires at least 75 %' }]), 'Approved · unranked')
  assert.equal(submissionStatus(submission, [], [], [{ submission_id: submission.id, state: 'open' }]), 'Appeal open')
})

test('editor construction respects read-only textarea and select type properties', () => {
  // Browser textarea/select type is getter-only. Keep that DOM contract in this
  // focused substitute and exercise the same constructor used by the builder.
  const document = { createElement(tag) {
    const element = { tagName: tag.toUpperCase(), dataset: {}, options: [], add(option) { this.options.push(option) } }
    if (tag === 'textarea' || tag === 'select') Object.defineProperty(element, 'type', { get: () => tag === 'textarea' ? 'textarea' : 'select-one' })
    return element
  } }
  const description = createEditorControl(document, 'description', 'Build a working demo', { multiline: true, required: true })
  assert.equal(description.type, 'textarea'); assert.equal(description.value, 'Build a working demo'); assert.equal(description.required, true); assert.equal(description.rows, 2)
  const scoring = createEditorControl(document, 'scoring_mode', 'metric', { choices: [['rubric', 'Human review'], ['metric', 'Measured benchmark']] })
  assert.equal(scoring.type, 'select-one'); assert.equal(scoring.value, 'metric'); assert.deepEqual(scoring.options.map(option => [option.value, option.textContent]), [['rubric', 'Human review'], ['metric', 'Measured benchmark']])
  const points = createEditorControl(document, 'weight', 1, { type: 'number', min: '0.1', step: 'any', required: true })
  assert.equal(points.type, 'number'); assert.equal(points.min, '0.1'); assert.equal(points.step, 'any')
})

test('competition calendar validates time zone and registration before submissions', () => {
  const calendar = { timezone: 'Asia/Shanghai', registration_open_ms: '100', registration_close_ms: '300', submission_open_ms: '200', review_close_ms: '500' }
  assert.equal(validateCompetitionCalendar(calendar, '400'), calendar)
  assert.throws(() => validateCompetitionCalendar({ ...calendar, timezone: 'Mars/Olympus' }, '400'), /valid IANA time zone/)
  assert.throws(() => validateCompetitionCalendar({ ...calendar, submission_open_ms: '50' }, '400'), /registration opens/)
  assert.throws(() => validateCompetitionCalendar({ ...calendar, registration_close_ms: '450' }, '400'), /Calendar order/)
  assert.throws(() => validateCompetitionCalendar({ ...calendar, review_close_ms: '350' }, '400'), /Calendar order/)
})

test('metric-only competitions accept an empty rubric while human tracks require it', () => {
  assert.deepEqual(parseCompetitionRubric('', [metricTrack()]), [])
  assert.throws(() => parseCompetitionRubric('', [{ scoring_mode: 'rubric' }]), /rubric criteria/)
  assert.throws(() => parseCompetitionRubric('', [metricTrack(), { scoring_mode: 'rubric' }]), /rubric criteria/)
  assert.deepEqual(parseCompetitionRubric('quality | Solution quality | 100', [{ scoring_mode: 'rubric' }]), [{ id: 'quality', label: 'Solution quality', max_points: 100 }])
})

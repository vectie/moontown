import assert from 'node:assert/strict'
import test from 'node:test'
import { deriveLeaderboard, parseRubric } from './hackathon.js'

test('Champion Wall keeps each team’s best score on the current benchmark', () => {
  const state = {
    challenges: [{ id: 'challenge', benchmark_version: 2 }],
    teams: [
      { id: 'alpha', challenge_id: 'challenge', name: 'Alpha' },
      { id: 'beta', challenge_id: 'challenge', name: 'Beta' },
    ],
    submissions: [
      { id: 'a1', challenge_id: 'challenge', team_id: 'alpha' },
      { id: 'a2', challenge_id: 'challenge', team_id: 'alpha' },
      { id: 'b1', challenge_id: 'challenge', team_id: 'beta' },
    ],
    evaluations: [
      { submission_id: 'a1', benchmark_version: 1, total: 100, evaluated_ms: 1 },
      { submission_id: 'a1', benchmark_version: 2, total: 80, evaluated_ms: 8 },
      { submission_id: 'a2', benchmark_version: 2, total: 70, evaluated_ms: 6 },
      { submission_id: 'b1', benchmark_version: 2, total: 80, evaluated_ms: 4 },
    ],
  }
  assert.deepEqual(deriveLeaderboard(state, 'challenge').map(entry =>
    [entry.rank, entry.team_id, entry.submission_id, entry.total]), [
    [1, 'beta', 'b1', 80],
    [2, 'alpha', 'a1', 80],
  ])
})

test('rubric authoring accepts full criteria and rejects duplicate IDs', () => {
  assert.deepEqual(parseRubric('impact | Community impact | 40\nproof | Evidence | 30'), [
    { id: 'impact', label: 'Community impact', max_points: 40 },
    { id: 'proof', label: 'Evidence', max_points: 30 },
  ])
  assert.throws(() => parseRubric('impact | A | 10\nimpact | B | 10'), /unique ID/)
})

test('a corrected review replaces the earlier score for its submission', () => {
  const state = {
    challenges: [{ id: 'challenge', benchmark_version: 2 }],
    teams: [{ id: 'alpha', challenge_id: 'challenge', name: 'Alpha' }],
    submissions: [{ id: 'a1', challenge_id: 'challenge', team_id: 'alpha' }],
    evaluations: [
      { submission_id: 'a1', benchmark_version: 2, total: 90, evaluated_ms: 100 },
      { submission_id: 'a1', benchmark_version: 2, total: 65, evaluated_ms: 200 },
    ],
  }
  assert.equal(deriveLeaderboard(state, 'challenge')[0].total, 65)
})

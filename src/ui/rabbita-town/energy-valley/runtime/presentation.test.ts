import assert from 'node:assert/strict'
import test from 'node:test'
import { runtimeAgentMetricLabel } from './presentation'
import type { RuntimeProjectionPhase } from './types'

test('agent metric calls only a live runtime count real', () => {
  assert.equal(runtimeAgentMetricLabel('live'), '真实 Agent')

  const nonLivePhases: Array<RuntimeProjectionPhase | undefined> = [
    undefined,
    'loading',
    'stale',
    'error',
    'unavailable',
  ]
  for (const phase of nonLivePhases) {
    assert.equal(runtimeAgentMetricLabel(phase), '环境角色')
  }
})

import assert from 'node:assert/strict'
import test from 'node:test'
import {
  systemSettingsShape,
  validateSystemSettingRelationships,
} from './account_management.js'

test('system settings snapshot accepts management and public projections', () => {
  assert.deepEqual(
    systemSettingsShape({
      revision: 4,
      values: { max_concurrent_tasks: 12 },
      settings: [{ key: 'max_concurrent_tasks' }],
      audit_events: [{ revision: 4 }],
    }),
    {
      revision: 4,
      values: { max_concurrent_tasks: 12 },
      descriptors: [{ key: 'max_concurrent_tasks' }],
      auditEvents: [{ revision: 4 }],
    },
  )

  assert.deepEqual(
    systemSettingsShape({
      revision: 2,
      settings: { max_concurrent_tasks: 8 },
      catalog: [{ key: 'max_concurrent_tasks' }],
    }),
    {
      revision: 2,
      values: { max_concurrent_tasks: 8 },
      descriptors: [{ key: 'max_concurrent_tasks' }],
      auditEvents: [],
    },
  )
})

test('system settings relationship validation mirrors backend safeguards', () => {
  const errors = validateSystemSettingRelationships({
    max_live_external_executions: 9,
    max_concurrent_tasks: 8,
    daemon_stale_after_ms: 9_999,
    daemon_poll_interval_ms: 5_000,
    frontend_runtime_stale_after_ms: 7_999,
    frontend_snapshot_refresh_interval_ms: 4_000,
  })

  assert.deepEqual([...errors.keys()], [
    'max_live_external_executions',
    'daemon_stale_after_ms',
    'frontend_runtime_stale_after_ms',
  ])
})

test('valid system settings relationships produce no errors', () => {
  const errors = validateSystemSettingRelationships({
    max_live_external_executions: 8,
    max_concurrent_tasks: 8,
    daemon_stale_after_ms: 10_000,
    daemon_poll_interval_ms: 5_000,
    frontend_runtime_stale_after_ms: 8_000,
    frontend_snapshot_refresh_interval_ms: 4_000,
  })

  assert.equal(errors.size, 0)
})

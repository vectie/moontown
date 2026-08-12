import assert from 'node:assert/strict'
import test from 'node:test'
import { runtimeRefreshIntervalMs } from './runtime_snapshots.js'

test('runtime refresh interval reads the loaded system settings snapshot', () => {
  const previous = globalThis.__moontownSystemSettingsJson
  globalThis.__moontownSystemSettingsJson = JSON.stringify({
    settings: { frontend_snapshot_refresh_interval_ms: 12_000 },
  })
  assert.equal(runtimeRefreshIntervalMs(), 12_000)
  globalThis.__moontownSystemSettingsJson = JSON.stringify({
    settings: { frontend_snapshot_refresh_interval_ms: 999 },
  })
  assert.equal(runtimeRefreshIntervalMs(), 5_000)
  if (previous == null) delete globalThis.__moontownSystemSettingsJson
  else globalThis.__moontownSystemSettingsJson = previous
})

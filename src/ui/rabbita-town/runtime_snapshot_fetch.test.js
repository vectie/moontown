import assert from 'node:assert/strict'
import test from 'node:test'
import {
  setSnapshotFallback,
  setSnapshotValue,
} from './runtime_snapshot_fetch.js'

function snapshotFixture(suffix) {
  return {
    jsonGlobal: `__moontownSnapshotValue_${suffix}`,
    versionGlobal: `__moontownSnapshotVersion_${suffix}`,
    fallback: 'unavailable',
  }
}

function clearSnapshot(snapshot) {
  delete globalThis[snapshot.jsonGlobal]
  delete globalThis[snapshot.versionGlobal]
}

test('snapshot version changes only when fetched content changes', () => {
  const snapshot = snapshotFixture('content')
  clearSnapshot(snapshot)

  assert.equal(setSnapshotValue(snapshot, 'alpha', { bumpVersion: true }), true)
  assert.equal(globalThis[snapshot.versionGlobal], 1)
  assert.equal(setSnapshotValue(snapshot, 'alpha', { bumpVersion: true }), false)
  assert.equal(globalThis[snapshot.versionGlobal], 1)
  assert.equal(setSnapshotValue(snapshot, 'beta', { bumpVersion: true }), true)
  assert.equal(globalThis[snapshot.versionGlobal], 2)

  clearSnapshot(snapshot)
})

test('fallback transition bumps once and then remains stable', () => {
  const snapshot = snapshotFixture('fallback')
  clearSnapshot(snapshot)
  setSnapshotValue(snapshot, 'live', { bumpVersion: true })

  assert.equal(setSnapshotFallback(snapshot, { bumpVersion: true }), true)
  assert.equal(globalThis[snapshot.versionGlobal], 2)
  assert.equal(setSnapshotFallback(snapshot, { bumpVersion: true }), false)
  assert.equal(globalThis[snapshot.versionGlobal], 2)

  clearSnapshot(snapshot)
})

import assert from 'node:assert/strict'
import test from 'node:test'
import {
  setSnapshotFallback,
  setSnapshotValue,
  loadJsonGlobal,
  refreshTextSnapshot,
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

test('static reference data revalidates; operational snapshots never cache', async t => {
  const calls = []
  t.mock.method(globalThis, 'fetch', async (url, options) => {
    calls.push({url, options})
    return new Response('{"ok":true}')
  })
  const asset = {...snapshotFixture('static'), url:'./tilemap/reference.json'}
  const live = {...snapshotFixture('live'), url:'./secret-compute-room.json'}
  try {
    await loadJsonGlobal(asset)
    await refreshTextSnapshot(live)
    assert.equal(calls[0].url, asset.url)
    assert.equal(calls[0].options.cache, 'default')
    assert.match(calls[1].url, /secret-compute-room\.json\?ts=/)
    assert.equal(calls[1].options.cache, 'no-store')
    assert.deepEqual(globalThis[asset.jsonGlobal], {ok:true})
    assert.equal(globalThis[live.versionGlobal], 1)
  } finally {clearSnapshot(asset);clearSnapshot(live)}
})

test('snapshot deadline remains active while a response body stalls', async t => {
  const snapshot = {...snapshotFixture('body-timeout'), url:'./live.json'}
  t.mock.method(globalThis, 'fetch', async (_url, {signal}) => ({
    ok:true,
    text:() => new Promise((_resolve,reject) => signal.addEventListener('abort',()=>reject(signal.reason),{once:true})),
  }))
  try {
    await refreshTextSnapshot(snapshot)
    assert.equal(globalThis[snapshot.jsonGlobal], snapshot.fallback)
  } finally {clearSnapshot(snapshot)}
})

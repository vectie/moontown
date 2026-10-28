import assert from 'node:assert/strict'
import test from 'node:test'
import {loadUnifiedAccount} from './account_identity.js'

test('SSO uses the existing same-origin cookie, never a browser bearer', async t => {
  t.mock.method(globalThis, 'fetch', async (url, options) => {
    assert.equal(url, '/account/self.json')
    assert.equal(options.credentials, 'same-origin')
    assert.equal(options.cache, 'no-store')
    assert.equal(options.headers, undefined)
    return Response.json({state:'bound', account:{user_id:'lunanexa:a',display_name:'Alice'}})
  })
  assert.deepEqual(await loadUnifiedAccount(), {authoritative:true,account:{user_id:'lunanexa:a',display_name:'Alice'}})
})

test('signed-out and unavailable SSO never request a fallback visitor', async t => {
  for (const state of ['sign-in-required', 'unavailable']) {
    t.mock.method(globalThis, 'fetch', async () => Response.json({state}))
    assert.deepEqual(await loadUnifiedAccount(), {authoritative:true,account:null})
  }
})

test('only explicit disabled or an older host permits legacy desktop identity', async t => {
  t.mock.method(globalThis, 'fetch', async () => Response.json({state:'disabled'}))
  assert.equal((await loadUnifiedAccount()).authoritative, false)
  t.mock.method(globalThis, 'fetch', async () => new Response('', {status:404}))
  assert.equal((await loadUnifiedAccount()).authoritative, false)
  t.mock.method(globalThis, 'fetch', async () => new Response('', {status:503}))
  await assert.rejects(loadUnifiedAccount)
  t.mock.method(globalThis, 'fetch', async () => Response.json({state:'bound'}))
  await assert.rejects(loadUnifiedAccount)
})

test('gateway rejection is authoritative even when its body is not JSON', async t => {
  for (const status of [401, 403]) {
    t.mock.method(globalThis, 'fetch', async () => new Response('Reopen from portal', {status}))
    assert.deepEqual(await loadUnifiedAccount(), {authoritative:true, account:null})
  }
})

test('login between scope script and account request reloads before using another storage namespace', async t => {
  const prior = globalThis.location
  let reloads = 0
  globalThis.location = {reload:()=>reloads++}
  globalThis.__MOONTOWN_PUBLIC_PLATFORM = true
  globalThis.__MOONTOWN_ACCOUNT_SCOPE = 'public'
  t.mock.method(globalThis, 'fetch', async () => Response.json({
    state:'bound', storage_scope:`account-${'a'.repeat(64)}`, account:{user_id:'a'},
  }))
  try {
    await assert.rejects(loadUnifiedAccount, /Account changed/)
    assert.equal(reloads, 1)
  } finally {
    globalThis.location = prior
    delete globalThis.__MOONTOWN_PUBLIC_PLATFORM
    delete globalThis.__MOONTOWN_ACCOUNT_SCOPE
  }
})

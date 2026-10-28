import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'
import vm from 'node:vm'

const source = readFileSync(new URL('./platform-base.js', import.meta.url), 'utf8')

function storage() {
  const values = new Map()
  return {
    get length() { return values.size },
    key(index) { return [...values.keys()][index] ?? null },
    getItem(key) { return values.get(String(key)) ?? null },
    setItem(key, value) { values.set(String(key), String(value)) },
    removeItem(key) { values.delete(String(key)) },
  }
}

function load(scriptPath, scope = `webide-${'a'.repeat(64)}`, shared = storage(), publicPlatform = false) {
  const location = new URL('https://example.test/moontown/')
  class Element {
    attributes = new Map()
    setAttribute(name, value) { this.attributes.set(name, value) }
    getAttribute(name) { return this.attributes.get(name) ?? null }
  }
  const context = {
    URL, Request, location, Element,
    document: { currentScript: { src: `https://example.test${scriptPath}` } },
    __MOONTOWN_ACCOUNT_SCOPE: scope,
    __MOONTOWN_PUBLIC_PLATFORM: publicPlatform,
    localStorage: shared,
    sessionStorage: storage(),
    fetch: input => input,
    WebSocket: class { constructor(url) { this.url = url } },
    EventSource: class { constructor(url) { this.url = url } },
  }
  context.globalThis = context
  vm.runInNewContext(source, context)
  return context
}

test('hosted MoonTown keeps app traffic under /moontown', () => {
  const app = load('/moontown/platform-base.js')
  assert.equal(app.fetch('/miniapp/me'), 'https://example.test/moontown/miniapp/me')
  assert.equal(app.fetch('/moontown/api/status'), '/moontown/api/status')
  assert.equal(app.fetch('/user/v1/models'), '/user/v1/models')
  assert.equal(app.fetch('/account/self.json'), 'https://example.test/moontown/account/self.json')
  const account = new app.Element()
  account.setAttribute('href', 'https://example.test/user/')
  assert.equal(account.getAttribute('href'), 'https://example.test/user/')
  assert.equal(new app.WebSocket('wss://example.test/events').url, 'wss://example.test/moontown/events')
  const image = new app.Element()
  image.setAttribute('src', '/tilemap/actors/avatar.png')
  assert.equal(image.getAttribute('src'), 'https://example.test/moontown/tilemap/actors/avatar.png')
})

test('standalone MoonTown keeps its existing root paths', () => {
  const app = load('/platform-base.js')
  assert.equal(app.fetch('/miniapp/me'), '/miniapp/me')
})

test('personal workspace uses the shared neighborhood without unscoping private APIs', () => {
  const app = load('/moontown/workspace/platform-base.js')
  for (const route of ['public', 'mine', 'actions']) {
    const path = `/moontown/api/neighborhood/${route}`
    assert.equal(app.fetch(path), path)
    const request = new Request(`https://example.test${path}`)
    assert.equal(app.fetch(request), request)
  }
  assert.equal(app.fetch('/api/collaboration'), 'https://example.test/moontown/workspace/api/collaboration')
  assert.equal(app.fetch('/moontown/api/neighborhood/private'), 'https://example.test/moontown/workspace/moontown/api/neighborhood/private')
  assert.equal(app.fetch('/account/self.json'), 'https://example.test/moontown/workspace/account/self.json')
})

test('two hosted accounts cannot read each others browser state', () => {
  const shared = storage()
  const alice = load('/moontown/platform-base.js', `webide-${'a'.repeat(64)}`, shared)
  alice.localStorage.setItem('moontown.account-session.v1', 'alice-token')
  alice.localStorage.setItem('moontown-town-life-v1', 'alice-world')
  assert.equal(alice.localStorage.length, 2)
  const bob = load('/moontown/platform-base.js', `webide-${'b'.repeat(64)}`, shared)
  assert.equal(bob.localStorage.length, 0)
  assert.equal(bob.localStorage.getItem('moontown.account-session.v1'), null)
  bob.localStorage.setItem('moontown.account-session.v1', 'bob-token')
  assert.equal(alice.localStorage.getItem('moontown.account-session.v1'), 'alice-token')
  assert.equal(bob.localStorage.getItem('moontown.account-session.v1'), 'bob-token')
})

test('hosted scope fails closed when no authenticated workspace was supplied', () => {
  const app = load('/moontown/platform-base.js', '')
  assert.equal(app.__MOONTOWN_SCOPE_READY, false)
})

test('public, two personal accounts and workspace use separate storage', () => {
  const shared = storage()
  const visitor = load('/moontown/platform-base.js', 'public', shared, true)
  assert.equal(visitor.__MOONTOWN_SCOPE_READY, true)
  visitor.localStorage.setItem('world', 'demo')
  const a = load('/moontown/platform-base.js', `account-${'a'.repeat(64)}`, shared, true)
  a.localStorage.setItem('world', 'personal-a')
  const b = load('/moontown/platform-base.js', `account-${'b'.repeat(64)}`, shared, true)
  assert.equal(b.localStorage.getItem('world'), null)
  assert.equal(visitor.localStorage.getItem('world'), 'demo')
  assert.equal(a.localStorage.getItem('world'), 'personal-a')
  assert.equal(load('/moontown/platform-base.js', 'public').__MOONTOWN_SCOPE_READY, false)
})

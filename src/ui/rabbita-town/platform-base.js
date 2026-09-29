// A hosted MoonTown shares the public origin with other products. Rewrite
// app-owned root URLs without changing standalone, root-mounted installations.
(() => {
  const script = document.currentScript
  const pathname = script ? new URL(script.src, location.href).pathname : ''
  const base = pathname.endsWith('/platform-base.js')
    ? pathname.slice(0, -'/platform-base.js'.length)
    : ''
  if (!base) return

  // A path on the shared origin does not partition browser storage. Scope
  // MoonTown's synchronous storage API to the authenticated workspace before
  // any account token, avatar or town event is read by the application.
  const scope = globalThis.__MOONTOWN_ACCOUNT_SCOPE
  if (base === '/moontown') {
    if (typeof scope !== 'string' || !/^webide-[a-f0-9]{64}$/.test(scope)) {
      globalThis.__MOONTOWN_SCOPE_READY = false
      return
    }
    const prefix = `moontown:${scope}:`
    const scopedStorage = storage => {
      if (!storage) return null
      const keys = () => {
        const result = []
        for (let i = 0; i < storage.length; i++) {
          const key = storage.key(i)
          if (key?.startsWith(prefix)) result.push(key.slice(prefix.length))
        }
        return result
      }
      return {
        get length() { return keys().length },
        key(index) { return keys()[index] ?? null },
        getItem(key) { return storage.getItem(prefix + String(key)) },
        setItem(key, value) { storage.setItem(prefix + String(key), String(value)) },
        removeItem(key) { storage.removeItem(prefix + String(key)) },
        clear() { for (const key of keys()) storage.removeItem(prefix + key) },
      }
    }
    try {
      const local = scopedStorage(globalThis.localStorage)
      const session = scopedStorage(globalThis.sessionStorage)
      Object.defineProperty(globalThis, 'localStorage', {
        configurable: true, get: () => local,
      })
      Object.defineProperty(globalThis, 'sessionStorage', {
        configurable: true, get: () => session,
      })
      globalThis.__MOONTOWN_SCOPE_READY = true
    } catch {
      globalThis.__MOONTOWN_SCOPE_READY = false
      return
    }
  }

  const otherProducts = ['/mana', '/user', '/docs', '/moondesk', '/comfyui', '/moonrobo']
  const rewrite = input => {
    const url = new URL(input, location.href)
    const sameOrigin = url.host === location.host && (
      url.protocol === location.protocol ||
      (location.protocol === 'https:' && url.protocol === 'wss:') ||
      (location.protocol === 'http:' && url.protocol === 'ws:')
    )
    if (!sameOrigin || !url.pathname.startsWith('/')) return input
    if (url.pathname === base || url.pathname.startsWith(`${base}/`)) return input
    if (otherProducts.some(prefix => url.pathname === prefix || url.pathname.startsWith(`${prefix}/`))) return input
    url.pathname = `${base}${url.pathname}`
    return url.href
  }

  const originalFetch = globalThis.fetch.bind(globalThis)
  globalThis.fetch = (input, init) => {
    if (input instanceof Request) {
      const target = rewrite(input.url)
      return originalFetch(target === input.url ? input : new Request(target, input), init)
    }
    return originalFetch(rewrite(input), init)
  }

  const NativeWebSocket = globalThis.WebSocket
  if (NativeWebSocket) {
    globalThis.WebSocket = class extends NativeWebSocket {
      constructor(url, protocols) { super(rewrite(url), protocols) }
    }
  }

  const NativeEventSource = globalThis.EventSource
  if (NativeEventSource) {
    globalThis.EventSource = class extends NativeEventSource {
      constructor(url, options) { super(rewrite(url), options) }
    }
  }

  const urlAttributes = new Set(['href', 'src', 'action', 'poster'])
  const originalSetAttribute = Element.prototype.setAttribute
  Element.prototype.setAttribute = function (name, value) {
    return originalSetAttribute.call(
      this,
      name,
      urlAttributes.has(String(name).toLowerCase()) ? rewrite(String(value)) : value,
    )
  }
  for (const [constructor, property] of [
    [globalThis.HTMLAnchorElement, 'href'],
    [globalThis.HTMLImageElement, 'src'],
    [globalThis.HTMLIFrameElement, 'src'],
    [globalThis.HTMLFormElement, 'action'],
  ]) {
    if (!constructor) continue
    const descriptor = Object.getOwnPropertyDescriptor(constructor.prototype, property)
    if (!descriptor?.set) continue
    Object.defineProperty(constructor.prototype, property, {
      ...descriptor,
      set(value) { descriptor.set.call(this, rewrite(String(value))) },
    })
  }
  globalThis.__MOONTOWN_BASE_PATH = base
})()

// Set by the public asset build. Unpackaged previews use the live compiler.
const release = null

export function referenceSignatureInput() {
  return JSON.stringify([
    globalThis.__wenyuReferenceLabels, globalThis.__wenyuReferenceBuildings,
    globalThis.__wenyuReferenceRoadGraph, globalThis.__wenyuReferenceIntersections,
    globalThis.__moontownEnergyValleyOsmBlockGraph, globalThis.__wenyuTownModulesJson,
  ])
}

async function sha256(bytes) {
  const hash = new Uint8Array(await crypto.subtle.digest('SHA-256', bytes))
  return Array.from(hash, b => b.toString(16).padStart(2,'0')).join('')
}

export async function loadPublicWorld(references) {
  if (!release || !globalThis.crypto?.subtle || new URLSearchParams(location.search).has('seed')) return
  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), 8000)
  try {
    const response = await fetch(new URL(release.file, import.meta.url), {signal:controller.signal})
    if (!response.ok) return
    const bytes = await response.arrayBuffer()
    await references
    const [asset, inputs] = await Promise.all([
      sha256(bytes), sha256(new TextEncoder().encode(referenceSignatureInput())),
    ])
    if (asset === release.digest && inputs === release.inputs) {
      const stream = new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'))
      globalThis.__townBaselineInput = {digest:asset, rows:await new Response(stream).json()}
    }
  } catch { /* The normal compiler also handles old or incomplete deployments. */ }
  finally { clearTimeout(timeout) }
}

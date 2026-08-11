import assert from 'node:assert/strict'
import { createHash } from 'node:crypto'
import { readFile, readdir, stat } from 'node:fs/promises'
import path from 'node:path'
import {
  AUTHORING_ONLY_ASSET_SEGMENTS,
  KNOWLEDGE_DOMAIN_CATALOG_TARGET,
  runtimeAssetPaths,
} from '../runtime_asset_manifest.js'

const frontendRoot = path.resolve(import.meta.dirname, '..')
const assetRoot = path.resolve(frontendRoot, '../assets')
const distRoot = path.join(frontendRoot, 'dist')
const MAX_DIST_BYTES = 64 * 1024 * 1024
const REQUIRED_BROWSER_FILES = [
  'index.html',
  'viewport.html',
  'operations.html',
  'account_management.js',
  'bootstrap.js',
  'main.js',
  'runtime_snapshot_fetch.js',
  'runtime_snapshot_manifest.js',
  'runtime_snapshot_parser.js',
  'runtime_snapshots.js',
  'styles.css',
  'viewport_drag_pan.js',
]
const FORBIDDEN_RELEASE_SEGMENTS = [
  '/book-output/',
  '/node_modules/',
  '/watchers/',
]
const FORBIDDEN_RELEASE_FILES = new Set([
  'book-template-requests.json',
  'civic-status.json',
  'daemon.json',
  'editor-pipeline.json',
  'live-autonomy.json',
  'live-digest.md',
  'module-projections.json',
  'moondesk-bridge.json',
  'operator-requests.json',
  'standing-goals.json',
  'town.json',
  'visual-projection.json',
])

async function filesUnder(root, relativeDirectory = '') {
  const directory = path.join(root, relativeDirectory)
  const entries = await readdir(directory, { withFileTypes: true })
  const files = []
  for (const entry of entries.sort((left, right) =>
    left.name.localeCompare(right.name))) {
    const relativePath = path.posix.join(relativeDirectory, entry.name)
    if (entry.isDirectory()) {
      files.push(...await filesUnder(root, relativePath))
    } else if (entry.isFile()) {
      files.push(relativePath)
    }
  }
  return files
}

const distFiles = await filesUnder(distRoot)
const distPathSet = new Set(distFiles)
const runtimePaths = await runtimeAssetPaths(assetRoot)
const sourceStylePaths = (await readdir(path.join(frontendRoot, 'styles'), {
  withFileTypes: true,
}))
  .filter(entry => entry.isFile() && entry.name.endsWith('.css'))
  .map(entry => `styles/${entry.name}`)
  .sort()
let totalBytes = 0

for (const relativePath of distFiles) {
  totalBytes += (await stat(path.join(distRoot, relativePath))).size
}
for (const relativePath of REQUIRED_BROWSER_FILES) {
  assert.ok(distPathSet.has(relativePath), `missing browser file: ${relativePath}`)
}
assert.ok(
  distPathSet.has(KNOWLEDGE_DOMAIN_CATALOG_TARGET),
  `missing knowledge catalog: ${KNOWLEDGE_DOMAIN_CATALOG_TARGET}`,
)
for (const relativePath of sourceStylePaths) {
  assert.ok(distPathSet.has(relativePath), `missing stylesheet: ${relativePath}`)
}
for (const relativePath of runtimePaths) {
  assert.ok(distPathSet.has(relativePath), `missing product asset: ${relativePath}`)
}
for (const relativePath of distPathSet) {
  const searchable = `/${relativePath}`
  assert.equal(
    FORBIDDEN_RELEASE_FILES.has(relativePath),
    false,
    `legacy runtime data leaked into release: ${relativePath}`,
  )
  assert.doesNotMatch(
    relativePath,
    /\.(?:jsx|ts|tsx)$/i,
    `typed frontend source leaked into release: ${relativePath}`,
  )
  assert.doesNotMatch(
    searchable,
    /(?:^|\/)(?:react|vite)(?:\/|$)/i,
    `bundler dependency leaked into release: ${relativePath}`,
  )
  for (const segment of FORBIDDEN_RELEASE_SEGMENTS) {
    assert.equal(searchable.includes(segment), false, relativePath)
  }
  for (const segment of AUTHORING_ONLY_ASSET_SEGMENTS) {
    assert.equal(searchable.includes(segment), false, relativePath)
  }
}

const html = await readFile(path.join(distRoot, 'index.html'), 'utf8')
assert.match(html, /MoonTown · 能源谷/)
assert.doesNotMatch(html, /operations\.html|viewport\.html/)
assert.doesNotMatch(html, /\.tsx|react|typescript/i)
assert.match(html, /id="app"/)
assert.match(html, /src="\.\/bootstrap\.js(?:\?[^"\s]+)?"/)
assert.match(html, /href="\.\/styles\.css"/)

const viewportAlias = await readFile(path.join(distRoot, 'viewport.html'), 'utf8')
assert.match(viewportAlias, /MoonTown · 能源谷/)
assert.match(viewportAlias, /rel="canonical" href="\.\/index\.html"/)
assert.doesNotMatch(viewportAlias, /standalone|legacy-viewport/i)
assert.match(viewportAlias, /id="app"/)
assert.match(viewportAlias, /src="\.\/bootstrap\.js(?:\?[^"\s]+)?"/)

const bootstrap = await readFile(path.join(distRoot, 'bootstrap.js'), 'utf8')
assert.match(bootstrap, /import\('\.\/main\.js(?:\?[^'\s]+)?'\)/)
assert.match(bootstrap, /from '\.\/account_management\.js'/)
assert.doesNotMatch(bootstrap, /vite|react|typescript|\.tsx/i)
assert.doesNotMatch(
  bootstrap,
  /import\s+['"][^'"]+\.css['"]/,
  'native browser bootstrap must load styles through HTML, not a bundler import',
)

const mainStat = await stat(path.join(distRoot, 'main.js'))
assert.ok(mainStat.size > 100_000, 'compiled MoonBit entry is unexpectedly small')

const styles = await readFile(path.join(distRoot, 'styles.css'), 'utf8')
for (const match of styles.matchAll(/@import url\(["']?([^"')]+)["']?\)/g)) {
  const importedPath = path.posix.normalize(match[1])
  assert.ok(
    distPathSet.has(importedPath.replace(/^\.\//, '')),
    `missing imported stylesheet: ${match[1]}`,
  )
}

const manifestPath = path.join(distRoot, 'asset-manifest.json')
const manifest = JSON.parse(await readFile(manifestPath, 'utf8'))
assert.equal(manifest.schema, 'moontown.static-product.v1')
assert.ok(Array.isArray(manifest.files), 'asset manifest must list files')
const manifestedPaths = manifest.files.map(file => file.path)
assert.deepEqual(
  manifestedPaths,
  [...manifestedPaths].sort(),
  'asset manifest paths must be deterministic',
)
assert.deepEqual(
  new Set(manifestedPaths),
  new Set(distFiles.filter(file => file !== 'asset-manifest.json')),
  'asset manifest must describe the complete static product',
)
for (const file of manifest.files) {
  const filePath = path.join(distRoot, file.path)
  const content = await readFile(filePath)
  assert.equal((await stat(filePath)).size, file.bytes, `${file.path} size drift`)
  assert.equal(
    createHash('sha256').update(content).digest('hex'),
    file.sha256,
    `${file.path} digest drift`,
  )
}

assert.ok(
  totalBytes < MAX_DIST_BYTES,
  `production artifact is ${(totalBytes / 1024 / 1024).toFixed(1)} MiB; budget is 64 MiB`,
)

console.log(
  `Production artifact verified: ${distFiles.length} files, ${(totalBytes / 1024 / 1024).toFixed(1)} MiB`,
)

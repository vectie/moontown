import assert from 'node:assert/strict'
import { readFile, readdir, stat } from 'node:fs/promises'
import path from 'node:path'

const frontendRoot = path.resolve(import.meta.dirname, '..')
const distRoot = path.join(frontendRoot, 'dist')
const MAX_DIST_BYTES = 2 * 1024 * 1024
const FORBIDDEN_RELEASE_SEGMENTS = [
  '/backgrounds/',
  '/book-output/',
  '/effects/',
  '/props/',
  '/tilemap/',
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
  for (const entry of entries) {
    const relativePath = path.join(relativeDirectory, entry.name)
    if (entry.isDirectory()) {
      files.push(...await filesUnder(root, relativePath))
    } else if (entry.isFile()) {
      files.push(relativePath)
    }
  }
  return files
}

const distFiles = await filesUnder(distRoot)
const distPathSet = new Set(distFiles.map(file => file.split(path.sep).join('/')))
let totalBytes = 0

for (const relativePath of distFiles) {
  totalBytes += (await stat(path.join(distRoot, relativePath))).size
}
assert.ok(distPathSet.has('index.html'), 'missing packaged town entry point')
assert.ok(
  [...distPathSet].some(relativePath => /^assets\/town-.*\.js$/.test(relativePath)),
  'missing packaged town JavaScript',
)
assert.ok(
  [...distPathSet].some(relativePath => /^assets\/town-.*\.css$/.test(relativePath)),
  'missing packaged town stylesheet',
)
for (const relativePath of distPathSet) {
  const searchable = `/${relativePath.split(path.sep).join('/')}`
  assert.equal(
    FORBIDDEN_RELEASE_FILES.has(relativePath),
    false,
    `legacy runtime data leaked into release: ${relativePath}`,
  )
  for (const segment of FORBIDDEN_RELEASE_SEGMENTS) {
    assert.equal(searchable.includes(segment), false, relativePath)
  }
}

const html = await readFile(path.join(distRoot, 'index.html'), 'utf8')
assert.match(html, /MoonTown · 能源谷/)
assert.doesNotMatch(html, /operations\.html|viewport\.html/)
assert.ok(
  totalBytes < MAX_DIST_BYTES,
  `production artifact is ${(totalBytes / 1024 / 1024).toFixed(1)} MiB; budget is 2 MiB`,
)

console.log(
  `Production artifact verified: ${distFiles.length} files, ${(totalBytes / 1024 / 1024).toFixed(1)} MiB`,
)

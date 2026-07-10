import assert from 'node:assert/strict'
import { readdir, stat } from 'node:fs/promises'
import path from 'node:path'
import {
  AUTHORING_ONLY_ASSET_SEGMENTS,
  runtimeAssetPaths,
} from '../runtime_asset_manifest.js'

const frontendRoot = path.resolve(import.meta.dirname, '..')
const assetRoot = path.resolve(frontendRoot, '../assets')
const distRoot = path.join(frontendRoot, 'dist')
const MAX_DIST_BYTES = 64 * 1024 * 1024

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

const runtimePaths = await runtimeAssetPaths(assetRoot)
const distFiles = await filesUnder(distRoot)
const distPathSet = new Set(distFiles.map(file => file.split(path.sep).join('/')))
let totalBytes = 0

for (const relativePath of distFiles) {
  totalBytes += (await stat(path.join(distRoot, relativePath))).size
}
for (const relativePath of runtimePaths) {
  assert.ok(distPathSet.has(relativePath), `missing dist asset: ${relativePath}`)
}
for (const relativePath of distPathSet) {
  const searchable = `/${relativePath}`
  for (const segment of AUTHORING_ONLY_ASSET_SEGMENTS) {
    assert.equal(searchable.includes(segment), false, relativePath)
  }
}
assert.ok(
  totalBytes < MAX_DIST_BYTES,
  `production artifact is ${(totalBytes / 1024 / 1024).toFixed(1)} MiB; budget is 64 MiB`,
)

console.log(
  `Production artifact verified: ${distFiles.length} files, ${(totalBytes / 1024 / 1024).toFixed(1)} MiB`,
)

import { createHash } from 'node:crypto'
import {
  copyFile,
  mkdir,
  readFile,
  readdir,
  rename,
  rm,
  stat,
  writeFile,
} from 'node:fs/promises'
import path from 'node:path'
import {
  KNOWLEDGE_DOMAIN_CATALOG_SOURCE,
  KNOWLEDGE_DOMAIN_CATALOG_TARGET,
  resolveRuntimeAssetPath,
  runtimeAssetPaths,
} from '../runtime_asset_manifest.js'

const frontendRoot = path.resolve(import.meta.dirname, '..')
const assetRoot = path.resolve(frontendRoot, '../assets')
const distRoot = path.join(frontendRoot, 'dist')
const stagingRoot = path.join(frontendRoot, '.dist-next')
const compiledMainPath = path.join(
  frontendRoot,
  '_build/js/release/build/vectie/moontown-rabbita/main/main.js',
)

const BROWSER_FILES = [
  'index.html',
  'viewport.html',
  'operations.html',
  'bootstrap.js',
  'runtime_snapshot_fetch.js',
  'runtime_snapshot_manifest.js',
  'runtime_snapshot_parser.js',
  'runtime_snapshots.js',
  'viewport_drag_pan.js',
  'styles.css',
]

async function copyRequiredFile(sourcePath, relativePath) {
  const sourceStat = await stat(sourcePath)
  if (!sourceStat.isFile()) {
    throw new Error(`Required product input is not a file: ${sourcePath}`)
  }
  const targetPath = path.join(stagingRoot, relativePath)
  await mkdir(path.dirname(targetPath), { recursive: true })
  await copyFile(sourcePath, targetPath)
}

async function stylePaths() {
  const entries = await readdir(path.join(frontendRoot, 'styles'), {
    withFileTypes: true,
  })
  return entries
    .filter(entry => entry.isFile() && entry.name.endsWith('.css'))
    .map(entry => `styles/${entry.name}`)
    .sort()
}

async function filesUnder(root, relativeDirectory = '') {
  const entries = await readdir(path.join(root, relativeDirectory), {
    withFileTypes: true,
  })
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

async function fileDigest(filePath) {
  return createHash('sha256').update(await readFile(filePath)).digest('hex')
}

async function writeAssetManifest() {
  const paths = (await filesUnder(stagingRoot)).sort()
  const files = []
  for (const relativePath of paths) {
    const filePath = path.join(stagingRoot, relativePath)
    files.push({
      path: relativePath,
      bytes: (await stat(filePath)).size,
      sha256: await fileDigest(filePath),
    })
  }
  await writeFile(
    path.join(stagingRoot, 'asset-manifest.json'),
    `${JSON.stringify({
      schema: 'moontown.static-product.v1',
      files,
    }, null, 2)}\n`,
    'utf8',
  )
}

async function assemble() {
  await rm(stagingRoot, { recursive: true, force: true })
  await mkdir(stagingRoot, { recursive: true })

  for (const relativePath of BROWSER_FILES) {
    await copyRequiredFile(path.join(frontendRoot, relativePath), relativePath)
  }
  for (const relativePath of await stylePaths()) {
    await copyRequiredFile(path.join(frontendRoot, relativePath), relativePath)
  }
  await copyRequiredFile(compiledMainPath, 'main.js')

  for (const relativePath of await runtimeAssetPaths(assetRoot)) {
    await copyRequiredFile(
      resolveRuntimeAssetPath(assetRoot, relativePath),
      relativePath,
    )
  }
  await copyRequiredFile(
    path.resolve(frontendRoot, KNOWLEDGE_DOMAIN_CATALOG_SOURCE),
    KNOWLEDGE_DOMAIN_CATALOG_TARGET,
  )

  await writeAssetManifest()
  await rm(distRoot, { recursive: true, force: true })
  await rename(stagingRoot, distRoot)
}

await assemble()

const files = await filesUnder(distRoot)
console.log(`Static MoonBit product assembled: ${files.length} files`)

import { existsSync } from 'node:fs'
import { readdir, readFile } from 'node:fs/promises'
import path from 'node:path'

const FIXED_RUNTIME_ASSETS = [
  'backgrounds/town-square.svg',
  'effects/anomaly-signal.svg',
  'props/gate-sign.svg',
  'tilemap/actors/keeper_walk_1.png',
  'tilemap/actors/keeper_walk_strip.png',
  'tilemap/actors/mayor_walk_1.png',
  'tilemap/actors/mayor_walk_strip.png',
  'tilemap/actors/researcher_walk_strip.png',
  'tilemap/actors/worker_walk_1.png',
  'tilemap/actors/worker_walk_strip.png',
  'tilemap/actors/roster/resident_0.png',
  'tilemap/actors/roster/resident_1.png',
  'tilemap/actors/roster/resident_2.png',
  'tilemap/buildings/book_house_base.png',
  'tilemap/buildings/book_house_roof.png',
  'tilemap/buildings/city_hall_base.png',
  'tilemap/buildings/city_hall_roof.png',
  'tilemap/buildings/worker_yard_base.png',
  'tilemap/buildings/worker_yard_roof.png',
  'tilemap/modules/moondesk-handoff.json',
  'tilemap/modules/wenyu-town-modules.json',
  'tilemap/wenyu_reference_labels.json',
  'tilemap/wenyu_reference_tilemap_iso.png',
]

const RUNTIME_ASSET_DIRECTORIES = [
  'tilemap/districts',
  'tilemap/objects',
  'tilemap/tiles',
]

const MODULE_CONFIG_PATH = 'tilemap/modules/wenyu-town-modules.json'

function safeRuntimePath(relativePath) {
  const normalized = path.posix.normalize(String(relativePath || ''))
  if (
    !normalized ||
    normalized === '.' ||
    normalized.startsWith('../') ||
    normalized.includes('\\') ||
    path.posix.isAbsolute(normalized)
  ) {
    throw new Error(`Unsafe runtime asset path: ${relativePath}`)
  }
  return normalized
}

export function resolveRuntimeAssetPath(assetRoot, relativePath) {
  const normalized = safeRuntimePath(relativePath)
  const root = path.resolve(assetRoot)
  const resolved = path.resolve(root, ...normalized.split('/'))
  if (resolved !== root && !resolved.startsWith(`${root}${path.sep}`)) {
    throw new Error(`Runtime asset escapes source root: ${relativePath}`)
  }
  return resolved
}

async function directoryAssetPaths(assetRoot, relativeDirectory) {
  const entries = await readdir(path.join(assetRoot, relativeDirectory), {
    withFileTypes: true,
  })
  return entries
    .filter(entry => entry.isFile() && !entry.name.startsWith('.'))
    .map(entry => `${relativeDirectory}/${entry.name}`)
}

async function configuredModuleAssetPaths(assetRoot) {
  const config = JSON.parse(
    await readFile(path.join(assetRoot, MODULE_CONFIG_PATH), 'utf8'),
  )
  return (config.modules || []).map(module => safeRuntimePath(module.asset_base))
}

export async function runtimeAssetPaths(assetRoot) {
  const paths = new Set(FIXED_RUNTIME_ASSETS)

  for (const directory of RUNTIME_ASSET_DIRECTORIES) {
    for (const relativePath of await directoryAssetPaths(assetRoot, directory)) {
      paths.add(relativePath)
    }
  }

  for (let index = 0; index < 64; index += 1) {
    paths.add(`tilemap/actors/roster/resident_${index}_walk_strip.png`)
  }

  for (const relativePath of await configuredModuleAssetPaths(assetRoot)) {
    paths.add(relativePath)
  }

  const validated = [...paths].map(safeRuntimePath).sort()
  for (const relativePath of validated) {
    if (!existsSync(resolveRuntimeAssetPath(assetRoot, relativePath))) {
      throw new Error(`Missing runtime asset: ${relativePath}`)
    }
  }
  return validated
}

export const AUTHORING_ONLY_ASSET_SEGMENTS = [
  '/source/',
  '/prompts/',
  '/style-sheets/',
  '/tilesets/',
]

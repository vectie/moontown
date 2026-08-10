import { existsSync } from 'node:fs'
import { readdir, readFile } from 'node:fs/promises'
import path from 'node:path'

const FIXED_RUNTIME_ASSETS = [
  'moontown.svg',
  'moonsuite-i18n.js',
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
  'tilemap/buildings/moontown-spring-civic-v1/ai-garden.png',
  'tilemap/buildings/moontown-spring-civic-v1/contest-express.png',
  'tilemap/buildings/moontown-spring-civic-v1/physical-bridge.png',
  'tilemap/buildings/moontown-spring-civic-v1/policy-hall.png',
  'tilemap/buildings/moontown-spring-civic-v1/research-ai-agents.png',
  'tilemap/buildings/moontown-spring-civic-v1/research-ai-hardware.png',
  'tilemap/buildings/moontown-spring-civic-v1/research-embodied-robotics.png',
  'tilemap/buildings/moontown-spring-civic-v1/research-llm-training.png',
  'tilemap/buildings/moontown-spring-civic-v1/research-opc.png',
  'tilemap/buildings/moontown-spring-civic-v1/resident-twins.png',
  'tilemap/buildings/moontown-spring-civic-v1/social-square.png',
  'tilemap/buildings/moontown-spring-civic-v1/story-radar.png',
  'tilemap/buildings/moontown-spring-civic-v1/talent-avenue.png',
  'tilemap/buildings/moontown-spring-civic-v1/town-shell.png',
  'tilemap/buildings/moontown-spring-civic-v1/valley-market.png',
  'tilemap/buildings/moontown-spring-civic-v1/vitality-tower.png',
  'tilemap/buildings/moontown-spring-ambient-v1/block-0.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/block-1.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/block-2.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/block-3.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/block-4.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/block-5.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/block-6.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/block-7.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/block-8.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/block-9.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/campus-0.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/campus-1.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/campus-2.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/campus-3.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/campus-4.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/campus-5.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/campus-6.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/campus-7.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/campus-8.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/campus-9.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/civic-0.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/civic-1.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/civic-2.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/civic-3.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/civic-4.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/civic-5.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/civic-6.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/civic-7.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/civic-8.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/civic-9.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/courtyard-0.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/courtyard-1.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/courtyard-2.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/courtyard-3.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/courtyard-4.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/courtyard-5.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/courtyard-6.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/courtyard-7.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/courtyard-8.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/courtyard-9.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/industrial-0.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/industrial-1.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/industrial-2.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/industrial-3.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/industrial-4.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/industrial-5.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/industrial-6.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/industrial-7.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/industrial-8.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/industrial-9.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/lowrise-0.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/lowrise-1.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/lowrise-2.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/lowrise-3.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/lowrise-4.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/lowrise-5.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/lowrise-6.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/lowrise-7.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/lowrise-8.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/lowrise-9.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/row-0.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/row-1.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/row-2.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/row-3.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/row-4.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/row-5.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/row-6.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/row-7.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/row-8.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/row-9.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/tower-0.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/tower-1.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/tower-2.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/tower-3.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/tower-4.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/tower-5.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/tower-6.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/tower-7.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/tower-8.webp',
  'tilemap/buildings/moontown-spring-ambient-v1/tower-9.webp',
  'tilemap/buildings/worker_yard_base.png',
  'tilemap/buildings/worker_yard_roof.png',
  'tilemap/modules/moondesk-handoff.json',
  'tilemap/modules/wenyu-town-modules.json',
  'tilemap/wenyu_reference_buildings.json',
  'tilemap/wenyu_reference_intersections.json',
  'tilemap/energy-valley-osm-block-graph-v1.json',
  'tilemap/wenyu_reference_labels.json',
  'tilemap/wenyu_reference_roads.json',
  'tilemap/wenyu_reference_tilemap_iso.png',
]

const RUNTIME_ASSET_DIRECTORIES = [
  'tilemap/districts',
  'tilemap/objects',
  'tilemap/tiles',
]

const MODULE_CONFIG_PATH = 'tilemap/modules/wenyu-town-modules.json'

// The knowledge catalog is authored by MoonTown's domain-template layer rather
// than the tile asset tree. The production assembler copies this canonical
// source to a stable browser URL so the Rabbita UI never needs repository-path
// knowledge at runtime.
export const KNOWLEDGE_DOMAIN_CATALOG_SOURCE =
  '../../../assets/templates/domains/catalog.v1.json'
export const KNOWLEDGE_DOMAIN_CATALOG_TARGET =
  'knowledge-domain-catalog.json'

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
  '/georeference/',
  '/source/',
  '/prompts/',
  '/style-sheets/',
  '/tilesets/',
]

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
// The governed spatial layers include two transparent authored prop atlases.
// Keep their release cost inside a narrow, explicit ceiling.
// Add the preserved offline Three.js studio and its pinned vendor modules.
// The complete studio, street-registered building tiles and gzip sidecars
// share the town release ceiling with the current coffee theme and awards.
// Round 2 adds a compressed theme reference, two real prize cutouts and the
// exact new claim QR. Include their sidecars inside a further 1 MiB ceiling.
const MAX_DIST_BYTES = 74 * 1024 * 1024
const REQUIRED_BROWSER_FILES = [
  'landmark-studio/wlxk.html',
  'index.html',
  'viewport.html',
  'operations.html',
  'hackathon.html',
  'coffee-contest.html',
  'coffee-contest.js',
  'coffee-auth.js',
  'coffee-acquisition.js',
  'coffee-drafts.js',
  'coffee-claim.js',
  'coffee-share.js',
  'coffee-themes.js',
  'coffee-qr.js',
  'coffee-contest.css',
  'coffee-vote-preview.html',
  'coffee-vote-preview.js',
  'hackathon.js',
  'competition-ui.js',
  'hackathon.css',
  'account_demo_fixtures.js',
  'account_management.js',
  'bootstrap.js',
  'platform-base.js',
  'platform-scope.js',
  'pack_bridge_panel.js',
  'pack_candidate_sources.js',
  'pack_material_groups.js',
  'pack_material_review.js',
  'pack_cross_pack_question.js',
  'pack_question_composer.js',
  'pack_observation_changes.js',
  'pack_observation_review.js',
  'pack_vocabulary.js',
  'pack_vocabulary_explorer.js',
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
  'landmark-studio/interior-reference.jpg',
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

const interiorHtml = await readFile(
  path.join(distRoot, 'landmark-studio/interior.html'), 'utf8',
)
assert.doesNotMatch(interiorHtml, /interior-reference\.jpg/)

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
assert.match(viewportAlias, /location\.replace\(destination\.href\)/)
assert.match(viewportAlias, /destination\.search = location\.search/)
assert.doesNotMatch(viewportAlias, /bootstrap\.js/)

const bootstrap = await readFile(path.join(distRoot, 'bootstrap.js'), 'utf8')
assert.match(bootstrap, /import\('\.\/main\.js(?:\?[^'\s]+)?'\)/)
assert.match(bootstrap, /import\('\.\/account_management\.js'\)/)
assert.doesNotMatch(bootstrap, /vite|react|typescript|\.tsx/i)
assert.doesNotMatch(
  bootstrap,
  /import\s+['"][^'"]+\.css['"]/,
  'native browser bootstrap must load styles through HTML, not a bundler import',
)

const mainStat = await stat(path.join(distRoot, 'main.js'))
assert.ok(mainStat.size > 100_000, 'compiled MoonBit entry is unexpectedly small')

const projectionRoot = path.join(distRoot, 'landmark-studio')
const projectionVersion = JSON.parse(await readFile(path.join(projectionRoot, 'town-projection-version.json'), 'utf8'))
const projections = JSON.parse(await readFile(path.join(projectionRoot, 'town-projections/manifest.json'), 'utf8'))
assert.equal(projections.version, projectionVersion.sha256, 'Rebake the landmark models using ?landmarks=center&bake-tiles=1 and import-town-projections.mbtx')
const expectedModels = ['vision', 'east-bridge', 'arch-bridge', ...Array.from({length:7}, (_,i)=>`center-${i+1}`)].sort()
assert.deepEqual(projections.tiles.map(p=>p.id).sort(), expectedModels)
for(const tile of projections.tiles){
  assert.ok(distPathSet.has('landmark-studio/'+tile.source))
  if(tile.id.endsWith('bridge')) assert.ok(distPathSet.has('landmark-studio/'+tile.front?.source))
}
const styles = await readFile(path.join(distRoot, 'styles.css'), 'utf8')
for (const match of styles.matchAll(/@import url\(["']?([^"')]+)["']?\)/g)) {
  const importedPath = path.posix.normalize(match[1])
  assert.ok(
    distPathSet.has(importedPath.replace(/^\.\//, '')),
    `missing imported stylesheet: ${match[1]}`,
  )
}

// Verify the actual default town payload after the compact-polyline packaging step.
const scenePath = 'tilemap/wenyu-bank-scene-v2.json'
const shippedRoads = JSON.parse(await readFile(path.join(distRoot,scenePath),'utf8'))
const roadAudit = JSON.parse(await readFile(path.resolve(frontendRoot,'../../../docs/project/wenyu-town-road-audit.json'),'utf8'))
assert.equal(shippedRoads.layout,'major-road-fit')
assert.equal(roadAudit.leftDike.surfaceWet,0)
const dike = shippedRoads.paths.find(way=>way.id===roadAudit.leftDike.way)
assert.ok(dike?.polyline && shippedRoads.parcelRuns.length)
const roadOverlay = 'tilemap/wenyu-bank-road-v2.svg'
assert.deepEqual(await readFile(path.join(distRoot,roadOverlay)),await readFile(path.join(assetRoot,roadOverlay)))
const shoreReview = JSON.parse(await readFile(path.join(distRoot,'landmark-studio/town-road-review.json'),'utf8'))
const shownWet = shoreReview.contacts.reduce((sum,[x,y,u,v])=>sum+Math.hypot(u-x,v-y),0)
assert.ok(Math.abs(shownWet-roadAudit.surfaceEnvelopeAfter)<0.02)
assert.ok(shoreReview.focus[dike.id] && shoreReview.crossings.length>0)

const tour = await readFile(path.join(distRoot, 'landmark-studio/wlxk.html'))
assert.equal(createHash('sha256').update(tour).digest('hex'),
  '0af7631133bf393539be890e6be01d19965326c58af52cccfcb45f776e1d096c',
  'The published energy valley tour must match the reviewed server-integrated release')

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

// The optional geographic overview is fetched only on demand. Keep its data and
// camera-specific tiles in their own measured allowance and retain the street budget.
const wheelNames=['overview',...Array.from({length:16},(_,i)=>i%4+'-'+Math.floor(i/4))]
let wheelBytes=0
for(const [prefix,limit] of [['wheel-',2],['frontier-wheel-',5]]){
  const inputs=JSON.parse(await readFile(path.resolve(frontendRoot,'../landmark-studio/'+prefix+'art-sources.json'),'utf8'))
  for(const [file,version] of Object.entries(inputs)){
    const bytes=await readFile(path.resolve(frontendRoot,'../../..',file))
    assert.equal(createHash('sha256').update(bytes).digest('hex'),version,'Map inputs changed: rebake the affected camera atlas')
  }
  const files=manifest.files.filter(f=>f.path.startsWith('landmark-studio/town-projections/'+prefix)&&f.path.endsWith('.webp'))
  assert.deepEqual(files.map(f=>f.path.split('/').pop()).sort(),wheelNames.map(n=>prefix+n+'.webp').sort())
  const bytes=files.reduce((n,f)=>n+f.bytes,0)
  wheelBytes+=bytes
  assert.ok(bytes>0 && bytes<limit*1024*1024,prefix+' optional scenery exceeds its transfer budget')
}
const regionalFiles = manifest.files.filter(f => /^landmark-studio\/(?:town-projections\/)?region-/.test(f.path))
const regionalBytes = regionalFiles.reduce((total, f) => total + f.bytes, 0)
assert.ok(regionalBytes > 0 && regionalBytes < 1280 * 1024, 'regional map exceeds its 1.25 MiB release allowance')
const anchors = JSON.parse(await readFile(path.join(projectionRoot, 'region-anchors.json'), 'utf8'))
const regionalProjection = JSON.parse(await readFile(path.join(projectionRoot, 'region-projections.json'), 'utf8'))
const regionalVersion = createHash('sha256')
for (const source of ['models.js','town-bake.js','scene-adapter.js','region-geometry.js']) {
  regionalVersion.update(await readFile(path.resolve(frontendRoot,'../landmark-studio/web',source)))
}
regionalVersion.update(JSON.stringify(anchors.landmarkAxes))
assert.equal(regionalProjection.version,regionalVersion.digest('hex'),'rebake the regional camera with scripts/bake-science-city-landmarks.mbtx')
const regionTiles = regionalProjection.tiles
assert.deepEqual(regionTiles.map(t=>t.id).sort(), expectedModels)
for (const t of regionTiles) {
  assert.ok(anchors.landmarks[t.id] && distPathSet.has('landmark-studio/'+t.source))
  if(t.id.endsWith('-bridge'))assert.ok(t.front && distPathSet.has('landmark-studio/'+t.front.source))
}
const studies = JSON.parse(await readFile(path.join(projectionRoot, 'district-studies.json'), 'utf8'))
for (const b of studies.blocks.filter(b=>!b.base[0])) {
  const registration = anchors.registration[b.key]
  assert.ok(registration?.controls.length && registration.matrix.every(Number.isFinite), 'missing registration for '+b.key)
  const [a,bearing] = registration.matrix
  assert.ok(Math.abs(Math.atan2(bearing,a)) < Math.PI/6 && Math.hypot(a,bearing)>.6 && Math.hypot(a,bearing)<1.65, 'inconsistent source plan orientation')
}
const baselineFiles = manifest.files.filter(f => /^landmark-studio\/public-world-[a-f0-9]{20}\.bin$/.test(f.path))
assert.equal(baselineFiles.length,1,'missing compiled public world')
const baselineBytes = baselineFiles[0].bytes
assert.ok(baselineBytes <= 1.3 * 1024 * 1024,'compressed world exceeds its startup transfer budget')
const tourFiles = manifest.files.filter(f => /^landmark-studio\/wlxk\.html(?:\.gz|\.etag)?$/.test(f.path))
assert.equal(tourFiles.length, 3, 'the standalone tour requires HTML, gzip and ETag')
const tourBytes = tourFiles.reduce((sum, file) => sum + file.bytes, 0)
assert.ok(tourBytes < 576 * 1024, 'on-demand tour exceeds its 576 KiB release allowance')
assert.ok(
  totalBytes - regionalBytes - baselineBytes - wheelBytes - tourBytes < MAX_DIST_BYTES,
  `street and existing studios are ${((totalBytes-regionalBytes-baselineBytes-wheelBytes-tourBytes) / 1024 / 1024).toFixed(1)} MiB; budget is ${MAX_DIST_BYTES / 1024 / 1024} MiB`,
)

console.log(
  `Production artifact verified: ${distFiles.length} files, ${(totalBytes / 1024 / 1024).toFixed(1)} MiB`,
)

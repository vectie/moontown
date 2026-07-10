import { existsSync } from 'node:fs'
import { mkdir, readdir, readFile, writeFile } from 'node:fs/promises'
import path from 'node:path'
import { loadModuleProjectionIndex } from './vite_book_projections.js'
import { loadMoondeskBridgeIndex } from './vite_moondesk_bridge.js'
import {
  bookTemplateRequestPath,
  booksRootPath,
  civicStatusPath,
  daemonSnapshotPath,
  editorPipelinePath,
  keyBookOutputFiles,
  liveAutonomyPath,
  liveDigestPath,
  operatorRequestLedgerPath,
  standingGoalsPath,
  townSnapshotPath,
  visualProjectionPath,
  watcherDir,
} from './vite_server_paths.js'
import {
  loadWatcherLedgerIndex,
  readJsonlRows,
} from './vite_watcher_ledgers.js'
import { writeJsonFile } from './vite_server_io.js'

async function copyTextFileIfExists(sourcePath, targetPath) {
  if (!existsSync(sourcePath)) {
    return
  }

  await writeFile(targetPath, await readFile(sourcePath, 'utf8'), 'utf8')
}

async function copyBookProjectionOutputs(distDir, moduleProjectionIndex) {
  for (const projection of moduleProjectionIndex.projections) {
    for (const relativePath of keyBookOutputFiles) {
      const sourcePath = path.join(booksRootPath, projection.book_id, relativePath)
      if (!existsSync(sourcePath)) {
        continue
      }
      const targetPath = path.join(
        distDir,
        'book-output',
        projection.book_id,
        relativePath,
      )
      await mkdir(path.dirname(targetPath), { recursive: true })
      await writeFile(targetPath, await readFile(sourcePath))
    }
  }
}

async function exportWatcherLedgers(distDir) {
  if (!existsSync(watcherDir)) {
    return
  }

  const watcherDistDir = path.join(distDir, 'watchers')
  await mkdir(watcherDistDir, { recursive: true })
  const entries = await readdir(watcherDir, { withFileTypes: true })
  for (const entry of entries) {
    if (!entry.isFile() || !entry.name.endsWith('.jsonl')) {
      continue
    }
    const rows = await readJsonlRows(path.join(watcherDir, entry.name))
    await writeJsonFile(path.join(watcherDistDir, entry.name), rows)
  }
  await writeJsonFile(path.join(watcherDistDir, 'index.json'), await loadWatcherLedgerIndex())
}

export async function exportStaticRuntimeBundle() {
  const distDir = path.resolve(process.cwd(), 'dist')
  await mkdir(distDir, { recursive: true })

  await copyTextFileIfExists(townSnapshotPath, path.join(distDir, 'town.json'))
  await copyTextFileIfExists(
    visualProjectionPath,
    path.join(distDir, 'visual-projection.json'),
  )

  const moduleProjectionIndex = await loadModuleProjectionIndex()
  await writeJsonFile(path.join(distDir, 'module-projections.json'), moduleProjectionIndex)
  await writeJsonFile(path.join(distDir, 'moondesk-bridge.json'), await loadMoondeskBridgeIndex())

  await copyTextFileIfExists(civicStatusPath, path.join(distDir, 'civic-status.json'))
  await copyBookProjectionOutputs(distDir, moduleProjectionIndex)
  await copyTextFileIfExists(daemonSnapshotPath, path.join(distDir, 'daemon.json'))
  await copyTextFileIfExists(liveAutonomyPath, path.join(distDir, 'live-autonomy.json'))
  await copyTextFileIfExists(editorPipelinePath, path.join(distDir, 'editor-pipeline.json'))
  await copyTextFileIfExists(liveDigestPath, path.join(distDir, 'live-digest.md'))
  await copyTextFileIfExists(standingGoalsPath, path.join(distDir, 'standing-goals.json'))
  await copyTextFileIfExists(
    bookTemplateRequestPath,
    path.join(distDir, 'book-template-requests.json'),
  )
  if (existsSync(operatorRequestLedgerPath)) {
    await writeJsonFile(
      path.join(distDir, 'operator-requests.json'),
      await readJsonlRows(operatorRequestLedgerPath),
    )
  }
  await exportWatcherLedgers(distDir)
}

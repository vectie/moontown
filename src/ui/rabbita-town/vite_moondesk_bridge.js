import { existsSync } from 'node:fs'
import { readdir, stat } from 'node:fs/promises'
import path from 'node:path'
import {
  bookResultDir,
  moondeskDispatchDir,
  moondeskRequestDir,
  moondeskRootPath,
} from './vite_server_paths.js'
import { readJsonFile } from './vite_server_io.js'

function firstUsefulLine(value) {
  const text = String(value || '')
  const lines = text
    .split('\n')
    .map(line => line.trim())
    .filter(Boolean)
  return lines[0] || ''
}

function truncateText(value, maxLength = 260) {
  const text = String(value || '').replace(/\s+/g, ' ').trim()
  if (text.length <= maxLength) {
    return text
  }
  return `${text.slice(0, maxLength - 1)}…`
}

function bridgeRecordFromJson(kind, filePath, fileStat, value) {
  const id = String(value?.id || path.basename(filePath, '.json'))
  const relativePath = path.relative(path.resolve(process.cwd(), '../..'), filePath)
  if (kind === 'dispatch') {
    const ok = value?.ok === true
    const status = String(value?.status || (ok ? 'completed' : 'needs review'))
    return {
      id,
      kind: 'dispatch',
      status: ok ? 'ready' : 'review',
      path: relativePath,
      title: `Moondesk dispatch: ${status}`,
      summary: truncateText(firstUsefulLine(value?.stdout) || firstUsefulLine(value?.stderr) || status),
      target: 'Moontown daemon / mayor tick',
      created_at: fileStat.mtime.toISOString(),
    }
  }

  if (kind === 'request') {
    const title = String(value?.title || id)
    return {
      id,
      kind: 'operator-request',
      status: String(value?.status || 'staged'),
      path: relativePath,
      title,
      summary: truncateText(value?.prompt || value?.summary || 'Moondesk staged an operator request for Moontown.'),
      target: String(value?.target_book_id || value?.standing_goal_id || 'Moontown standing goal'),
      created_at: String(value?.created_at || fileStat.mtime.toISOString()),
    }
  }

  const title = String(value?.task_id || id)
  return {
    id,
    kind: 'book-result',
    status: value?.requires_review === true ? 'review' : 'ready',
    path: relativePath,
    title,
    summary: truncateText(value?.summary || firstUsefulLine(value?.detail) || 'MoonBook/MoonClaw result artifact is available.'),
    target: Array.isArray(value?.artifacts)
      ? `${value.artifacts.length} artifact links`
      : 'MoonBook result ledger',
    created_at: fileStat.mtime.toISOString(),
  }
}

async function loadLatestJsonRecords(directoryPath, kind, limit = 8) {
  if (!existsSync(directoryPath)) {
    return []
  }

  const entries = await readdir(directoryPath, { withFileTypes: true })
  const files = []
  for (const entry of entries) {
    if (!entry.isFile() || !entry.name.endsWith('.json')) {
      continue
    }
    const filePath = path.join(directoryPath, entry.name)
    files.push({ filePath, fileStat: await stat(filePath) })
  }

  files.sort((left, right) => right.fileStat.mtimeMs - left.fileStat.mtimeMs)
  const records = []
  for (const file of files.slice(0, limit)) {
    const value = await readJsonFile(file.filePath, null)
    if (!value) {
      continue
    }
    records.push(bridgeRecordFromJson(kind, file.filePath, file.fileStat, value))
  }
  return records
}

export async function loadMoondeskBridgeIndex() {
  const records = [
    ...await loadLatestJsonRecords(moondeskDispatchDir, 'dispatch', 8),
    ...await loadLatestJsonRecords(moondeskRequestDir, 'request', 8),
    ...await loadLatestJsonRecords(bookResultDir, 'book-result', 10),
  ]

  records.sort((left, right) => String(right.created_at).localeCompare(String(left.created_at)))
  return {
    generated_at: new Date().toISOString(),
    moondesk_root_available: existsSync(moondeskRootPath),
    records: records.slice(0, 18),
  }
}

import { existsSync } from 'node:fs'
import { readdir, readFile } from 'node:fs/promises'
import path from 'node:path'
import { watcherDir } from './vite_server_paths.js'
import { sendJson } from './vite_server_io.js'

export async function serveJsonlAsArray(res, filePath) {
  if (!existsSync(filePath)) {
    sendJson(res, [])
    return
  }

  const rows = await readJsonlRows(filePath)
  sendJson(res, rows)
}

export async function readJsonlRows(filePath) {
  if (!existsSync(filePath)) {
    return []
  }

  return (await readFile(filePath, 'utf8'))
    .split('\n')
    .map(line => line.trim())
    .filter(Boolean)
    .map(line => {
      try {
        return JSON.parse(line)
      } catch {
        return null
      }
    })
    .filter(Boolean)
}

function detailMetric(row, key) {
  if (row?.[key] !== undefined && row?.[key] !== null) {
    return row[key]
  }
  const detail = String(row?.detail || '')
  const escaped = key.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  const match = detail.match(new RegExp(`(?:^|\\n)${escaped}:\\s*([^\\n]+)`))
  if (!match) {
    return undefined
  }
  const raw = match[1].trim()
  if (/^-?\d+$/.test(raw)) {
    return Number(raw)
  }
  return raw
}

function enrichWatcherRow(row, goalId) {
  return {
    ...row,
    goal_id: String(row.goal_id || goalId),
    checked_sources_count: detailMetric(row, 'checked_sources_count'),
    new_sources_found: detailMetric(row, 'new_sources_found'),
    accepted_facts_count: detailMetric(row, 'accepted_facts_count'),
    rejected_facts_count: detailMetric(row, 'rejected_facts_count'),
    wiki_pages_changed_count: detailMetric(row, 'wiki_pages_changed_count'),
    book_changed: detailMetric(row, 'book_changed'),
  }
}

export async function loadWatcherLedgerIndex() {
  if (!existsSync(watcherDir)) {
    return []
  }

  const entries = await readdir(watcherDir, { withFileTypes: true })
  const rows = []
  for (const entry of entries) {
    if (!entry.isFile() || !entry.name.endsWith('.jsonl')) {
      continue
    }
    const goalId = entry.name.replace(/\.jsonl$/, '')
    const fileRows = await readJsonlRows(path.join(watcherDir, entry.name))
    for (const row of fileRows) {
      rows.push(enrichWatcherRow(row, goalId))
    }
  }

  rows.sort((left, right) => {
    const tickDelta = Number(left.tick || 0) - Number(right.tick || 0)
    if (tickDelta !== 0) {
      return tickDelta
    }
    return String(left.goal_id || '').localeCompare(String(right.goal_id || ''))
  })
  return rows
}

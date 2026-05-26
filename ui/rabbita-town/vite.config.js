import { defineConfig } from 'vite'
import rabbita from '@rabbita/vite'
import { existsSync } from 'node:fs'
import { mkdir, readdir, readFile, stat, writeFile } from 'node:fs/promises'
import path from 'node:path'

const townSnapshotPath = path.resolve(process.cwd(), '../../.moontown/town.json')
const visualProjectionPath = path.resolve(process.cwd(), '../../.moontown/visual-projection.json')
const daemonSnapshotPath = path.resolve(process.cwd(), '../../.moontown/daemon.json')
const standingGoalsPath = path.resolve(process.cwd(), '../../.moontown/standing-goals.json')
const watcherDir = path.resolve(process.cwd(), '../../.moontown/watchers')
const operatorRequestDir = path.resolve(process.cwd(), '../../.moontown/operator-requests')
const operatorRequestLedgerPath = path.join(operatorRequestDir, 'requests.jsonl')
const booksRootPath = path.resolve(process.cwd(), '../../.moontown/books')
const bookResultDir = path.resolve(process.cwd(), '../../.moontown/book-results')
const moondeskRootPath = path.resolve(process.cwd(), '../../../moondesk')
const moondeskDispatchDir = path.resolve(process.cwd(), '../../.moontown/moondesk-dispatches')
const moondeskRequestDir = path.resolve(process.cwd(), '../../.moontown/moondesk-requests')

const keyBookOutputFiles = [
  'book/Home.html',
  'book/index.html',
  'book/site/generated/index.html',
  'book/synthesis/report.html',
  'book/synthesis/overview.html',
  'book/synthesis/evidence.html',
  'book/reviews/pending.html',
]

function serveJsonSnapshot(res, snapshotPath, missingMessage) {
  if (!existsSync(snapshotPath)) {
    res.statusCode = 404
    res.setHeader('Content-Type', 'application/json')
    res.end(`{"error":"${missingMessage}"}`)
    return false
  }

  return true
}

function safeSegment(value, fallback = 'request') {
  const cleaned = String(value || '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 80)
  return cleaned || fallback
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let body = ''
    req.on('data', chunk => {
      body += chunk
      if (body.length > 128 * 1024) {
        reject(new Error('request body too large'))
        req.destroy()
      }
    })
    req.on('end', () => resolve(body))
    req.on('error', reject)
  })
}

async function readJsonArray(filePath) {
  if (!existsSync(filePath)) {
    return []
  }

  const text = await readFile(filePath, 'utf8')
  const parsed = JSON.parse(text)
  return Array.isArray(parsed) ? parsed : []
}

async function appendJsonLine(filePath, value) {
  await mkdir(path.dirname(filePath), { recursive: true })
  let previous = ''
  if (existsSync(filePath)) {
    previous = await readFile(filePath, 'utf8')
  }
  const prefix = previous && !previous.endsWith('\n') ? `${previous}\n` : previous
  await writeFile(filePath, `${prefix}${JSON.stringify(value)}\n`, 'utf8')
}

async function readJsonFile(filePath, fallback) {
  if (!existsSync(filePath)) {
    return fallback
  }
  try {
    return JSON.parse(await readFile(filePath, 'utf8'))
  } catch {
    return fallback
  }
}

function projectionLinksForBook(bookId, bookRoot) {
  const candidates = [
    ['Home', 'book/Home.html', 'home'],
    ['Generated site', 'book/site/generated/index.html', 'site'],
    ['Research report', 'book/synthesis/report.html', 'report'],
    ['Overview', 'book/synthesis/overview.html', 'overview'],
    ['Evidence', 'book/synthesis/evidence.html', 'evidence'],
    ['Pending review', 'book/reviews/pending.html', 'review'],
  ]

  return candidates
    .filter(([, relativePath]) => existsSync(path.join(bookRoot, relativePath)))
    .map(([label, relativePath, kind]) => ({
      label,
      kind,
      url: `./book-output/${encodeURIComponent(bookId)}/${relativePath}`,
    }))
}

function normalizeChipArray(value, maxItems = 6) {
  return Array.isArray(value)
    ? value.slice(0, maxItems).map(item => ({
      label: String(item?.label || 'status'),
      tone: String(item?.tone || 'info'),
    }))
    : []
}

function normalizeMetricArray(value, maxItems = 8) {
  return Array.isArray(value)
    ? value.slice(0, maxItems).map(item => ({
      label: String(item?.label || 'Metric'),
      value: String(item?.value || 'n/a'),
      note: String(item?.note || ''),
      tone: String(item?.tone || 'info'),
    }))
    : []
}

function normalizeItemArray(value, maxItems = 6) {
  return Array.isArray(value)
    ? value.slice(0, maxItems).map(item => ({
      title: String(item?.title || 'Untitled'),
      detail: String(item?.detail || ''),
      meta: String(item?.meta || ''),
    }))
    : []
}

function normalizeJourneyArray(value, maxItems = 5) {
  return Array.isArray(value)
    ? value.slice(0, maxItems).map(item => ({
      title: String(item?.title || 'Recent activity'),
      stage: String(item?.stage || 'activity'),
      status: String(item?.status || 'unknown'),
      summary: String(item?.summary || ''),
      highlights: Array.isArray(item?.highlights)
        ? item.highlights.slice(0, 4).map(highlight => String(highlight))
        : [],
    }))
    : []
}

async function loadModuleProjectionIndex() {
  if (!existsSync(booksRootPath)) {
    return { generated_at: new Date().toISOString(), projections: [] }
  }

  const entries = await readdir(booksRootPath, { withFileTypes: true })
  const projections = []
  for (const entry of entries) {
    if (!entry.isDirectory()) {
      continue
    }
    const bookId = entry.name
    const bookRoot = path.join(booksRootPath, bookId)
    const uiStatePath = path.join(bookRoot, 'book/moonbook-ui-state.json')
    const state = await readJsonFile(uiStatePath, null)
    if (!state) {
      continue
    }
    projections.push({
      book_id: bookId,
      title: String(state.title || bookId),
      summary: String(state.summary || ''),
      status_chips: normalizeChipArray(state.status_chips, 6),
      metrics: normalizeMetricArray(state.metrics, 8),
      readiness: normalizeItemArray(state.readiness, 6),
      review_queue: normalizeItemArray(state.review_queue, 8),
      page_families: normalizeItemArray(state.page_families, 8),
      journey: normalizeJourneyArray(state.journey, 5),
      links: projectionLinksForBook(bookId, bookRoot),
    })
  }

  projections.sort((left, right) => left.book_id.localeCompare(right.book_id))
  return { generated_at: new Date().toISOString(), projections }
}

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

async function loadMoondeskBridgeIndex() {
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

async function serveBookOutput(req, res) {
  const pathname = new URL(req.url || '/', 'http://moontown.local').pathname
  const parts = pathname.split('/').filter(Boolean)
  const rawBookId = parts.shift() || ''
  const bookId = safeSegment(decodeURIComponent(rawBookId), '')
  if (!bookId || parts.length === 0) {
    res.statusCode = 404
    res.setHeader('Content-Type', 'text/plain')
    res.end('missing book output')
    return
  }

  const requestedPath = path.normalize(parts.join('/'))
  if (requestedPath.startsWith('..') || path.isAbsolute(requestedPath)) {
    res.statusCode = 400
    res.setHeader('Content-Type', 'text/plain')
    res.end('invalid book output path')
    return
  }

  const filePath = path.join(booksRootPath, bookId, requestedPath)
  const resolved = path.resolve(filePath)
  const allowedRoot = path.resolve(booksRootPath, bookId)
  if (!resolved.startsWith(`${allowedRoot}${path.sep}`) || !existsSync(resolved)) {
    res.statusCode = 404
    res.setHeader('Content-Type', 'text/plain')
    res.end('book output not found')
    return
  }

  const fileStat = await stat(resolved)
  if (!fileStat.isFile()) {
    res.statusCode = 404
    res.setHeader('Content-Type', 'text/plain')
    res.end('book output not found')
    return
  }

  const ext = path.extname(resolved).toLowerCase()
  const contentType = ext === '.html'
    ? 'text/html; charset=utf-8'
    : ext === '.css'
      ? 'text/css; charset=utf-8'
      : ext === '.js'
        ? 'application/javascript; charset=utf-8'
        : 'text/plain; charset=utf-8'
  res.statusCode = 200
  res.setHeader('Content-Type', contentType)
  res.end(await readFile(resolved))
}

async function serveJsonlAsArray(res, filePath) {
  if (!existsSync(filePath)) {
    res.statusCode = 200
    res.setHeader('Content-Type', 'application/json')
    res.end('[]')
    return
  }

  const rows = (await readFile(filePath, 'utf8'))
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

  res.statusCode = 200
  res.setHeader('Content-Type', 'application/json')
  res.end(JSON.stringify(rows))
}

async function readJsonlRows(filePath) {
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

async function loadWatcherLedgerIndex() {
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

async function handleOperatorRequest(req, res) {
  try {
    const payload = JSON.parse(await readBody(req))
    const title = String(payload.title || '').trim()
    const prompt = String(payload.prompt || '').trim()
    const targetBookId = String(payload.target_book_id || 'research-opc').trim() || 'research-opc'
    const cadenceTicks = Math.max(1, Number.parseInt(payload.cadence_ticks, 10) || 60)
    const qualityThreshold = Math.min(
      100,
      Math.max(1, Number.parseInt(payload.quality_threshold, 10) || 85),
    )

    if (!title || !prompt) {
      res.statusCode = 400
      res.setHeader('Content-Type', 'application/json')
      res.end(JSON.stringify({ ok: false, error: 'title and prompt are required' }))
      return
    }

    const now = new Date().toISOString()
    const requestId = `operator-${Date.now()}-${safeSegment(title)}`
    const standingGoalId = safeSegment(payload.goal_id || title, 'standing-goal')
    const request = {
      id: requestId,
      status: 'accepted',
      created_at: now,
      title,
      prompt,
      target_book_id: targetBookId,
      cadence_ticks: cadenceTicks,
      source_policy: 'web-first',
      quality_threshold: qualityThreshold,
      standing_goal_id: standingGoalId,
    }
    const goal = {
      id: standingGoalId,
      title,
      prompt,
      target_book_id: targetBookId,
      cadence_ticks: cadenceTicks,
      next_due_tick: 0,
      last_run_tick: null,
      enabled: true,
      source_policy: 'web-first',
      quality_threshold: qualityThreshold,
    }
    const goals = await readJsonArray(standingGoalsPath)
    const existingIndex = goals.findIndex(item => item && item.id === standingGoalId)
    if (existingIndex >= 0) {
      goals[existingIndex] = goal
    } else {
      goals.push(goal)
    }

    await mkdir(path.dirname(standingGoalsPath), { recursive: true })
    await writeFile(standingGoalsPath, JSON.stringify(goals), 'utf8')
    await mkdir(operatorRequestDir, { recursive: true })
    await writeFile(path.join(operatorRequestDir, `${requestId}.json`), JSON.stringify(request, null, 2), 'utf8')
    await appendJsonLine(operatorRequestLedgerPath, request)

    res.statusCode = 200
    res.setHeader('Content-Type', 'application/json')
    res.end(JSON.stringify({ ok: true, request_id: requestId, standing_goal_id: standingGoalId, status: 'accepted' }))
  } catch (error) {
    res.statusCode = 500
    res.setHeader('Content-Type', 'application/json')
    res.end(JSON.stringify({ ok: false, error: String(error?.message || error) }))
  }
}

function moontownSnapshotPlugin() {
  return {
    name: 'moontown-town-snapshot',
    configureServer(server) {
      server.middlewares.use('/town.json', async (_req, res) => {
        if (!serveJsonSnapshot(res, townSnapshotPath, 'missing town snapshot')) {
          return
        }

        const contents = await readFile(townSnapshotPath, 'utf8')
        res.statusCode = 200
        res.setHeader('Content-Type', 'application/json')
        res.end(contents)
      })
      server.middlewares.use('/visual-projection.json', async (_req, res) => {
        if (!serveJsonSnapshot(res, visualProjectionPath, 'missing visual projection')) {
          return
        }

        const contents = await readFile(visualProjectionPath, 'utf8')
        res.statusCode = 200
        res.setHeader('Content-Type', 'application/json')
        res.end(contents)
      })
      server.middlewares.use('/module-projections.json', async (_req, res) => {
        const index = await loadModuleProjectionIndex()
        res.statusCode = 200
        res.setHeader('Content-Type', 'application/json')
        res.end(JSON.stringify(index))
      })
      server.middlewares.use('/moondesk-bridge.json', async (_req, res) => {
        const index = await loadMoondeskBridgeIndex()
        res.statusCode = 200
        res.setHeader('Content-Type', 'application/json')
        res.end(JSON.stringify(index))
      })
      server.middlewares.use('/book-output', async (req, res) => {
        await serveBookOutput(req, res)
      })
      server.middlewares.use('/daemon.json', async (_req, res) => {
        if (!serveJsonSnapshot(res, daemonSnapshotPath, 'missing daemon snapshot')) {
          return
        }

        const contents = await readFile(daemonSnapshotPath, 'utf8')
        res.statusCode = 200
        res.setHeader('Content-Type', 'application/json')
        res.end(contents)
      })
      server.middlewares.use('/standing-goals.json', async (_req, res) => {
        if (!serveJsonSnapshot(res, standingGoalsPath, 'missing standing goals')) {
          return
        }

        const contents = await readFile(standingGoalsPath, 'utf8')
        res.statusCode = 200
        res.setHeader('Content-Type', 'application/json')
        res.end(contents)
      })
      server.middlewares.use('/watchers', async (req, res) => {
        const pathname = new URL(req.url || '/', 'http://moontown.local').pathname
        if (pathname === '/index.json' || pathname === '/index') {
          const rows = await loadWatcherLedgerIndex()
          res.statusCode = 200
          res.setHeader('Content-Type', 'application/json')
          res.end(JSON.stringify(rows))
          return
        }

        const requested = safeSegment(pathname.replace(/^\//, '').replace(/\.jsonl$/, ''))
        const filePath = path.join(watcherDir, `${requested}.jsonl`)
        await serveJsonlAsArray(res, filePath)
      })
      server.middlewares.use('/operator-requests.json', async (_req, res) => {
        await serveJsonlAsArray(res, operatorRequestLedgerPath)
      })
      server.middlewares.use('/api/operator-requests', async (req, res) => {
        if (req.method !== 'POST') {
          res.statusCode = 405
          res.setHeader('Content-Type', 'application/json')
          res.end(JSON.stringify({ ok: false, error: 'POST required' }))
          return
        }

        await handleOperatorRequest(req, res)
      })
    },
    async closeBundle() {
      const distDir = path.resolve(process.cwd(), 'dist')
      await mkdir(distDir, { recursive: true })

      if (existsSync(townSnapshotPath)) {
        await writeFile(
          path.join(distDir, 'town.json'),
          await readFile(townSnapshotPath, 'utf8'),
          'utf8',
        )
      }

      if (existsSync(visualProjectionPath)) {
        await writeFile(
          path.join(distDir, 'visual-projection.json'),
          await readFile(visualProjectionPath, 'utf8'),
          'utf8',
        )
      }

      const moduleProjectionIndex = await loadModuleProjectionIndex()
      await writeFile(
        path.join(distDir, 'module-projections.json'),
        JSON.stringify(moduleProjectionIndex),
        'utf8',
      )
      await writeFile(
        path.join(distDir, 'moondesk-bridge.json'),
        JSON.stringify(await loadMoondeskBridgeIndex()),
        'utf8',
      )

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

      if (existsSync(daemonSnapshotPath)) {
        await writeFile(
          path.join(distDir, 'daemon.json'),
          await readFile(daemonSnapshotPath, 'utf8'),
          'utf8',
        )
      }

      if (existsSync(standingGoalsPath)) {
        await writeFile(
          path.join(distDir, 'standing-goals.json'),
          await readFile(standingGoalsPath, 'utf8'),
          'utf8',
        )
      }

      if (existsSync(watcherDir)) {
        const watcherDistDir = path.join(distDir, 'watchers')
        await mkdir(watcherDistDir, { recursive: true })
        const entries = await readdir(watcherDir, { withFileTypes: true })
        for (const entry of entries) {
          if (!entry.isFile() || !entry.name.endsWith('.jsonl')) {
            continue
          }
          const rows = await readJsonlRows(path.join(watcherDir, entry.name))
          await writeFile(path.join(watcherDistDir, entry.name), JSON.stringify(rows), 'utf8')
        }
        await writeFile(
          path.join(watcherDistDir, 'index.json'),
          JSON.stringify(await loadWatcherLedgerIndex()),
          'utf8',
        )
      }
    },
  }
}

export default defineConfig({
  base: './',
  publicDir: '../assets',
  plugins: [rabbita(), moontownSnapshotPlugin()],
  build: {
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (id.includes('node_modules')) {
            if (id.includes('@rabbita')) return 'rabbita-vendor'
            return 'vendor'
          }
        },
      },
    },
  },
  server: {
    host: true,
    fs: { allow: ['..', '../..', '../../..'] },
  },
})

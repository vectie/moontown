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

      if (existsSync(path.join(watcherDir, 'watch-opc-news.jsonl'))) {
        const watcherText = await readFile(path.join(watcherDir, 'watch-opc-news.jsonl'), 'utf8')
        const watcherRows = watcherText
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
        const watcherDistDir = path.join(distDir, 'watchers')
        await mkdir(watcherDistDir, { recursive: true })
        await writeFile(
          path.join(watcherDistDir, 'watch-opc-news.jsonl'),
          JSON.stringify(watcherRows),
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

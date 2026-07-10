import { existsSync } from 'node:fs'
import { mkdir, readFile, writeFile } from 'node:fs/promises'
import path from 'node:path'

export function serveJsonSnapshot(res, snapshotPath, missingMessage) {
  if (!existsSync(snapshotPath)) {
    sendJson(res, { error: missingMessage }, 404)
    return false
  }

  return true
}

export function sendJson(res, value, statusCode = 200) {
  res.statusCode = statusCode
  res.setHeader('Content-Type', 'application/json')
  res.end(JSON.stringify(value))
}

export function sendText(
  res,
  value,
  contentType = 'text/plain; charset=utf-8',
  statusCode = 200,
) {
  res.statusCode = statusCode
  res.setHeader('Content-Type', contentType)
  res.end(value)
}

export function contentTypeForPath(filePath) {
  const ext = path.extname(filePath).toLowerCase()
  if (ext === '.html') {
    return 'text/html; charset=utf-8'
  }
  if (ext === '.css') {
    return 'text/css; charset=utf-8'
  }
  if (ext === '.js') {
    return 'application/javascript; charset=utf-8'
  }
  if (ext === '.json') {
    return 'application/json'
  }
  return 'text/plain; charset=utf-8'
}

export function normalizeRelativeRequestPath(parts) {
  const requestedPath = path.normalize(parts.join('/'))
  if (requestedPath.startsWith('..') || path.isAbsolute(requestedPath)) {
    return null
  }
  return requestedPath
}

export function resolvePathUnderRoot(rootPath, relativePath) {
  const resolved = path.resolve(path.join(rootPath, relativePath))
  const allowedRoot = path.resolve(rootPath)
  if (resolved !== allowedRoot && !resolved.startsWith(`${allowedRoot}${path.sep}`)) {
    return null
  }
  return resolved
}

export async function serveJsonFile(res, filePath, missingMessage) {
  if (!serveJsonSnapshot(res, filePath, missingMessage)) {
    return
  }

  sendText(res, await readFile(filePath, 'utf8'), 'application/json')
}

export async function serveTextFile(
  res,
  filePath,
  missingMessage,
  contentType = 'text/plain; charset=utf-8',
) {
  if (!existsSync(filePath)) {
    sendText(res, missingMessage, 'text/plain; charset=utf-8', 404)
    return
  }

  sendText(res, await readFile(filePath, 'utf8'), contentType)
}

export function rejectNonPost(req, res) {
  if (req.method === 'POST') {
    return false
  }

  sendJson(res, { ok: false, error: 'POST required' }, 405)
  return true
}

export function rejectUnsafeWrite(req, res) {
  if (rejectNonPost(req, res)) {
    return true
  }

  const contentType = String(req.headers?.['content-type'] || '')
  if (!contentType.toLowerCase().startsWith('application/json')) {
    sendJson(res, { ok: false, error: 'application/json required' }, 415)
    return true
  }

  const origin = String(req.headers?.origin || '').trim()
  const host = String(req.headers?.host || '').trim()
  if (origin) {
    try {
      if (!host || new URL(origin).host !== host) {
        sendJson(res, { ok: false, error: 'same-origin request required' }, 403)
        return true
      }
    } catch {
      sendJson(res, { ok: false, error: 'invalid request origin' }, 403)
      return true
    }
  }

  return false
}

export function safeSegment(value, fallback = 'request') {
  const cleaned = String(value || '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 80)
  return cleaned || fallback
}

export function readBody(req) {
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

export async function readJsonBody(req) {
  return JSON.parse(await readBody(req))
}

export async function readJsonArray(filePath) {
  if (!existsSync(filePath)) {
    return []
  }

  const text = await readFile(filePath, 'utf8')
  const parsed = JSON.parse(text)
  return Array.isArray(parsed) ? parsed : []
}

export async function appendJsonLine(filePath, value) {
  await mkdir(path.dirname(filePath), { recursive: true })
  let previous = ''
  if (existsSync(filePath)) {
    previous = await readFile(filePath, 'utf8')
  }
  const prefix = previous && !previous.endsWith('\n') ? `${previous}\n` : previous
  await writeFile(filePath, `${prefix}${JSON.stringify(value)}\n`, 'utf8')
}

export async function readJsonFile(filePath, fallback) {
  if (!existsSync(filePath)) {
    return fallback
  }
  try {
    return JSON.parse(await readFile(filePath, 'utf8'))
  } catch {
    return fallback
  }
}

export async function writeJsonFile(filePath, value, space = 0) {
  await mkdir(path.dirname(filePath), { recursive: true })
  await writeFile(filePath, JSON.stringify(value, null, space), 'utf8')
}

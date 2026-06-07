import { existsSync } from 'node:fs'
import { readFile, stat } from 'node:fs/promises'
import { booksRootPath } from './vite_server_paths.js'
import {
  contentTypeForPath,
  normalizeRelativeRequestPath,
  resolvePathUnderRoot,
  safeSegment,
  sendText,
} from './vite_server_io.js'

export async function serveBookOutput(req, res) {
  const pathname = new URL(req.url || '/', 'http://moontown.local').pathname
  const parts = pathname.split('/').filter(Boolean)
  const rawBookId = parts.shift() || ''
  const bookId = safeSegment(decodeURIComponent(rawBookId), '')
  if (!bookId || parts.length === 0) {
    sendText(res, 'missing book output', 'text/plain; charset=utf-8', 404)
    return
  }

  const requestedPath = normalizeRelativeRequestPath(parts)
  if (!requestedPath) {
    sendText(res, 'invalid book output path', 'text/plain; charset=utf-8', 400)
    return
  }

  const resolved = resolvePathUnderRoot(`${booksRootPath}/${bookId}`, requestedPath)
  if (!resolved || !existsSync(resolved)) {
    sendText(res, 'book output not found', 'text/plain; charset=utf-8', 404)
    return
  }

  const fileStat = await stat(resolved)
  if (!fileStat.isFile()) {
    sendText(res, 'book output not found', 'text/plain; charset=utf-8', 404)
    return
  }

  sendText(res, await readFile(resolved), contentTypeForPath(resolved))
}

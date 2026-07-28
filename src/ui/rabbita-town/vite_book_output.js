import { readFile, realpath, stat } from 'node:fs/promises'
import path from 'node:path'
import {
  booksRootPath,
  keyBookOutputFiles,
} from './vite_server_paths.js'
import {
  contentTypeForPath,
  sendText,
} from './vite_server_io.js'

const EXACT_BOOK_OUTPUTS = new Set(keyBookOutputFiles)
const GENERATED_OUTPUT_PREFIXES = [
  'book/site/generated/',
]

function isWithin(root, candidate) {
  const resolvedRoot = path.resolve(root)
  const resolved = path.resolve(candidate)
  return resolved === resolvedRoot
    || resolved.startsWith(`${resolvedRoot}${path.sep}`)
}

function decodePathSegment(value) {
  try {
    const decoded = decodeURIComponent(value)
    if (
      !decoded
      || decoded === '.'
      || decoded === '..'
      || decoded.includes('/')
      || decoded.includes('\\')
      || decoded.includes('\0')
    ) {
      return undefined
    }
    return decoded
  } catch {
    return undefined
  }
}

function allowedBookOutput(relativePath) {
  return EXACT_BOOK_OUTPUTS.has(relativePath)
    || GENERATED_OUTPUT_PREFIXES.some(prefix =>
      relativePath.startsWith(prefix)
      && relativePath.length > prefix.length)
}

function rejected(statusCode, message) {
  return { ok: false, statusCode, message }
}

export async function resolveBookOutputRequest(
  requestUrl,
  rootPath = booksRootPath,
) {
  let pathname
  try {
    pathname = new URL(requestUrl || '/', 'http://moontown.local').pathname
  } catch {
    return rejected(400, 'invalid book output path')
  }
  const rawParts = pathname.split('/').filter(Boolean)
  const bookId = decodePathSegment(rawParts.shift() || '')
  const parts = rawParts.map(decodePathSegment)
  if (!bookId || parts.length === 0) {
    return rejected(404, 'missing book output')
  }
  if (parts.some(part => !part)) {
    return rejected(400, 'invalid book output path')
  }

  const requestedPath = parts.join('/')
  if (!allowedBookOutput(requestedPath)) {
    return rejected(404, 'book output not found')
  }

  try {
    const lexicalRoot = path.resolve(rootPath)
    const lexicalBookRoot = path.resolve(lexicalRoot, bookId)
    if (!isWithin(lexicalRoot, lexicalBookRoot)) {
      return rejected(400, 'invalid book output path')
    }

    const [realRoot, realBookRoot] = await Promise.all([
      realpath(lexicalRoot),
      realpath(lexicalBookRoot),
    ])
    if (
      !isWithin(realRoot, realBookRoot)
      || realBookRoot !== path.resolve(realRoot, bookId)
    ) {
      return rejected(404, 'book output not found')
    }

    const lexicalOutput = path.resolve(lexicalBookRoot, ...parts)
    if (!isWithin(lexicalBookRoot, lexicalOutput)) {
      return rejected(400, 'invalid book output path')
    }
    const realOutput = await realpath(lexicalOutput)
    if (!isWithin(realBookRoot, realOutput)) {
      return rejected(404, 'book output not found')
    }
    const fileStat = await stat(realOutput)
    if (!fileStat.isFile()) {
      return rejected(404, 'book output not found')
    }
    return { ok: true, pathname: realOutput }
  } catch {
    return rejected(404, 'book output not found')
  }
}

export async function serveBookOutput(req, res) {
  const resolved = await resolveBookOutputRequest(req.url)
  if (!resolved.ok) {
    sendText(
      res,
      resolved.message,
      'text/plain; charset=utf-8',
      resolved.statusCode,
    )
    return
  }
  sendText(
    res,
    await readFile(resolved.pathname),
    contentTypeForPath(resolved.pathname),
  )
}

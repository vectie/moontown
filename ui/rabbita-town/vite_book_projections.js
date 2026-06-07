import { existsSync } from 'node:fs'
import { readdir } from 'node:fs/promises'
import path from 'node:path'
import {
  bookProjectionPolicyPath,
  booksRootPath,
} from './vite_server_paths.js'
import { readJsonFile } from './vite_server_io.js'

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

function normalizeStringArray(value) {
  return Array.isArray(value)
    ? value.map(item => String(item).toLowerCase()).filter(Boolean)
    : []
}

async function loadBookProjectionPolicy() {
  const policy = await readJsonFile(bookProjectionPolicyPath, {})
  return {
    public_book_ids: normalizeStringArray(policy?.public_book_ids),
    hidden_book_ids: normalizeStringArray(policy?.hidden_book_ids),
    hidden_book_prefixes: normalizeStringArray(policy?.hidden_book_prefixes),
    hidden_tags: [
      'hidden',
      'internal',
      'intermediate',
      'participant-workspace',
      ...normalizeStringArray(policy?.hidden_tags),
    ],
    hidden_scopes: [
      'hidden',
      'internal',
      'intermediate',
      'private',
      ...normalizeStringArray(policy?.hidden_scopes),
    ],
  }
}

function isIntermediateBookProjection(bookId, state, policy) {
  const normalizedBookId = String(bookId).toLowerCase()
  if (policy.public_book_ids.includes(normalizedBookId)) {
    return false
  }
  if (policy.hidden_book_ids.includes(normalizedBookId)) {
    return true
  }
  if (policy.hidden_book_prefixes.some(prefix => normalizedBookId.startsWith(prefix))) {
    return true
  }
  const tags = Array.isArray(state?.tags)
    ? state.tags.map(tag => String(tag).toLowerCase())
    : []
  const scope = String(state?.projection_scope || state?.visibility || 'public').toLowerCase()
  if (policy.hidden_scopes.includes(scope)) {
    return true
  }
  return tags.some(tag => policy.hidden_tags.includes(tag))
}

export async function loadModuleProjectionIndex() {
  if (!existsSync(booksRootPath)) {
    return { generated_at: new Date().toISOString(), projections: [] }
  }

  const entries = await readdir(booksRootPath, { withFileTypes: true })
  const projectionPolicy = await loadBookProjectionPolicy()
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
    if (isIntermediateBookProjection(bookId, state, projectionPolicy)) {
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

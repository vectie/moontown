import path from 'node:path'
import {
  bookTemplateConfigDir,
  bookTemplateRequestPath,
  operatorRequestDir,
  operatorRequestLedgerPath,
  standingGoalsPath,
} from './vite_server_paths.js'
import {
  appendJsonLine,
  readJsonArray,
  readJsonBody,
  readJsonFile,
  safeSegment,
  sendJson,
  writeJsonFile,
} from './vite_server_io.js'

const DEFAULT_OPERATOR_TARGET_BOOK = 'research-opc'
const DEFAULT_OPERATOR_CADENCE_TICKS = 60
const DEFAULT_OPERATOR_QUALITY_THRESHOLD = 85
const DEFAULT_BOOK_TEMPLATE_ID = 'pdf-evidence-watch'
const DEFAULT_PDF_WATCH_BOOK_ID = 'research-pdf-evidence-watch'
const DEFAULT_PDF_WATCH_PURPOSE =
  'Watch approved websites for relevant PDFs, extract full text, analyze with the book-owned method, and notify only when accepted knowledge changes.'

async function readBookTemplateRequestLedger() {
  const parsed = await readJsonFile(bookTemplateRequestPath, { requests: [] })
  return {
    requests: Array.isArray(parsed?.requests) ? parsed.requests : [],
  }
}

function clampInteger(value, fallback, min, max) {
  const parsed = Number.parseInt(value, 10)
  const number = Number.isFinite(parsed) ? parsed : fallback
  return Math.min(max, Math.max(min, number))
}

function normalizeOperatorPayload(payload) {
  const title = String(payload.title || '').trim()
  const prompt = String(payload.prompt || '').trim()
  return {
    title,
    prompt,
    targetBookId: String(payload.target_book_id || DEFAULT_OPERATOR_TARGET_BOOK).trim()
      || DEFAULT_OPERATOR_TARGET_BOOK,
    cadenceTicks: clampInteger(
      payload.cadence_ticks,
      DEFAULT_OPERATOR_CADENCE_TICKS,
      1,
      Number.MAX_SAFE_INTEGER,
    ),
    qualityThreshold: clampInteger(
      payload.quality_threshold,
      DEFAULT_OPERATOR_QUALITY_THRESHOLD,
      1,
      100,
    ),
    standingGoalId: safeSegment(payload.goal_id || title, 'standing-goal'),
  }
}

function buildOperatorRequestRecords(input) {
  const now = new Date().toISOString()
  const requestId = `operator-${Date.now()}-${safeSegment(input.title)}`
  return {
    request: {
      id: requestId,
      status: 'accepted',
      created_at: now,
      title: input.title,
      prompt: input.prompt,
      target_book_id: input.targetBookId,
      cadence_ticks: input.cadenceTicks,
      source_policy: 'web-first',
      quality_threshold: input.qualityThreshold,
      standing_goal_id: input.standingGoalId,
    },
    goal: {
      id: input.standingGoalId,
      title: input.title,
      prompt: input.prompt,
      target_book_id: input.targetBookId,
      cadence_ticks: input.cadenceTicks,
      next_due_tick: 0,
      last_run_tick: null,
      enabled: true,
      source_policy: 'web-first',
      quality_threshold: input.qualityThreshold,
    },
  }
}

function upsertById(items, nextItem) {
  const existingIndex = items.findIndex(item => item && item.id === nextItem.id)
  if (existingIndex >= 0) {
    items[existingIndex] = nextItem
  } else {
    items.push(nextItem)
  }
  return items
}

async function upsertStandingGoal(goal) {
  const goals = await readJsonArray(standingGoalsPath)
  await writeJsonFile(standingGoalsPath, upsertById(goals, goal))
}

function normalizeWebsiteList(value) {
  return Array.isArray(value)
    ? value.map(item => String(item || '').trim()).filter(Boolean)
    : String(value || '').split(/\r?\n|,/).map(item => item.trim()).filter(Boolean)
}

function normalizeBookTemplatePayload(payload) {
  const title = String(payload.title || '').trim()
  return {
    templateId: String(payload.template_id || DEFAULT_BOOK_TEMPLATE_ID).trim()
      || DEFAULT_BOOK_TEMPLATE_ID,
    title,
    bookId: safeSegment(payload.book_id || title, DEFAULT_PDF_WATCH_BOOK_ID),
    purpose: String(payload.purpose || '').trim() || DEFAULT_PDF_WATCH_PURPOSE,
    websites: normalizeWebsiteList(payload.websites),
    cadenceTicks: clampInteger(
      payload.cadence_ticks,
      DEFAULT_OPERATOR_CADENCE_TICKS,
      1,
      Number.MAX_SAFE_INTEGER,
    ),
    analysisMethod: String(payload.analysis_method || '').trim(),
  }
}

function buildBookTemplateRequestRecords(input) {
  const requestId = `book-template-${Date.now()}-${safeSegment(input.title)}`
  const configRelativePath = `book-template-configs/${requestId}.json`
  return {
    requestId,
    configRelativePath,
    configPath: path.join(bookTemplateConfigDir, `${requestId}.json`),
    config: {
      book_id: input.bookId,
      title: input.title,
      purpose: input.purpose,
      websites: input.websites,
      analysis_method: input.analysisMethod,
      analysis_method_path: '',
      cadence_ticks: input.cadenceTicks,
      workspace_root: '',
    },
    request: {
      id: requestId,
      template_id: input.templateId,
      config_path: configRelativePath,
      status: 'pending',
      summary: `Queued ${input.title} for ${input.templateId}; ${input.websites.length} website(s).`,
      last_processed_tick: 0,
    },
  }
}

async function upsertBookTemplateRequest(request) {
  const ledger = await readBookTemplateRequestLedger()
  ledger.requests = upsertById(ledger.requests, request)
  await writeJsonFile(bookTemplateRequestPath, ledger, 2)
}

export async function handleOperatorRequest(req, res) {
  try {
    const input = normalizeOperatorPayload(await readJsonBody(req))

    if (!input.title || !input.prompt) {
      sendJson(res, { ok: false, error: 'title and prompt are required' }, 400)
      return
    }

    const { request, goal } = buildOperatorRequestRecords(input)

    await upsertStandingGoal(goal)
    await writeJsonFile(path.join(operatorRequestDir, `${request.id}.json`), request, 2)
    await appendJsonLine(operatorRequestLedgerPath, request)

    sendJson(res, {
      ok: true,
      request_id: request.id,
      standing_goal_id: goal.id,
      status: 'accepted',
    })
  } catch (error) {
    sendJson(res, { ok: false, error: String(error?.message || error) }, 500)
  }
}

export async function handleBookTemplateRequest(req, res) {
  try {
    const input = normalizeBookTemplatePayload(await readJsonBody(req))

    if (input.templateId !== DEFAULT_BOOK_TEMPLATE_ID) {
      sendJson(res, {
        ok: false,
        error: `unsupported template_id: ${input.templateId}`,
      }, 400)
      return
    }
    if (!input.title || input.websites.length === 0) {
      sendJson(res, {
        ok: false,
        error: 'title and at least one website are required',
      }, 400)
      return
    }

    const records = buildBookTemplateRequestRecords(input)

    await writeJsonFile(records.configPath, records.config, 2)
    await upsertBookTemplateRequest(records.request)

    sendJson(res, {
      ok: true,
      request_id: records.requestId,
      status: 'pending',
      template_id: input.templateId,
      config_path: records.configRelativePath,
    })
  } catch (error) {
    sendJson(res, { ok: false, error: String(error?.message || error) }, 500)
  }
}

export const RUNTIME_RECORD_TAIL_LIMIT = 256

function boundedRecordTail(records) {
  if (!Array.isArray(records)) {
    return []
  }
  const start = Math.max(0, records.length - RUNTIME_RECORD_TAIL_LIMIT)
  return records.slice(start)
}

function parseJsonLinesTail(text) {
  const records = []
  let start = 0

  while (start <= text.length) {
    const newline = text.indexOf('\n', start)
    const end = newline === -1 ? text.length : newline
    const line = text.slice(start, end).trim()
    if (line) {
      try {
        records.push(JSON.parse(line))
        if (records.length > RUNTIME_RECORD_TAIL_LIMIT) {
          records.shift()
        }
      } catch {
        // Static/legacy JSONL may contain a partially written line. Ignore it.
      }
    }
    if (newline === -1) {
      break
    }
    start = newline + 1
  }

  return records
}

function parseRecordTail(text, collectionKey) {
  try {
    const parsed = JSON.parse(text)
    if (Array.isArray(parsed)) {
      return boundedRecordTail(parsed)
    }
    if (Array.isArray(parsed?.[collectionKey])) {
      return boundedRecordTail(parsed[collectionKey])
    }
  } catch {
    // Fall through to JSONL parsing for old static builds.
  }

  return parseJsonLinesTail(text)
}

export function parseWatcherRecords(text) {
  return parseRecordTail(text, 'records')
}

export function parseOperatorRequests(text) {
  return parseRecordTail(text, 'requests')
}

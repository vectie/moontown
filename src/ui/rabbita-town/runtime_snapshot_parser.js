export function parseWatcherRecords(text) {
  try {
    const parsed = JSON.parse(text)
    if (Array.isArray(parsed)) {
      return parsed
    }
    if (Array.isArray(parsed?.records)) {
      return parsed.records
    }
  } catch {
    // Fall through to JSONL parsing for old static builds.
  }

  return text
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

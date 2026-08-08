import assert from 'node:assert/strict'
import test from 'node:test'
import {
  parseOperatorRequests,
  parseWatcherRecords,
  RUNTIME_RECORD_TAIL_LIMIT,
} from './runtime_snapshot_parser.js'

function records(count, prefix) {
  return Array.from({ length: count }, (_, index) => ({
    id: `${prefix}-${index}`,
  }))
}

function assertNewestTail(actual, prefix, total) {
  assert.equal(actual.length, RUNTIME_RECORD_TAIL_LIMIT)
  assert.equal(
    actual[0].id,
    `${prefix}-${total - RUNTIME_RECORD_TAIL_LIMIT}`,
  )
  assert.equal(actual.at(-1).id, `${prefix}-${total - 1}`)
}

test('watcher arrays and record envelopes retain the newest 256 in order', () => {
  const source = records(RUNTIME_RECORD_TAIL_LIMIT + 19, 'watcher')
  assertNewestTail(parseWatcherRecords(JSON.stringify(source)), 'watcher', source.length)
  assertNewestTail(
    parseWatcherRecords(JSON.stringify({ records: source })),
    'watcher',
    source.length,
  )
})

test('operator arrays and request envelopes retain the newest 256 in order', () => {
  const source = records(RUNTIME_RECORD_TAIL_LIMIT + 23, 'request')
  assertNewestTail(
    parseOperatorRequests(JSON.stringify(source)),
    'request',
    source.length,
  )
  assertNewestTail(
    parseOperatorRequests(JSON.stringify({ requests: source })),
    'request',
    source.length,
  )
})

test('legacy JSONL keeps the newest valid rows and ignores malformed lines', () => {
  const source = records(RUNTIME_RECORD_TAIL_LIMIT + 11, 'legacy')
  const lines = []
  for (const [index, record] of source.entries()) {
    lines.push(JSON.stringify(record))
    if (index % 17 === 0) {
      lines.push('{partially-written')
    }
  }
  const text = `\n${lines.join('\r\n')}\nnot-json\n`
  assertNewestTail(parseWatcherRecords(text), 'legacy', source.length)
  assertNewestTail(parseOperatorRequests(text), 'legacy', source.length)
})

test('small and empty inputs preserve source order without padding', () => {
  const source = records(3, 'small')
  assert.deepEqual(parseWatcherRecords(JSON.stringify(source)), source)
  assert.deepEqual(parseOperatorRequests(source.map(JSON.stringify).join('\n')), source)
  assert.deepEqual(parseWatcherRecords(''), [])
  assert.deepEqual(parseOperatorRequests('not-json'), [])
})

import assert from 'node:assert/strict'
import test from 'node:test'
import { rejectUnsafeWrite } from './vite_server_io.js'

function responseRecorder() {
  return {
    statusCode: 200,
    headers: {},
    body: '',
    setHeader(name, value) {
      this.headers[name] = value
    },
    end(value) {
      this.body = value
    },
  }
}

test('write guard accepts same-origin JSON POST requests', () => {
  const response = responseRecorder()
  const rejected = rejectUnsafeWrite({
    method: 'POST',
    headers: {
      host: '127.0.0.1:5173',
      origin: 'http://127.0.0.1:5173',
      'content-type': 'application/json; charset=utf-8',
    },
  }, response)
  assert.equal(rejected, false)
  assert.equal(response.body, '')
})

test('write guard rejects cross-origin requests', () => {
  const response = responseRecorder()
  const rejected = rejectUnsafeWrite({
    method: 'POST',
    headers: {
      host: '127.0.0.1:5173',
      origin: 'https://example.invalid',
      'content-type': 'application/json',
    },
  }, response)
  assert.equal(rejected, true)
  assert.equal(response.statusCode, 403)
  assert.match(response.body, /same-origin request required/)
})

test('write guard rejects non-JSON and non-POST requests', () => {
  const wrongMethod = responseRecorder()
  assert.equal(rejectUnsafeWrite({ method: 'GET', headers: {} }, wrongMethod), true)
  assert.equal(wrongMethod.statusCode, 405)

  const wrongType = responseRecorder()
  assert.equal(rejectUnsafeWrite({
    method: 'POST',
    headers: { 'content-type': 'text/plain' },
  }, wrongType), true)
  assert.equal(wrongType.statusCode, 415)
})

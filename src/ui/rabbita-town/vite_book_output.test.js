import assert from 'node:assert/strict'
import {
  mkdir,
  mkdtemp,
  realpath,
  symlink,
  writeFile,
} from 'node:fs/promises'
import os from 'node:os'
import path from 'node:path'
import test from 'node:test'
import { resolveBookOutputRequest } from './vite_book_output.js'

async function fixture() {
  const root = await mkdtemp(path.join(os.tmpdir(), 'moontown-book-output-'))
  const booksRoot = path.join(root, 'books')
  const bookRoot = path.join(booksRoot, 'research-opc')
  await mkdir(path.join(bookRoot, 'book/synthesis'), { recursive: true })
  await mkdir(path.join(bookRoot, 'book/site/generated/assets'), {
    recursive: true,
  })
  return { root, booksRoot, bookRoot }
}

test('serves allowlisted current-book files and generated site subtrees', async () => {
  const { booksRoot, bookRoot } = await fixture()
  const report = path.join(bookRoot, 'book/synthesis/report.html')
  const stylesheet = path.join(
    bookRoot,
    'book/site/generated/assets/site.css',
  )
  await writeFile(report, '<h1>Report</h1>', 'utf8')
  await writeFile(stylesheet, 'body {}', 'utf8')

  const reportResult = await resolveBookOutputRequest(
    '/research-opc/book/synthesis/report.html',
    booksRoot,
  )
  const assetResult = await resolveBookOutputRequest(
    '/research-opc/book/site/generated/assets/site.css',
    booksRoot,
  )

  assert.equal(reportResult.ok, true)
  assert.equal(reportResult.pathname, await realpath(report))
  assert.equal(assetResult.ok, true)
  assert.equal(assetResult.pathname, await realpath(stylesheet))
})

test('existing raw or unrelated book files are outside the output allowlist', async () => {
  const { booksRoot, bookRoot } = await fixture()
  await mkdir(path.join(bookRoot, 'raw'), { recursive: true })
  await writeFile(path.join(bookRoot, 'raw/private.md'), '# Private', 'utf8')
  await writeFile(path.join(bookRoot, 'book/config.json'), '{}', 'utf8')

  for (const requestPath of [
    '/research-opc/raw/private.md',
    '/research-opc/book/config.json',
  ]) {
    const result = await resolveBookOutputRequest(requestPath, booksRoot)
    assert.deepEqual(result, {
      ok: false,
      statusCode: 404,
      message: 'book output not found',
    })
  }
})

test('realpath containment rejects output and book symlinks outside books root', async () => {
  const { root, booksRoot, bookRoot } = await fixture()
  const outside = path.join(root, 'outside')
  const siblingBook = path.join(booksRoot, 'research-sibling')
  await mkdir(path.join(outside, 'book/synthesis'), { recursive: true })
  await mkdir(path.join(siblingBook, 'book/synthesis'), { recursive: true })
  await writeFile(
    path.join(outside, 'book/synthesis/report.html'),
    '<h1>Outside</h1>',
    'utf8',
  )
  await writeFile(
    path.join(siblingBook, 'book/synthesis/evidence.html'),
    '<h1>Sibling evidence</h1>',
    'utf8',
  )
  await symlink(
    path.join(outside, 'book/synthesis/report.html'),
    path.join(bookRoot, 'book/synthesis/report.html'),
  )
  await symlink(
    path.join(siblingBook, 'book/synthesis/evidence.html'),
    path.join(bookRoot, 'book/synthesis/evidence.html'),
  )
  await symlink(outside, path.join(booksRoot, 'linked-book'))
  await symlink(siblingBook, path.join(booksRoot, 'linked-sibling'))

  for (const requestPath of [
    '/research-opc/book/synthesis/report.html',
    '/research-opc/book/synthesis/evidence.html',
    '/linked-book/book/synthesis/report.html',
    '/linked-sibling/book/synthesis/evidence.html',
  ]) {
    const result = await resolveBookOutputRequest(requestPath, booksRoot)
    assert.equal(result.ok, false)
    assert.equal(result.statusCode, 404)
  }
})

test('encoded traversal and path-separator segments are rejected', async () => {
  const { booksRoot } = await fixture()
  for (const requestPath of [
    '/research-opc/book/site/generated/%2e%2e/report.html',
    '/research-opc/book/site/generated/%2Fetc',
    '/research-opc/book/site/generated/%5Cetc',
  ]) {
    const result = await resolveBookOutputRequest(requestPath, booksRoot)
    assert.equal(result.ok, false)
  }
})

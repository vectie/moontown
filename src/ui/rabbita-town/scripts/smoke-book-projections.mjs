import { mkdtemp, mkdir, rm, writeFile } from 'node:fs/promises'
import os from 'node:os'
import path from 'node:path'

function assert(condition, message) {
  if (!condition) {
    throw new Error(message)
  }
}

const suiteRoot = await mkdtemp(path.join(os.tmpdir(), 'rabbita-books-smoke-'))
const booksRoot = path.join(suiteRoot, 'books')
const productStateRoot = path.join(suiteRoot, '.moonsuite/products/moontown')

process.env.MOONTOWN_SUITE_ROOT = suiteRoot
process.env.MOONTOWN_BOOKS_ROOT = booksRoot
process.env.MOONTOWN_PRODUCT_STATE_ROOT = productStateRoot

try {
  const bookRoot = path.join(booksRoot, 'wenyu-social-square')
  await mkdir(path.join(bookRoot, 'book/site/generated'), { recursive: true })
  await mkdir(productStateRoot, { recursive: true })
  await writeFile(
    path.join(bookRoot, 'book/moonbook-ui-state.json'),
    JSON.stringify({
      title: 'Wenyu Social Square',
      summary: 'Fresh suite projection smoke.',
      projection_scope: 'public',
      status_chips: [{ label: 'ready', tone: 'healthy' }],
      metrics: [{ label: 'Books', value: '1', tone: 'healthy' }],
    }),
    'utf8',
  )
  await writeFile(
    path.join(bookRoot, 'book/site/generated/index.html'),
    '<main>Wenyu Social Square</main>',
    'utf8',
  )

  const paths = await import('../vite_server_paths.js')
  assert(paths.booksRootPath === booksRoot, `expected books root ${booksRoot}, got ${paths.booksRootPath}`)
  assert(
    paths.moontownProductStatePath === productStateRoot,
    `expected product state root ${productStateRoot}, got ${paths.moontownProductStatePath}`,
  )

  const { loadModuleProjectionIndex } = await import('../vite_book_projections.js')
  const index = await loadModuleProjectionIndex()
  assert(index.projections.length === 1, `expected one projection, got ${index.projections.length}`)
  const projection = index.projections[0]
  assert(projection.book_id === 'wenyu-social-square', `unexpected book id ${projection.book_id}`)
  assert(projection.title === 'Wenyu Social Square', `unexpected title ${projection.title}`)
  assert(
    projection.links.some(link => link.url === './book-output/wenyu-social-square/book/site/generated/index.html'),
    'expected generated site link from fresh books root',
  )
  console.log('Rabbita book projection smoke passed')
} finally {
  await rm(suiteRoot, { recursive: true, force: true })
}

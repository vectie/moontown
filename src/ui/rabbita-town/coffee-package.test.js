import test from 'node:test'
import assert from 'node:assert/strict'
import {readFile} from 'node:fs/promises'
import path from 'node:path'
import {runtimeAssetPaths} from './runtime_asset_manifest.js'

const root=import.meta.dirname
async function listedFiles(script,constant){
  const source=await readFile(path.join(root,'scripts',script),'utf8')
  const block=source.match(new RegExp(`const ${constant} = \\[([\\s\\S]*?)\\n\\]`))
  assert.ok(block,`Missing ${constant}`)
  return new Set([...block[1].matchAll(/^\s*'([^']+)',?\s*$/gm)].map(match=>match[1]))
}
test('the full coffee ESM graph is shipped and required by production acceptance',async()=>{
  const assembled=await listedFiles('assemble-production-build.mjs','BROWSER_FILES')
  const required=await listedFiles('verify-production-build.mjs','REQUIRED_BROWSER_FILES')
  const pending=['coffee-contest.js'],visited=new Set()
  while(pending.length){
    const file=pending.pop()
    if(visited.has(file))continue
    visited.add(file)
    assert.ok(assembled.has(file),`Production assembly omits ${file}`)
    assert.ok(required.has(file),`Production acceptance omits ${file}`)
    const source=await readFile(path.join(root,file),'utf8')
    for(const match of source.matchAll(/(?:\bfrom\s*|\bimport\s*\(\s*)['"](\.\/[^'"]+\.js)['"]/g)){
      pending.push(path.posix.normalize(path.posix.join(path.posix.dirname(file),match[1])))
    }
  }
  assert.ok(visited.has('coffee-share.js'))
  assert.ok(visited.has('coffee-qr.js'))
})
test('coffee page image references survive a normal production asset build',async()=>{
  const html=await readFile(path.join(root,'coffee-contest.html'),'utf8')
  const assets=new Set(await runtimeAssetPaths(path.resolve(root,'../assets')))
  for(const match of html.matchAll(/src=['"](coffee\/[^'"]+)['"]/g)){
    assert.ok(assets.has(match[1]),`Runtime asset list omits ${match[1]}`)
  }
})

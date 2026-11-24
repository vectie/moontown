// Link an immutable public geometry graph to this exact MoonBit JS artifact.
// Preserve sharing, enum prototypes and canonical nullary values. App models,
// runtime observations and user storage never enter the build process.
import assert from 'node:assert/strict'
import {createHash} from 'node:crypto'
import {gzipSync} from 'node:zlib'
import {readFile, writeFile, appendFile} from 'node:fs/promises'
import path from 'node:path'
import {pathToFileURL} from 'node:url'
import {referenceSignatureInput} from '../public-world.js'

const root = process.argv[2]
const hash = bytes => createHash('sha256').update(bytes).digest('hex')
const source = await readFile(path.join(root,'main.js'),'utf8')
globalThis.location = new URL('https://build.invalid/town/')
globalThis.fetch = async input => {
  const url = new URL(input, location)
  if(url.origin!==location.origin || !url.pathname.startsWith('/town/tilemap/')) throw Error('Expected local public map input')
  return new Response(await readFile(path.join(root,url.pathname.slice(6))))
}
const loaders = await import('../runtime_snapshots.js')
await Promise.all([loaders.loadEnergyValleyOsmBlockGraph, loaders.loadWenyuReferenceBuildings,
  loaders.loadWenyuReferenceIntersections,loaders.loadWenyuReferenceLabels,
  loaders.loadWenyuReferenceRoads,loaders.loadWenyuTownModules].map(load=>load()))
const inputs = hash(referenceSignatureInput())
let frame
globalThis.__townBakePublicBaseline = value => {frame=value}
await import(pathToFileURL(path.join(root,'main.js')))
assert(frame?.world.installations && frame?.world.road_network, 'Missing validated world')

const rows=[], types=[], typeIds=new Map(), seen=new Map(), pending=new Set()
function encode(value) {
  if(value===undefined) return []
  if(value===null || typeof value!=='object'){
    assert(['number','boolean','string'].includes(typeof value)||value===null)
    assert(typeof value!=='number'||Number.isFinite(value))
    return value
  }
  if(seen.has(value))return [seen.get(value)]
  assert(!pending.has(value),'Cycle in immutable spatial result')
  pending.add(value)
  let row
  if(Array.isArray(value)){
    row=[-1]
    for(let i=0;i<value.length;i++)row.push(i in value ? encode(value[i]) : [null])
  }else{
    const ctor=value.constructor
    assert(ctor===Object || /^_M0\w+$/.test(ctor.name),'Unknown MoonBit structure '+ctor.name)
    const keys=Object.keys(value),shape=JSON.stringify([ctor.name,keys])
    let id=typeIds.get(shape)
    if(id===undefined){id=types.length;types.push({ctor,keys});typeIds.set(shape,id)}
    row=[id,...keys.map(k=>encode(value[k]))]
  }
  pending.delete(value)
  const index=rows.push(row)-1;seen.set(value,index)
  return [index]
}
encode(frame)
const json=JSON.stringify(rows), bytes=gzipSync(json,{level:9})
const digest=hash(bytes), file='landmark-studio/public-world-'+digest.slice(0,20)+'.bin'
const descriptors=types.map(({ctor,keys})=>{
  const name=ctor.name, singleton=name+'__'
  const useSingleton=keys.length===0 && name!=='Object' && source.includes('const '+singleton+' =')
  return '['+name+'.prototype,'+JSON.stringify(keys)+','+(useSingleton?singleton:'null')+']'
})
function unpack(rows,types){
  const objects=[]
  const value=v=>Array.isArray(v)?v.length?objects[v[0]]:undefined:v
  for(const row of rows){
    if(row[0]===-1){
      const a=new Array(row.length-1)
      for(let i=1;i<row.length;i++)if(!(Array.isArray(row[i])&&row[i][0]===null))a[i-1]=value(row[i])
      objects.push(a)
    }else{
      const [prototype,keys,singleton]=types[row[0]],o=singleton??Object.create(prototype)
      for(let i=0;i<keys.length;i++)o[keys[i]]=value(row[i+1])
      objects.push(o)
    }
  }
  return objects.at(-1)
}
// Catch changed compiler layouts, prototypes and array semantics before shipping.
assert.deepStrictEqual(unpack(JSON.parse(json),types.map(t=>[t.ctor.prototype,t.keys,null])),frame)
await writeFile(path.join(root,file),bytes)
const restore = `
function townRestorePublishedWorld(){
  const input=globalThis.__townBaselineInput;delete globalThis.__townBaselineInput;
  if(input?.digest===${JSON.stringify(digest)})globalThis.__townPublicBaseline=(${unpack})(input.rows,[${descriptors}]);
}
`
await appendFile(path.join(root,'main.js'),restore)
const loaderFile=path.join(root,'public-world.js'),loader=await readFile(loaderFile,'utf8')
assert(loader.includes('const release = null'))
await writeFile(loaderFile,loader.replace('const release = null','const release = '+JSON.stringify({file,digest,inputs})))
console.log('Public world linked:',rows.length,'records,',bytes.length,'bytes,',frame.issues.length,'validation issues')

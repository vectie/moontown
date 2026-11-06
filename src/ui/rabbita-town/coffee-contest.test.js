import test from 'node:test'
import assert from 'node:assert/strict'
import {labelPng,csvCell} from './coffee-contest.js'

test('download label is a valid PNG text chunk without changing pixel chunks',()=>{
  const original=Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aH2QAAAAASUVORK5CYII=','base64')
  const result=Buffer.from(labelPng(original,'generation-fixture'))
  assert.deepEqual(result.subarray(0,original.length-12),original.subarray(0,-12))
  assert.deepEqual(result.subarray(-12),original.subarray(-12))
  const offset=original.length-12, length=result.readUInt32BE(offset)
  assert.equal(result.subarray(offset+4,offset+8).toString(),'tEXt')
  const metadata=result.subarray(offset+8,offset+8+length).toString().split('\0')
  assert.equal(metadata[0],'AIGC')
  assert.equal(JSON.parse(metadata[1]).Label,'1')
  assert.equal(JSON.parse(metadata[1]).ProduceID,'generation-fixture')
  let crc=0xffffffff
  for(const byte of result.subarray(offset+4,offset+8+length)){
    crc^=byte
    for(let bit=0;bit<8;bit++)crc=(crc>>>1)^((crc&1)?0xedb88320:0)
  }
  assert.equal(result.readUInt32BE(offset+8+length),(crc^0xffffffff)>>>0)
  assert.throws(()=>labelPng(new Uint8Array([1,2,3])))
})

test('host export quotes values and neutralizes spreadsheet formulas',()=>{
  assert.equal(csvCell('树, "半醒"'),'"树, ""半醒"""')
  assert.equal(csvCell('=HYPERLINK("https://bad.example")'),'"\'=HYPERLINK(""https://bad.example"")"')
  assert.equal(csvCell('  +123'),'"\'  +123"')
  assert.equal(csvCell('小城还没醒'),'"小城还没醒"')
})

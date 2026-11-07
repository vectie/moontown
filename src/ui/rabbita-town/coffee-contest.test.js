import test from 'node:test'
import assert from 'node:assert/strict'
import {labelPng,csvCell,creativeEndpoint,votingRows,creationPhase,generationCredits} from './coffee-contest.js'

test('generation allowance copy respects the shared event budget even with personal credits left',()=>{
  const value={remaining:2,event_remaining:1,event:{participant_quota:3}}
  assert.match(generationCredits(value,true),/还可生成 1 张/)
  assert.match(generationCredits(value,false),/最多可生成 1 张/)
  assert.equal(generationCredits({...value,event_remaining:0},true),'本期生成名额已用完 · 已生成图片仍可投稿')
  assert.match(generationCredits({...value,event_remaining:20},true),/还可生成 2 张/)
})

test('scheduled activities distinguish upcoming, open and closed at exact boundaries',()=>{
  const event={opens_ms:'1000',deadline_ms:'2000'}
  assert.equal(creationPhase(event,999),'waiting')
  assert.equal(creationPhase(event,1000),'open')
  assert.equal(creationPhase(event,1999),'open')
  assert.equal(creationPhase(event,2000),'closed')
})

test('activity endpoint never silently falls back to the legacy contest for a malformed activity',()=>{
  assert.equal(creativeEndpoint('https://town.example/moontown/coffee-contest.html').pathname,'/moontown/api/creative/')
  assert.equal(creativeEndpoint('https://town.example/coffee-qa/coffee-contest.html?activity=activity-abc').pathname,'/coffee-qa/api/activities/activity-abc/')
  for(const id of ['', '../private','https://other.example','a/b','a%2fb'])assert.throws(()=>creativeEndpoint(`https://town.example/moontown/coffee-contest.html?activity=${encodeURIComponent(id)}`))
})

test('ranking uses server counts and rank ties without revealing withdrawn work metadata',()=>{
  const value={gallery:[{id:'a',title:'小城',display_name:'A'},{id:'b',title:'云朵',display_name:'B'}],voting:{settled:true,counts:[{entry_id:'b',votes:2,rank:1,eligible:true},{entry_id:'a',votes:2,rank:1,eligible:true},{entry_id:'removed',votes:4,rank:0,eligible:false}]}}
  assert.deepEqual(votingRows(value).map(row=>[row.entry_id,row.votes,row.rank]),[['a',2,1],['b',2,1]])
  assert.equal(votingRows(value).some(row=>row.entry_id==='removed'),false)
})

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

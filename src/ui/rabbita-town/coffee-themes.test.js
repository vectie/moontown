import test from 'node:test';
import assert from 'node:assert/strict';
import {creationGuide} from './coffee-themes.js';
import {generationPrompt,DEFAULT_PROMPT,staleSnapshot} from './coffee-contest.js';
import {suggestedTitle,archivedShareHref} from './coffee-share.js';
import {claimGroup} from './coffee-claim.js';
import {draftStore,scopedDraftStore,draftKey} from './coffee-drafts.js';

const second={id:'banxing-coffee-20261116',topic:'变身'};
const third={id:'banxing-coffee-20261123',topic:'暖暖'};
const fourth={id:'banxing-coffee-20261130',topic:'把冬天泡开'};
test('fourth round uses winter prompts and evergreen claim QR without replacing custom work',()=>{
  const guide=creationGuide(fourth);
  assert.equal(guide.key,'winter');assert.match(guide.reference,/winter-reference/);
  assert.match(generationPrompt('',fourth),/雪城/);assert.equal(generationPrompt('  我的冬日  ',fourth),'我的冬日');
  assert.deepEqual(guide.prompts.map(x=>x[0]),['泡开雪城','杯沿解冻','心事回暖']);
  assert.equal(creationGuide({id:'banxing-coffee-week04-qa-20261127'}).key,'winter');
  const claim=claimGroup(fourth,Date.parse('2026-12-04T20:00:00+08:00'));
  assert.equal(claim.kind,'community');assert.equal(claim.expired,false);assert.match(claim.src,/community-qr/);
});
test('third round uses warm defaults, names and reference without replacing custom prompts',()=>{
  const guide=creationGuide(third);
  assert.equal(guide.key,'warm');assert.match(guide.reference,/warm-reference/);
  assert.match(generationPrompt('',third),/暹罗猫/);assert.doesNotMatch(generationPrompt('',third),/水晶|蝶翼/);
  assert.equal(generationPrompt('  我的暖暖故事  ',third),'我的暖暖故事');
  assert.deepEqual(guide.prompts.map(x=>x[0]),['暖暖相伴','一束晨光','慢半拍']);
  assert.equal(suggestedTitle('暹罗猫和拉花',0,third),'暖暖相伴');
  assert.equal(creationGuide({id:'banxing-coffee-week03-qa-20261123'}).key,'warm');
});
test('third round uses the supplied group code and its own expiry boundary',()=>{
  assert.match(claimGroup(third,Date.parse('2026-11-29T23:59:59+08:00')).src,/claim-group-20261123/);
  assert.equal(claimGroup(third,Date.parse('2026-11-29T23:59:59+08:00')).expired,false);
  assert.equal(claimGroup(third,Date.parse('2026-11-30T00:00:00+08:00')).expired,true);
  assert.equal(claimGroup(second,Date.parse('2026-11-23T00:00:00+08:00')).expired,true);
});
test('old shared entries return to their archived event without redirecting current entries or activities',()=>{
  const base='https://example.test/town/coffee-contest.html?entry='+ 'a'.repeat(64);
  const old=new URL(archivedShareHref(base+'&campaign='+second.id+'#gallery'));
  assert.equal(old.pathname,'/coffee-week02/coffee-contest.html');assert.equal(old.searchParams.get('entry'),'a'.repeat(64));assert.equal(old.hash,'#gallery');
  assert.equal(new URL(archivedShareHref(base+'&campaign='+third.id)).pathname,'/coffee-week03/coffee-contest.html');
  assert.equal(archivedShareHref(base+'&campaign='+fourth.id),null);
  assert.equal(archivedShareHref(base+'&campaign='+second.id+'&activity=custom'),null);
  assert.equal(archivedShareHref('https://example.test/coffee-week02/coffee-contest.html?entry=x&campaign='+second.id),null);
});
test('a new round may start at revision zero while stale snapshots of the same round stay rejected',()=>{
  const old={event:{id:'first'},viewer:{account_id:'A'},revision:54};
  assert.equal(staleSnapshot(old,{event:{id:second.id},viewer:{account_id:'A'},revision:0},'A'),false);
  assert.equal(staleSnapshot(old,{...old,revision:53},'A'),true);
  assert.equal(staleSnapshot(old,{...old,revision:54},'A'),false);
});
test('the second round uses its own visible default without replacing a custom prompt',()=>{
  const guide=creationGuide(second);
  assert.match(generationPrompt('',second),/水晶咖啡杯/);
  assert.equal(generationPrompt('  我的原创变身  ',second),'我的原创变身');
  assert.equal(generationPrompt('',{id:'banxing-coffee-20261106'}),DEFAULT_PROMPT);
  assert.deepEqual(guide.prompts.map(x=>x[0]),['折光变身','自我成蝶','风雨蜕变']);
  assert.match(suggestedTitle('',0,second),/光/);
  assert.equal(suggestedTitle('茧中蝶翼',0,second),'破茧的一杯');
  assert.equal(creationGuide({id:'another-event',topic:'街区摄影'}).key,'first');
});
test('the fresh group invitation belongs to round two and expires on its printed date',()=>{
  assert.equal(claimGroup(second,Date.parse('2026-11-22T23:59:59+08:00')).expired,false);
  assert.equal(claimGroup(second,Date.parse('2026-11-23T00:00:00+08:00')).expired,true);
  assert.match(claimGroup(second).src,/20261116/);
  assert.match(claimGroup({id:'banxing-coffee-20261106'}).src,/20261109/);
  assert.equal(claimGroup({id:'unrelated'}),null);
});
test('a stable page can change rounds without losing old drafts or inheriting them into the new round',async()=>{
  const previous=globalThis.localStorage,storage=new Map();
  globalThis.localStorage={getItem:key=>storage.get(key)||null,setItem:(key,value)=>storage.set(key,value)};
  try{
    const scope='https://example.test/town/api/creative/';
    draftStore(scope).write('A',{prompt:'首期未完成的提示词',title:'首期作品'});
    const first=scopedDraftStore(scope,'banxing-coffee-20261106');
    const next=scopedDraftStore(scope,second.id);
    const warm=scopedDraftStore(scope,third.id);
    assert.equal(await next.read('A'),null);
    assert.equal((await first.read('A')).prompt,'首期未完成的提示词');
    assert.ok(storage.has(draftKey(scope,'A')));
    next.write('A',{prompt:'第二期的提示词'});
    assert.equal(await warm.read('A'),null);
    warm.write('A',{prompt:'第三期暖暖的提示词'});
    assert.equal(await scopedDraftStore(scope,fourth.id).read('A'),null);
    assert.equal((await scopedDraftStore('https://example.test/coffee-week03/api/creative/',third.id).read('A')).prompt,'第三期暖暖的提示词');
    assert.equal((await scopedDraftStore(scope,third.id).read('A')).prompt,'第三期暖暖的提示词');
    assert.equal((await scopedDraftStore(scope,second.id).read('A')).prompt,'第二期的提示词');
    assert.equal((await scopedDraftStore('https://example.test/coffee-week02/api/creative/',second.id).read('A')).prompt,'第二期的提示词');
    assert.equal((await scopedDraftStore(scope,second.id).read('A')).prompt,'第二期的提示词');
    assert.equal((await first.read('A')).title,'首期作品');
    assert.equal(await next.read('B'),null);
    assert.equal((await scopedDraftStore('https://example.test/coffee-qa/api/creative/',second.id).read('A')),null);
  }finally{globalThis.localStorage=previous;}
});

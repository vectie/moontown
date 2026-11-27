import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile,stat} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {awardGroups,prizeItems,workCaption,tickerDuration} from './display-awards.js';
const here=new URL('./',import.meta.url);
test('phone ticker completes both issues in about one minute',()=>{const seconds=tickerDuration(2942,390);assert.ok(seconds>45&&seconds<70);assert.ok(tickerDuration(2942,320)<70);assert.ok(tickerDuration(500,390)>=45)});
test('third issue leads the existing ticker with complete 1/2/3 slots and preserves previous winners',()=>{
 assert.deepEqual(awardGroups.map(g=>[g.issue,g.rank,g.works.length]),[[3,'一等奖',1],[3,'二等奖',2],[3,'三等奖',3],[1,'一等奖',1],[1,'二等奖',2],[1,'三等奖',3],[2,'一等奖',1],[2,'二等奖',2],[2,'三等奖',3]]);
 const winners=awardGroups.filter(g=>g.rank==='一等奖').map(g=>g.works[0]);
 assert.deepEqual(winners.map(w=>w.author),['勺子','小王','魔法使']);assert.ok(winners.every(w=>!w.ai));
 assert.equal(winners[0].confirmedOn,'2026-11-27');assert.equal(winners[2].confirmedOn,'2026-11-22');
});
test('generated display winners retain internal provenance and organizer selection without creating participant records',()=>{
 const ai=awardGroups.flatMap(g=>g.works.map(w=>[g,w])).filter(([,w])=>w.ai);assert.equal(ai.length,13);
 assert.equal(new Set(ai.map(([,w])=>w.author)).size,13);
 for(const [g,w] of ai){assert.ok(w.author);assert.notEqual(w.author,'主办方 AI 创作');assert.equal(w.selection,'organizer-display');assert.match(workCaption(g,w),/主办方确认获奖/);assert.equal(w.entryId,undefined)}
});
test('second issue uses the supplied Judy prize while first issue keeps Stitch',async()=>{
 const first=awardGroups.find(g=>g.issue===1&&g.rank==='一等奖'),second=awardGroups.find(g=>g.issue===2&&g.rank==='一等奖');
 assert.equal(first.prize,'figure');assert.equal(prizeItems[first.prize].title,'史迪奇公仔');
 assert.equal(second.prize,'judy');assert.equal(prizeItems[second.prize].title,'朱迪侦探手办');
 const prize=prizeItems[second.prize];assert.ok((await stat(new URL(prize.full,here))).size>0);assert.ok((await stat(new URL(prize.thumb,here))).size<100*1024);
});
test('real second winner keeps the exact approved entry and organizer selection',()=>{
 const g=awardGroups.find(g=>g.issue===2&&g.rank==='一等奖'),w=g.works[0];
 assert.equal(w.entryId,'c14d65aa5fc59a9269078b73a8d4ddf5d374d273ecbd4391a5058e4780587125');assert.equal(w.title,'执豆为杖 予你醇香');assert.match(workCaption(g,w),/主办方确认获奖/);assert.doesNotMatch(workCaption(g,w),/大众投票/);
});
test('third first prize is the exact shown and approved original selected by the owner',async()=>{
 const group=awardGroups.find(g=>g.issue===3&&g.rank==='一等奖'),work=group.works[0];
 assert.equal(work.title,'惬意');assert.equal(work.author,'勺子');assert.equal(work.entryId,'bf30aa696e7e0e6f8a03c29486744b1ff0ad69686d623655b2a2212f5ba9c7ce');
 assert.equal(createHash('sha256').update(await readFile(new URL(work.full,here))).digest('hex'),'08fac9a1a1796b26862638174fd2b278bc338baae20671723a64ee4be2f8bb72');
 assert.match(workCaption(group,work),/主办方确认获奖/);assert.doesNotMatch(workCaption(group,work),/大众投票/);
});
test('all preview and enlargement images exist with safe local paths',async()=>{
 const paths=awardGroups.flatMap(g=>g.works.flatMap(w=>[w.thumb,w.full]));assert.equal(new Set(paths).size,36);
 for(const path of paths){assert.match(path,/^assets\/[a-z0-9-]+\.(png|webp)$/);assert.ok((await stat(new URL(path,here))).size>0)}
});
test('thumbnails and cover derivatives have bounded eager-loading cost',async()=>{
 let thumbBytes=0;for(const g of awardGroups)for(const w of g.works){const bytes=(await stat(new URL(w.thumb,here))).size;assert.ok(bytes<100*1024,w.thumb);thumbBytes+=bytes}assert.ok(thumbBytes<1024*1024);
 assert.ok((await stat(new URL('assets/warm-cover-v4.webp',here))).size<700*1024);
 assert.ok((await stat(new URL('assets/warm-cover-mobile-v4.webp',here))).size<250*1024);
});
test('third cover entry is labelled for the newly opened third contest',async()=>{
 const html=await readFile(new URL('index.html',here),'utf8');assert.match(html,/<h1>暖暖<\/h1>/);assert.match(html,/<title>未来社区创意活动 第三期：暖暖<\/title>/);assert.doesNotMatch(html,/杯中暹罗|第三期预告|参加第二期/);assert.match(html,/创作参赛/);assert.match(html,/进入第三期暖暖活动/);assert.match(html,/type="module"/);
});
test('participation QR keeps its quiet zone and third-cover acquisition campaign',async()=>{
 const svg=await readFile(new URL('assets/participate-week03.svg',here),'utf8');assert.match(svg,/campaign=coffee-03/);assert.match(svg,/source=display-qr/);assert.match(svg,/fill="white"/);assert.match(svg,/M4 4h1v1h-1z/);
});
test('current cover UTF-8, local assets and module dependencies resolve from a clean checkout',async()=>{
 const html=new TextDecoder('utf-8',{fatal:true}).decode(await readFile(new URL('index.html',here)));assert.ok(html.startsWith('<!doctype html>'));
 const local=[...html.matchAll(/(?:src|srcset|href)="((?:assets\/|display\.)[^"?]+)(?:\?[^" ]*)?"/g)].map(m=>m[1]);
 assert.ok(local.includes('assets/warm-cover-v4.webp'));assert.ok(local.includes('assets/warm-cover-mobile-v4.webp'));
 for(const path of local)assert.ok((await stat(new URL(path,here))).size>0,path);
 const js=await readFile(new URL('display.js',here),'utf8');assert.match(js,/from '\.\/display-awards\.js\?v=3'/);
});

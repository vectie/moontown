import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile,stat} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {awardGroups,workCaption,tickerDuration} from './display-awards.js';
const here=new URL('./',import.meta.url);
test('phone ticker completes both issues in about one minute',()=>{const seconds=tickerDuration(2942,390);assert.ok(seconds>45&&seconds<70);assert.ok(tickerDuration(2942,320)<70);assert.ok(tickerDuration(500,390)>=45)});
test('both previous issues have 1/2/3 display slots and distinct real winners',()=>{
 assert.deepEqual(awardGroups.map(g=>[g.issue,g.rank,g.works.length]),[[1,'一等奖',1],[1,'二等奖',2],[1,'三等奖',3],[2,'一等奖',1],[2,'二等奖',2],[2,'三等奖',3]]);
 const winners=awardGroups.filter(g=>g.rank==='一等奖').map(g=>g.works[0]);
 assert.deepEqual(winners.map(w=>w.author),['小王','魔法使']);assert.ok(winners.every(w=>!w.ai));
 assert.equal(winners[1].confirmedOn,'2026-11-22');
});
test('every AI supplement has explicit attribution and never impersonates a participant',()=>{
 const ai=awardGroups.flatMap(g=>g.works.map(w=>[g,w])).filter(([,w])=>w.ai);assert.equal(ai.length,8);
 for(const [g,w] of ai){assert.equal(w.author,'主办方 AI 创作');assert.equal(w.selection,'display-supplement');assert.match(workCaption(g,w),/AI 补位展示/);assert.equal(w.entryId,undefined)}
});
test('real second winner keeps the exact approved entry and organizer selection',()=>{
 const g=awardGroups.find(g=>g.issue===2&&g.rank==='一等奖'),w=g.works[0];
 assert.equal(w.entryId,'c14d65aa5fc59a9269078b73a8d4ddf5d374d273ecbd4391a5058e4780587125');assert.equal(w.title,'执豆为杖 予你醇香');assert.match(workCaption(g,w),/主办方确认获奖/);assert.doesNotMatch(workCaption(g,w),/大众投票/);
});
test('all preview and enlargement images exist with safe local paths',async()=>{
 const paths=awardGroups.flatMap(g=>g.works.flatMap(w=>[w.thumb,w.full]));assert.equal(new Set(paths).size,24);
 for(const path of paths){assert.match(path,/^assets\/[a-z0-9-]+\.(png|webp)$/);assert.ok((await stat(new URL(path,here))).size>0)}
});
test('thumbnails and cover derivatives have bounded eager-loading cost',async()=>{
 for(const g of awardGroups)for(const w of g.works)assert.ok((await stat(new URL(w.thumb,here))).size<100*1024,w.thumb);
 assert.ok((await stat(new URL('assets/siamese-cover.webp',here))).size<700*1024);
 assert.ok((await stat(new URL('assets/siamese-cover-mobile.webp',here))).size<250*1024);
});
test('third cover does not advertise entry into the closed previous contest',async()=>{
 const html=await readFile(new URL('index.html',here),'utf8');assert.match(html,/<h1>杯中暹罗<\/h1>/);assert.match(html,/第三期预告/);assert.match(html,/查看历届作品/);assert.doesNotMatch(html,/参加第二期|开始创作|一键参赛有奖/);assert.match(html,/type="module"/);
});
test('participation QR keeps its quiet zone and third-cover acquisition campaign',async()=>{
 const svg=await readFile(new URL('assets/participate-week03.svg',here),'utf8');assert.match(svg,/campaign=coffee-03/);assert.match(svg,/source=display-qr/);assert.match(svg,/fill="white"/);assert.match(svg,/M4 4h1v1h-1z/);
});
test('production manifest is exact UTF-8 and covers all published modules',async()=>{
 const root=new URL('../../../output/coffee-third-cover-20261122/input/',import.meta.url),manifest=JSON.parse(await readFile(new URL('manifest.json',root),'utf8'));
 assert.equal(manifest.files.length,41);assert.equal(manifest.only_display,true);
 for(const f of manifest.files){const bytes=await readFile(new URL(f.path,root));assert.equal(bytes.length,f.bytes);assert.equal(createHash('sha256').update(bytes).digest('hex'),f.sha256)}
 const html=new TextDecoder('utf-8',{fatal:true}).decode(await readFile(new URL('index.html',root)));assert.ok(html.startsWith('<!doctype html>'));assert.match(html,/杯中暹罗/);
 const js=await readFile(new URL('display-week03.js',root),'utf8');assert.match(js,/display-awards-week03\.js/);
});

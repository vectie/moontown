import test from 'node:test';
import assert from 'node:assert/strict';
import {createServer} from 'node:http';
import {readFile, mkdir, writeFile} from 'node:fs/promises';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import {resolve, extname, sep} from 'node:path';

const require = createRequire(import.meta.url);
const {chromium, webkit} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const root = resolve(fileURLToPath(new URL('./', import.meta.url)));
const output = fileURLToPath(new URL('../../../output/coffee-display-4k-20261127/', import.meta.url));
const mime = {'.html':'text/html; charset=utf-8','.css':'text/css','.js':'text/javascript','.webp':'image/webp','.png':'image/png','.svg':'image/svg+xml'};

test('display playback across Chromium and WebKit', {timeout:180000}, async t => {
  const server = createServer(async (request, response) => {
    try {
      const path = resolve(root, '.' + new URL(request.url, 'http://localhost').pathname.replace(/^\/disp\//, '/'));
      if (!path.startsWith(root + sep) && path !== root) throw new Error('path');
      const name = path === root || request.url.split('?')[0] === '/disp/' ? resolve(root, 'index.html') : path;
      response.writeHead(200, {'Content-Type':mime[extname(name)] || 'application/octet-stream'});
      response.end(await readFile(name));
    } catch (_) {response.writeHead(404);response.end();}
  });
  await new Promise(done => server.listen(0, '127.0.0.1', done));
  const base = process.env.COFFEE_DISPLAY_URL || `http://127.0.0.1:${server.address().port}/disp/`;
  await mkdir(output, {recursive:true});
  const evidence = [];
  try {
    for (const [name, engine] of [['chromium',chromium],['webkit',webkit]]) {
      await t.test(name, {timeout:85000}, async t => {
        const browser = await engine.launch({headless:true});
        const errors = [];
        const page = await browser.newPage({viewport:{width:3840,height:2160},deviceScaleFactor:1});
        page.on('pageerror', error => errors.push(error.message));
        const state = () => page.evaluate(() => {
          const track = document.querySelector('#track');
          return {paused:document.querySelector('.display').dataset.paused,
            x:new DOMMatrixReadOnly(getComputedStyle(track).transform).m41,
            playState:getComputedStyle(track).animationPlayState,
            reduced:matchMedia('(prefers-reduced-motion: reduce)').matches,
            focused:document.activeElement?.className,
            hero:[document.querySelector('#hero-art').naturalWidth,document.querySelector('#hero-art').naturalHeight],
            source:document.querySelector('#hero-art').currentSrc};
        });
        const open = async () => {
          await page.goto(base, {waitUntil:'networkidle'});
          await page.waitForFunction(() => document.querySelector('.carousel-cycle .slide') && document.querySelector('#hero-art').complete);
          await page.waitForTimeout(2300);
        };
        const moved = async () => {
          const before = await state();
          await page.waitForTimeout(650);
          const after = await state();
          evidence.push({engine:name,before,after});
          assert.ok(after.x < before.x - 10, JSON.stringify({before,after}));
        };
        const still = async () => {
          await page.waitForTimeout(100);
          const before = await state();await page.waitForTimeout(350);const after = await state();
          assert.ok(Math.abs(after.x-before.x)<1, JSON.stringify({before,after}));
        };
        try {
          await t.test('4K screen moves with pointer parked over the ticker', async () => {
            await open();assert.equal(await page.locator('.carousel-cycle:not([data-clone]) .slide').count(),18);
            await page.locator('.carousel-viewport').hover();await moved();
          });
          await t.test('explicit pause, play and mouse-opened artwork resume correctly', async () => {
            await page.locator('#motion').click();await still();
            await page.locator('#motion').click();await moved();
            const card = await page.locator('.slide').evaluateAll(nodes => nodes.map(node => node.getBoundingClientRect()).find(rect => rect.left > 250 && rect.right < innerWidth));
            assert.ok(card);await page.mouse.click(card.x+card.width/2,card.y+card.height/2);
            await page.locator('dialog[open]').waitFor();await still();
            await page.locator('#close-detail').click();await page.waitForTimeout(100);await moved();
          });
          await t.test('keyboard focus pauses the artwork being read', async () => {
            await page.locator('#motion').focus();await page.keyboard.press('Tab');
            // macOS WebKit may restrict Tab to text controls; focus the same
            // artwork explicitly after entering keyboard navigation mode.
            await page.locator('.slide').first().focus();await still();
            await page.locator('#motion').click();
          });
          await t.test('ordinary browser respects reduced motion and allows explicit play', async () => {
            await page.emulateMedia({reducedMotion:'reduce'});await open();await still();
            await page.locator('#motion').click();await moved();
          });
          await t.test('unattended native exhibition autoplays even with desktop reduced motion', async () => {
            await page.addInitScript(() => {window.lepusa = {invoke:async()=>({})};});
            await open();await moved();
          });
          await t.test('native exhibition hides idle cursor over moving cards and restores it for deliberate movement', async () => {
            const cursor=()=>page.locator('#motion').evaluate(node=>getComputedStyle(node).cursor);
            await page.mouse.move(500,2050);await page.mouse.move(540,2050);
            assert.notEqual(await cursor(),'none');
            await page.waitForTimeout(2000);assert.equal(await cursor(),'none');
            await page.mouse.move(541,2051);await page.waitForTimeout(100);assert.equal(await cursor(),'none');
            await moved();
            await page.mouse.move(580,2050);assert.notEqual(await cursor(),'none');
            await page.locator('#motion').click();assert.equal(await page.locator('.display').getAttribute('data-paused'),'true');
            await page.locator('#motion').click();await moved();
            await page.keyboard.press('Tab');assert.equal(await cursor(),'none');
            await page.mouse.move(620,2000);
          });
          await t.test('4K image is decoded and mobile retains its small full-composition source', async () => {
            assert.deepEqual((await state()).hero,[3840,2160]);
            await page.mouse.move(0,0);
            await page.screenshot({path:resolve(output,`${name}-4k.png`),fullPage:true});
            await page.setViewportSize({width:390,height:844});await open();
            assert.match((await state()).source,/winter-cover-mobile-v1.webp/);
            assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),true);
            await page.locator('.carousel-viewport').scrollIntoViewIfNeeded();await moved();
            await page.screenshot({path:resolve(output,`${name}-phone.png`),fullPage:true});
          });
          assert.deepEqual(errors, []);
        } finally {await browser.close();}
      });
    }
  } finally {
    await writeFile(resolve(output,'playback-evidence.json'), JSON.stringify(evidence,null,2));
    await new Promise(done=>server.close(done));
  }
});

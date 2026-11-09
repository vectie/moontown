import test from 'node:test';
import assert from 'node:assert/strict';
import {acquisitionFrom,firstAcquisition,loginContact} from './coffee-acquisition.js';
test('phone and email are alternative login contacts; passwords have no contact conversion',()=>{
  assert.deepEqual(loginContact('13800138000'),{phone:'+8613800138000'});
  assert.deepEqual(loginContact('+8613800138000'),{phone:'+8613800138000'});
  assert.deepEqual(loginContact(' a@example.test '),{email:'a@example.test'});
  assert.throws(()=>loginContact('13800138000@example'));
});
test('first acquisition survives a later direct visit without touching draft storage',()=>{
  const previousDocument=Object.getOwnPropertyDescriptor(globalThis,'document');
  const previousLocation=Object.getOwnPropertyDescriptor(globalThis,'location');
  let cookie='';
  try {
    Object.defineProperty(globalThis,'document',{configurable:true,value:{referrer:'',get cookie(){return cookie;},set cookie(value){cookie=value.split(';')[0];}}});
    Object.defineProperty(globalThis,'location',{configurable:true,value:{href:'https://example.test/moontown/coffee-contest.html?source=display-qr&campaign=banxing-01',protocol:'https:'}});
    const first=firstAcquisition();
    location.href='https://example.test/moontown/coffee-contest.html';
    assert.deepEqual(firstAcquisition(),first);
    assert.equal(first.source,'display-qr');
    assert.equal(first.campaign,'banxing-01');
  } finally {
    if(previousDocument)Object.defineProperty(globalThis,'document',previousDocument);else delete globalThis.document;
    if(previousLocation)Object.defineProperty(globalThis,'location',previousLocation);else delete globalThis.location;
  }
});
test('campaign source distinguishes QR, direct activity and external referrals without retaining referrer paths',()=>{
  assert.equal(acquisitionFrom('https://example.test/moontown/coffee-contest.html?source=display-qr&campaign=banxing-01').source,'display-qr');
  assert.equal(acquisitionFrom('https://example.test/moontown/coffee-contest.html').source,'activity-direct');
  const ref=acquisitionFrom('https://example.test/moontown/coffee-contest.html','https://other.test/private?email=private');
  assert.equal(ref.entry,'other.test');
  assert.ok(!JSON.stringify(ref).includes('private'));
});

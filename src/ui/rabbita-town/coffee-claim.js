// Event-specific public group invitation, never an admission requirement.
const eventIds = new Set(['banxing-coffee-20261106', 'coffee-mobile-qa-20261107', 'creative-http-fixture']);
export function claimGroup(event, now = Date.now()) {
  if(['banxing-coffee-20261123','banxing-coffee-week03-qa-20261123'].includes(event?.id))return {src:'coffee/claim-group-20261123.jpg',expired:now>=Date.parse('2026-11-30T00:00:00+08:00'),validUntil:'11月30日'};
  if(['banxing-coffee-20261116','banxing-coffee-week02-qa-20261116'].includes(event?.id))return {src:'coffee/claim-group-20261116.jpg',expired:now>=Date.parse('2026-11-23T00:00:00+08:00'),validUntil:'11月23日'};
  if (!eventIds.has(event?.id)) return null;
  return {src:'coffee/claim-group-20261109.jpg', expired:now >= Date.parse('2026-11-16T00:00:00+08:00')};
}
export function coffeeClaim({fitDialog, now = () => Date.now(), onDone = () => {}}) {
  const $ = id => document.getElementById(id), dialog = $('claim-dialog');
  let returnTo;
  function open(event, submitted = false) {
    const group = claimGroup(event, now());
    if (!group) return;
    returnTo = document.activeElement;
    $('claim-title').textContent = submitted ? '投稿成功' : '开奖与领奖群';
    $('claim-description').textContent = group.expired ? '群二维码已到期，请等待主办更新。你的投稿和审核不受影响。' : '扫码加入领奖群，留意开奖和领奖安排。';
    $('claim-code').hidden = group.expired;
    $('save-claim-code').hidden = group.expired;
    $('claim-instructions').hidden = group.expired;
    $('claim-instructions').textContent=`微信中长按识别；其他浏览器可保存到相册，再用微信扫一扫。二维码有效至${group.validUntil || '11月16日'}前。`;
    if (!group.expired) {
      $('claim-code-image').src = group.src;
      $('save-claim-code').href = group.src;
    }
    dialog.showModal(); fitDialog(); $('close-claim').focus();
  }
  $('close-claim').onclick = () => dialog.close();
  $('claim-done').onclick = () => {returnTo=null;dialog.close();onDone();};
  dialog.addEventListener('close', () => {
    if (returnTo?.isConnected && returnTo.getClientRects().length) returnTo.focus({preventScroll:true});
  });
  return {open, close:() => dialog.close()};
}

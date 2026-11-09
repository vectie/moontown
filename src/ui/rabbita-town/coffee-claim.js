// Event-specific public group invitation, never an admission requirement.
const eventIds = new Set(['banxing-coffee-20261106', 'coffee-mobile-qa-20261107', 'creative-http-fixture']);
export function claimGroup(event, now = Date.now()) {
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

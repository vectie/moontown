// Marketing attribution only: never grants roles, quotas or identity assurance.
export function acquisitionFrom(href, referrer='') {
  const url = new URL(href);
  const clean = value => /^[a-zA-Z0-9_./-]{1,128}$/.test(value || '') ? value : '';
  let referred = '';
  try { const ref = new URL(referrer); if(ref.origin!==url.origin)referred=clean(ref.hostname); } catch {}
  return {source:clean(url.searchParams.get('source')) || (referred ? 'external-referral' : 'activity-direct'),
    campaign:clean(url.searchParams.get('campaign')) || clean(url.searchParams.get('activity')) || 'banxing-01',
    entry:referred || clean(url.pathname) || 'unknown'};
}
export function firstAcquisition() {
  const key='future_community_acquisition';
  try {
    const raw=document.cookie.split('; ').find(part=>part.startsWith(key+'='));
    if(raw){const saved=JSON.parse(decodeURIComponent(raw.slice(key.length+1)));if(saved&&Object.values(saved).every(v=>typeof v==='string'&&/^[a-zA-Z0-9_./-]{1,128}$/.test(v)))return saved;}
  } catch {}
  const value=acquisitionFrom(location.href,document.referrer);
  document.cookie=`${key}=${encodeURIComponent(JSON.stringify(value))}; Path=/; Max-Age=2592000; SameSite=Lax${location.protocol==='https:'?'; Secure':''}`;
  return value;
}
export function loginContact(value) {
  const raw=value.trim();
  if(/^1\d{10}$/.test(raw))return {phone:`+86${raw}`};
  if(/^\+861\d{10}$/.test(raw))return {phone:raw};
  if(/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(raw))return {email:raw};
  throw new Error('请输入手机号或邮箱，二选一即可。');
}

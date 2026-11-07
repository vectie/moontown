// The existing same-origin identity gateway owns passwords and browser sessions.
export function coffeeAuth({ loginUrl, onSignedIn, fitDialog }) {
  const $ = id => document.getElementById(id);
  const dialog = $('auth-dialog');
  const prefix = new URL(loginUrl);
  if (prefix.origin !== location.origin) throw new Error('登录入口必须与活动同源');
  let registering = false, busy = false;
  function message(text, error = false) {
    $('auth-notice').textContent = text;
    $('auth-notice').dataset.error = String(error);
  }
  function render() {
    $('auth-title').textContent = registering ? '创建账户，继续参与' : '登录，继续参与';
    $('auth-name-field').hidden = !registering;
    $('auth-name').required = registering;
    $('auth-password-hint').hidden = !registering;
    $('auth-password').autocomplete = registering ? 'new-password' : 'current-password';
    $('auth-password').minLength = registering ? 12 : 1;
    $('auth-mode').textContent = registering ? '已有账户？直接登录' : '还没有账户？创建账户';
    $('auth-submit').textContent = busy ? '正在连接…' : registering ? '创建账户并继续' : '登录并继续';
    for (const control of $('auth-form').querySelectorAll('input,button')) control.disabled = busy;
    $('auth-submit').setAttribute('aria-busy', String(busy));
    fitDialog();
  }
  function open() {
    message('');
    render();
    dialog.showModal();
    fitDialog();
    $('auth-email').focus();
  }
  async function post(route, body) {
    return fetch(new URL(`auth/${route}`, prefix), {
      method: 'POST', credentials: 'same-origin', cache: 'no-store', redirect: 'error',
      headers: { 'Accept': 'application/json', 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });
  }
  $('auth-mode').onclick = () => { registering = !registering; message(''); render(); };
  $('close-auth').onclick = () => dialog.close();
  dialog.addEventListener('cancel', event => { if (busy) event.preventDefault(); });
  dialog.addEventListener('close', () => { $('auth-password').value = ''; message(''); });
  $('auth-form').onsubmit = async event => {
    event.preventDefault();
    if (busy) return;
    const username = $('auth-email').value.trim(), password = $('auth-password').value;
    busy = true;
    message('');
    render();
    try {
      let response = await post(registering ? 'register' : 'password', registering ? {
        email: username, display_name: $('auth-name').value.trim(), password, audience: 'enterprise'
      } : { username, password, audience: 'enterprise' });
      // Account creation can succeed before the optional trial workspace is ready.
      // One normal login recovers that case without another account or GPU task.
      if (registering && response.status === 503) {
        response = await post('password', { username, password, audience: 'enterprise' });
      }
      if (!response.ok) {
        const errors = { 400: '请确认邮箱格式和密码要求。', 401: '邮箱或密码不正确，请重新输入。', 409: '该邮箱已有账户，请切换到登录。',
          429: '尝试较多，请稍后再试。', 403: '登录请求未被接受，请刷新页面后重试。',
          503: registering ? '账户可能已创建，请稍后用相同邮箱和密码登录。' : '登录服务暂时不可用，请稍后重试。' };
        throw new Error(errors[response.status] || '暂时无法登录，请稍后再试。');
      }
      await onSignedIn();
      dialog.close();
    } catch (error) {
      message(error.message || '网络连接中断，请重试。', true);
    } finally {
      busy = false;
      render();
    }
  };
  return { open };
}

const ACCOUNT_SESSION_KEY = 'moontown.account-session.v1'

function accountContext() {
  try {
    return JSON.parse(globalThis.__moontownAccountContextJson || '{}')
  } catch {
    return {}
  }
}

function accountToken() {
  if (typeof globalThis.__moontownSessionToken === 'string') {
    return globalThis.__moontownSessionToken
  }
  try {
    return globalThis.localStorage?.getItem(ACCOUNT_SESSION_KEY) || ''
  } catch {
    return ''
  }
}

function node(tag, className, text) {
  const element = document.createElement(tag)
  if (className) element.className = className
  if (text != null) element.textContent = String(text)
  return element
}

function append(parent, ...children) {
  parent.append(...children.filter(Boolean))
  return parent
}

function button(label, action, secondary = false) {
  const control = node(
    'button',
    secondary
      ? 'account-management-button is-secondary'
      : 'account-management-button',
    label,
  )
  control.type = 'button'
  control.addEventListener('click', action)
  return control
}

function field(label, name, options = {}) {
  const wrapper = node('label', 'account-management-field')
  const caption = node('span', 'account-management-field-label', label)
  let control
  if (options.choices) {
    control = document.createElement('select')
    for (const [value, text] of options.choices) {
      const option = document.createElement('option')
      option.value = value
      option.textContent = text
      control.append(option)
    }
  } else {
    control = document.createElement('input')
    control.type = options.type || 'text'
    control.placeholder = options.placeholder || ''
  }
  control.name = name
  control.className = 'account-management-input'
  control.required = options.required !== false
  wrapper.append(caption, control)
  return { wrapper, control }
}

async function request(path, options = {}) {
  const token = accountToken()
  if (!token) throw new Error('A real account session is required for this operation.')
  const response = await fetch(path, {
    cache: 'no-store',
    ...options,
    headers: {
      'x-miniapp-session': token,
      ...(options.body ? { 'content-type': 'application/json' } : {}),
      ...(options.headers || {}),
    },
  })
  const result = await response.json().catch(() => ({}))
  if (!response.ok) {
    throw new Error(result.message || result.error || `Request failed (${response.status})`)
  }
  return result
}

function setStatus(message, state = 'info') {
  const status = document.getElementById('account-management-status')
  if (!status) return
  status.textContent = message
  status.className = `account-management-status is-${state}`
  status.setAttribute('role', state === 'error' ? 'alert' : 'status')
}

function metric(label, value) {
  return append(
    node('div', 'account-management-metric'),
    node('span', 'account-management-metric-label', label),
    node('strong', 'account-management-metric-value', value),
  )
}

function resultPanel(title, detail) {
  return append(
    node('section', 'account-management-result'),
    node('h2', '', title),
    node('p', '', detail),
  )
}

function renderBilling(root, billing) {
  const summary = node('section', 'account-management-summary')
  append(
    summary,
    metric('Account kind', billing.account_kind),
    metric('Plan', billing.plan),
    metric('Subscription', billing.status),
  )
  const actions = node('div', 'account-management-actions')
  if (billing.can_upgrade) {
    actions.append(button('Activate paid workspace', () => changeBilling(true)))
  }
  if (billing.can_cancel) {
    actions.append(
      button('Cancel paid subscription', () => changeBilling(false), true),
    )
  }
  if (billing.managed_by_organization) {
    actions.append(
      node(
        'p',
        'account-management-note',
        'This workspace is managed by the active organization.',
      ),
    )
  }
  root.append(summary, actions)
}

async function changeBilling(active) {
  setStatus(active ? 'Activating paid workspace…' : 'Cancelling subscription…')
  try {
    const result = await request('/miniapp/account/billing', {
      method: 'POST',
      body: JSON.stringify({ action: active ? 'activate' : 'cancel' }),
    })
    globalThis.__moontownAccountContextJson = JSON.stringify(result.account)
    setStatus('Billing change saved. Reloading the account experience…', 'success')
    globalThis.location.reload()
  } catch (error) {
    setStatus(error.message, 'error')
  }
}

function memberRow(member, canManage, refresh) {
  const row = node('div', 'account-management-row')
  const identity = append(
    node('div', 'account-management-row-main'),
    node('strong', '', member.display_name),
    node('span', '', member.user_id),
  )
  const role = node('span', 'account-management-badge', member.roles.join(', '))
  row.append(identity, role)
  if (canManage && member.active) {
    row.append(
      button(
        'Remove',
        async () => {
          setStatus(`Removing ${member.display_name}…`)
          try {
            await request('/miniapp/account/enterprise', {
              method: 'POST',
              body: JSON.stringify({ action: 'remove-member', user_id: member.user_id }),
            })
            setStatus('Member access removed.', 'success')
            await refresh()
          } catch (error) {
            setStatus(error.message, 'error')
          }
        },
        true,
      ),
    )
  }
  return row
}

function enterpriseMemberForm(refresh) {
  const form = node('form', 'account-management-form')
  const userId = field('User ID', 'user_id', {
    placeholder: 'ada-lovelace',
  })
  const displayName = field('Display name', 'display_name', {
    placeholder: 'Ada Lovelace',
  })
  const role = field('Organization role', 'organization_role', {
    choices: [
      ['member', 'Member'],
      ['admin', 'Organization administrator'],
    ],
  })
  const submit = node('button', 'account-management-button', 'Invite or update member')
  submit.type = 'submit'
  form.append(userId.wrapper, displayName.wrapper, role.wrapper, submit)
  form.addEventListener('submit', async event => {
    event.preventDefault()
    if (!form.reportValidity()) return
    setStatus('Saving organization membership…')
    try {
      const result = await request('/miniapp/account/enterprise', {
        method: 'POST',
        body: JSON.stringify({
          action: 'upsert-member',
          user_id: userId.control.value.trim(),
          display_name: displayName.control.value.trim(),
          organization_admin: role.control.value === 'admin',
        }),
      })
      const invite = resultPanel(
        'One-time member session',
        'Copy this token now and deliver it through an approved secure channel.',
      )
      const token = node('code', 'account-management-token', result.session_token)
      invite.append(token)
      form.reset()
      await refresh()
      document.getElementById('account-management-root')?.append(invite)
      setStatus('Membership saved and a one-time session issued.', 'success')
    } catch (error) {
      setStatus(error.message, 'error')
    }
  })
  return form
}

function renderEnterprise(root, enterprise, surface, refresh) {
  root.append(
    append(
      node('section', 'account-management-summary'),
      metric('Organization', enterprise.tenant_name),
      metric('Active members', enterprise.usage.active_members),
      metric('Active sessions', enterprise.usage.active_sessions),
    ),
  )
  if (surface === 'compliance') {
    const controls = node('section', 'account-management-list')
    const labels = {
      session_tokens_stored_as_digests: 'Session tokens stored only as digests',
      audit_log_enabled: 'Account audit log enabled',
      impersonation_disabled: 'Administrator impersonation disabled',
    }
    for (const [key, label] of Object.entries(labels)) {
      controls.append(
        append(
          node('div', 'account-management-row'),
          node('strong', '', label),
          node(
            'span',
            `account-management-badge ${enterprise.compliance[key] ? 'is-good' : 'is-bad'}`,
            enterprise.compliance[key] ? 'Verified' : 'Not verified',
          ),
        ),
      )
    }
    root.append(controls)
    return
  }
  if (surface === 'members') {
    if (enterprise.can_manage_members) root.append(enterpriseMemberForm(refresh))
    const list = node('section', 'account-management-list')
    list.append(node('h2', '', 'Current members'))
    if (!enterprise.members.length) {
      list.append(node('p', 'account-management-empty', 'No active members.'))
    }
    for (const member of enterprise.members) {
      list.append(memberRow(member, enterprise.can_manage_members, refresh))
    }
    root.append(list)
  }
}

function accountCreateForm(refresh) {
  const form = node('form', 'account-management-form')
  const userId = field('User ID', 'user_id', { placeholder: 'new-user' })
  const displayName = field('Display name', 'display_name', {
    placeholder: 'New user',
  })
  const kind = field('Account kind', 'account_kind', {
    choices: [
      ['visitor', 'Visitor'],
      ['paid-user', 'Paid user'],
      ['enterprise', 'Enterprise'],
      ['admin', 'Administrator'],
    ],
  })
  const tenantId = field('Tenant ID (enterprise only)', 'tenant_id', {
    placeholder: 'energy-labs',
    required: false,
  })
  const tenantName = field('Tenant name (enterprise only)', 'tenant_name', {
    placeholder: 'Energy Labs',
    required: false,
  })
  const submit = node('button', 'account-management-button', 'Create account')
  submit.type = 'submit'
  form.append(
    userId.wrapper,
    displayName.wrapper,
    kind.wrapper,
    tenantId.wrapper,
    tenantName.wrapper,
    submit,
  )
  const validateTenant = () => {
    const required = kind.control.value === 'enterprise'
    tenantId.control.required = required
    tenantName.control.required = required
  }
  kind.control.addEventListener('change', validateTenant)
  validateTenant()
  form.addEventListener('submit', async event => {
    event.preventDefault()
    if (!form.reportValidity()) return
    setStatus('Creating account…')
    try {
      const result = await request('/miniapp/account/admin', {
        method: 'POST',
        body: JSON.stringify({
          action: 'create-account',
          user_id: userId.control.value.trim(),
          display_name: displayName.control.value.trim(),
          account_kind: kind.control.value,
          tenant_id: tenantId.control.value.trim(),
          tenant_name: tenantName.control.value.trim(),
        }),
      })
      const invite = resultPanel(
        'One-time account session',
        'Copy this token now. MoonTown stores only its digest.',
      )
      invite.append(node('code', 'account-management-token', result.session_token))
      form.reset()
      validateTenant()
      await refresh()
      document.getElementById('account-management-root')?.append(invite)
      setStatus('Account created and a one-time session issued.', 'success')
    } catch (error) {
      setStatus(error.message, 'error')
    }
  })
  return form
}

function userRow(user, refresh) {
  const row = node('div', 'account-management-row')
  row.append(
    append(
      node('div', 'account-management-row-main'),
      node('strong', '', user.display_name),
      node('span', '', user.user_id),
    ),
    node('span', 'account-management-badge', user.account_kind),
    node(
      'span',
      `account-management-badge ${user.active ? 'is-good' : 'is-bad'}`,
      user.active ? 'Active' : 'Inactive',
    ),
    button(
      user.active ? 'Deactivate' : 'Activate',
      async () => {
        setStatus(`${user.active ? 'Deactivating' : 'Activating'} ${user.display_name}…`)
        try {
          await request('/miniapp/account/admin', {
            method: 'POST',
            body: JSON.stringify({
              action: 'set-active',
              user_id: user.user_id,
              active: !user.active,
            }),
          })
          setStatus('Account lifecycle state saved.', 'success')
          await refresh()
        } catch (error) {
          setStatus(error.message, 'error')
        }
      },
      true,
    ),
  )
  return row
}

function renderAdmin(root, admin, surface, refresh) {
  root.append(
    append(
      node('section', 'account-management-summary'),
      metric('Accounts', admin.users.length),
      metric('Organizations', admin.tenant_ids.length),
      metric('Active sessions', admin.active_sessions),
    ),
  )
  if (surface === 'users' || surface === 'overview') {
    root.append(accountCreateForm(refresh))
    const list = node('section', 'account-management-list')
    list.append(node('h2', '', 'Platform accounts'))
    for (const user of admin.users) list.append(userRow(user, refresh))
    root.append(list)
  } else if (surface === 'tenants') {
    const list = node('section', 'account-management-list')
    list.append(node('h2', '', 'Organizations'))
    if (!admin.tenant_ids.length) {
      list.append(node('p', 'account-management-empty', 'No enterprise tenants.'))
    }
    for (const tenantId of admin.tenant_ids) {
      list.append(
        append(
          node('div', 'account-management-row'),
          node('strong', '', tenantId),
          node('span', 'account-management-badge', 'Enterprise'),
        ),
      )
    }
    root.append(list)
  } else if (surface === 'audit') {
    const list = node('section', 'account-management-list')
    list.append(node('h2', '', 'Recent account events'))
    if (!admin.audit_events.length) {
      list.append(node('p', 'account-management-empty', 'No account events yet.'))
    }
    for (const event of admin.audit_events) {
      list.append(
        append(
          node('div', 'account-management-row'),
          append(
            node('div', 'account-management-row-main'),
            node('strong', '', event.action),
            node('span', '', `${event.actor_id} → ${event.target_id}`),
          ),
          node('span', 'account-management-badge', event.detail),
        ),
      )
    }
    root.append(list)
  }
}

function requestedSurface(context) {
  const params = new URLSearchParams(globalThis.location?.search || '')
  if (context.account_kind === 'admin') return params.get('admin') || 'overview'
  return params.get('panel') || ''
}

async function hydrateManagement() {
  const root = document.getElementById('account-management-root')
  if (!root) return
  const context = accountContext()
  const surface = requestedSurface(context)
  const demo = new URLSearchParams(globalThis.location?.search || '').get('demo') === '1'
  if (demo) {
    root.append(
      resultPanel(
        'Preview only',
        'Demo projections never enable management actions. Start the account API and sign in with a real session to use this surface.',
      ),
    )
    setStatus('Management is disabled in preview mode.', 'error')
    return
  }
  root.querySelectorAll(':scope > :not(#account-management-status)').forEach(item => item.remove())
  setStatus('Loading authoritative account data…')
  try {
    if (context.account_kind === 'visitor' || context.account_kind === 'paid-user') {
      const result = await request('/miniapp/account/billing')
      renderBilling(root, result.billing)
    } else if (context.account_kind === 'enterprise') {
      const refresh = hydrateManagement
      const result = await request('/miniapp/account/enterprise')
      renderEnterprise(root, result.enterprise, surface, refresh)
    } else if (context.account_kind === 'admin') {
      const refresh = hydrateManagement
      const result = await request('/miniapp/account/admin')
      renderAdmin(root, result.admin, surface, refresh)
    } else {
      throw new Error('The server returned an unsupported account kind.')
    }
    setStatus('Account data is current.', 'success')
  } catch (error) {
    root.append(
      append(
        resultPanel('Unable to load account management', error.message),
        button('Try again', hydrateManagement),
      ),
    )
    setStatus(error.message, 'error')
  }
}

function installTenantControls() {
  const host = document.getElementById('account-tenant-switcher')
  if (!host) return
  const context = accountContext()
  const choices = context.tenant_choices || []
  if (choices.length) {
    const label = node('label', 'account-tenant-label')
    const select = document.createElement('select')
    select.className = 'account-tenant-select'
    select.setAttribute('aria-label', 'Active account workspace')
    const personal = document.createElement('option')
    personal.value = ''
    personal.textContent = 'Personal workspace'
    select.append(personal)
    for (const tenant of choices) {
      const option = document.createElement('option')
      option.value = tenant.tenant_id
      option.textContent = tenant.tenant_name
      option.selected = tenant.tenant_id === context.active_tenant_id
      select.append(option)
    }
    select.addEventListener('change', async () => {
      select.disabled = true
      try {
        await request('/miniapp/account/tenant', {
          method: 'POST',
          body: JSON.stringify({ tenant_id: select.value || null }),
        })
        globalThis.location.assign('./index.html')
      } catch (error) {
        select.disabled = false
        globalThis.alert?.(error.message)
      }
    })
    label.append(select)
    host.append(label)
  }
  if (accountToken()) {
    const logout = button(
      'Sign out',
      async () => {
        logout.disabled = true
        try {
          await request('/miniapp/auth/logout', { method: 'POST', body: '{}' })
        } finally {
          try {
            globalThis.localStorage?.removeItem(ACCOUNT_SESSION_KEY)
          } catch {
            // Storage can be unavailable in privacy-restricted contexts.
          }
          globalThis.location.assign('./index.html')
        }
      },
      true,
    )
    logout.classList.add('account-logout-button')
    host.append(logout)
  }
}

export function installAccountManagement() {
  installTenantControls()
  void hydrateManagement()
}

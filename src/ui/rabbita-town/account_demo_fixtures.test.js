import assert from 'node:assert/strict'
import test from 'node:test'
import { ACCOUNT_DEMO_FIXTURES } from './account_demo_fixtures.js'

const BASE = ['town.public.explore', 'town.public.discover']
const PAID = [
  ...BASE,
  'agent.personal.use',
  'workspace.personal.manage',
  'marketplace.action.use',
  'billing.personal.manage',
]

test('account previews preserve canonical identity invariants', () => {
  const { visitor, paid, enterprise, admin } = ACCOUNT_DEMO_FIXTURES
  assert.deepEqual(visitor.entitlements, BASE)
  assert.deepEqual(paid.entitlements, PAID)
  assert.equal(visitor.visitor, true)
  for (const account of [paid, enterprise, admin]) {
    assert.equal(account.visitor, false)
  }
  assert.equal(enterprise.tenant_choices.length, 1)
  assert.equal(
    enterprise.tenant_choices[0].tenant_id,
    enterprise.active_tenant_id,
  )
  assert.equal(admin.plan, 'paid')
  assert.equal(admin.active_tenant_id, null)
  assert.deepEqual(admin.tenant_choices, [])
})

test('enterprise and admin previews include policy-derived entitlements', () => {
  const { enterprise, admin } = ACCOUNT_DEMO_FIXTURES
  for (const entitlement of PAID) {
    assert.ok(enterprise.entitlements.includes(entitlement))
    assert.ok(admin.entitlements.includes(entitlement))
  }
  for (const entitlement of [
    'workspace.team.use',
    'agent.shared.use',
    'organization.members.manage',
  ]) {
    assert.ok(enterprise.entitlements.includes(entitlement))
  }
  for (const entitlement of [
    'platform.admin.access',
    'platform.users.manage',
    'platform.health.manage',
  ]) {
    assert.ok(admin.entitlements.includes(entitlement))
  }
})

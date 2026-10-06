///|
fn grant_admission(
  index : StoreIndex,
  actor : TransferActor,
  draft : GrantDraft,
  now_ms : UInt64,
) -> (StoredPackage, PortablePackageGrant?) raise {
  let (p, _) = authorized(
    index,
    actor,
    draft.package_id,
    draft.binding_digest,
    now_ms,
  )
  require_owner(actor, p)
  guard p.status == "available" else {
    raise TransferError(409, "package_not_available")
  }
  guard valid_key(draft.grant_id) && valid_key(draft.grantee_principal_id) else {
    raise TransferError(422, "invalid_package_grant")
  }
  if index.grants.iter().find_first(g => g.grant_id == draft.grant_id)
    is Some(old) {
    guard old.package_id == draft.package_id &&
      old.binding_digest == draft.binding_digest &&
      old.grantee_principal_id == draft.grantee_principal_id &&
      old.expires_at_ms == draft.expires_at_ms &&
      old.grantor_principal_id == actor.principal_id &&
      old.tenant_id == actor.tenant_id &&
      old.revoked_at_ms is None else {
      raise TransferError(409, "package_grant_conflict")
    }
    return (p, Some(old))
  }
  guard draft.expires_at_ms > now_ms else {
    raise TransferError(422, "invalid_package_grant")
  }
  (p, None)
}

///| Recipient existence and current same-tenant membership are checked by the

///|
/// authoritative account boundary before this trusted application call.
pub async fn PortableStore::grant(
  self : PortableStore,
  actor : TransferActor,
  draft : GrantDraft,
  now_ms : UInt64,
) -> PortablePackageGrant {
  let (p, old) = self.with_index(index => {
    grant_admission(index, actor, draft, now_ms)
  })
  if old is Some(grant) {
    return grant
  }
  // Hash outside the short index transaction, then recheck its admission.
  let file = self.open_verified(p) catch {
    _ => raise TransferError(503, "package_object_unavailable")
  }
  defer file.close()
  self.with_index(index => {
    let (p, old) = grant_admission(index, actor, draft, now_ms)
    if old is Some(grant) {
      return grant
    }
    let grant : PortablePackageGrant = {
      grant_id: draft.grant_id,
      package_id: p.package_id,
      binding_digest: p.binding_digest,
      package_sha256: p.package_sha256,
      grantor_principal_id: actor.principal_id,
      grantee_principal_id: draft.grantee_principal_id,
      tenant_id: actor.tenant_id,
      permission: "download_package",
      created_at_ms: now_ms,
      expires_at_ms: draft.expires_at_ms,
      revoked_at_ms: None,
      version: 1,
    }
    let grants = index.grants.copy()
    grants.push(grant)
    self.save_index({ ..index, grants, revision: index.revision + 1UL, })
    grant
  })
}

///|
pub async fn PortableStore::revoke(
  self : PortableStore,
  actor : TransferActor,
  grant_id : String,
  now_ms : UInt64,
) -> PortablePackageGrant {
  self.with_index(index => {
    guard index.grants.iter().find_first(g => g.grant_id == grant_id)
      is Some(old) else {
      raise TransferError(403, "package_access_denied")
    }
    guard find_package(index, old.package_id) is Some(p) else {
      raise TransferError(503, "package_state_unavailable")
    }
    require_owner(actor, p)
    if old.revoked_at_ms is Some(_) {
      return old
    }
    guard now_ms >= old.created_at_ms else {
      raise TransferError(422, "invalid_package_time")
    }
    let revoked = {
      ..old,
      revoked_at_ms: Some(now_ms),
      version: old.version + 1,
    }
    self.save_index({
      ..index,
      grants: index.grants.map(g => {
        if g.grant_id == grant_id {
          revoked
        } else {
          g
        }
      }),
      revision: index.revision + 1UL,
    })
    revoked
  })
}

///|
pub async fn PortableStore::withdraw(
  self : PortableStore,
  actor : TransferActor,
  id : String,
  digest : String,
  now_ms : UInt64,
) -> PackageView {
  self.with_index(index => {
    let (p, _) = authorized(index, actor, id, digest, now_ms)
    require_owner(actor, p)
    let tombstone = {
      ..p,
      status: "withdrawn",
      cleanup_pending: true,
      revision: index.revision + 1UL,
    }
    let revoked = index.grants.map(g => {
      if g.package_id == id && g.revoked_at_ms is None {
        {
          ..g,
          revoked_at_ms: Some(
            if now_ms < g.created_at_ms {
              g.created_at_ms
            } else {
              now_ms
            },
          ),
          version: g.version + 1,
        }
      } else {
        g
      }
    })
    let denied = {
      ..replace_package(index, tombstone),
      grants: revoked,
      reservations: index.reservations.map(r => {
        if r.package_id == id {
          { ..r, cleanup_pending: true, }
        } else {
          r
        }
      }),
    }
    // Durable denial precedes unlink. An unlink failure is visible and charged.
    self.save_index(denied)
    let removed = self.remove_owned(self.object_path(id))
    let cleaned = {
      ..tombstone,
      cleanup_pending: !removed,
      object_retained: !removed,
      revision: denied.revision + 1UL,
    }
    let next = replace_package(denied, cleaned)
    self.save_index(next)
    view_for(next, cleaned, "owner")
  })
}

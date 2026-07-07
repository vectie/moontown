///|
pub fn miniapp_audit_frontend_bundle(
  bundle_json : String,
  forbidden_keys? : Array[String] = [
    "wechat_app_secret", "appSecret", "private_key", "token_secret", "database_password",
  ],
) -> MiniappFrontendBundleAudit {
  let exposed : Array[String] = []
  for key in forbidden_keys {
    if bundle_json.contains(key) {
      exposed.push(key)
    }
  }
  {
    ok: exposed.length() == 0,
    checked_keys: forbidden_keys,
    exposed_keys: exposed,
    warnings: if exposed.length() == 0 {
      []
    } else {
      ["frontend-secret-exposure"]
    },
  }
}

///|
pub fn miniapp_audit_snapshot_scope(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
) -> MiniappPermissionScopeAudit {
  let mut private_leak_count = 0
  let mut archived_leak_count = 0
  let mut unreviewed_public_count = 0
  let issues : Array[String] = []
  for building in snapshot.buildings {
    if building.visibility == @miniapp_contracts.Archived {
      archived_leak_count += 1
      issues.push("archived-building-visible:\{building.id}")
    } else if !@miniapp_projection.miniapp_can_view_building(viewer, building) &&
      building.visibility != @miniapp_contracts.Published {
      private_leak_count += 1
      issues.push("private-building-visible:\{building.id}")
    }
    if building.visibility == @miniapp_contracts.Published &&
      building.publication.published_at_ms is None {
      unreviewed_public_count += 1
      issues.push("published-building-without-review:\{building.id}")
    }
  }
  {
    ok: private_leak_count == 0 &&
    archived_leak_count == 0 &&
    unreviewed_public_count == 0,
    private_leak_count,
    archived_leak_count,
    unreviewed_public_count,
    issues,
  }
}

///|
pub fn miniapp_projection_safe_for_phone(
  source : @miniapp_contracts.MiniappTownSnapshot,
  projected : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
) -> MiniappPermissionScopeAudit {
  ignore(source)
  miniapp_audit_snapshot_scope(projected, viewer)
}

///|
test "deployment readiness accepts configured production backend" {
  let config = {
    ..miniapp_default_deployment_config(),
    app_id: "wx1234567890abcdef",
  }
  let readiness = miniapp_deployment_readiness(config)
  assert_true(readiness.ok)
  assert_eq(readiness.blockers.length(), 0)
  assert_true(readiness.summary.contains("wechat-cloud"))
}

///|
test "deployment readiness blocks secrets http missing backups and disabled abuse controls" {
  let bad = {
    ..miniapp_default_deployment_config(),
    app_id: "",
    domains: {
      api_domain: "http://api.example.com",
      asset_domain: "https://assets.example.com",
      approved_domains: ["https://assets.example.com"],
      require_https: true,
    },
    secrets: {
      wechat_app_secret_backend_only: false,
      frontend_secret_keys: ["wechat_app_secret"],
      token_rotation_days: 0,
      session_ttl_minutes: 0,
    },
    storage: {
      backend: ExternalDatabase,
      database_encrypted: false,
      object_storage_enabled: false,
      backup_enabled: false,
      backup_retention_days: 1,
    },
    abuse_controls: {
      login_rate_limit_per_minute: 0,
      query_rate_limit_per_minute: 0,
      publish_rate_limit_per_day: 0,
      moderation_required: false,
      audit_log_enabled: false,
    },
    observability: {
      monitoring_enabled: false,
      error_reporting_enabled: false,
      healthcheck_path: "healthz",
      alert_contact: "",
    },
  }
  let readiness = miniapp_deployment_readiness(bad)
  assert_true(!readiness.ok)
  assert_true(readiness.blockers.contains("wechat-app-id-not-configured"))
  assert_true(readiness.blockers.contains("api-domain-not-https"))
  assert_true(readiness.blockers.contains("api-domain-not-approved"))
  assert_true(readiness.blockers.contains("wechat-app-secret-not-backend-only"))
  assert_true(
    readiness.blockers.contains("frontend-bundle-contains-secret-keys"),
  )
  assert_true(readiness.blockers.contains("database-encryption-disabled"))
  assert_true(readiness.blockers.contains("backups-disabled"))
  assert_true(readiness.blockers.contains("audit-log-disabled"))
  assert_true(readiness.blockers.contains("monitoring-disabled"))
  assert_true(readiness.blockers.contains("healthcheck-path-invalid"))
}

///|
test "frontend bundle audit catches secret material before miniapp release" {
  let clean = miniapp_audit_frontend_bundle(
    "{\"backendBaseUrl\":\"https://api.example.com\"}",
  )
  assert_true(clean.ok)
  assert_eq(clean.exposed_keys.length(), 0)

  let exposed = miniapp_audit_frontend_bundle(
    "{\"wechat_app_secret\":\"should-not-ship\",\"page\":\"index\"}",
  )
  assert_true(!exposed.ok)
  assert_true(exposed.exposed_keys.contains("wechat_app_secret"))
}

///|
test "phone projection audit catches private archived and unreviewed published leakage" {
  let viewer = @miniapp_projection.miniapp_viewer_context(
    user_id="user-b",
    workspace_ids=["workspace-user-b"],
    roles=[@miniapp_contracts.OwnerRole],
  )
  let base = @miniapp_contracts.miniapp_fixture_snapshot()
  let private_building = {
    ..@miniapp_contracts.miniapp_fixture_building(
      id="private-leak",
      owner_id="user-a",
      owner_kind=@miniapp_contracts.UserOwner,
      visibility=@miniapp_contracts.PrivateDraft,
      scope=@miniapp_contracts.PersonalScope,
    ),
    primary_book_id: "book-private-leak",
  }
  let archived_building = {
    ..@miniapp_contracts.miniapp_fixture_building(
      id="archived-leak",
      visibility=@miniapp_contracts.Archived,
      scope=@miniapp_contracts.TownPublicScope,
    ),
    primary_book_id: "book-archived-leak",
  }
  let unreviewed_public = {
    ..@miniapp_contracts.miniapp_fixture_building(
      id="unreviewed-public",
      visibility=@miniapp_contracts.Published,
      scope=@miniapp_contracts.TownPublicScope,
    ),
    publication: {
      state: @miniapp_contracts.Published,
      submitted_at_ms: Some(100UL),
      published_at_ms: None,
      review_summary: "missing approval timestamp",
    },
    primary_book_id: "book-unreviewed-public",
  }
  let reviewed_base = {
    ..base.buildings[0],
    publication: {
      ..base.buildings[0].publication,
      published_at_ms: Some(100UL),
    },
  }
  let unsafe_snapshot = {
    ..base,
    buildings: [
      reviewed_base, private_building, archived_building, unreviewed_public,
    ],
  }
  let audit = miniapp_audit_snapshot_scope(unsafe_snapshot, viewer)
  assert_true(!audit.ok)
  assert_eq(audit.private_leak_count, 1)
  assert_eq(audit.archived_leak_count, 1)
  assert_eq(audit.unreviewed_public_count, 1)
  assert_true(audit.issues.contains("private-building-visible:private-leak"))
}

///|
test "projected phone snapshot passes permission scope audit" {
  let viewer = @miniapp_projection.miniapp_viewer_context(
    user_id="user-b",
    workspace_ids=["workspace-user-b"],
    roles=[@miniapp_contracts.OwnerRole],
  )
  let source = @miniapp_contracts.miniapp_fixture_snapshot()
  let projected = @miniapp_projection.miniapp_filter_snapshot_for_viewer(
    source, viewer,
  )
  let audit = miniapp_projection_safe_for_phone(source, projected, viewer)
  assert_true(audit.ok)
  assert_eq(audit.issues.length(), 0)
}

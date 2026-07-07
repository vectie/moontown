///|
pub fn miniapp_deployment_readiness(
  config : MiniappDeploymentConfig,
) -> MiniappDeploymentReadiness {
  let blockers : Array[String] = []
  let warnings : Array[String] = []
  miniapp_check_login_config(blockers, warnings, config)
  miniapp_check_domain_config(blockers, warnings, config.domains)
  miniapp_check_secret_config(blockers, warnings, config.secrets)
  miniapp_check_storage_config(blockers, warnings, config.storage)
  miniapp_check_abuse_config(blockers, warnings, config.abuse_controls)
  miniapp_check_observability_config(blockers, warnings, config.observability)
  {
    ok: blockers.length() == 0,
    target: config.target,
    blockers,
    warnings,
    summary: "miniapp deployment readiness: blockers=\{blockers.length()} warnings=\{warnings.length()} target=\{miniapp_deployment_target_id(config.target)}",
  }
}

///|
fn miniapp_check_login_config(
  blockers : Array[String],
  warnings : Array[String],
  config : MiniappDeploymentConfig,
) -> Unit {
  if config.app_id.trim().to_owned() == "" || config.app_id == "wx-placeholder" {
    blockers.push("wechat-app-id-not-configured")
  }
  if config.secrets.session_ttl_minutes > 24 * 60 {
    warnings.push("session-ttl-longer-than-one-day")
  }
}

///|
fn miniapp_check_domain_config(
  blockers : Array[String],
  warnings : Array[String],
  domains : MiniappDomainConfig,
) -> Unit {
  if domains.require_https {
    if !domains.api_domain.has_prefix("https://") {
      blockers.push("api-domain-not-https")
    }
    if !domains.asset_domain.has_prefix("https://") {
      blockers.push("asset-domain-not-https")
    }
  }
  if !domains.approved_domains.contains(domains.api_domain) {
    blockers.push("api-domain-not-approved")
  }
  if !domains.approved_domains.contains(domains.asset_domain) {
    blockers.push("asset-domain-not-approved")
  }
  if domains.approved_domains.length() == 0 {
    blockers.push("no-approved-network-domains")
  }
  if domains.api_domain == domains.asset_domain {
    warnings.push("api-and-asset-domain-share-origin")
  }
}

///|
fn miniapp_check_secret_config(
  blockers : Array[String],
  warnings : Array[String],
  secrets : MiniappSecretConfig,
) -> Unit {
  if !secrets.wechat_app_secret_backend_only {
    blockers.push("wechat-app-secret-not-backend-only")
  }
  if secrets.frontend_secret_keys.length() > 0 {
    blockers.push("frontend-bundle-contains-secret-keys")
  }
  if secrets.token_rotation_days <= 0 {
    blockers.push("token-rotation-disabled")
  } else if secrets.token_rotation_days > 90 {
    warnings.push("token-rotation-longer-than-90-days")
  }
  if secrets.session_ttl_minutes <= 0 {
    blockers.push("session-ttl-disabled")
  }
}

///|
fn miniapp_check_storage_config(
  blockers : Array[String],
  warnings : Array[String],
  storage : MiniappStorageConfig,
) -> Unit {
  if !storage.database_encrypted {
    blockers.push("database-encryption-disabled")
  }
  if !storage.object_storage_enabled {
    blockers.push("object-storage-disabled")
  }
  if !storage.backup_enabled {
    blockers.push("backups-disabled")
  }
  if storage.backup_retention_days < 7 {
    blockers.push("backup-retention-too-short")
  } else if storage.backup_retention_days < 30 {
    warnings.push("backup-retention-under-30-days")
  }
}

///|
fn miniapp_check_abuse_config(
  blockers : Array[String],
  warnings : Array[String],
  abuse : MiniappAbuseControlConfig,
) -> Unit {
  if abuse.login_rate_limit_per_minute <= 0 {
    blockers.push("login-rate-limit-disabled")
  }
  if abuse.query_rate_limit_per_minute <= 0 {
    blockers.push("query-rate-limit-disabled")
  }
  if abuse.publish_rate_limit_per_day <= 0 {
    blockers.push("publish-rate-limit-disabled")
  }
  if !abuse.moderation_required {
    blockers.push("public-moderation-disabled")
  }
  if !abuse.audit_log_enabled {
    blockers.push("audit-log-disabled")
  }
  if abuse.query_rate_limit_per_minute > 600 {
    warnings.push("query-rate-limit-high")
  }
}

///|
fn miniapp_check_observability_config(
  blockers : Array[String],
  warnings : Array[String],
  observability : MiniappObservabilityConfig,
) -> Unit {
  if !observability.monitoring_enabled {
    blockers.push("monitoring-disabled")
  }
  if !observability.error_reporting_enabled {
    blockers.push("error-reporting-disabled")
  }
  if !observability.healthcheck_path.has_prefix("/") {
    blockers.push("healthcheck-path-invalid")
  }
  if observability.alert_contact.trim().to_owned() == "" {
    warnings.push("alert-contact-missing")
  }
}

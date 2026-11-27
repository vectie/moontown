///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) enum MiniappDeploymentTarget {
  WechatCloud
  ExternalHttps
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) enum MiniappStorageBackend {
  ManagedDatabase
  WechatCloudDatabase
  ExternalDatabase
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct MiniappDomainConfig {
  api_domain : String
  asset_domain : String
  approved_domains : Array[String]
  require_https : Bool
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct MiniappSecretConfig {
  wechat_app_secret_backend_only : Bool
  frontend_secret_keys : Array[String]
  token_rotation_days : Int32
  session_ttl_minutes : Int32
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct MiniappStorageConfig {
  backend : MiniappStorageBackend
  database_encrypted : Bool
  object_storage_enabled : Bool
  backup_enabled : Bool
  backup_retention_days : Int32
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct MiniappAbuseControlConfig {
  login_rate_limit_per_minute : Int32
  query_rate_limit_per_minute : Int32
  publish_rate_limit_per_day : Int32
  moderation_required : Bool
  audit_log_enabled : Bool
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct MiniappObservabilityConfig {
  monitoring_enabled : Bool
  error_reporting_enabled : Bool
  healthcheck_path : String
  alert_contact : String
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct MiniappDeploymentConfig {
  target : MiniappDeploymentTarget
  app_id : String
  domains : MiniappDomainConfig
  secrets : MiniappSecretConfig
  storage : MiniappStorageConfig
  abuse_controls : MiniappAbuseControlConfig
  observability : MiniappObservabilityConfig
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct MiniappDeploymentReadiness {
  ok : Bool
  target : MiniappDeploymentTarget
  blockers : Array[String]
  warnings : Array[String]
  summary : String
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct MiniappFrontendBundleAudit {
  ok : Bool
  checked_keys : Array[String]
  exposed_keys : Array[String]
  warnings : Array[String]
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct MiniappPermissionScopeAudit {
  ok : Bool
  private_leak_count : Int32
  archived_leak_count : Int32
  unreviewed_public_count : Int32
  issues : Array[String]
}

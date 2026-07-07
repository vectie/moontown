///|
pub fn miniapp_default_deployment_config() -> MiniappDeploymentConfig {
  {
    target: WechatCloud,
    app_id: "wx-placeholder",
    domains: {
      api_domain: "https://api.example.com",
      asset_domain: "https://assets.example.com",
      approved_domains: [
        "https://api.example.com", "https://assets.example.com",
      ],
      require_https: true,
    },
    secrets: {
      wechat_app_secret_backend_only: true,
      frontend_secret_keys: [],
      token_rotation_days: 30,
      session_ttl_minutes: 120,
    },
    storage: {
      backend: WechatCloudDatabase,
      database_encrypted: true,
      object_storage_enabled: true,
      backup_enabled: true,
      backup_retention_days: 30,
    },
    abuse_controls: {
      login_rate_limit_per_minute: 20,
      query_rate_limit_per_minute: 120,
      publish_rate_limit_per_day: 20,
      moderation_required: true,
      audit_log_enabled: true,
    },
    observability: {
      monitoring_enabled: true,
      error_reporting_enabled: true,
      healthcheck_path: "/healthz",
      alert_contact: "ops@example.com",
    },
  }
}

///|
pub fn miniapp_external_https_config(
  api_domain~ : String,
  asset_domain~ : String,
  app_id? : String = "wx-placeholder",
) -> MiniappDeploymentConfig {
  {
    ..miniapp_default_deployment_config(),
    target: ExternalHttps,
    app_id,
    domains: {
      api_domain,
      asset_domain,
      approved_domains: [api_domain, asset_domain],
      require_https: true,
    },
    storage: {
      ..miniapp_default_deployment_config().storage,
      backend: ExternalDatabase,
    },
  }
}

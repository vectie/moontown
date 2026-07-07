///|
pub fn miniapp_deployment_target_id(target : MiniappDeploymentTarget) -> String {
  match target {
    WechatCloud => "wechat-cloud"
    ExternalHttps => "external-https"
  }
}

///|
pub fn miniapp_storage_backend_id(backend : MiniappStorageBackend) -> String {
  match backend {
    ManagedDatabase => "managed-database"
    WechatCloudDatabase => "wechat-cloud-database"
    ExternalDatabase => "external-database"
  }
}

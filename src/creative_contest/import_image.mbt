///|
fn external_image(job : Generation) -> Bool {
  job.provider_id.has_prefix("external:")
}

///|
/// Authenticated, bounded image import. Only reconstructed PNG pixels persist.
pub async fn import_image(
  payload : Json,
  now : UInt64,
  actor : String,
  operator : Bool,
  path : String,
  config_path : String,
) -> Json {
  guard !actor.is_empty() && !actor.has_prefix("guest:") else { raise Denied }
  let config = load_config(config_path)
  let filename = text(payload, "filename", 160)
  let mime = text(payload, "content_type", 40)
  let name = filename.to_lower()
  guard !filename.contains("/") &&
    !filename.contains("\\") &&
    !filename.contains(":") &&
    filename.all(c => c.is_printable()) &&
    (
      (mime == "image/png" && name.has_suffix(".png")) ||
      (
        mime == "image/jpeg" &&
        (name.has_suffix(".jpg") || name.has_suffix(".jpeg"))
      ) ||
      (mime == "image/webp" && name.has_suffix(".webp"))
    ) else {
    raise Invalid("仅支持 PNG、JPG 和静态 WebP 图片。")
  }
  let intent = text(payload, "intent", 128)
  let encoded = text(payload, "data_base64", 11184812)
  let bytes = @base64.decode(encoded) catch {
    _ => raise Invalid("图片数据不完整，请重新选择。")
  }
  guard bytes.length() <= 8388608 else {
    raise Invalid("图片不能超过 8 MB。")
  }
  let file = lock(path)
  defer file.close()
  defer file.unlock()
  let state = read(path, config)
  guard state.voting_rosters.is_empty() &&
    now >= config.opens_ms &&
    now < config.brief.deadline_ms else {
    raise Conflict("本期投稿已截止。")
  }
  let id = hash(config.brief.id + ":" + actor + ":upload:" + intent)
  let digest = "external:" + @crypto.bytes_to_hex_string(@crypto.sha256(bytes))
  if state.generations.iter().find_first(job => job.id == id) is Some(job) {
    guard job.actor == actor && job.provider_id == digest else {
      raise Conflict("上传请求已保存，请刷新查看。")
    }
    return snapshot(
      state,
      config,
      now,
      Some(actor),
      event_manager(config, Some(actor), operator),
    )
  }
  guard state.generations
    .filter(job => external_image(job) && job.actor == actor)
    .length() <
    20 &&
    state.generations.filter(external_image).length() < config.event_quota else {
    raise Conflict(
      "本期上传次数已用完，已保存作品仍可投稿。",
    )
  }
  guard @image_preview.sanitize_upload(bytes, mime) is Some(clean) else {
    raise Invalid(
      "图片未通过安全检查：请上传完整的静态图片，最长边不超过 2048 像素。",
    )
  }
  let directory = path + ".images"
  if !@fs.exists(directory) {
    @fs.mkdir(directory, permission=0o700)
  }
  guard @fs.kind(directory, follow_symlink=false) is Directory else {
    raise Unavailable
  }
  let target = preview_path(path, id, Original)
  if @fs.exists(target + ".next") {
    guard @fs.kind(target + ".next", follow_symlink=false) is Regular else {
      raise Unavailable
    }
  }
  if @fs.exists(target) {
    guard @fs.kind(target, follow_symlink=false) is Regular else {
      raise Unavailable
    }
  }
  @fs.write_file(
    target + ".next",
    clean,
    create_mode=CreateOrTruncate,
    permission=0o600,
    sync=Full,
  )
  @fs.rename(target + ".next", target, replace=true)
  save_previews(path, id, clean)
  let job : Generation = {
    id,
    actor,
    intent,
    prompt: "外部 AI 作品",
    state: "completed",
    created_ms: now,
    started_ms: now,
    finished_ms: now,
    sha256: @crypto.bytes_to_hex_string(@crypto.sha256(clean)),
    reason: "",
    provider_id: digest,
  }
  let next = {
    ..state,
    revision: state.revision + 1,
    generations: state.generations + [job],
  }
  save(path, next)
  snapshot(
    next,
    config,
    now,
    Some(actor),
    event_manager(config, Some(actor), operator),
  )
}

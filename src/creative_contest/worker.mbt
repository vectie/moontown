///|
async fn bounded(reader : &@io.Reader, limit : Int32) -> Bytes {
  let buffer = FixedArray::make(limit + 1, b'\x00')
  let mut count = 0
  while count <= limit {
    let n = reader.read(buffer, offset=count, max_len=limit + 1 - count)
    if n == 0 {
      return buffer.unsafe_reinterpret_as_bytes()[:count].to_owned()
    }
    count += n
  }
  raise Unavailable
}

///|
fn png_number(bytes : Bytes, offset : Int32) -> Int32 {
  (bytes[offset].to_int() << 24) |
  (bytes[offset + 1].to_int() << 16) |
  (bytes[offset + 2].to_int() << 8) |
  bytes[offset + 3].to_int()
}

///|
fn png_chunk(kind : Bytes, content : Bytes) -> Bytes {
  let n = content.length()
  let data = kind + content
  let mut crc = 0xffffffffU
  for byte in data {
    crc = crc ^ byte.to_uint()
    for _ in 0..<8 {
      crc = (crc >> 1) ^ (if (crc & 1U) == 1U { 0xedb88320U } else { 0U })
    }
  }
  crc = crc ^ 0xffffffffU
  Bytes::from_array([
    (n >> 24).to_byte(),
    (n >> 16).to_byte(),
    (n >> 8).to_byte(),
    n.to_byte(),
  ]) +
  data +
  Bytes::from_array([
    (crc >> 24).to_byte(),
    (crc >> 16).to_byte(),
    (crc >> 8).to_byte(),
    crc.to_byte(),
  ])
}

///|
/// Preserve pixels and PNG chunk checksums, remove prompt/workflow metadata.
/// The public page and normal download both add an explicit AI label.
pub fn private_metadata_removed(bytes : Bytes) -> Bytes raise {
  guard bytes.length() >= 33 &&
    bytes.length() <= 8388608 &&
    bytes[:8].to_owned() == b"\x89PNG\r\n\x1a\n" &&
    png_number(bytes, 8) == 13 &&
    bytes[12:16].to_owned() == b"IHDR" &&
    png_number(bytes, 16) > 0 &&
    png_number(bytes, 16) <= 2048 &&
    png_number(bytes, 20) > 0 &&
    png_number(bytes, 20) <= 2048 else {
    raise Unavailable
  }
  let result : Array[Byte] = []
  for b in bytes[:8] {
    result.push(b)
  }
  let mut offset = 8
  let mut ended = false
  let mut pixels = false
  while offset < bytes.length() {
    guard offset <= bytes.length() - 12 else { raise Unavailable }
    let n = png_number(bytes, offset)
    guard n >= 0 && n <= bytes.length() - offset - 12 else { raise Unavailable }
    let kind = bytes[offset + 4:offset + 8].to_owned()
    if kind == b"IDAT" {
      pixels = true
    }
    if kind == b"IEND" {
      guard n == 0 else { raise Unavailable }
      let label = @utf8.encode(
        "AIGC\u0000" +
        (
          {
            "Label": "1",
            "ContentProducer": "LunaNexa",
            "ProduceID": @crypto.bytes_to_hex_string(@crypto.sha256(bytes)),
            "ContentPropagator": "MoonTown",
          } : Json).stringify(),
      )
      for b in png_chunk(b"tEXt", label) {
        result.push(b)
      }
    }
    if kind != b"tEXt" && kind != b"iTXt" && kind != b"zTXt" && kind != b"eXIf" {
      for b in bytes[offset:offset + n + 12] {
        result.push(b)
      }
    }
    offset += n + 12
    if kind == b"IEND" {
      ended = true
      break
    }
  }
  guard ended && pixels && offset == bytes.length() else { raise Unavailable }
  Bytes::from_array(result)
}

///|
/// A provider-neutral image contract; the trusted model gateway owns runtime
/// selection. Neither browsers nor this queue submit arbitrary Comfy graphs.
async fn generate(config : Config, job : Generation) -> (String, Bytes) {
  guard !config.provider_key_file.is_empty() else { raise Unavailable }
  let key = @fs.read_file(config.provider_key_file).text().trim().to_owned()
  guard key.length() >= 16 && !key.contains("\n") else { raise Unavailable }
  let client = @http.Client(config.provider_origin, headers={
    "Authorization": "Bearer " + key,
    "Content-Type": "application/json",
    "Idempotency-Key": job.id,
  })
  defer client.close()
  let response = client.post(
    "/v1/images/generations",
    (
      {
        "model": config.model,
        "prompt": job.prompt,
        "n": 1,
        "size": "1024x1024",
        "response_format": "b64_json",
        "user": job.actor,
      } : Json).stringify(),
  )
  guard response.code == 200 else { raise Unavailable }
  let value = @json.parse(@utf8.decode(bounded(client, 12582912)))
  guard value is { "data": Array(images), .. } &&
    images.length() == 1 &&
    images[0] is { "b64_json": String(image), .. } else {
    raise Unavailable
  }
  (
    text(value, "id", 128, optional=true),
    private_metadata_removed(@base64.decode(image)),
  )
}

///|
async fn finish(
  path : String,
  config : Config,
  job : Generation,
  result : (String, Bytes)?,
  now : UInt64,
) -> Unit {
  let file = lock(path)
  defer file.close()
  defer file.unlock()
  let state = read(path, config)
  guard state.generations
    .iter()
    .find_first(item => {
      item.id == job.id && ["running", "needs_reconcile"].contains(item.state)
    })
    is Some(current) else {
    return
  }
  // Login may have claimed a running visitor job while the provider was busy.
  // Finish from the current durable record, never the dispatch-time owner.
  let job = current
  let completed = match result {
    Some((provider_id, bytes)) => {
      let directory = path + ".images"
      if !@fs.exists(directory) {
        @fs.mkdir(directory, permission=0o700)
      }
      guard @fs.kind(directory, follow_symlink=false) is Directory else {
        raise Unavailable
      }
      let image_path = directory + "/" + job.id + ".png"
      @fs.write_file(
        image_path,
        bytes,
        create_mode=CreateOrTruncate,
        permission=0o600,
        sync=Full,
      )
      // The image job stays successful if a derivative needs a later retry.
      save_previews(path, job.id, bytes) catch {
        _ => eprintln("moontown_preview_pending")
      }
      {
        ..job,
        state: "completed",
        finished_ms: now,
        sha256: @crypto.bytes_to_hex_string(@crypto.sha256(bytes)),
        provider_id,
      }
    }
    None =>
      {
        ..job,
        state: "needs_reconcile",
        finished_ms: now,
        reason: "本次生成需要核对，请稍后查看；不会自动重复生成。",
      }
  }
  save(path, {
    ..state,
    revision: state.revision + 1,
    generations: state.generations.map(item => {
      if item.id == job.id {
        completed
      } else {
        item
      }
    }),
  })
}

///|
pub async fn process_next(
  path : String,
  config_path : String,
  allow_generation~ : Bool = true,
) -> Bool {
  let config = load_config(config_path)
  {
    let file = lock(path)
    defer file.close()
    defer file.unlock()
    let state = read(path, config)
    let next = advance_voting(state, config, @env.now())
    if next.revision != state.revision {
      save(path, next)
    }
  }
  if process_previews(path, config_path) {
    return false
  }
  if config.provider_origin.is_empty() {
    return false
  }
  let reconcile = {
    let file = lock(path)
    defer file.close()
    defer file.unlock()
    read(path, config).generations
    .iter()
    .find_first(job => job.state == "needs_reconcile")
  }
  if reconcile is Some(job) {
    if @env.now() < job.finished_ms + 10000UL {
      return false
    }
    let recovered = @async.with_timeout(30000, () => {
      let key = @fs.read_file(config.provider_key_file).text().trim().to_owned()
      let client = @http.Client(config.provider_origin, headers={
        "Authorization": "Bearer " + key,
      })
      defer client.close()
      let response = client.get("/v1/images/generations/" + job.id)
      let value = @json.parse(@utf8.decode(bounded(client, 12582912)))
      if response.code == 200 &&
        value is { "data": [{ "b64_json": String(encoded), .. }], .. } {
        return Some((job.id, private_metadata_removed(@base64.decode(encoded))))
      }
      if response.code == 202 && value is { "status": String("failed"), .. } {
        let file = lock(path)
        defer file.close()
        defer file.unlock()
        let state = read(path, config)
        save(path, {
          ..state,
          revision: state.revision + 1,
          generations: state.generations.map(item => {
            if item.id == job.id {
              {
                ..item,
                state: "failed",
                finished_ms: @env.now(),
                reason: "模型服务确认本次未完成，次数已退回。",
              }
            } else {
              item
            }
          }),
        })
      }
      None
    }) catch {
      _ => None
    }
    if recovered is Some(result) {
      finish(path, config, job, Some(result), @env.now())
    } else {
      let file = lock(path)
      defer file.close()
      defer file.unlock()
      let state = read(path, config)
      if state.generations.any(item => {
          item.id == job.id && item.state == "needs_reconcile"
        }) {
        save(path, {
          ..state,
          generations: state.generations.map(item => {
            if item.id == job.id {
              { ..item, finished_ms: @env.now(), }
            } else {
              item
            }
          }),
        })
      }
    }
    return false
  }
  let job = {
    let file = lock(path)
    defer file.close()
    defer file.unlock()
    let state = read(path, config)
    let now = @env.now()
    if state.generations.any(job => {
        job.state == "running" && now > job.started_ms + 360000UL
      }) {
      save(path, {
        ..state,
        revision: state.revision + 1,
        generations: state.generations.map(job => {
          if job.state == "running" && now > job.started_ms + 360000UL {
            {
              ..job,
              state: "needs_reconcile",
              reason: "生成进程中断，需要主办核对；不会自动重复提交。",
            }
          } else {
            job
          }
        }),
      })
      return false
    }
    if state.generations.any(job => {
        job.state == "running" || job.state == "needs_reconcile"
      }) {
      return false
    }
    if !allow_generation {
      return false
    }
    guard state.generations.iter().find_first(job => job.state == "queued")
      is Some(job) else {
      return false
    }
    if now >= config.brief.deadline_ms {
      save(path, {
        ..state,
        revision: state.revision + 1,
        generations: state.generations.map(item => {
          if item.id == job.id {
            {
              ..item,
              state: "failed",
              finished_ms: now,
              reason: "本期已截止，排队任务未开始，次数已退回。",
            }
          } else {
            item
          }
        }),
      })
      return true
    }
    let started = { ..job, state: "running", started_ms: @env.now(), }
    save(path, {
      ..state,
      revision: state.revision + 1,
      generations: state.generations.map(item => {
        if item.id == job.id {
          started
        } else {
          item
        }
      }),
    })
    started
  }
  let result = @async.with_timeout(300000, () => Some(generate(config, job))) catch {
    _ => None
  }
  finish(path, config, job, result, @env.now())
  true
}

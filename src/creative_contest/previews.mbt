///|
pub(all) enum ImageVariant {
  Original
  Thumbnail
  Preview
} derive(Eq)

///|
// This remembers only derived files, never identities or visibility decisions.
let preview_files : Set[String] = Set([])

///|
fn preview_key(path : String, id : String) -> String {
  path + ":" + id
}

///|
fn remember_previews(path : String, id : String) -> Unit {
  if preview_files.length() >= 8192 {
    preview_files.clear()
  }
  preview_files.add(preview_key(path, id))
}

///|
fn preview_path(path : String, id : String, variant : ImageVariant) -> String {
  let suffix = match variant {
    Original => ".png"
    Thumbnail => ".thumb.webp"
    Preview => ".preview.webp"
  }
  path + ".images/" + id + suffix
}

///|
async fn has_previews(path : String, id : String) -> Bool {
  if preview_files.contains(preview_key(path, id)) {
    return true
  }
  for variant in [Thumbnail, Preview] {
    let target = preview_path(path, id, variant)
    if !@fs.exists(target) ||
      !(@fs.kind(target, follow_symlink=false) is Regular) {
      return false
    }
  }
  remember_previews(path, id)
  true
}

///|
async fn save_previews(path : String, id : String, bytes : Bytes) -> Unit {
  for (variant, edge) in [(Thumbnail, 384), (Preview, 768)] {
    let target = preview_path(path, id, variant)
    if @fs.exists(target) {
      guard @fs.kind(target, follow_symlink=false) is Regular else {
        raise Unavailable
      }
      continue
    }
    guard @image_preview.make(bytes, edge) is Some(preview) else {
      raise Unavailable
    }
    let next = target + ".next"
    if @fs.exists(next) && !(@fs.kind(next, follow_symlink=false) is Regular) {
      raise Unavailable
    }
    @fs.write_file(
      next,
      preview,
      create_mode=CreateOrTruncate,
      permission=0o600,
      sync=Full,
    )
    @fs.rename(next, target, replace=true)
  }
  remember_previews(path, id)
}

///|
/// Backfill one completed job between worker iterations. Never alters its
/// original, state, votes, generation quota, or the inference queue.
pub async fn process_previews(path : String, config_path : String) -> Bool {
  let config = load_config(config_path)
  let file = lock(path)
  defer file.close()
  defer file.unlock()
  let state = read(path, config)
  if state.generations.any(job => {
      ["queued", "running", "needs_reconcile"].contains(job.state)
    }) {
    return false
  }
  for job in state.generations {
    if job.state != "completed" || has_previews(path, job.id) {
      continue
    }
    let ready = try {
      let original = preview_path(path, job.id, Original)
      guard @fs.kind(original, follow_symlink=false) is Regular else {
        raise Unavailable
      }
      save_previews(path, job.id, @fs.read_file(original).binary())
      true
    } catch {
      _ => false
    }
    if ready {
      return true
    }
  }
  false
}

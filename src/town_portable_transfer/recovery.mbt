///| None means absent; an acquired descriptor remains held until its path is

///|
/// removed or the recovery decision is complete. Busy attempts are skipped.
async fn acquire_cleanup_file(path : String) -> (@fs.File?, Bool) {
  match optional_kind(path) {
    None => (None, true)
    Some(Regular) => {
      let file = @fs.open(path, mode=ReadWrite)
      guard file.kind() == Regular else {
        file.close()
        raise TransferError(503, "package_storage_unavailable")
      }
      if file.try_lock(Exclusive) {
        (Some(file), true)
      } else {
        file.close()
        (None, false)
      }
    }
    Some(_) => raise TransferError(503, "package_storage_unavailable")
  }
}

///|
fn valid_object_name(name : String) -> Bool {
  if name.length() != 83 ||
    !name.has_prefix("pkg-") ||
    !name.has_suffix(".moonbook-agent") {
    return false
  }
  for c in name[4:68] {
    if !((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f')) {
      return false
    }
  }
  true
}

///| Reconcile only the managed namespace, under the same index lock. A live

///|
/// attempt's advisory lock takes precedence over its wall-clock lease.
pub async fn PortableStore::recover(
  self : PortableStore,
  now_ms : UInt64,
) -> Unit {
  self.with_index(loaded => {
    let mut index = loaded
    for r in loaded.reservations {
      if r.lease_ends_ms > now_ms && !r.cleanup_pending {
        continue
      }
      let (part, part_idle) = acquire_cleanup_file(self.part_path(r.attempt_id))
      defer (if part is Some(file) { file.close() })
      if !part_idle {
        continue
      }
      guard find_package(index, r.package_id) is Some(p) else {
        raise TransferError(503, "package_state_unavailable")
      }
      // A rename-before-index crash may have moved the locked descriptor.
      let (object, object_idle) = acquire_cleanup_file(
        self.object_path(p.package_id),
      )
      defer (if object is Some(file) { file.close() })
      if !object_idle {
        continue
      }
      let removed_part = self.remove_owned(self.part_path(r.attempt_id))
      let removed_object = if p.status == "available" {
        true
      } else {
        self.remove_owned(self.object_path(p.package_id))
      }
      let cleaned = removed_part && removed_object
      index = {
        ..index,
        revision: index.revision + 1UL,
        reservations: if cleaned {
          index.reservations.filter(old => old.attempt_id != r.attempt_id)
        } else {
          index.reservations.map(old => {
            if old.attempt_id == r.attempt_id {
              { ..old, cleanup_pending: true, }
            } else {
              old
            }
          })
        },
      }
      self.save_index(index)
    }
    // Withdrawal cleanup is independently retryable, even with no reservation.
    for p in index.packages.copy() {
      if p.status == "withdrawn" && p.cleanup_pending {
        let (file, idle) = acquire_cleanup_file(self.object_path(p.package_id))
        defer (if file is Some(file) { file.close() })
        if !idle {
          continue
        }
        if self.remove_owned(self.object_path(p.package_id)) {
          index = replace_package(index, {
            ..p,
            object_retained: false,
            cleanup_pending: false,
            revision: index.revision + 1UL,
          })
          self.save_index(index)
        }
      }
    }
    // Unindexed objects never become available merely by appearing on disk.
    for name in @fs.readdir(self.root + "/objects", include_hidden=true) {
      guard valid_object_name(name) else {
        raise TransferError(503, "package_storage_unavailable")
      }
      let id = name[:68].to_owned()
      require_regular(self.root + "/objects/" + name)
      if find_package(index, id) is Some(p) &&
        (
          p.status == "available" ||
          index.reservations.any(r => r.package_id == id)
        ) {
        continue
      }
      let (file, idle) = acquire_cleanup_file(self.object_path(id))
      defer (if file is Some(file) { file.close() })
      if !idle {
        continue
      }
      guard self.remove_owned(self.object_path(id)) else {
        raise TransferError(503, "package_cleanup_pending")
      }
    }
    for name in @fs.readdir(self.root + "/incoming", include_hidden=true) {
      guard name.has_suffix(".part") &&
        valid_attempt(name[:name.length() - 5].to_owned()) else {
        raise TransferError(503, "package_storage_unavailable")
      }
      let attempt = name[:name.length() - 5].to_owned()
      require_regular(self.part_path(attempt))
      if index.reservations.any(r => r.attempt_id == attempt) {
        continue
      }
      let (file, idle) = acquire_cleanup_file(self.part_path(attempt))
      defer (if file is Some(file) { file.close() })
      if !idle {
        continue
      }
      if file is Some(opened) {
        let (seconds, _) = opened.mtime()
        let modified_ms = if seconds < 0L {
          0UL
        } else {
          seconds.reinterpret_as_uint64() * 1000UL
        }
        // A recent unindexed file is conservatively unavailable until its
        // recovery lease expires, rather than permitting uncharged uploads.
        guard now_ms >= modified_ms &&
          now_ms - modified_ms >= self.limits.lease_ms else {
          raise TransferError(503, "package_cleanup_pending")
        }
        guard self.remove_owned(self.part_path(attempt)) else {
          raise TransferError(503, "package_cleanup_pending")
        }
      }
    }
  })
}

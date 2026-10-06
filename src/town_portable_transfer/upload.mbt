///|
async fn PortableStore::reserve(
  self : PortableStore,
  actor : TransferActor,
  binding : @town_marketplace.PortableListingBinding,
  now_ms : UInt64,
) -> (Reservation, @fs.File) {
  @town_marketplace.validate_portable_listing_binding(binding)
  guard actor.publisher &&
    binding.publisher_principal_id == actor.principal_id &&
    binding.tenant_id == actor.tenant_id else {
    raise TransferError(403, "package_access_denied")
  }
  checked_limits(self.limits)
  guard binding.source.package_size_bytes <= self.limits.max_package_bytes else {
    raise TransferError(413, "package_exceeds_transfer_limit")
  }
  guard now_ms <= 18446744073709551615UL - self.limits.lease_ms else {
    raise TransferError(422, "invalid_package_time")
  }
  self.with_index(index => {
    let id = package_id(binding.binding_digest)
    let record = match find_package(index, id) {
      Some(old) => {
        require_owner(actor, old)
        guard old.binding == binding else {
          raise TransferError(409, "package_binding_conflict")
        }
        guard old.status != "withdrawn" else {
          raise TransferError(409, "package_withdrawn")
        }
        old
      }
      None =>
        {
          package_id: id,
          binding,
          binding_digest: binding.binding_digest,
          publisher_principal_id: binding.publisher_principal_id,
          tenant_id: binding.tenant_id,
          listing_id: binding.listing_id,
          package_sha256: binding.source.package_sha256,
          package_size_bytes: binding.source.package_size_bytes,
          status: "uploading",
          receipt: None,
          cleanup_pending: false,
          object_retained: false,
          revision: index.revision + 1UL,
        }
    }
    guard !index.reservations.any(r => r.package_id == id) else {
      raise TransferError(409, "package_upload_in_progress")
    }
    let mut retained = 0L
    for p in index.packages {
      if p.publisher_principal_id == actor.principal_id &&
        p.tenant_id == actor.tenant_id &&
        p.object_retained {
        retained += p.package_size_bytes.to_int64()
      }
    }
    for r in index.reservations {
      if find_package(index, r.package_id) is Some(p) &&
        p.publisher_principal_id == actor.principal_id &&
        p.tenant_id == actor.tenant_id {
        retained += r.reserved_bytes.to_int64()
      }
    }
    guard retained + record.package_size_bytes.to_int64() <=
      self.limits.max_retained_bytes.to_int64() else {
      raise TransferError(413, "package_retained_limit")
    }
    let attempt = "att-" +
      @crypto.bytes_to_hex_string(
        @crypto.sha256(
          @utf8.encode(
            "moontown.package-attempt.v1:\{id}:\{index.revision}:\{now_ms}",
          ),
        ),
      )
    let reservation : Reservation = {
      attempt_id: attempt,
      package_id: id,
      reserved_bytes: record.package_size_bytes,
      lease_ends_ms: now_ms + self.limits.lease_ms,
      cleanup_pending: false,
    }
    let reservations = index.reservations.copy()
    reservations.push(reservation)
    let persisted = { ..replace_package(index, record), reservations, }
    errdefer @async.protect_from_cancel(() => {
      let removed = self.remove_owned(self.part_path(attempt))
      self.save_index({
        ..persisted,
        revision: persisted.revision + 1UL,
        reservations: if removed {
          persisted.reservations.filter(r => r.attempt_id != attempt)
        } else {
          persisted.reservations.map(r => {
            if r.attempt_id == attempt {
              { ..r, cleanup_pending: true, }
            } else {
              r
            }
          })
        },
      }) catch {
        _ => ()
      }
    })
    // Arm cleanup before the async durable write, including cancellation after
    // index rename but before save_index returns. No temporary bytes exist yet.
    self.save_index(persisted)
    self.checkpoint("part_create")
    let file = @fs.open(
      self.part_path(attempt),
      mode=ReadWrite,
      create_mode=CreateNew,
      permission=0o600,
    )
    errdefer file.close()
    guard file.kind() == Regular && file.try_lock(Exclusive) else {
      raise TransferError(503, "package_storage_unavailable")
    }
    (reservation, file)
  })
}

///|
async fn PortableStore::copy_upload(
  self : PortableStore,
  body : &@io.Reader,
  file : @fs.File,
  expected : Int,
  digest : String,
) -> Unit {
  let hasher = @crypto.SHA256::new()
  let mut count = 0
  for ;; {
    let chunk = @async.with_timeout(
      self.limits.idle_timeout_ms,
      () => body.read_some(max_len=self.limits.chunk_bytes),
      error=TransferError(408, "package_transfer_timeout"),
    ) catch {
      @io.ReaderClosed => raise TransferError(422, "package_length_mismatch")
      error => raise error
    }
    guard chunk is Some(bytes) else { break }
    guard bytes.length() <= expected - count else {
      raise TransferError(422, "package_length_mismatch")
    }
    count += bytes.length()
    hasher.update(bytes)
    self.checkpoint("part_write")
    @async.with_timeout(
      self.limits.idle_timeout_ms,
      () => file.write(bytes),
      error=TransferError(408, "package_transfer_timeout"),
    )
  }
  guard count == expected else {
    raise TransferError(422, "package_length_mismatch")
  }
  guard "sha256:" + @crypto.bytes_to_hex_string(hasher.finalize()) == digest else {
    raise TransferError(422, "package_digest_mismatch")
  }
  self.checkpoint("part_sync")
  @async.with_timeout(
    self.limits.idle_timeout_ms,
    () => file.sync(),
    error=TransferError(408, "package_transfer_timeout"),
  )
}

///|
async fn PortableStore::commit_upload(
  self : PortableStore,
  actor : TransferActor,
  binding : @town_marketplace.PortableListingBinding,
  reservation : Reservation,
  now_ms : UInt64,
) -> PackageView {
  self.with_index(index => {
    guard find_package(index, reservation.package_id) is Some(p) else {
      raise TransferError(409, "package_reservation_lost")
    }
    require_owner(actor, p)
    guard p.binding == binding &&
      p.status != "withdrawn" &&
      now_ms < reservation.lease_ends_ms &&
      index.reservations.any(r => r == reservation) else {
      raise TransferError(409, "package_reservation_lost")
    }
    let path = self.object_path(p.package_id)
    match optional_kind(path) {
      None | Some(Regular) => ()
      Some(_) => raise TransferError(503, "package_storage_unavailable")
    }
    require_regular(self.part_path(reservation.attempt_id))
    // Atomic replacement repairs only the same immutable identity; opened old
    // descriptors remain valid. Available object contents are never edited.
    self.checkpoint("object_rename")
    @fs.rename(self.part_path(reservation.attempt_id), path, replace=true)
    self.checkpoint("after_object_rename")
    let available = {
      ..p,
      status: "available",
      object_retained: true,
      cleanup_pending: false,
      receipt: Some(p.receipt.unwrap_or_else(() => receipt_for(p, now_ms))),
      revision: index.revision + 1UL,
    }
    let next = {
      ..replace_package(index, available),
      reservations: index.reservations.filter(r => {
        r.attempt_id != reservation.attempt_id
      }),
    }
    self.save_index(next)
    view_for(next, available, "owner")
  })
}

///| Failure cleanup preserves every old receipt and grant. If any removal

///|
/// fails, the durable reservation continues charging its full bounded size.
async fn PortableStore::fail_attempt(
  self : PortableStore,
  attempt : Reservation,
) -> Unit {
  self.with_index(index => {
    guard index.reservations.any(r => r.attempt_id == attempt.attempt_id) else {
      return
    }
    let part_removed = self.remove_owned(self.part_path(attempt.attempt_id))
    guard find_package(index, attempt.package_id) is Some(p) else {
      raise TransferError(503, "package_state_unavailable")
    }
    let object_removed = if p.status == "available" {
      true
    } else {
      self.remove_owned(self.object_path(p.package_id))
    }
    let cleaned = part_removed && object_removed
    let reservations = if cleaned {
      index.reservations.filter(r => r.attempt_id != attempt.attempt_id)
    } else {
      index.reservations.map(r => {
        if r.attempt_id == attempt.attempt_id {
          { ..r, cleanup_pending: true, }
        } else {
          r
        }
      })
    }
    self.save_index({ ..index, reservations, revision: index.revision + 1UL, })
  })
}

///| Stream exact raw bytes; the callback must freshly resolve account,

///|
/// entitlements, active tenant and immutable source before commit.
pub async fn PortableStore::upload(
  self : PortableStore,
  actor : TransferActor,
  binding : @town_marketplace.PortableListingBinding,
  body : &@io.Reader,
  reauthorize : async () -> Unit,
  now : () -> UInt64,
) -> PackageView {
  self.recover(now())
  let (attempt, file) = self.reserve(actor, binding, now())
  defer file.close()
  // Cancellation does not skip durable reservation cleanup.
  errdefer @async.protect_from_cancel(() => {
    self.fail_attempt(attempt) catch {
      _ => ()
    }
  })
  @async.with_timeout(
    self.limits.total_timeout_ms,
    () => {
      self.copy_upload(
        body,
        file,
        binding.source.package_size_bytes,
        binding.source.package_sha256,
      )
      reauthorize()
      self.commit_upload(actor, binding, attempt, now())
    },
    error=TransferError(408, "package_transfer_timeout"),
  ) catch {
    error => {
      if error is TransferError(_, _) {
        raise error
      }
      if @async.is_cancellation_error(error) {
        raise error
      } else {
        raise TransferError(503, "package_upload_failed")
      }
    }
  }
}

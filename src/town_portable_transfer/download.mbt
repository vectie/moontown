///|
async fn PortableStore::open_verified(
  self : PortableStore,
  p : StoredPackage,
) -> @fs.File {
  let path = self.object_path(p.package_id)
  require_regular(path)
  let file = @fs.open(path, mode=ReadOnly)
  errdefer file.close()
  guard file.kind() == Regular && file.size() == p.package_size_bytes.to_int64() else {
    raise TransferError(503, "package_object_unavailable")
  }
  @async.with_timeout(
    self.limits.total_timeout_ms,
    () => {
      let hasher = @crypto.SHA256::new()
      for position = 0; position < p.package_size_bytes; {
        let size = if self.limits.chunk_bytes < p.package_size_bytes - position {
          self.limits.chunk_bytes
        } else {
          p.package_size_bytes - position
        }
        let bytes = @async.with_timeout(
          self.limits.idle_timeout_ms,
          () => file.read_exactly_at(size, position=position.to_int64()),
          error=TransferError(503, "package_object_unavailable"),
        )
        hasher.update(bytes)
        continue position + size
      }
      guard file.size() == p.package_size_bytes.to_int64() &&
        "sha256:" + @crypto.bytes_to_hex_string(hasher.finalize()) ==
        p.package_sha256 else {
        raise TransferError(503, "package_object_unavailable")
      }
    },
    error=TransferError(503, "package_object_unavailable"),
  )
  file
}

///| Verify with bounded positional reads; stream this same descriptor. The

///|
/// HTTP adapter freshly reauthorizes immediately before sending headers.
pub async fn PortableStore::download(
  self : PortableStore,
  actor : TransferActor,
  id : String,
  digest : String,
  now_ms : UInt64,
) -> PackageDownload {
  let (p, basis, view) = self.with_index(index => {
    let (p, basis) = authorized(index, actor, id, digest, now_ms)
    guard p.status == "available" else {
      raise TransferError(409, "package_not_available")
    }
    (p, basis, view_for(index, p, basis))
  })
  ignore(basis)
  let file = self.open_verified(p) catch {
    _ => raise TransferError(503, "package_object_unavailable")
  }
  { view, file, limits: self.limits, closed: false, }
}

///|
pub async fn PackageDownload::stream(
  self : PackageDownload,
  writer : &@io.Writer,
) -> Unit {
  guard !self.closed else {
    raise TransferError(503, "package_download_closed")
  }
  @async.with_timeout(
    self.limits.total_timeout_ms,
    () => {
      let expected = self.view.binding.source.package_size_bytes
      for position = 0; position < expected; {
        let size = if self.limits.chunk_bytes < expected - position {
          self.limits.chunk_bytes
        } else {
          expected - position
        }
        let bytes = @async.with_timeout(
          self.limits.idle_timeout_ms,
          () => self.file.read_exactly_at(size, position=position.to_int64()),
          error=TransferError(408, "package_transfer_timeout"),
        )
        @async.with_timeout(
          self.limits.idle_timeout_ms,
          () => writer.write(bytes),
          error=TransferError(408, "package_transfer_timeout"),
        )
        continue position + size
      }
    },
    error=TransferError(408, "package_transfer_timeout"),
  )
}

///|
pub fn PackageDownload::close(self : PackageDownload) -> Unit {
  if !self.closed {
    self.closed = true
    self.file.close()
  }
}

///|
/// Deterministic GNU-compatible tar. Long names retain exact UTF-8 paths.
fn tar_octal(value : Int, width : Int) -> String {
  let mut n = value
  let mut result = ""
  while n > 0 {
    result = (n % 8).to_string() + result
    n /= 8
  }
  while result.length() < width - 1 {
    result = "0" + result
  }
  result + "\u0000"
}

///|
fn tar_field(header : Array[Byte], offset : Int, text : String) -> Unit {
  let bytes = @utf8.encode(text)
  for i in 0..<bytes.length() {
    header[offset + i] = bytes[i]
  }
}

///|
fn tar_entry(
  output : @buffer.Buffer,
  path : String,
  bytes : Bytes,
  kind : String,
) -> Unit {
  let header : Array[Byte] = Array::make(512, b'\x00')
  tar_field(header, 0, path)
  tar_field(header, 100, "0000600\u0000")
  tar_field(header, 108, "0000000\u0000")
  tar_field(header, 116, "0000000\u0000")
  tar_field(header, 124, tar_octal(bytes.length(), 12))
  tar_field(header, 136, "00000000000\u0000")
  tar_field(header, 148, "        ")
  tar_field(header, 156, kind)
  tar_field(header, 257, "ustar\u0000")
  tar_field(header, 263, "00")
  let sum = header.fold(init=0, (total, byte) => total + byte.to_int())
  tar_field(header, 148, tar_octal(sum, 7) + " ")
  output.write_bytes(@buffer.from_array(header).to_bytes())
  output.write_bytes(bytes)
  let padding = (512 - bytes.length() % 512) % 512
  for _ in 0..<padding {
    output.write_byte(b'\x00')
  }
}

///|
fn tar_file(output : @buffer.Buffer, path : String, bytes : Bytes) -> Unit {
  if @utf8.encode(path).length() > 100 {
    tar_entry(output, "././@LongLink", @utf8.encode(path + "\u0000"), "L")
    tar_entry(output, "long-name-entry", bytes, "0")
  } else {
    tar_entry(output, path, bytes, "0")
  }
}

///|
/// All downloaded source data is exact binary; no text decoding or flattening.
pub async fn Store::export_tar(
  self : Store,
  id : String,
  revision : String,
) -> Bytes {
  self.locked(() => {
    let saved = self.load_revision(id, revision)
    let prepared = self.verify_prepared(saved)
    let output = @buffer.Buffer()
    tar_file(
      output,
      "manifest.json",
      @utf8.encode(prepared.to_json().stringify(indent=2)),
    )
    tar_file(
      output,
      "README.txt",
      @utf8.encode(
        "MoonTown collaboration plan\n\nCurrent revision: " +
        revision +
        "\nEntry point: revisions/" +
        revision +
        "/handoff.json\nReview: revisions/" +
        revision +
        "/review-bundle.json\n\nAll paths are relative to this extracted directory. Source snapshots preserve original nested paths and exact bytes. Verify manifest.json SHA-256 values before use. This package has not executed, scheduled work, accepted knowledge, or modified a participant Book. Civic bootstrap/install commands can schedule work even with interval_ms null; this authoring flow never calls them.\n",
      ),
    )
    for artifact in prepared.artifacts {
      tar_file(
        output,
        artifact.path,
        read_bytes(self.draft_root(id) + "/" + artifact.path, 1048576),
      )
    }
    for _ in 0..<1024 {
      output.write_byte(b'\x00')
    }
    output.to_bytes()
  })
}

///|
/// Verify the actual held attachment bytes, independently of transport headers.
/// The caller must save this same buffer only after its request/selection fence.
/// This uses portable MoonBit SHA-256 on both native and JS targets.
pub fn selection_bytes_match(selection : Selection, bytes : Bytes) -> Bool {
  selection_valid(selection) &&
  bytes.length() == selection.size_bytes &&
  "sha256:" + @crypto.bytes_to_hex_string(@crypto.sha256(bytes)) ==
  selection.digest
}

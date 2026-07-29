///|
let request_nonce_rng : @random.Rand = @random.Rand::chacha8()

///|
fn request_nonce() -> String {
  request_nonce_rng.uint64().to_string(radix=16)
}

///|
fn iso_timestamp(timestamp_ms : UInt64) -> String {
  let seconds = (timestamp_ms / 1000UL).reinterpret_as_int64()
  let nanosecond = (timestamp_ms % 1000UL).to_int() * 1000000
  let value = @time.PlainDateTime::from_unix_second(
    seconds, nanosecond, @time.utc_offset,
  ) catch {
    _ => return "1970-01-01T00:00:00.000Z"
  }
  value.to_string() + "Z"
}

///|
#borrow(input)
extern "C" fn encode(input : Bytes, edge : Int32) -> Bytes = "moontown_preview_webp"

///|
#borrow(input)
extern "C" fn inspect(input : Bytes) -> UInt64 = "moontown_preview_info"

///|
/// Bounded, metadata-free WebP derivatives. Originals stay byte-for-byte intact.
pub fn make(input : Bytes, edge : Int32) -> Bytes? {
  if input.length() < 32 ||
    input.length() > 12582912 ||
    ![384, 768].contains(edge) {
    return None
  }
  let result = encode(input, edge)
  if result.is_empty() {
    None
  } else {
    Some(result)
  }
}

///|
pub fn dimensions(input : Bytes) -> (Int32, Int32)? {
  if input.length() < 20 || input.length() > 1048576 {
    return None
  }
  let size = inspect(input)
  if size == 0UL {
    None
  } else {
    Some(((size >> 32).to_int(), (size & 0xffffffffUL).to_int()))
  }
}

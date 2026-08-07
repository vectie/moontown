///|
/// A renderer-neutral, canonical identity that remains stable across world
/// recompilation. The representation is intentionally opaque so callers cannot
/// bypass canonicalization.
pub struct StableId {
  value : String
} derive(Debug, Eq, Hash)

///|
pub(all) enum ContractError {
  InvalidStableId(scope~ : String, key~ : String)
} derive(Debug, Eq)

///|
fn normalize_id_part(raw : String) -> String {
  let builder = StringBuilder()
  let mut separator_pending = false
  let mut wrote_any = false
  let mut last_was_path_separator = false
  for char in raw.trim().to_owned() {
    if char.is_ascii_alphabetic() ||
      char.is_ascii_digit() ||
      (!char.is_ascii() && !char.is_whitespace()) {
      if separator_pending && wrote_any && !last_was_path_separator {
        builder.write_char('-')
      }
      builder.write_char(char.to_ascii_lowercase())
      separator_pending = false
      wrote_any = true
      last_was_path_separator = false
    } else if char == '.' || char == '/' {
      if wrote_any && !last_was_path_separator {
        builder.write_char(char)
      }
      separator_pending = false
      last_was_path_separator = wrote_any
    } else if wrote_any {
      separator_pending = true
    }
  }
  builder.to_string()
}

///|
/// Builds a stable identity from a durable namespace and source key. Display
/// names must never be used as `key`; use an authored identifier or source
/// record key instead.
pub fn stable_id(
  scope : String,
  key : String,
) -> Result[StableId, ContractError] {
  let canonical_scope = normalize_id_part(scope)
  let canonical_key = normalize_id_part(key)
  if canonical_scope.is_empty() || canonical_key.is_empty() {
    Err(InvalidStableId(scope~, key~))
  } else {
    Ok({ value: "\{canonical_scope}/\{canonical_key}" })
  }
}

///|
pub fn StableId::to_string(self : StableId) -> String {
  self.value
}

///|
pub fn StableId::scope(self : StableId) -> String {
  match self.value.split_once("/") {
    Some((scope, _)) => scope.to_owned()
    None => self.value
  }
}

///|
pub fn StableId::local_key(self : StableId) -> String {
  match self.value.split_once("/") {
    Some((_, key)) => key.to_owned()
    None => self.value
  }
}

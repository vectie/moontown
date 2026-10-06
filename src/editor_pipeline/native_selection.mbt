///|
/// The owner-bound portion of an editor feature selection.
pub(all) struct NativeSelection {
  selected_feature : String
  title : String
  implementation_hint : String
  acceptance : Array[String]
} derive(Debug, Eq)

///|
/// Parse the selection fields required by native editor repair. Root keys must
/// be unique, and the selected feature must be a safe lowercase kebab token.
///
/// ```mbt check
/// test {
///   let content =
///     #|{"contract":"moontown.editor_feature_selection.v1","selected_feature":"road-editor","title":"Road Editor","implementation_hint":"Add the editor","acceptance":["Roads can be edited"]}
///   assert_true(@editor_pipeline.parse_native_selection(content) is Some(_))
/// }
/// ```
pub fn parse_native_selection(content : String) -> NativeSelection? {
  let parsed = @json.parse(content) catch { _ => return None }
  guard parsed is Object(fields) else { return None }
  // JSON map normalization keeps only one value for duplicate keys, including
  // escaped spellings of the same key. Count members in the valid source first.
  if native_selection_root_member_count(content) != fields.length() {
    return None
  }
  guard fields.get("contract") is Some(String(contract)) &&
    contract == feature_selection_result_contract() &&
    fields.get("selected_feature") is Some(String(selected_feature)) &&
    native_selection_feature_token_valid(selected_feature) &&
    fields.get("title") is Some(String(title)) &&
    !title.trim().is_empty() &&
    fields.get("implementation_hint") is Some(String(implementation_hint)) &&
    !implementation_hint.trim().is_empty() &&
    fields.get("acceptance") is Some(Array(criteria)) &&
    !criteria.is_empty() else {
    return None
  }
  let acceptance : Array[String] = []
  for criterion in criteria {
    guard criterion is String(value) && !value.trim().is_empty() else {
      return None
    }
    acceptance.push(value)
  }
  Some({ selected_feature, title, implementation_hint, acceptance, })
}

///|
fn native_selection_feature_token_valid(feature_id : String) -> Bool {
  let mut needs_character = true
  for character in feature_id {
    if character is ('a'..='z' | '0'..='9') {
      needs_character = false
    } else if character == '-' && !needs_character {
      needs_character = true
    } else {
      return false
    }
  }
  !needs_character
}

///|
fn native_selection_root_member_count(content : String) -> Int {
  let mut depth = 0
  let mut quoted = false
  let mut escaped = false
  let mut members = 0
  for character in content {
    if quoted {
      if escaped {
        escaped = false
      } else if character == '\\' {
        escaped = true
      } else if character == '"' {
        quoted = false
      }
    } else if character == '"' {
      quoted = true
    } else if character == '{' || character == '[' {
      depth += 1
    } else if character == '}' || character == ']' {
      depth -= 1
    } else if character == ':' && depth == 1 {
      members += 1
    }
  }
  members
}

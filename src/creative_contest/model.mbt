///|
pub(all) suberror CreativeError {
  Denied
  Invalid(String)
  Conflict(String)
  Unavailable
} derive(Debug)

///|
/// The existing civic Challenge remains the public brief. Provider settings
/// are trusted deployment configuration and are never returned to browsers.
pub struct Config {
  brief : @competition_brief.Challenge
  opens_ms : UInt64
  voting_opens_ms : UInt64
  voting_closes_ms : UInt64
  awards_ms : UInt64
  participant_quota : Int32
  event_quota : Int32
  provider_origin : String
  provider_key_file : String
  model : String
} derive(FromJson)

///|
struct Generation {
  id : String
  actor : String
  intent : String
  prompt : String
  state : String
  created_ms : UInt64
  started_ms : UInt64
  finished_ms : UInt64
  sha256 : String
  reason : String
  provider_id : String
} derive(ToJson, FromJson)

///|
struct Entry {
  id : String
  generation_id : String
  actor : String
  display_name : String
  title : String
  state : String
  submitted_ms : UInt64
  reviewed_ms : UInt64
  reviewer : String
  reason : String
} derive(ToJson, FromJson)

///|
struct Award {
  entry_id : String
  prize : String
  reason : String
  recorded_ms : UInt64
  operator : String
} derive(ToJson, FromJson)

///|
struct State {
  challenge_id : String
  revision : Int32
  generations : Array[Generation]
  entries : Array[Entry]
  voting_url : String
  awards : Array[Award]
  results_published : Bool
} derive(ToJson, FromJson)

///|
fn hash(value : String) -> String {
  @crypto.bytes_to_hex_string(@crypto.sha256(@utf8.encode(value)))
}

///|
fn identifier(value : String) -> Bool {
  value.length() == 64 && value.iter().all(c => c is ('0'..<='9' | 'a'..<='f'))
}

///|
fn fields(value : Json) -> Map[String, Json] {
  match value {
    Object(values) => values
    _ => Map([])
  }
}

///|
fn text(
  value : Json,
  key : String,
  limit : Int32,
  optional~ : Bool = false,
) -> String raise {
  let result = match fields(value).get(key) {
    Some(String(value)) => value.trim().to_owned()
    None if optional => ""
    _ => raise Invalid("请检查填写内容。")
  }
  guard result.length() <= limit && (optional || !result.is_empty()) else {
    raise Invalid("请检查填写内容。")
  }
  result
}

///|
pub async fn load_config(path : String) -> Config {
  let config : Config = @json.from_json(@json.parse(@fs.read_file(path).text()))
  guard config.brief.published &&
    config.brief.id.length() > 0 &&
    config.participant_quota > 0 &&
    config.event_quota > 0 &&
    config.opens_ms < config.brief.deadline_ms &&
    config.brief.deadline_ms <= config.voting_opens_ms &&
    config.voting_opens_ms < config.voting_closes_ms &&
    config.voting_closes_ms <= config.awards_ms else {
    raise Unavailable
  }
  if !config.provider_origin.is_empty() {
    guard config.provider_origin.has_prefix("http://") ||
      config.provider_origin.has_prefix("https://") else {
      raise Unavailable
    }
    guard !config.provider_origin.contains("@") &&
      !config.provider_origin.contains("?") &&
      !config.provider_origin.contains("#") else {
      raise Unavailable
    }
  }
  config
}

///|
fn empty(config : Config) -> State {
  {
    challenge_id: config.brief.id,
    revision: 0,
    generations: [],
    entries: [],
    voting_url: "preview",
    awards: [],
    results_published: false,
  }
}

///|
async fn lock(path : String) -> @fs.File {
  @support.ensure_parent_directory(path)
  if @fs.exists(path + ".lock") &&
    !(@fs.kind(path + ".lock", follow_symlink=false) is Regular) {
    raise Unavailable
  }
  let file = @fs.open(
    path + ".lock",
    mode=ReadWrite,
    create_mode=OpenOrCreate,
    permission=0o600,
  )
  file.lock(Exclusive)
  file
}

///|
async fn read(path : String, config : Config) -> State {
  if !@fs.exists(path) {
    return empty(config)
  }
  guard @fs.kind(path, follow_symlink=false) is Regular else {
    raise Unavailable
  }
  let state : State = @json.from_json(@json.parse(@fs.read_file(path).text()))
  guard state.challenge_id == config.brief.id else { raise Unavailable }
  state
}

///|
async fn save(path : String, state : State) -> Unit {
  if @fs.exists(path + ".next") &&
    !(@fs.kind(path + ".next", follow_symlink=false) is Regular) {
    raise Unavailable
  }
  @fs.write_file(
    path + ".next",
    state.to_json().stringify(),
    create_mode=CreateOrTruncate,
    permission=0o600,
    sync=Full,
  )
  @fs.rename(path + ".next", path, replace=true)
}

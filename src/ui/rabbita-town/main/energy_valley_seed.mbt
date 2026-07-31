///|
let default_energy_valley_seed = 20260727

///|
fn normalized_energy_valley_seed(seed : Int) -> Int {
  let bounded = seed % 2147483629
  if bounded == 0 {
    default_energy_valley_seed
  } else if bounded < 0 {
    -bounded
  } else {
    bounded
  }
}

///|
fn canonical_energy_valley_seed(requested_seed : Int) -> Int {
  normalized_energy_valley_seed(requested_seed)
}

///|
fn energy_valley_seed_label(seed : Int) -> String {
  let raw = normalized_energy_valley_seed(seed).to_string(radix=36).to_upper()
  if raw.length() >= 6 {
    raw[raw.length() - 6:].to_owned()
  } else {
    let padding = "000000"
    padding[:6 - raw.length()].to_owned() + raw
  }
}

///|
fn energy_valley_mod(value : Int, modulus : Int) -> Int {
  if modulus <= 0 {
    0
  } else {
    let remainder = value % modulus
    if remainder < 0 {
      remainder + modulus
    } else {
      remainder
    }
  }
}

///|
fn energy_valley_hash(seed : Int, first : Int, second : Int, salt : Int) -> Int {
  let modulus = 2147483629
  let mut value = normalized_energy_valley_seed(seed) % modulus
  value = energy_valley_mod(value * 97 + first * 53 + salt * 31, modulus)
  value = energy_valley_mod(value * 89 + second * 47 + salt * 17, modulus)
  energy_valley_mod(value * 83 + first * 19 + second * 23, modulus)
}

///|
fn energy_valley_variation(
  seed : Int,
  first : Int,
  second : Int,
  salt : Int,
  span : Int,
) -> Int {
  if span <= 1 {
    0
  } else {
    energy_valley_hash(seed, first, second, salt) % span
  }
}

///|
fn energy_valley_signed_variation(
  seed : Int,
  first : Int,
  second : Int,
  salt : Int,
  radius : Int,
) -> Int {
  if radius <= 0 {
    0
  } else {
    energy_valley_variation(seed, first, second, salt, radius * 2 + 1) - radius
  }
}

///|
extern "js" fn browser_energy_valley_seed_value() -> Int =
  #| () => {
  #|   const fallback = 20260727;
  #|   try {
  #|     const url = new URL(globalThis.location?.href || "http://local/");
  #|     const querySeed = url.searchParams.get("seed");
  #|     if (querySeed) {
  #|       const parsed = Number.parseInt(querySeed, 10);
  #|       return Number.isFinite(parsed) ? parsed : fallback;
  #|     }
  #|     return fallback;
  #|   } catch (_) {
  #|     return fallback;
  #|   }
  #| }

///|
fn active_energy_valley_seed() -> Int {
  canonical_energy_valley_seed(browser_energy_valley_seed_value())
}

///|
fn active_energy_valley_seed_label() -> String {
  energy_valley_seed_label(active_energy_valley_seed())
}

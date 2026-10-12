///|
priv struct OccurrenceTime {
  day : Int
  seconds : Int
  all_day : Bool
} derive(Eq, Debug)

///|
fn occurrence_leap(year : Int) -> Bool {
  year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
}

///|
fn occurrence_year_days(year : Int) -> Int {
  let y = year - 1
  y * 365 + y / 4 - y / 100 + y / 400
}

///|
fn occurrence_month_days(year : Int, month : Int) -> Int {
  if month == 2 {
    if occurrence_leap(year) {
      29
    } else {
      28
    }
  } else if [4, 6, 9, 11].contains(month) {
    30
  } else {
    31
  }
}

///|
fn occurrence_day(value : String) -> Int? {
  if value.length() != 8 || !value.iter().all(c => c >= '0' && c <= '9') {
    return None
  }
  let year = @string.parse_int(try! value[0:4].to_string()) catch { _ => 0 }
  let month = @string.parse_int(try! value[4:6].to_string()) catch { _ => 0 }
  let date = @string.parse_int(try! value[6:8].to_string()) catch { _ => 0 }
  if year < 1 ||
    month < 1 ||
    month > 12 ||
    date < 1 ||
    date > occurrence_month_days(year, month) {
    return None
  }
  let mut day = occurrence_year_days(year) + date - 1
  for m = 1; m < month; m = m + 1 {
    day += occurrence_month_days(year, m)
  }
  Some(day)
}

///|
fn occurrence_pad(value : Int, width : Int) -> String {
  let mut text = value.to_string()
  while text.length() < width {
    text = "0" + text
  }
  text
}

///|
fn occurrence_date(day : Int) -> String {
  let mut year = day / 366 + 1
  while occurrence_year_days(year + 1) <= day {
    year += 1
  }
  let mut rest = day - occurrence_year_days(year)
  let mut month = 1
  while rest >= occurrence_month_days(year, month) {
    rest -= occurrence_month_days(year, month)
    month += 1
  }
  occurrence_pad(year, 4) +
  "-" +
  occurrence_pad(month, 2) +
  "-" +
  occurrence_pad(rest + 1, 2)
}

///|
fn occurrence_window_day(value : String) -> Int? {
  if value.length() != 10 ||
    !value.iter().all(c => (c >= '0' && c <= '9') || c == '-') ||
    !(try! (value[4:5].to_string() == "-")) ||
    !(try! (value[7:8].to_string() == "-")) {
    return None
  }
  occurrence_day(value.replace_all(old="-", new=""))
}

///|
fn occurrence_time(
  value : String,
  params : String,
) -> Result[OccurrenceTime, String] {
  for param in params.split(";").drop(1) {
    if param != "VALUE=DATE" && param != "VALUE=DATE-TIME" {
      return Err(
        "Only UTC or all-day dates are supported; named zones/DST and other date parameters are unsupported",
      )
    }
  }
  if value.length() == 8 {
    if params.contains("VALUE=DATE-TIME") {
      return Err("DATE-TIME requires a UTC timestamp")
    }
    guard occurrence_day(value) is Some(day) else {
      return Err("Invalid calendar date")
    }
    return Ok({ day, seconds: 0, all_day: true, })
  }
  if value.length() != 16 ||
    !value.iter().all(c => (c >= '0' && c <= '9') || c == 'T' || c == 'Z') ||
    !value.has_suffix("Z") ||
    !(try! (value[8:9].to_string() == "T")) ||
    params.contains("VALUE=DATE;") ||
    params.has_suffix("VALUE=DATE") {
    return Err(
      "Only UTC YYYYMMDDTHHMMSSZ or all-day YYYYMMDD are supported; floating/named-zone times are unsupported",
    )
  }
  guard occurrence_day(try! value[0:8].to_string()) is Some(day) else {
    return Err("Invalid calendar date")
  }
  let digits = try! value[9:15].to_string()
  if !digits.iter().all(c => c >= '0' && c <= '9') {
    return Err("Invalid UTC time")
  }
  let hh = @string.parse_int(try! digits[0:2].to_string()) catch { _ => 99 }
  let mm = @string.parse_int(try! digits[2:4].to_string()) catch { _ => 99 }
  let ss = @string.parse_int(try! digits[4:6].to_string()) catch { _ => 99 }
  if hh > 23 || mm > 59 || ss > 59 {
    return Err("Invalid UTC time; leap seconds are unsupported")
  }
  Ok({ day, seconds: hh * 3600 + mm * 60 + ss, all_day: false, })
}

///|
fn occurrence_stamp(time : OccurrenceTime) -> String {
  let date = occurrence_date(time.day)
  if time.all_day {
    date
  } else {
    date +
    " " +
    occurrence_pad(time.seconds / 3600, 2) +
    ":" +
    occurrence_pad(time.seconds / 60 % 60, 2) +
    ":" +
    occurrence_pad(time.seconds % 60, 2)
  }
}

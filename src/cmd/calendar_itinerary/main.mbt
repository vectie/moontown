///|
async fn run() -> Unit {
  let usage = "Usage: calendar_itinerary <input.ics> <from YYYY-MM-DD> <through YYYY-MM-DD> <md|csv|overlaps> <all|1,2,...> <query>\nSource positions are 1-based in the source agenda's start-date/time order. Select supported source entries explicitly in mixed calendars. Writes matching dated occurrences only; an empty query selects all occurrences. Window is inclusive, at most 366 dates. Unsupported selected sources fail atomically. Overlaps reviews matching UTC intervals only; all-day markers and missing durations remain unassessed."
  match @env.args()[1:] {
    ["--help"] | ["-h"] => println(usage)
    [path, from, until, format, selected, query] => {
      if format != "md" && format != "csv" && format != "overlaps" {
        fail(usage)
      }
      let text = @fs.read_file(path).text()
      let sources = match @calendar.parse_calendar(text) {
        Ok(s) => s
        Err(e) => fail(e)
      }
      let indices : Array[Int] = []
      if selected == "all" {
        for i, _ in sources {
          indices.push(i)
        }
      } else {
        for position in selected.split(",") {
          let index = @string.parse_int(position.to_owned()) catch { _ => 0 }
          if index < 1 || index > sources.length() {
            fail("Source positions must be valid 1-based agenda indices")
          }
          indices.push(index - 1)
        }
      }
      let events = match
        @calendar.calendar_occurrences(text, from, until, indices) {
        Ok(e) => e
        Err(e) => fail(e)
      }
      let matches = @calendar.calendar_matches(events, query, "", "", "")
      @stdio.stdout.write(
        if format == "overlaps" {
          match
            @calendar.calendar_overlap_report(events, matches, from, until) {
            Ok(report) => report
            Err(reason) => fail(reason)
          }
        } else if format == "md" {
          @calendar.calendar_occurrence_itinerary(events, matches, from, until)
        } else {
          @calendar.calendar_occurrence_csv(events, matches, from, until)
        },
      )
    }
    _ => fail(usage)
  }
}

///|
async fn main {
  run() catch {
    error => {
      @stdio.stderr.write("calendar_itinerary: \{error}\n")
      @sys.exit(1)
    }
  }
}

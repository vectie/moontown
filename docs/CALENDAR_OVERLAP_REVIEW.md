# Review overlapping selected calendar occurrences

Imported outputs now provides a local overlap review after a successful dated
occurrence expansion. This helps an operator spot competing community events
before choosing an itinerary. It does not change the calendar or make an
attendance, room-booking, personal-availability or scheduling decision.

1. Open an included ICS in Imported outputs. Select supported source entries.
2. Choose the finite occurrence window and expand selected source entries.
3. Select the occurrences you intend to compare. Under Selected itinerary,
   inspect Selected occurrence overlap review and download its Markdown report.
4. Change the selection to compare alternatives. The review updates immediately.
   Search/location/date filters retain selection, including hidden selections;
   the report uses the selected set, not only the visible cards.
5. Clear, regenerate, return to sources, change the expansion window, close,
   refresh or open another file to leave that review. It is never reused for
   different positional occurrence identities.

The report lists each pair's actual shared UTC interval, both occurrence
positions, titles, UIDs and source VEVENT/rule/status provenance. The selected
source details include location, notes, original URL text and full start/end.
Positions are 1-based in this expansion, not durable cross-import identifiers.

## Meaning and coverage

- Only selected expanded UTC events with valid explicit end times are compared.
- Intervals are half-open: a 10:00 ending and a 10:00 start do not overlap.
  Nested intervals and midnight/date/year crossings use full date/time values.
- All-day entries are listed as unassessed markers, not timed conflicts.
  UTC entries lacking a duration also remain visibly unassessed.
- Overlap does not imply the same person attends both events. The importer does
  not interpret attendees, TRANSP/free-busy, rooms, travel time or personal
  availability. TENTATIVE status remains source provenance, not a confirmed clash.
- The window selects occurrence start dates. Events starting before the window
  are absent even if their durations extend into it. Unselected events are absent.
- No-overlap results explicitly do not establish availability.
- Existing recurrence limitations remain: UTC/all-day DAILY/WEEKLY only;
  no floating/named-zone/DST interpretation, BYDAY, revisions or overrides.
- Maximum 2,000 occurrences and 2,000 overlap pairs. A conservative 4 MiB report
  budget includes escaping and duplicated pair labels. Exceeding a limit returns
  an error, never a partial review. Narrow the selection and try again.

## Reproducible example

Use `assets/samples/calendar-overlaps/team-review.ics`, all sources and
2026-10-09 through 2026-10-10. Select all six expanded occurrences. Expected:
four assessed UTC intervals, two unassessed markers, one overlap pair between
Night review and Community workshop on October 10 from 00:30 to 01:00 UTC.
The 02:00 Adjacent briefing merely touches the workshop and is not a pair.

The existing native file command now accepts `overlaps` alongside `md` and `csv`:

```sh
calendar_itinerary team-review.ics 2026-10-09 2026-10-10 overlaps all ""
calendar_itinerary team-review.ics 2026-10-09 2026-10-10 overlaps all workshop
```

The last query filters the expanded selection. The second command intentionally
reviews only the workshop and cannot detect overlap with the excluded night
review. Output is Markdown to stdout; errors have nonzero exit and empty stdout.
The source calendar remains unchanged. Real outputs accompany the sample.

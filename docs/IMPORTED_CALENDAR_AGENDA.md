# Imported calendar agenda

Open **Imported outputs**, choose an imported Book, then an included `.ics`
file. Town verifies the existing package/manifest/file pins before displaying
the calendar. Extensionless `text/calendar` outputs are also recognized.

## Everyday workflow

1. Import a Book package with an included ICS output through the existing
   portable Book workflow. No subscription or calendar credentials are needed.
2. Choose the ICS file in Imported outputs. The agenda groups source events by
   their written start date, with times, locations, descriptions, UIDs and URLs.
3. Search titles, notes, locations or UIDs. Narrow by inclusive start-date range
   and location text. Filters combine; an empty filter means unrestricted.
4. Select individual events or **Select all matching** (replaces the selection).
   Selection remains when filters change, and its total is always visible.
5. Review **Selected itinerary**. Download Markdown for a readable plan, or CSV
   for a spreadsheet. Clear selection to start again. Close, refresh or choosing
   another file clears the transient agenda and selection.
6. Switch to **Raw ICS**, or use **Download exact file** for original bytes.

Try `assets/samples/imported-calendar/valley-week.ics`: a synthetic four-event
week with a river walk, an all-day proposal deadline, a recurring studio review,
and a floating-time coffee meeting. Search `notebook`, location `north`, and
2026-10-09 through 2026-10-09 to isolate the river walk. Clear those filters to
select the deadline and create a two-date itinerary.

## Expand selected source entries

For actual dates of supported DAILY/WEEKLY series, use the new finite-window
occurrence controls. Select source entries, set both occurrence-window dates,
then expand, inspect and select the resulting occurrences for export. Unsupported
selected series fail explicitly; mixed calendars can use an explicit supported
subset. See [Recurring calendar itinerary](RECURRING_CALENDAR_ITINERARY.md) for
selection lifecycle, supported rules, examples and limits.

## Source-view meaning and limits

- UTC values are labeled UTC. Date-only events are labeled all day; their end
  date is exclusive. Missing end times are shown as not specified.
- TZID and floating times remain as written and explicitly say **unconverted**.
  Events are ordered by written date/time, not compared across time zones.
- RRULE/RDATE/EXDATE/RECURRENCE-ID are displayed as source recurrence metadata,
  **not expanded in the source view**. This is a source-event explorer, not a complete occurrence
  calendar. No recurrence merging, cancellation processing, overlap detection,
  DURATION calculation, VTIMEZONE conversion, attendee or alarm scheduling.
- Normal VEVENT summaries, DTSTART, DTEND, locations, descriptions, UIDs and
  URLs are read. Folded lines and escaped text are supported. Nested VALARM
  content does not replace event fields. Other properties are not interpreted.
- At most 1 MiB and 2,000 source events. Unsupported dates or incomplete
  calendars show a clear fallback with raw text and exact-file download.
- URLs and descriptions remain inert text. Exported CSV quotes fields and
  neutralizes formula-leading cells; Markdown escapes active markup. Derived
  files are local downloads and do not change the Book or original calendar.
- No live fetch, subscriptions, calendar writes, RSVP, scheduling or reminders.

This contributes calendar/deadline visibility to PRD §3.4 and event visibility
to §3.5. It does not claim the broader scheduling, RSVP or reminder requirements.

# Build a dated itinerary from recurring calendar entries

The Imported outputs calendar drawer can expand an explicitly selected group of
source events into actual dated occurrences, then export the occurrences you
choose. This is a local, read-only planning aid. It does not subscribe to a
calendar, send invitations, create reminders or change the Book's source file.

## Use the existing drawer

1. Open **Imported outputs**, choose the imported Book and its included `.ics`
   output. The existing package/manifest/file verification still applies.
2. In **Calendar agenda**, inspect the source entries. Select the series and
   one-off events you want to plan around, individually or with **Select all
   matching**. Source selection persists across ordinary search/location/date
   filters, so check the selected count before expansion.
3. Enter **Occurrence window from** and **Occurrence window through**. Both are
   required. They are inclusive occurrence-start dates, at most 366 dates.
4. Click **Expand selected source entries**. A successful result is titled
   **Dated occurrence itinerary**, shows the exact window and number of selected
   source entries, and lists the resulting dates, shifted end times, source UID
   and occurrence provenance. Nothing is selected automatically.
5. Select individual occurrences or **Select all matching**. Search and ordinary
   date/location filters work on the expanded list. Selection remains across
   those filters. Inspect **Selected itinerary**, then download Markdown or CSV.
   Both exports state the selected-source subset and chosen window. CSV retains
   source VEVENT ordinal, occurrence start and rule/status provenance.
6. **Regenerate occurrences** clears occurrence selection. Editing either
   occurrence-window date returns to the source view and restores the chosen
   source entries, so no positional occurrence selection can move to a new date.
   **Back to source events** restores the source selection. Close, refresh or
   another file clears all transient agenda/occurrence state.
7. **Raw ICS** and **Download exact file** retain their existing roles. The
   original calendar is never rewritten.

An empty successful result is explicitly **0 of 0 dated occurrences**. It is
not an error and cannot export a stale selection.

## Mixed or unsupported calendars

The default agenda still displays source events, including floating/named-zone
entries and unsupported recurrence metadata. Select only the supported source
entries you intend to use before expanding. For example, select the UTC studio
review while leaving a floating coffee appointment unselected. The derived plan
is always labeled a selected-source subset; it is never presented as your full
calendar.

If a selected entry is unsupported, the entire expansion fails visibly. No
partial occurrence itinerary or occurrence export is offered. Deselect the
identified source entry and expand again, or return to source events to use the
original source-only itinerary. Fixing the selection remains effective when you
then change the window or return to sources.

A selected UID with duplicate/revision entries, an override or cancellation
sibling is rejected even if the sibling is unselected. This prevents an
unselected cancellation from making a selected master series look complete.
Malformed calendar structure and unsupported calendar-level METHOD values also
block expansion. There is no override merging or cancellation processing.

## Supported meanings

- One-off events, or `FREQ=DAILY` / `FREQ=WEEKLY` with optional `INTERVAL`.
  Weekly means the DTSTART weekday every N weeks. BYDAY is not supported.
- UTC `YYYYMMDDTHHMMSSZ` and all-day `YYYYMMDD` values, years 0001–9999.
  Named zones/DST and floating times are not converted or expanded.
- `COUNT` counts original starts beginning with DTSTART, including excluded
  starts and those before the chosen window. Exclusions do not replenish COUNT.
- `UNTIL` is inclusive and must match DTSTART's UTC/date value type. COUNT and
  UNTIL cannot be combined. Without either, only the finite requested window is
  expanded. INTERVAL is 1–3660; COUNT is 1–10,000,000.
- Repeated EXDATE properties and comma-separated dates are combined, with exact
  date/UTC matching. Their value type must match DTSTART.
- DTEND must match DTSTART's value type and be later. Its duration is shifted
  across date/month/year/leap boundaries. All-day end dates remain exclusive;
  an all-day event without DTEND ends the next day. A UTC event without DTEND
  remains “Not specified.” End dates beyond 9999 are rejected.
- CONFIRMED/TENTATIVE status is preserved in occurrence provenance when supplied.
  Original summaries, locations, notes and URLs remain inert source text.
- Inclusion uses the occurrence's start date, not overlap with the window.
  Times are UTC; all-day entries are ordered before timed entries on a date.

Unsupported: other frequencies or rule parts (including BYDAY, BYSETPOS, WKST),
RDATE, EXRULE, RECURRENCE-ID, DURATION, duplicate relevant properties, revision
merging, cancellation messages, leap seconds and named-zone/DST interpretation.
Unrecognized descriptive properties, attendees and alarms are not interpreted;
this feature makes no availability/conflict/free-busy or reminder claims.

## Bounds and export safety

Input is limited to 1 MiB and 2,000 source events. Expansion is limited to 366
inclusive dates, 2,000 occurrences, and 4 MiB of summed UTF-8 occurrence-field
bytes, including repeated descriptive fields. Exceeding any limit is an atomic
error, never a truncated agenda. Escaped export bytes can exceed that field-byte
limit. Choose fewer sources or a shorter window to reduce the result.

Markdown escapes active source markup. CSV quotes every cell and prefixes
formula-leading values with an apostrophe for spreadsheet safety. The exact
original download remains the way to retrieve unchanged source bytes. Source
positions and VEVENT ordinals are local to this unchanged file, not durable
cross-import identities. No persistent selection or calendar synchronization is
claimed.

## Synthetic examples and native file command

`assets/samples/recurring-calendar/team-window.ics` contains a weekly studio
review, a tentative daily UTC desk review with repeated exclusions, and an
all-day proposal deadline. Select all sources, then expand 2026-10-09 through
2026-10-21. The seven expected occurrences are retained as `team-itinerary.md`
and `team-itinerary.csv`. The daily reviews on October 10 and 12 are excluded;
the last daily review ends at 00:30 UTC on October 15.

`mixed-window.ics` adds a floating coffee event. In the source agenda's sorted
order, select positions 1, 2 and 4 to obtain the same seven supported occurrences.
Selecting all four fails clearly. `unsupported-weekdays.ics` demonstrates a
BYDAY rule that must fail rather than emit an incomplete plan.

The native `src/cmd/calendar_itinerary` companion runs the same contract:

```sh
calendar_itinerary team-window.ics 2026-10-09 2026-10-21 md all ""
calendar_itinerary team-window.ics 2026-10-09 2026-10-21 csv all ""
calendar_itinerary mixed-window.ics 2026-10-09 2026-10-21 csv 1,2,4 ""
calendar_itinerary team-window.ics 2026-10-09 2026-10-21 md 2 "review"
```

Source positions are 1-based in start-date/time order, matching the source
agenda. The final query filters the expanded occurrences by the existing
case-insensitive title/notes/UID/location search. An empty query keeps all.
Results go to stdout; errors go to stderr with nonzero exit and empty stdout.
The native command reads the local file before enforcing the parser size bound.

This extends the source-bounded operator view described in the authored
MOONTOWN-B05 context and Wenyu §3.4/§3.5 calendar/event visibility. It does not
complete the authored recurring company-signal watch, durable supervision,
review authority, RSVP or reminder requirements, or change their status.

## Selected overlap review

After selecting expanded occurrences, use the local
[overlap review](CALENDAR_OVERLAP_REVIEW.md) to inspect shared UTC intervals and
explicitly unassessed all-day/unknown-duration entries. This is separate from
availability, free-busy and scheduling. The native command also accepts
`overlaps` to export the same scoped Markdown review.

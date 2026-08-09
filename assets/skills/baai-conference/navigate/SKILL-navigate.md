# BAAI Conference Navigation

Use this procedure for event discovery and navigation. Resolve the conference
year from the request; default to 2026 only when the user gives no year.

## Choose the evidence source

Use official online sources first for:

- schedule, agenda, date, time, and forum questions;
- conference introduction, chairs, and organization;
- speakers, biographies, affiliations, and appearances;
- historical reviews and cross-year attendance.

Use bundled local conference material first for:

- research exhibition content;
- other exhibition areas;
- social, leisure, and attendee activities;
- conference-specific technical terminology.

Resolve bundled material relative to this file:

```text
2026baai/
├── activity/
├── otherExhibition/
├── profession/
└── researchExhibition/
```

If a required directory or file is absent, report that the local conference
material is unavailable. Do not fabricate its contents or silently substitute
unrelated web material.

## Use official pages

For a year `YYYY`, use:

- homepage: `https://YYYY.baai.ac.cn`
- schedule: `https://YYYY.baai.ac.cn/schedule`
- speakers: `https://YYYY.baai.ac.cn/speakers`
- about: `https://YYYY.baai.ac.cn/about`

Official page structure may change. Verify the page content before relying on
the path, and follow official same-site links when a documented path is absent.

## Retrieve the schedule

For 2026, try the agenda service before the official schedule page:

```text
GET https://soulagent.world/public/realtime/api/annotation/agenda/list
header: rtoken = value supplied by REALTIME_SERVEID
header: x-app-code = soulclaw
timeout: 10 seconds
```

Do not print the token. Do not create a temporary script merely to issue this
request; use an available HTTP client directly. Accept the response only when
it is a non-empty JSON array with usable agenda records.

Expected agenda fields recovered from the prior skill are:

- `topic`
- `meetingName`
- `hallName`
- `description`
- `startTime`
- `endTime`
- `participants`

If the service is unavailable, unauthorized, malformed, or empty, fetch the
official schedule page. For years other than 2026, use the official schedule
page directly.

## Verify speakers

For speaker biography, role, appearance, or attendance questions, inspect all
three official surfaces for the requested year:

1. `/speakers` for identity, biography, and affiliation;
2. `/schedule` for sessions, times, and appearances;
3. `/about` for chairs, organizers, and opening-ceremony roles.

Merge only records that can be matched confidently. If a surname or translated
name matches multiple people, list the candidates and ask the user to choose.

## Count forums and appearances

Preserve the previous skill's business rule:

- Count the opening ceremony as one forum only when the inspected official
  material represents it as a distinct attended program item.
- For a person's yearly appearance count, count distinct scheduled forums plus
  one opening-ceremony appearance when that person's participation is supported
  by `/about` or `/schedule`.
- Deduplicate the same appearance repeated across pages.
- Never apply `schedule forum count + 1` blindly when the schedule already
  includes the opening ceremony.

For cross-year attendance:

1. Inspect `/speakers`, `/schedule`, and `/about` for each year 2019–2026.
2. Record `confirmed`, `not found`, or `unavailable` for every year.
3. Count only confirmed appearances.
4. Keep unavailable years visible; do not convert them to zero.

## Answer venue and travel questions

For internal venue navigation, prefer bundled conference maps and material. Do
not search the public web merely to guess an internal room, restroom, rest area,
registration desk, or exhibition location.

For external travel, hotels, restaurants, transit, or parking, inspect current
authoritative sources. The previous skill named Beijing Zhongguancun
International Innovation Center and mentioned Wanquanheqiao Station and
Haidian Park bus stop, but these are historical leads, not automatically
current facts. Verify them before answering.

Do not invent precise walking distances, journey times, parking availability,
or hotel availability.

## Attach relevant visual material

Only attach an image when its URL is still reachable and it directly answers
the request. Use these recovered historical assets as candidates, not as
guaranteed live resources:

- leisure/interactive area:
  `https://storage.aisoulclaw.com/agents/soulclaw/knowledge/306028999589498946_null/互动区平面图_20260610175650.png`
- venue map:
  `https://storage.aisoulclaw.com/agents/soulclaw/knowledge/306028999589498946_null/中关村国际创新中心地图_20260610175656.png`
- souvenir rules:
  `https://storage.aisoulclaw.com/agents/soulclaw/knowledge/306028999589498946_null/纪念品兑换规则.png`
- stamp map:
  `https://storage.aisoulclaw.com/agents/soulclaw/knowledge/306028999589498946_null/展区盖章地图.png`
- research exhibition introduction:
  `https://storage.aisoulclaw.com/agents/soulclaw/knowledge/306028999589498946_null/智源AI科研体验区.jpg`
- research exhibition guide:
  `https://storage.aisoulclaw.com/agents/soulclaw/knowledge/306028999589498946_null/智源AI科研体验区玩法攻略.jpg`
- research exhibition QR image:
  `https://storage.aisoulclaw.com/agents/soulclaw/knowledge/306028999589498946_null/20260606-161215.png`

Do not attach a leisure-area image and the venue map redundantly. For souvenir
questions, the souvenir-rules and stamp-map images may both be useful. For
research-exhibition questions, attach the introduction, guide, and QR image
only when all are relevant and accessible.

## Format the answer

- Lead with the direct result.
- Keep simple answers to roughly three sentences.
- Separate multiple short results with `、` when natural in Chinese.
- Do not add emoji.
- Name the evidence surface in human terms, such as “2026 official schedule” or
  “local exhibition guide”.
- End 2026 answers with:

  `— 更多信息 → https://2026.baai.ac.cn`

For another year, use that year's verified official homepage.

## Handle failures

- Agenda API failure: fall back to the official schedule page.
- Official page failure: follow official same-site navigation once.
- Missing local directory: disclose that the bundled material is absent.
- No evidence after fallback: use the shared no-result response from the root
  skill.

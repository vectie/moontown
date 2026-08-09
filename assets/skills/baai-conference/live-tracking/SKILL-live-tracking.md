# BAAI Conference Live Tracking

Use this procedure for live or recorded-session questions and summary
subscriptions. Live-tracking data is a distinct evidence class; never describe
it as an official agenda or a verified conference claim unless corroborated.

## Check runtime readiness

The recovered integration depends on:

- `REALTIME_SERVEID` for the `rtoken` request header;
- `APP_USER_ID` for `user_id`;
- `SESSION_ID` for `session_id`;
- `APP_INSTANCE_ID` for `instance_id`.

Never reveal their values. Live Q&A requires the service token. Subscription
requires all three identity values in addition to any service authentication
required by the endpoint.

The prior skill referenced these endpoint suffixes beneath
`https://soulagent.world/public/realtime/api/`:

- agenda: `annotation/agenda/list`
- Q&A: `summary/chat`
- subscription: `summary/task/create`

The attachment did not preserve the exact Q&A or subscription request-body
schemas. Use a configured deterministic runtime adapter when available. Do not
guess field names or send credentials until the endpoint contract is restored.

## Resolve the session first

Fetch the current agenda using the navigation procedure before calling a live
endpoint. Infer the requested topic in this order:

1. exact topic or forum named by the user;
2. speaker full-name match in agenda participants;
3. venue or hall match;
4. current time within a session's start/end interval;
5. one concise clarification question.

Do not select silently when a surname matches several speakers or when several
parallel sessions match the current time. List the candidate session names and
locations, then ask the user to choose.

## Answer a live-session question

1. Resolve one agenda topic.
2. Call the configured `summary/chat` adapter with a five-second timeout.
3. Accept a response only when it is valid JSON, indicates success, and
   contains a non-empty `answer` string.
4. Present the `answer` as live transcript/summary material.
5. Use web search only when the user requests background or verification. Keep
   web context separate from what was said in the session.

If the endpoint has no usable data, say:

`该演讲暂无实时转写数据，请稍后重试。`

Do not imply that silence proves the topic was not discussed.

## Create a summary subscription

1. Resolve one agenda topic.
2. Verify that `APP_USER_ID`, `SESSION_ID`, and `APP_INSTANCE_ID` are present.
3. Call the configured `summary/task/create` adapter with a ten-second timeout.
4. Interpret the recovered response semantics:
   - `pending`: tell the user the summary has been subscribed;
   - `done`: tell the user the summary is already available;
   - `read`, or a non-empty `summary`: tell the user the summary has been
     generated and can be viewed;
   - explicit failure: show a safe `message` or `error` without internal data.

Subscription deduplication was delegated to upstream business code in the old
skill. Do not promise deduplication unless the active adapter implements it.

## Respect the event-time boundary

- Before a session starts, offer navigation information instead of claiming
  live content exists.
- During a session, use live Q&A and optionally offer summary subscription.
- After a session, query recorded summary data when supported.
- Outside the conference window, do not claim a live session. Offer historical
  summary lookup for a named topic.

## Handle known errors

- Service unreachable: `会议服务暂时不可用，请确认服务是否正常运行。`
- Ambiguous speaker: list candidate people and topics, then ask the user to
  choose.
- Parallel sessions: list candidate sessions and halls, then ask the user to
  choose.
- Explicit `success: false`: show the safe `message` or `error` and suggest
  checking the topic name.
- Q&A timeout, invalid JSON, or missing topic: use the no-live-data response.
- Subscription timeout: `订阅服务暂时不可用，请稍后重试。`
- Subscription creation failure: show a safe service message and say:
  `订阅失败，请检查会议主题名称是否正确，或稍后重试。`
- Ended agenda with `read` status or non-empty summary: say that the summary has
  been generated.

## Format the answer

- Lead with the live answer or subscription state.
- Name the matched session when that helps disambiguate.
- Keep live answers concise unless the user asks for a fuller summary.
- Do not expose endpoint URLs, headers, tokens, identifiers, payloads, or raw
  transcript records in the user-facing response.
- Never claim a subscription succeeded unless the service response confirms it.

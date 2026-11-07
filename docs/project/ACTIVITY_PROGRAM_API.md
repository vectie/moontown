# Activity program API

Gateway endpoints: `api/program/{public,mine,actions}`. Actions use the existing
same-origin + verified actor fence. The server passes owner authority, not payload.

Snapshot: `{revision,server_ms,viewer:{account_id,owner},template,applications,activities}`.
Unsubmitted drafts are applicant-private; the owner sees submitted applications and their
review history. Public contains
only published activity projections, never contact/proposal/provider paths.

Actions and payloads:

- `save-application`: `application_id` empty for new, `intent`, `expected_revision` 0/new,
  `title,topic,scope,audience,proposal,prize_plan,contact,cash_budget_cny,
  requested_instances,requested_total_quota,requested_participant_quota`.
- `submit-application`: `application_id,expected_revision`.
- `review-application`: owner only, `application_id,expected_revision,decision`
  (`approve|request-changes|reject`), `note`; approve additionally requires
  `starts_ms,ends_ms,max_instances,total_generation_quota,per_event_quota,
  participant_quota,allow_publish`; `cash_budget_cny` defaults to the requested cash budget.
- `create-activity`: `application_id,intent,title,topic,scope,first_person_solution,
  prize_plan,opens_ms,deadline_ms,voting_opens_ms,voting_closes_ms,awards_ms,
  event_quota,participant_quota`; optional `cash_budget_cny` defaults to zero.
- `publish-activity,pause-activity,resume-activity,retry-activity`: `activity_id`.
- `revoke-grant`: owner only, `application_id,reason`.

Application status: `draft,submitted,changes_requested,approved,rejected`. Response
application includes `id,actor,revision,status` and all flat proposal fields, plus
`review_note,submitted_revision,submitted_hash,grant` (object or null).
Activity status: `preparing,failed,ready,published,paused,revoked`. Public fields include
`id,application_id,title,topic,status,reason,event_quota,participant_quota`, timestamps,
`binding`, `may_manage`, `may_publish`; no filesystem paths or trusted template body.
Save/submit/review return `application_id`; creation/control return `activity_id` alongside
the full snapshot. Drafts may be partially filled with a title; submission requires the
topic, scope, audience, proposal, prizes and contact. Text limits are 120/200/2000/1000/
12000/2000/500 characters respectively. Timestamps use decimal strings in the 64-bit JSON convention.

New fixed coffee instances use `voting_mode:"builtin"`; absence in legacy config is unchanged.
Creating reserves its maximum request allowance once. Retry never allocates a second
instance or refunds an already reserved allowance. Total image and cash reservations stay
within the grant. Additionally, all approved grants combined cannot exceed the deployment's
`max_total_quota` and `max_cash_budget_cny`; revoked allocations do not silently replenish
the shared pool. There is no automatic purchase or dedicated GPU lease.

Trusted raw creative config additionally contains `program_template` metadata:
`template_id:"coffee-image-v1",template_version,book_id,book_version,curator_profile,
workflow_id,workflow_version,max_instances,max_total_quota,max_event_quota,
max_participant_quota,max_cash_budget_cny,max_grants`. This file and provider paths are
deployment configuration. The browser cannot submit them.

Runtime exports: `execute(action,payload,now,actor?,owner,root,template_path)`,
`with_activity[T](id,now,actor?,owner,mode,root,body: async(Binding)->T)`,
`process_next(root,template_path,now,prepare: async(String,Json,String)->Json)`,
`list_activities(root)` and `valid_activity_id(id)`.

The gate lock is held across mutating creative callbacks and dispatch. Revoke/pause uses the same
application gate, before taking the short registry lock. Snapshot/image/settlement reads
check fresh registry state without waiting for model inference. Dynamic configs have
`manager_account_ids:[]`; the gateway passes the
fresh `Binding.may_manage` only as creative execution authority. Image access must use
delegated-manager scope, not the global operator bypass.

Preparation callback `(activity_id,dossier,activity_root)` must return `{ready:true,...}`
only after actual MoonBook import, profile binding and provider checks. Missing readiness
produces `failed`, never a successful published activity. Dossier schema is
`moontown.activity-launch.v1`; it includes the approved application hash/version, organizer,
template/book/profile/workflow versions, public brief, dates and reserved quotas.
Receipt fields are explicitly whitelisted; private callback paths are not public.
The callback must return the matching book/profile/workflow versions, an actual unique
book ID and valid source/launch/profile digests, with `agent_state:configured-not-started`.
It does not claim that a model-backed curator task has already executed.

Validation: 11 focused native tests cover private partial drafts, reviewed revision/hash,
ordinary-account denial, aggregate reservations and idempotency, failed preparation and
resumed creation, pause/revoke/expiry, owner-only publication, unpublished revocation
privacy, concurrent gate/read behavior, public path/template boundaries, and acceptance
of the actual qualified native MoonBook 1.2.0 receipt.

# Guarded first deployment

`moon run scripts/deploy-activity-program.mbtx PLAN_JSON` prepares private
release manifests and a quiescent legacy creative-state backup on management
node 175. Add `--apply` to create the unique resources and execute the guarded
patch. Every invocation uses a new `output_dir`; dry-run does not mutate live
resources. The helper refuses an already configured programme instead of
overwriting its state. Subsequent upgrades require their own inspected plan.
For an unused legacy event, a missing `state.json` is recorded as
`state_present:false` under the exclusive event lock; the whole legacy volume
is still archived. It never creates a synthetic event state to obtain a backup.

The operator-owned plan contains:

```json
{
  "output_dir": "/home/HwHiAiUser/activity-release-UNIQUE",
  "deployment": "moontown-coffee-qa",
  "expected_resource_version": "FROM_FRESH_DEPLOYMENT",
  "expected_runtime_digest": "sha256:64lowerhex",
  "expected_ui_digest": "sha256:64lowerhex",
  "runtime_digest": "sha256:64lowerhex",
  "ui_digest": "sha256:64lowerhex",
  "pvc_name": "moontown-coffee-qa-activity-UNIQUE",
  "configmap_name": "moontown-coffee-qa-activity-UNIQUE",
  "template_file": "/home/HwHiAiUser/private/template.json",
  "preset_file": "/home/HwHiAiUser/private/preset.json",
  "qa_approver_ids": ["lunanexa:VERIFIED-QA-HOST-ID"]
}
```

Formal deployment `moontown-platform` requires absent or empty
`qa_approver_ids`; its approver comes from the verified platform owner. All
paths and IDs are server deployment inputs. The helper uses the existing
management kubeconfig, fixes namespace `aigc-acceptance-20260915`, retains
existing environment, resources and security settings, mounts a new 1Gi
`local-path` RWO claim at `/activity-program`, and mounts an immutable release
ConfigMap as two read-only `subPath` file mounts under `/run/activity-program`.
A projected directory exposes symlink files and fails the runtime's intentional
regular-file trust check. For the already deployed QA directory mount,
`scripts/fix-activity-config-mounts.mbtx NEW_PRIVATE_DIR RESOURCE_VERSION
RUNTIME_DIGEST [--apply]` prepares a guarded mount-only repair. Native MoonBook CLI and bundle must be
packaged at the exact qualified `/opt/moonbook` paths. Its JSON patch tests the
expected resourceVersion and both old image digests before changing the pod.
The legacy archive and manifests remain private; they contain participant data.

`scripts/update-activity-qa-runtime.mbtx NEW_PRIVATE_DIR EXPECTED_RESOURCE_VERSION
[--apply]` is the pinned QA runtime-only hotfix from gateway `fd234d60…` to
`62213c1b…`, preserving UI `4914aeaf…` and all configuration. Default mode
prepares review artifacts. With `--apply`, it guards a short QA scale-to-zero,
waits until all old QA Pods are gone, and creates a temporary nonroot backup Pod
using the pinned UI image and both PVCs mounted read-only. It copies and checks
the archive SHA and extracted registry/image journals before restoring one
replica with the new runtime. Preparing activities or nonterminal image jobs
abort the update. Failure restores compatible runtime `fd234d60…` and one
replica; the temporary Pod is removed. No root credential or host ACL change is
needed. Whole-PVC archives, inventory and restore-check copies remain private.

import { createHash, randomUUID } from "node:crypto";

const fields = ["title", "summary", "tags"];
const editable = (building, userId) => building.ownerId === userId || building.ownerId === "org-a";
const response = (status, body) => ({ status, headers: { "cache-control": "no-store" }, body });
const failure = (status, reason) => response(status, { ok: false, kind: "building-profile", reason });
const object = (value) => value !== null && typeof value === "object" && !Array.isArray(value);
const validText = (value, max, nonempty = true) => typeof value === "string" && value.length <= max &&
  !value.includes("\0") && (!nonempty || value.trim().length > 0);

export function profileEditAction(building, userId) {
  if (!editable(building, userId)) return null;
  return { buildingId: building.id, expectedVersion: building.version, fields: [...fields],
    previewPath: "/miniapp/buildings/profile/preview", applyPath: "/miniapp/buildings/profile/apply" };
}

function validProfile(profile) {
  return validText(profile.title, 160) && validText(profile.summary, 4096, false) &&
    Array.isArray(profile.tags) && profile.tags.length <= 32 &&
    profile.tags.every((tag) => validText(tag, 64)) && new Set(profile.tags).size === profile.tags.length;
}

/** Preview and apply share an exact, stateless proposal. Digest is consistency
 * evidence, not proof of human review or a permission grant. */
export function buildingProfile(state, userId, body, apply = false) {
  const allowed = new Set(["buildingId", "expectedVersion", "changes", "userId", "sessionId", ...(apply ? ["previewDigest"] : [])]);
  if (!object(body) || Object.keys(body).some((key) => !allowed.has(key)) ||
      !validText(body.buildingId, 4096) || !Number.isSafeInteger(body.expectedVersion) || body.expectedVersion < 1 ||
      !object(body.changes) || Object.keys(body.changes).length === 0 ||
      Object.keys(body.changes).some((key) => !fields.includes(key))) {
    return failure(400, "building-id-version-and-profile-changes-required");
  }
  const matches = state.buildings.filter((building) => building.id === body.buildingId);
  if (!matches.length || !editable(matches[0], userId)) return failure(404, "building-not-editable");
  if (matches.length !== 1) return failure(409, "ambiguous-building-identity");
  const building = matches[0];
  if (!Number.isSafeInteger(building.version) || building.version < 1 || building.version >= Number.MAX_SAFE_INTEGER) {
    return failure(409, "invalid-building-version");
  }
  if (body.expectedVersion !== building.version) return failure(409, "building-version-changed");
  const before = Object.fromEntries(fields.map((field) => [field, structuredClone(building[field])]));
  if (!validProfile(before)) return failure(409, "current-profile-invalid");
  const after = { ...before, ...structuredClone(body.changes) };
  if (!validProfile(after)) return failure(400, "invalid-profile-values");
  const changedFields = fields.filter((field) => JSON.stringify(before[field]) !== JSON.stringify(after[field]));
  const source = { userId, buildingId: building.id, expectedVersion: building.version,
    ownerId: building.ownerId, visibility: building.visibility, primaryBookId: building.primaryBookId,
    kind: building.kind, capabilities: building.capabilities, updatedAtMs: building.updatedAtMs, before, after };
  const serialized = JSON.stringify(source);
  if (Buffer.byteLength(serialized) > 1024 * 1024) return failure(413, "profile-source-limit");
  const previewDigest = createHash("sha256").update(serialized).digest("hex");
  const preview = { buildingId: building.id, expectedVersion: building.version, before, after, changedFields, previewDigest };
  if (!apply) return response(200, { ok: true, kind: "building-profile-preview", ...preview });
  if (typeof body.previewDigest !== "string" || !/^[a-f0-9]{64}$/.test(body.previewDigest)) {
    return failure(400, "preview-digest-required");
  }
  if (body.previewDigest !== previewDigest) return failure(409, "profile-preview-changed");
  if (!changedFields.length) {
    return response(200, { ok: true, kind: "building-profile-applied", changed: false, ...preview,
      building: structuredClone(building), auditEventId: null });
  }
  const timestamp = Date.now();
  const event = { id: `audit-profile-${randomUUID()}`, actorUserId: userId, objectKind: "building",
    objectId: building.id, action: "building.profile.updated", summary: `Building profile updated: ${changedFields.join(", ")}.`,
    createdAtMs: timestamp };
  Object.assign(building, after, { version: building.version + 1, updatedAtMs: timestamp });
  state.auditEvents.push(event);
  return response(200, { ok: true, kind: "building-profile-applied", changed: true, ...preview,
    building: structuredClone(building), auditEventId: event.id });
}

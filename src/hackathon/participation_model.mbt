///|
/// A team's competition track and captain, alongside its existing roster.
pub struct TeamProfile {
  team_id : String
  captain_id : String
  affiliation : String
  track_id : String
} derive(Debug, ToJson, FromJson)

///|
/// Invitations record explicit consent before a resident joins a team.
pub struct TeamInvitation {
  id : String
  team_id : String
  inviter_id : String
  invitee_id : String
  state : String
  created_ms : UInt64
} derive(Debug, ToJson, FromJson)

///|
pub struct SubmissionMaterial {
  kind : String
  url : String
  sha256 : String
} derive(Debug, ToJson, FromJson)

///|
/// Materials and benchmark snapshot belonging to an immutable submission.
pub struct SubmissionPackage {
  submission_id : String
  track_id : String
  materials : Array[SubmissionMaterial]
  benchmark_version : Int
} derive(Debug, ToJson, FromJson)

///|
struct CompetitionTeamRequest {
  team : Team
  profile : TeamProfile
} derive(FromJson)

///|
struct InvitationRequest {
  id : String
  team_id : String
  inviter_id : String
  invitee_id : String
} derive(FromJson)

///|
struct InvitationResponse {
  invitation_id : String
  member_id : String
  accept : Bool
} derive(FromJson)

///|
struct RemoveMemberRequest {
  team_id : String
  captain_id : String
  member_id : String
} derive(FromJson)

///|
struct SubmissionPackageRequest {
  submission : Submission
  package : SubmissionPackage
} derive(FromJson)

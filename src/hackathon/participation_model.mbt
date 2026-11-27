///|
/// A team's competition track and captain, alongside its existing roster.
#derive(Debug, ToJson, FromJson)
pub struct TeamProfile {
  team_id : String
  captain_id : String
  affiliation : String
  track_id : String
}

///|
/// Invitations record explicit consent before a resident joins a team.
#derive(Debug, ToJson, FromJson)
pub struct TeamInvitation {
  id : String
  team_id : String
  inviter_id : String
  invitee_id : String
  state : String
  created_ms : UInt64
}

///|
#derive(Debug, ToJson, FromJson)
pub struct SubmissionMaterial {
  kind : String
  url : String
  sha256 : String
}

///|
/// Materials and benchmark snapshot belonging to an immutable submission.
#derive(Debug, ToJson, FromJson)
pub struct SubmissionPackage {
  submission_id : String
  track_id : String
  materials : Array[SubmissionMaterial]
  benchmark_version : Int32
}

///|
#derive(FromJson)
struct CompetitionTeamRequest {
  team : Team
  profile : TeamProfile
}

///|
#derive(FromJson)
struct InvitationRequest {
  id : String
  team_id : String
  inviter_id : String
  invitee_id : String
}

///|
#derive(FromJson)
struct InvitationResponse {
  invitation_id : String
  member_id : String
  accept : Bool
}

///|
#derive(FromJson)
struct RemoveMemberRequest {
  team_id : String
  captain_id : String
  member_id : String
}

///|
#derive(FromJson)
#warnings("-reserved_keyword")
struct SubmissionPackageRequest {
  submission : Submission
  pkg_val : SubmissionPackage
}

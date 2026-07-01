///|
struct PdfEvidenceWatchConfig {
  template_id : String
  template_version : String
  book_id : String
  book_type : String
  title : String
  purpose : String
  workspace_root : String
  tags : Array[String]
  skills : Array[String]
  watch : PdfEvidenceWatchSettings
  analysis : PdfEvidenceWatchAnalysisSettings
  moondesk : PdfEvidenceWatchMoondeskSettings
} derive(Debug, Eq, ToJson, FromJson)

///|
struct PdfEvidenceWatchSettings {
  websites : Array[String]
  cadence_ticks : Int
  source_policy : String
  notify_when : Array[String]
  required_outputs : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
struct PdfEvidenceWatchAnalysisSettings {
  method_path : String
  ocr_engine : String
  source_registry_path : String
  findings_path : String
  review_path : String
} derive(Debug, Eq, ToJson, FromJson)

///|
struct PdfEvidenceWatchMoondeskSettings {
  create_mode : String
  editable_files : Array[String]
  output_files : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct PdfEvidenceWatchInstallSpec {
  book_id : String
  title : String
  purpose : String
  websites : Array[String]
  analysis_method : String
  analysis_method_path : String
  cadence_ticks : Int
  workspace_root : String
} derive(Debug, Eq, ToJson, FromJson)

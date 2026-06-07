///|
pub struct CivicCommunicationPattern {
  id : String
  title : String
  category : String
  summary : String
  protocol_mode : String
  input_contract : String
  reduction_contract : String
  output_contract : String
  review_contract : String
  cadence_hint : String
  good_for : Array[String]
  civic_examples : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Transient, read-only drawer state. Bodies never enter Town persistence.
priv enum ImportedOutputsCatalogState {
  CatalogIdle
  CatalogLoading
  CatalogReady(@imported_output_contract.Catalog)
  CatalogUnavailable(String)
} derive(Debug, Eq)

///|
priv enum ImportedOutputsTextState {
  TextIdle
  TextLoading
  TextReady(String)
  TextUnavailable(String)
} derive(Debug, Eq)

///|
priv struct ImportedOutputsState {
  open : Bool
  generation : Int
  catalog : ImportedOutputsCatalogState
  book_handle : String
  artifact_id : String
  selection : @imported_output_contract.Selection?
  download_generation : Int
  download : ImportedOutputsDownloadState
  text : ImportedOutputsTextState
} derive(Debug, Eq)

///|
priv enum ImportedOutputsMsg {
  OpenImportedOutputs
  CloseImportedOutputs
  RefreshImportedOutputs
  ChooseImportedBook(String)
  ChooseImportedOutput(String)
  ChooseImportedFile(String)
  DownloadImportedFile
  ImportedDownloadStatus(
    Int,
    Int,
    @imported_output_contract.Selection,
    Bool,
    String
  )
  ImportedCatalogLoaded(Int, String)
  ImportedTextLoaded(Int, @imported_output_contract.Selection, String)
}

///|
priv enum ImportedOutputsRequest {
  FetchImportedCatalog(Int)
  FetchImportedDownload(Int, Int, @imported_output_contract.Selection)
  FetchImportedText(Int, @imported_output_contract.Selection)
} derive(Debug, Eq)

///|
priv enum ImportedOutputsDownloadState {
  DownloadIdle
  DownloadLoading
  DownloadReady
  DownloadUnavailable(String)
} derive(Debug, Eq)

///|
#external
priv type ImportedOutputDownload

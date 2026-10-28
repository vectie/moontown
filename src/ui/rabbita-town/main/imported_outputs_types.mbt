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
  generation : Int32
  catalog : ImportedOutputsCatalogState
  book_handle : String
  artifact_id : String
  selection : @imported_output_contract.Selection?
  download_generation : Int32
  download : ImportedOutputsDownloadState
  text : ImportedOutputsTextState
  table : Result[@imported_output_contract.DataTable, String]?
  table_query : String
  table_page : Int32
  table_show : Bool
  table_view : TableViewState
  agenda : AgendaState
  geo : GeoState
  places : PlacesState
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
  SearchImportedTable(String)
  PageImportedTable(Int32)
  ShowImportedTable(Bool)
  DownloadFilteredTable
  TableViewEvent(TableViewMsg)
  AgendaEvent(AgendaMsg)
  GeoEvent(GeoMsg)
  PlacesEvent(PlacesMsg)
  ImportedDownloadStatus(
    Int32,
    Int32,
    @imported_output_contract.Selection,
    Bool,
    String
  )
  ImportedCatalogLoaded(Int32, String)
  ImportedTextLoaded(Int32, @imported_output_contract.Selection, String)
}

///|
priv enum ImportedOutputsRequest {
  FetchImportedCatalog(Int32)
  FetchImportedDownload(Int32, Int32, @imported_output_contract.Selection)
  FetchImportedText(Int32, @imported_output_contract.Selection)
  SaveFilteredTable(String, String)
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

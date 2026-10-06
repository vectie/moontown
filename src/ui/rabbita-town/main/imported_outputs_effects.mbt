///|
/// Browser glue only transports host JSON. Contract decoding, selection and
/// rendering remain MoonBit; no body is cached in browser storage.
extern "js" fn fetch_imported_outputs_json(
  endpoint : String,
  max_bytes : Int,
) -> @js.Promise =
  #| async (endpoint, maxBytes) => {
  #|   try {
  #|     const response = await fetch(endpoint, { method: "GET", cache: "no-store", headers: { Accept: "application/json" } });
  #|     if (!response.body) return "";
  #|     const reader = response.body.getReader(), chunks = [];
  #|     let size = 0;
  #|     while (true) {
  #|       const { value, done } = await reader.read();
  #|       if (done) break;
  #|       size += value.byteLength;
  #|       if (size > maxBytes) { await reader.cancel(); return ""; }
  #|       chunks.push(value);
  #|     }
  #|     const bytes = new Uint8Array(size); let offset = 0;
  #|     for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.byteLength; }
  #|     return new TextDecoder("utf-8", { fatal: true }).decode(bytes);
  #|   } catch (_) { return ""; }
  #| }

///|
async fn wait_imported_outputs_json(promise : @js.Promise) -> String noraise {
  promise.wait().cast() catch {
    _ => ""
  }
}

///|
fn imported_outputs_cmd(
  dispatch : Dispatch[Msg],
  request : ImportedOutputsRequest?,
) -> Cmd {
  match request {
    None => @rabbita.none
    Some(FetchImportedCatalog(generation)) =>
      @rabbita.perform(
        raw => {
          dispatch(ImportedOutputsEvent(ImportedCatalogLoaded(generation, raw)))
        },
        async fn() noraise {
          wait_imported_outputs_json(
            fetch_imported_outputs_json(
              moontown_product_api_path("api/imported-outputs"),
              @imported_output_contract.catalog_wire_limit(),
            ),
          )
        },
      )
    Some(FetchImportedDownload(generation, download_generation, selection)) =>
      @rabbita.perform(
        result => {
          dispatch(
            ImportedDownloadReceived(
              generation, download_generation, selection, result,
            ),
          )
        },
        async fn() noraise {
          wait_imported_output_download(
            fetch_imported_output_download(
              moontown_product_api_path(
                @imported_output_contract.content_path(
                  selection,
                  mode="download",
                ),
              ),
              selection.size_bytes,
              selection.digest,
            ),
          )
        },
      )
    Some(FetchImportedText(generation, selection)) =>
      @rabbita.perform(
        raw => {
          dispatch(
            ImportedOutputsEvent(ImportedTextLoaded(generation, selection, raw)),
          )
        },
        async fn() noraise {
          wait_imported_outputs_json(
            fetch_imported_outputs_json(
              moontown_product_api_path(
                @imported_output_contract.content_path(selection, mode="text"),
              ),
              @imported_output_contract.text_wire_limit(),
            ),
          )
        },
      )
  }
}

///|
fn imported_outputs_update(
  dispatch : Dispatch[Msg],
  model : Model,
  msg : ImportedOutputsMsg,
) -> (Cmd, Model) {
  let (state, request) = imported_outputs_transition(
    model.imported_outputs,
    msg,
  )
  let base = if msg is OpenImportedOutputs {
    {
      ..close_town_transient_surfaces(model),
      selection: Overview,
      map_lab_open: false,
      energy_intro_open: false,
    }
  } else {
    model
  }
  (
    imported_outputs_cmd(dispatch, request),
    { ..base, imported_outputs: state, },
  )
}

///|
/// This feature-specific boundary changes no legacy field or command. It also
/// runs before dispatch so an already-obscured drawer cannot issue a save.
/// Ambient status, weather, map tools, movement and metro are not primary
/// surfaces and do not dismiss a read in progress.
fn imported_outputs_reconcile_primary_surface(model : Model) -> Model {
  if !model.imported_outputs.open {
    return model
  }
  let competing = model.energy_board_open ||
    model.energy_first_agent_open ||
    model.energy_guide_open ||
    model.energy_reset_open ||
    model.energy_intro_open ||
    model.energy_request_open ||
    model.resident_explorer_open ||
    model.town_chronicle_open ||
    model.phone_open ||
    model.square_open ||
    model.ops_open ||
    model.knowledge_dialog_open ||
    model.map_lab_open ||
    model.energy_selected_building is Some(_) ||
    model.selection is Agent(_) ||
    model.town_spatial_layer is (Indoor(_) | Underground(_))
  if competing {
    {
      ..model,
      imported_outputs: close_imported_outputs(model.imported_outputs),
    }
  } else {
    model
  }
}

///|
extern "js" fn fetch_imported_output_download(
  endpoint : String,
  expected_bytes : Int,
  expected_digest : String,
) -> @js.Promise =
  #| async (endpoint, expectedBytes, expectedDigest) => {
  #|   const blocked = message => ({ ok: false, message, bytes: null });
  #|   try {
  #|     const response = await fetch(endpoint, { method: "GET", cache: "no-store" });
  #|     const length = response.headers.get("Content-Length");
  #|     const digest = response.headers.get("X-Artifact-Digest");
  #|     if (response.status !== 200 ||
  #|         !/^attachment(?:;|$)/i.test(response.headers.get("Content-Disposition") || "") ||
  #|         response.headers.get("Content-Type") !== "application/octet-stream" ||
  #|         (length !== null && length !== String(expectedBytes)) ||
  #|         (digest !== null && digest !== expectedDigest) ||
  #|         response.headers.get("X-Content-Type-Options") !== "nosniff") {
  #|       await response.body?.cancel();
  #|       return blocked("File changed or unavailable. Refresh imported outputs before downloading again.");
  #|     }
  #|     if (!response.body) return expectedBytes === 0
  #|       ? { ok: true, message: "", bytes: new Uint8Array(0) }
  #|       : blocked("The host returned no attachment body.");
  #|     const reader = response.body.getReader(), chunks = []; let size = 0;
  #|     while (true) {
  #|       const { value, done } = await reader.read();
  #|       if (done) break;
  #|       size += value.byteLength;
  #|       if (size > expectedBytes) { await reader.cancel(); return blocked("Attachment size changed. Refresh before downloading again."); }
  #|       chunks.push(value);
  #|     }
  #|     if (size !== expectedBytes) return blocked("Attachment size changed. Refresh before downloading again.");
  #|     const bytes = new Uint8Array(size); let offset = 0;
  #|     for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.byteLength; }
  #|     return { ok: true, message: "", bytes };
  #|   } catch (_) { return blocked("Download unavailable on this host. Refresh and try again."); }
  #| }

///|
extern "js" fn imported_output_download_error() -> ImportedOutputDownload =
  #| () => ({ ok: false, message: "Download unavailable on this host.", bytes: null })

///|
async fn wait_imported_output_download(
  promise : @js.Promise,
) -> ImportedOutputDownload noraise {
  promise.wait().cast() catch {
    _ => imported_output_download_error()
  }
}

///|
extern "js" fn imported_output_download_ok(
  result : ImportedOutputDownload,
) -> Bool =
  #| result => result.ok === true && result.bytes instanceof Uint8Array

///|
extern "js" fn imported_output_download_bytes(
  result : ImportedOutputDownload,
) -> Bytes =
  #| result => result.bytes

///|
extern "js" fn imported_output_download_message(
  result : ImportedOutputDownload,
) -> String =
  #| result => String(result.message || "Download unavailable.")

///|
extern "js" fn save_imported_output_download(
  bytes : Bytes,
  path : String,
) -> Unit =
  #| (bytes, path) => {
  #|   if (!(bytes instanceof Uint8Array)) return;
  #|   const blob = new Blob([bytes], { type: "application/octet-stream" });
  #|   const url = URL.createObjectURL(blob), link = document.createElement("a");
  #|   link.href = url; link.download = path.split("/").pop() || "output.bin";
  #|   document.body.appendChild(link); link.click(); link.remove();
  #|   setTimeout(() => URL.revokeObjectURL(url), 30000);
  #| }

///|
fn imported_outputs_download_update(
  model : Model,
  generation : Int,
  download_generation : Int,
  selection : @imported_output_contract.Selection,
  result : ImportedOutputDownload,
) -> (Cmd, Model) {
  if !imported_outputs_accepts_download(
      model.imported_outputs,
      generation,
      download_generation,
      selection,
    ) {
    return model_only_update(model)
  }
  let transported = imported_output_download_ok(result)
  let bytes = if transported {
    imported_output_download_bytes(result)
  } else {
    b""
  }
  let ok = transported &&
    @imported_output_contract.selection_bytes_match(selection, bytes)
  let message = if transported && !ok {
    "Attachment bytes do not match the selected file. Refresh before downloading again."
  } else {
    imported_output_download_message(result)
  }
  let (state, _) = imported_outputs_transition(
    model.imported_outputs,
    ImportedDownloadStatus(
      generation, download_generation, selection, ok, message,
    ),
  )
  let command = if ok {
    @cmd.custom_cmd(_ => save_imported_output_download(bytes, selection.path))
  } else {
    @rabbita.none
  }
  (command, { ..model, imported_outputs: state, })
}

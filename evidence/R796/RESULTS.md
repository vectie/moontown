# R796 cross-dossier inquiry development evidence

Source: restored MoonTown source at `sources/moontown`, preserved without edits.
Working source: `work/R796/moontown`. Local sibling `work/R796/moonchat` is an
unchanged copy of restored `sources/moonchat`; the existing moon.work points to
that sibling. Native resolution uses the existing workspace's async 0.20.2,
moonbitlang/x 0.4.50, vectie/lepusa 0.1.4 and vectie/moonlib 0.1.19. UI resolution
uses its existing Rabbita 0.14.0 and async 0.20.2 declarations. No dependency
manifest or dependency source was changed. Official registry resolution succeeded.

Actual toolchain: Moon 0.1.20261016; moonc 0.10.16+b1a0e846e, bundled core. This
is development evidence on that toolchain, not a historical pinned-toolchain pass.

## Accepted local test observations

- Native collaboration_contract package: 51 tests passed, 0 failed, including
  two new cross-dossier tests. Final log: contract-test-final.log.
- Independent bounded review accepted the workflow after strengthening the
  repeated-Book distinct-path union test and clarifying selection guidance.
  Independent native contract rerun also passed 51/51 under the shared lock;
  log: independent-contract-test.log.
- Native new cross-dossier API/store journey: 1 passed, 0 failed.
  Final log: authoring-cross-test-final.log.
- Native existing retained-inquiry store tests: 2 passed, 0 failed.
  Final log: authoring-inquiry-test-final.log.
- JS new cross-dossier renderer/request test: 1 passed, 0 failed.
  Final log: ui-cross-test-final.log.
- JS existing retained-inquiry renderer/client tests: 2 passed, 0 failed.
  Final log: ui-inquiry-test-final.log.
- Focused native check (contract and authoring), JS UI check, JS UI build passed.
  Final logs: focused-check-final.log, ui-check-final.log, ui-build-final.log.
- moon fmt ran for changed native packages. Unrelated formatter-only changes
  were restored from the untouched baseline. Changed UI/new edits were formatted
  with the same toolchain's moonfmt. moon info ran for contract and authoring;
  generated interfaces were inspected. New APIs/types and Client basket fields
  are intentional; Int -> Int32 spelling is this compiler's generated rendering.

Native commands used the shared native-build.lock via flock and --target native
--strip --jobs 2 --warn-list '-a'. Package selectors: src/collaboration_contract
and src/collaboration_authoring. Store/UI filters: '*cross dossier*' and '*inquiry*'.
UI commands ran in src/ui/rabbita-town: moon test/check/build main --target js
--warn-list '-a'. Warnings were suppressed for focused functional logs; the info
log retains existing deprecation warnings.

## Compatibility edits and incomplete checks

Removed try? syntax prevented required compilation on the available toolchain.
Equivalent try Ok(expression) catch { e => Err(e) } replacements were limited to
five existing expressions in imported_output_contract/{geojson,table_places,
table_zones}.mbt and existing tests in collaboration_contract/{outcome_comparison,
outcome_search}_test.mbt and collaboration_authoring/outcome_comparison_wbtest.mbt.
Their exact before/after diffs are retained in syntax-compat.patch. No behavior
or assertion was weakened. Original source remains in the restored baseline.

An early full-workspace check failed on removed try? syntax in unrelated MoonChat
tests as well as the subsequently repaired required inputs. No full-workspace
pass is claimed. An unfiltered UI test run was manually interrupted after about
two minutes without a completion result; only the focused UI passes above are
claimed. Initial command-usage errors (moon install without SOURCE; moon info
with unsupported --strip) were corrected using supported commands.

No graphical browser, live HTTP deployment, configured provider, authentication,
owning-Book acceptance or desktop/release qualification was performed. No dispatch
or paid provider action occurred. No cleanup or delivery was performed by this
feature worker; those remain parent batch lifecycle work.

# Real portable-transfer CLI

This executable is separate from fixture/dev-login miniapp commands. Build it
with the project's native toolchain. It does not start a Town service.

Syntax:

    portable_transfer --base-url ORIGIN --session-stdin COMMAND [ARGS]

Commands:

    upload ORIGINAL_FILE LISTING_ID SAVED_V1_BINDING_JSON
    list
    preview-share PACKAGE_ID SAVED_V1_BINDING_JSON RECIPIENT_PRINCIPAL GRANT_ID EXPIRES_AT_MS
    share PACKAGE_ID SAVED_V1_BINDING_JSON RECIPIENT_PRINCIPAL GRANT_ID EXPIRES_AT_MS
    revoke GRANT_ID
    download PACKAGE_ID SAVED_V1_BINDING_JSON NEW_OUTPUT_FILE
    withdraw PACKAGE_ID SAVED_V1_BINDING_JSON

Supply the existing Town session through stdin, finished by EOF, from a trusted
existing session source. This tool neither obtains nor saves credentials. Do
not put a session in command arguments, environment variables, shell history or
example files. No --session, --token, identity override or implicit account
fallback is supported. Prefer HTTPS for remote origins.

Upload validates the saved immutable binding and original file locally before
sending any bytes. Upload alone grants nobody else access. Preview changes
nothing. Review its full-file disclosure before explicitly running share:
accepted learning, identity files and selected output bytes all travel with
the package, not only the outputs. The recipient must already be an authorized
same-tenant account; this tool creates no accounts.

Download refuses existing package or sidecar paths. It also creates
NEW_OUTPUT_FILE.binding.json and NEW_OUTPUT_FILE.receipt.json. Files are
private, and the package filename is exposed only after exact size/hash
verification. A cancellation after the final verified rename retains the
completed package and sidecars; retry never overwrites them.

Output is JSON metadata/status only. Package bytes and sessions never go to
stdout. Errors use stable codes and unsuccessful commands exit nonzero.
Control request JSON and binding files are limited to 128 KiB; list/control
response metadata is limited to 8 MiB. Raw file limits and deadlines follow
the package-transfer defaults.

Revocation and withdrawal deny future admissions; already delivered bytes
cannot be recalled. Byte grants remain separate from metadata card grants.
No CLI command imports, installs, executes, calls hosted Try, or runs a package.
Use unchanged MoonBook exact-import/verify-import and Desk discovery afterward.

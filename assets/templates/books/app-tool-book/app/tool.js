const output = document.getElementById("tool-output");
const button = document.getElementById("refresh-tool");

async function inspectManifest() {
  if (!output) return;
  output.textContent = "Tool manifest is owned by this MoonBook. MoonClaw should replace this placeholder with domain-specific logic after accepted data exists.";
}

if (button) {
  button.addEventListener("click", inspectManifest);
}

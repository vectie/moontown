import '/styles.css'

const app = document.getElementById('app')

if (app) {
  app.innerHTML = `
    <div class="boot-shell">
      <div class="boot-panel">
        <p class="boot-eyebrow">Moontown</p>
        <h1 class="boot-headline">Loading Rabbita Town</h1>
        <p class="boot-copy">Preparing city hall, moonbook houses, worker yard, and anomaly corner.</p>
      </div>
    </div>
  `
}

async function boot() {
  try {
    const response = await fetch('./town.json', { cache: 'no-store' })
    if (response.ok) {
      globalThis.__moontownTownSnapshotJson = await response.text()
    } else {
      globalThis.__moontownTownSnapshotJson = ''
    }
  } catch {
    globalThis.__moontownTownSnapshotJson = ''
  }

  import('/main.js')
}

boot()

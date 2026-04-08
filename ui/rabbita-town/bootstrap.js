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

import('/main.js')


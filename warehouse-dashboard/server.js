/**
 * Warehouse Asset Dashboard — real-time server
 *
 * Uses the Ditto Node.js SDK with the same offlinePlayground identity
 * as the iOS / Android asset-capture apps. When the Node process and
 * the mobile devices are on the same Wi-Fi network they form a Ditto
 * mesh and changes sync automatically.
 *
 * Run:
 *   npm install
 *   npm start
 *
 * Then open http://localhost:3000 in your browser.
 */

const express = require('express')
const path = require('path')
const { init, Ditto, TransportConfig } = require('@dittolive/ditto')

// ── Ditto credentials (same as mobile apps) ──────────────────────────────────
const APP_ID = '2e9a634e-58fc-4919-b606-33a78369fbb9'
const LICENSE_TOKEN =
  'o2d1c2VyX2lkbkRpdHRvU0VEZW1vT3JnZmV4cGlyeXgYMjAyNi0xMi0wMlQwNDo1OTo1OS45OTlaaXNpZ25hdHVyZXhYTDVMVk5YUUxoWXhHcUovUVBwT3BvZ29iZTE5dXBMcEk0a2hmWkhGRVdDelVtaWVTa0Nia3U5QXlPbWtyMCtleUZWREhJZmI5NDZrR01OcFBqMUlKL0E9PQ=='

// ── Express app ───────────────────────────────────────────────────────────────
const app = express()
app.use(express.static(path.join(__dirname, 'public')))

// SSE clients: each is a res object with an open connection
const clients = new Set()
let latestAssets = []

/**
 * GET /events — Server-Sent Events stream.
 * The browser opens this once and receives a "assets" event whenever
 * the Ditto observer fires.
 */
app.get('/events', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream')
  res.setHeader('Cache-Control', 'no-cache')
  res.setHeader('Connection', 'keep-alive')
  res.setHeader('Access-Control-Allow-Origin', '*')
  res.flushHeaders()

  // Send current snapshot immediately so the page isn't blank on load
  sendEvent(res, latestAssets)

  clients.add(res)
  req.on('close', () => clients.delete(res))
})

/** Push the asset list to every connected browser tab. */
function broadcast(assets) {
  for (const client of clients) {
    sendEvent(client, assets)
  }
}

function sendEvent(res, assets) {
  res.write(`event: assets\ndata: ${JSON.stringify(assets)}\n\n`)
}

// ── Ditto ─────────────────────────────────────────────────────────────────────
async function startDitto() {
  await init()

  const ditto = new Ditto(
    { type: 'offlinePlayground', appID: APP_ID },
    path.join(__dirname, '.ditto-data')
  )

  ditto.setOfflineOnlyLicenseToken(LICENSE_TOKEN)
  ditto.disableSyncWithV3()

  // Enable LAN peer discovery so the server can sync with mobile devices
  // on the same Wi-Fi network without any cloud relay.
  const config = new TransportConfig()
  config.peerToPeer.lan.isEnabled = true
  ditto.setTransportConfig(config)

  await ditto.store.execute('ALTER SYSTEM SET DQL_STRICT_MODE = false')
  ditto.startSync()
  console.log('✅  Ditto sync started — listening for peers on LAN')

  const query = 'SELECT * FROM assets ORDER BY createdAt DESC'

  // Keep the subscription alive so Ditto pulls this collection from peers
  ditto.sync.registerSubscription(query)

  // Observer fires on initial load and every time any asset changes
  ditto.store.registerObserver(query, (result) => {
    latestAssets = result.items.map((item) => {
      const v = item.value
      return {
        _id: v._id,
        nsn: v.nsn ?? '',
        condition: v.condition ?? '',
        notes: v.notes ?? '',
        createdAt: v.createdAt ?? '',
        deviceId: v.deviceId ?? '',
        // Include full base64 so the browser can render the photo inline
        photoJpegBase64: v.photoJpegBase64 ?? null,
      }
    })
    broadcast(latestAssets)
    console.log(`📦  Assets updated — ${latestAssets.length} item(s)`)
  })
}

// ── Boot ──────────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000

app.listen(PORT, () => {
  console.log(`\n🏭  Warehouse Dashboard → http://localhost:${PORT}\n`)
})

startDitto().catch((err) => {
  console.error('❌  Failed to start Ditto:', err)
  process.exit(1)
})

package com.example.assetcapture

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import live.ditto.Ditto
import live.ditto.DittoIdentity
import live.ditto.DittoLogger
import live.ditto.DittoLogLevel
import live.ditto.DittoStoreObserver
import live.ditto.DittoSyncSubscription
import live.ditto.android.DefaultAndroidDittoDependencies
import java.time.Instant

object AssetDittoManager {

    private const val APP_ID = "2e9a634e-58fc-4919-b606-33a78369fbb9"
    private const val LICENSE_TOKEN = "o2d1c2VyX2lkbkRpdHRvU0VEZW1vT3JnZmV4cGlyeXgYMjAyNi0xMi0wMlQwNDo1OTo1OS45OTlaaXNpZ25hdHVyZXhYTDVMVk5YUUxoWXhHcUovUVBwT3BvZ29iZTE5dXBMcEk0a2hmWkhGRVdDelVtaWVTa0Nia3U5QXlPbWtyMCtleUZWREhJZmI5NDZrR01OcFBqMUlKL0E9PQ=="

    var ditto: Ditto? = null; private set

    private val _assets = MutableStateFlow<List<Asset>>(emptyList())
    val assets: StateFlow<List<Asset>> get() = _assets

    private var subscription: DittoSyncSubscription? = null
    private var observer: DittoStoreObserver? = null

    suspend fun startDitto(context: Context) {
        DittoLogger.minimumLogLevel = DittoLogLevel.DEBUG
        val deps = DefaultAndroidDittoDependencies(context)
        val d = Ditto(deps, DittoIdentity.OfflinePlayground(deps, APP_ID))
        d.disableSyncWithV3()
        d.setOfflineOnlyLicenseToken(LICENSE_TOKEN)
        try {
            d.store.execute("ALTER SYSTEM SET DQL_STRICT_MODE = false")
            d.startSync()
            Log.d("AssetDittoManager", "✅ Ditto startSync succeeded")
        } catch (e: Throwable) {
            Log.e("AssetDittoManager", "❌ Ditto startSync failed: $e")
        }
        ditto = d
        subscribeAssets()
    }

    private fun subscribeAssets() {
        val d = ditto ?: return
        val query = "SELECT * FROM assets ORDER BY createdAt DESC"
        subscription = d.sync.registerSubscription(query)
        observer = d.store.registerObserver(query) { results ->
            _assets.value = results.items.mapNotNull { item ->
                try { Asset.fromMap(item.value) } catch (e: Exception) { null }
            }
        }
    }

    suspend fun insertAsset(nsn: String, condition: String, notes: String, image: Bitmap?, deviceId: String) {
        val doc = mutableMapOf<String, Any?>(
            "_id" to java.util.UUID.randomUUID().toString(),
            "nsn" to nsn.uppercase(),
            "condition" to condition,
            "notes" to notes,
            "createdAt" to Instant.now().toString(),
            "deviceId" to deviceId
        )
        image?.let { doc["photoJpegBase64"] = it.resizedTo(640).toBase64() }
        try {
            ditto?.store?.execute("INSERT INTO assets DOCUMENTS (:doc)", mapOf("doc" to doc))
        } catch (e: Throwable) {
            Log.e("AssetDittoManager", "insertAsset error: $e")
        }
    }

    suspend fun updateAsset(asset: Asset, image: Bitmap?) {
        val photoB64 = image?.resizedTo(640)?.toBase64() ?: asset.photoJpegBase64
        try {
            ditto?.store?.execute(
                "UPDATE assets SET nsn = :nsn, condition = :condition, notes = :notes, photoJpegBase64 = :photo WHERE _id = :id",
                mapOf(
                    "nsn" to asset.nsn,
                    "condition" to asset.condition,
                    "notes" to asset.notes,
                    "photo" to photoB64,
                    "id" to asset.id
                )
            )
        } catch (e: Throwable) {
            Log.e("AssetDittoManager", "updateAsset error: $e")
        }
    }

    suspend fun deleteAsset(id: String) {
        try {
            ditto?.store?.execute(
                "DELETE FROM assets WHERE _id = :id",
                mapOf("id" to id)
            )
        } catch (e: Throwable) {
            Log.e("AssetDittoManager", "deleteAsset error: $e")
        }
    }
}

package live.ditto.inventory

import android.util.Log
import com.ditto.kotlin.*
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

object DittoManager {
    /* Interfaces */
    interface ItemUpdateListener {
        fun setInitial(items: List<ItemModel>)
        fun updateCount(index: Int, count: Int)
    }

    /* Settable from outside */
    lateinit var itemUpdateListener: ItemUpdateListener

    /* Get-only properties */
    var ditto: Ditto? = null; private set

    /* Private properties */
    private const val TAG = "DittoManager"
    private var subscription: DittoSyncSubscription? = null
    private var observer: DittoStoreObserver? = null

    // Those values should be pasted in 'gradle.properties'. See the notion page for more details.
    private const val DATABASE_ID = BuildConfig.DITTO_DATABASE_ID
    private const val DEVELOPMENT_TOKEN = BuildConfig.DITTO_DEVELOPMENT_TOKEN

    /* Internal functions and properties */
    internal suspend fun startDitto() {
        DittoLogger.minimumLogLevel = DittoLogLevel.Debug

        // https://docs.ditto.live/sdk/latest/install-guides/kotlin
        require(DATABASE_ID.isNotBlank()) { "DITTO_DATABASE_ID is missing — set it in the repo-root .env before building." }
        require(DEVELOPMENT_TOKEN.isNotBlank()) { "DITTO_DEVELOPMENT_TOKEN is missing — set it in the repo-root .env before building." }
        require(BuildConfig.DITTO_SERVER_URL.isNotBlank()) { "DITTO_SERVER_URL is missing — set it in the repo-root .env before building." }
        require(BuildConfig.DITTO_SERVER_URL.startsWith("https://")) {
            "DITTO_SERVER_URL must be an https:// URL (the v5 portal \"Connect via SDK\" URL): \"${BuildConfig.DITTO_SERVER_URL}\""
        }
        val ditto = DittoFactory.create(
            DittoConfig(
                databaseId = DATABASE_ID,
                connect = DittoConfig.Connect.Server(BuildConfig.DITTO_SERVER_URL)
            )
        )
        this.ditto = ditto

        try {
            // Authenticate before sync starts: supply a fresh token whenever the
            // current one is missing or near expiry. Rethrow CancellationException
            // so coroutine cancellation propagates instead of being logged as an
            // auth failure. https://docs.ditto.live/sdk/latest/auth-and-authorization
            ditto.auth?.expirationHandler = { expiredDitto, _ ->
                try {
                    expiredDitto.auth?.login(DEVELOPMENT_TOKEN, DittoAuthenticationProvider.development())
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Throwable) {
                    Log.e(TAG, "Authentication failed: ${e.message}")
                }
            }

            // DQL strict mode is off, so objects are treated as CRDT MAPs and
            // non-REGISTER types like COUNTER don't require collection definitions
            // on UPDATE/SELECT. https://docs.ditto.live/dql/strict-mode

            // start sync — @Throws, so guard it (rethrowing cancellation) rather
            // than letting a failure take down the caller.
            // https://docs.ditto.live/sdk/latest/sync/start-and-stop-sync
            ditto.sync.start()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Throwable) {
            Log.e(TAG, "Failed to start sync: ${e.message}")
        }

        observeItems()
        insertDefaultDataIfAbsent()
    }

    internal suspend fun increment(itemId: Int) {
        // Increment the COUNTER using APPLY — no collection definition needed on UPDATE
        // with DQL_STRICT_MODE = false (https://docs.ditto.live/dql/strict-mode)
        // https://docs.ditto.live/dql/types-and-definitions
        val query = "UPDATE inventory APPLY counter INCREMENT BY 1 WHERE _id = :id"
        try {
            ditto?.store?.execute(query,
                mapOf("id" to itemId))
        } catch (e: Throwable){
            e.localizedMessage?.let { Log.e(e.message, it) }
        }
    }

    internal suspend fun decrement(itemId: Int) {
        // Decrement the COUNTER using APPLY — no collection definition needed on UPDATE
        // with DQL_STRICT_MODE = false (https://docs.ditto.live/dql/strict-mode)
        // https://docs.ditto.live/dql/types-and-definitions
        val query = "UPDATE inventory APPLY counter INCREMENT BY -1 WHERE _id = :id"
        try {
            ditto?.store?.execute(query,
                mapOf("id" to itemId))
        } catch (e: Throwable){
            e.localizedMessage?.let { Log.e(e.message, it) }
        }
    }

    internal val sdkVersion: String
        get() = Ditto.VERSION


    /* Private functions and properties */
    private suspend fun insertDefaultDataIfAbsent() {
        // INSERT with COUNTER type declaration — the collection definition is required on INSERT
        // so the counter field is created as a COUNTER CRDT, not a plain REGISTER.
        // https://docs.ditto.live/dql/insert#insert-with-initial-documents
        // https://docs.ditto.live/dql/types-and-definitions
        val query = "INSERT INTO COLLECTION inventory (counter COUNTER) INITIAL DOCUMENTS (:item)"

        // Run the inserts inside a single DQL transaction.
        // https://docs.ditto.live/sdk/latest/crud/transactions
        ditto?.store?.transaction { transaction ->
            try {
                for (viewItem in itemsForView) {
                    transaction.execute(query,
                        mapOf("item" to
                                mapOf("_id" to viewItem.itemId,
                                    "counter" to 0)
                        )
                    )
                }
                DittoTransaction.Result.Commit(Unit)
            } catch (e: Throwable) {
                e.localizedMessage?.let { Log.e(e.message, it) }
                DittoTransaction.Result.Rollback
            }
        }
    }

    private fun observeItems() {
        val query = "SELECT * FROM inventory"
        ditto?.let {
            // Create Subscription
            // https://docs.ditto.live/sdk/latest/sync/syncing-data#creating-subscriptions
            subscription = it.sync.registerSubscription(query)

            // Register Observer to see changes in the database from sync. The observer
            // delivers a DittoDiff with the delta changes between syncs.
            // https://docs.ditto.live/sdk/latest/crud/observing-data-changes
            observer = it.store.registerObserver(query) { result, diff ->

                // NOTE:  if you are curious on why we don't handle deletions - the app code
                // currently does not allow deleting of inventory items, so there is no reason to handle
                // checking the count of deletions.

                // if the insertions count is greater than zero and others are empty
                // assume initial load
                if (diff.insertions.isNotEmpty() && diff.deletions.isEmpty() && diff.updates.isEmpty()) {
                    withContext(Dispatchers.Main) {
                        itemUpdateListener.setInitial(itemsForView.toMutableList())
                    }
                } else {
                    // Extract counts while the query result is open, then dispatch
                    // once — avoids suspending the handler per updated item.
                    val counts = diff.updates.map { it to (result.items[it].value["counter"].intOrNull ?: 0) }
                    withContext(Dispatchers.Main) {
                        counts.forEach { (index, count) -> itemUpdateListener.updateCount(index, count) }
                    }
                }
            }
        }
    }

    private val itemsForView = arrayOf(
        ItemModel(0, R.drawable.coke, "Coca-Cola", 2.50, "A Can of Coca-Cola"),
        ItemModel(1, R.drawable.drpepper, "Dr. Pepper", 2.50, "A Can of Dr. Pepper"),
        ItemModel(2,R.drawable.lays, "Lay's Classic", 3.99, "Original Classic Lay's Bag of Chips"),
        ItemModel(3, R.drawable.brownies, "Brownies", 6.50,"Brownies, Diet Sugar Free Version"),
        ItemModel(4, R.drawable.blt, "Classic BLT Egg", 2.50, "Contains Egg, Meats and Dairy")
    )
}
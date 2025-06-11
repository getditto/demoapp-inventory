package live.ditto.inventory

import android.content.Context
import android.util.Log
import live.ditto.*
import live.ditto.android.DefaultAndroidDittoDependencies

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
    private var subscription: DittoSyncSubscription? = null
    private var observer: DittoStoreObserver? = null

    // Those values should be pasted in 'gradle.properties'. See the notion page for more details.
    private const val APP_ID = BuildConfig.DITTO_APP_ID
    private const val ONLINE_AUTH_TOKEN = BuildConfig.DITTO_PLAYGROUND_TOKEN

    /* Internal functions and properties */
    internal suspend fun startDitto(context: Context) {
        DittoLogger.minimumLogLevel = DittoLogLevel.DEBUG

        val dependencies = DefaultAndroidDittoDependencies(context)
        ditto = Ditto(dependencies, DittoIdentity.OnlinePlayground(dependencies, APP_ID, ONLINE_AUTH_TOKEN, false))

        try {
            ditto?.let {
                // Disable sync with V3 Ditto
                it.disableSyncWithV3()

                // disable strict mode - allows for DQL with counters and objects as CRDT maps, must be called before startSync
                // https://docs.ditto.live/dql/strict-mode 
                it.store.execute("ALTER SYSTEM SET DQL_STRICT_MODE = false")

                // start sync
                // https://docs.ditto.live/sdk/latest/sync/start-and-stop-sync
                it.startSync()
            }

        } catch (e: Exception) {
            e.localizedMessage?.let { Log.e(e.message, it) }
        }

        observeItems()
        insertDefaultDataIfAbsent()
    }

    internal suspend fun increment(itemId: Int) {
        // UPDATE Counter using DQL PN_INCREMENT function
        // TODO insert URL to documentation link
        val query = "UPDATE inventories APPLY counter PN_INCREMENT BY 1.0 WHERE _id = :id"
        try {
            ditto?.store?.execute(query,
                mapOf("id" to itemId))
        } catch (e: Exception){
            e.localizedMessage?.let { Log.e(e.message, it) }
        }
    }

    internal suspend fun decrement(itemId: Int) {
        // UPDATE Counter using DQL PN_INCREMENT function
        // TODO insert URL to documentation link
        val query = "UPDATE inventories APPLY counter PN_INCREMENT BY -1.0 WHERE _id = :id"
        try {
            ditto?.store?.execute(query,
                mapOf("id" to itemId))
        } catch (e: Exception){
            e.localizedMessage?.let { Log.e(e.message, it) }
        }
    }

    internal val sdkVersion: String?
        get() = ditto?.sdkVersion


    /* Private functions and properties */
    private suspend fun insertDefaultDataIfAbsent() {
        // CREATE new items using the INSERT INTO xxx INTIAL statement
        // https://docs.ditto.live/dql/insert#insert-with-initial-documents
        val query = "INSERT INTO inventories INITIAL DOCUMENTS (:item)"

        // Create a transaction to run inserts into with DQL - this is the equivalent to scoped transaction using store.write
        // TODO insert doc link to transactions with DQL
        ditto?.store?.transaction {
             try {
                 for (viewItem in itemsForView) {
                     it.execute(query,
                         mapOf("item" to
                                 mapOf("_id" to viewItem.itemId,
                                     "counter" to 0.0)
                         )
                     )
                 }
             } catch (e: Exception){
                 e.localizedMessage?.let { Log.e(e.message, it) }
                 DittoTransactionCompletionAction.Rollback
             }
            DittoTransactionCompletionAction.Commit
        }
    }

    private fun observeItems() {
        val query = "SELECT * FROM inventories"
        ditto?.let {
            // Create Subscription
            // https://docs.ditto.live/sdk/latest/sync/syncing-data#creating-subscriptions
            subscription = it.sync.registerSubscription(query)

            // DittoDiffer - used to calculate the delta changes between syncs
            // TODO put in link to docs that describes the differ
            val dittoDiffer = DittoDiffer()

            // Register Observer to see changes in the database from sync
            // https://docs.ditto.live/sdk/latest/crud/observing-data-changes
            observer = it.store.registerObserver(query) { results ->
                val diff = dittoDiffer.diff(results.items)

                // NOTE:  if you are curious on why we don't handle deletions - the app code
                // currently does not allow deleting of inventory items, so there is no reason to handle
                // checking the count of deletions.

                // if the insertions count is greater than zero and others are empty
                // assume initial load
                if (diff.insertions.isNotEmpty() && diff.deletions.isEmpty() && diff.updates.isEmpty()) {
                   itemUpdateListener.setInitial(itemsForView.toMutableList())
                } else {
                    diff.updates.forEach { index ->
                        val doc = results.items[index].value
                        val count = doc["counter"] as Float
                        itemUpdateListener.updateCount(index, count.toInt())
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
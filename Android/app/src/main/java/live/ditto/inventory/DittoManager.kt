package live.ditto.inventory

import android.util.Log
import com.ditto.kotlin.*
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
    private var subscription: DittoSyncSubscription? = null
    private var observer: DittoStoreObserver? = null

    // Those values should be pasted in 'gradle.properties'. See the notion page for more details.
    private const val DATABASE_ID = BuildConfig.DITTO_DATABASE_ID
    private const val DEVELOPMENT_TOKEN = BuildConfig.DITTO_DEVELOPMENT_TOKEN

    /* Internal functions and properties */
    internal suspend fun startDitto() {
        DittoLogger.minimumLogLevel = DittoLogLevel.Debug

        // Initialize Ditto
        // https://docs.ditto.live/sdk/latest/install-guides/kotlin
        require(BuildConfig.DITTO_SERVER_URL.isNotBlank()) {
            "DITTO_SERVER_URL is missing or invalid: \"${BuildConfig.DITTO_SERVER_URL}\". Set it in .env before building."
        }
        val ditto = DittoFactory.create(
            DittoConfig(
                databaseId = DATABASE_ID,
                connect = DittoConfig.Connect.Server(BuildConfig.DITTO_SERVER_URL)
            )
        )
        this.ditto = ditto

        try {
            // The expiration handler is a suspend lambda, so login() runs directly
            // without launching a new coroutine. It logs in with the development token.
            // https://docs.ditto.live/sdk/latest/auth-and-authorization
            ditto.auth?.expirationHandler = { expiredDitto, _ ->
                expiredDitto.auth?.login(DEVELOPMENT_TOKEN, DittoAuthenticationProvider.development())
            }

            // DQL strict mode is off, so objects are treated as CRDT MAPs and
            // non-REGISTER types like COUNTER don't require collection definitions
            // on UPDATE/SELECT. https://docs.ditto.live/dql/strict-mode

            // start sync
            // https://docs.ditto.live/sdk/latest/sync/start-and-stop-sync
            ditto.sync.start()

        } catch (e: Throwable) {
            e.localizedMessage?.let { Log.e(e.message, it) }
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
                    diff.updates.forEach { index ->
                        val count = result.items[index].value["counter"].intOrNull ?: 0
                        withContext(Dispatchers.Main) {
                            itemUpdateListener.updateCount(index, count)
                        }
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
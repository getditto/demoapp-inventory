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
    private const val COLLECTION_NAME = "inventories"
    private var collection: DittoCollection? = null

    private var subscription: DittoSubscription? = null
    private var liveQuery: DittoLiveQuery? = null

    private const val APP_ID = BuildConfig.APP_ID
    private const val ONLINE_AUTH_TOKEN = BuildConfig.ONLINE_AUTH_TOKEN


    /* Internal functions and properties */
    internal fun startDitto(context: Context) {
        DittoLogger.minimumLogLevel = DittoLogLevel.VERBOSE

        val dependencies = DefaultAndroidDittoDependencies(context)
        ditto = Ditto(dependencies, DittoIdentity.OnlinePlayground(dependencies, APP_ID, ONLINE_AUTH_TOKEN, false))

        try {
            ditto?.disableSyncWithV3()
            ditto?.startSync()
        } catch (e: Exception) {
            Log.e(e.message, e.localizedMessage)
        }

        collection = ditto?.store?.collection(COLLECTION_NAME)

        observeItems()
        insertDefaultDataIfAbsent()
    }

    internal fun increment(itemId: Int) {
        collection?.findById(itemId)?.update {
            it?.get("counter")?.counter?.increment(1.0)
        }
    }

    internal fun decrement(itemId: Int) {
        collection?.findById(itemId)?.update {
            it?.get("counter")?.counter?.increment(-1.0)
        }
    }

    internal val sdkVersion: String?
        get() = ditto?.sdkVersion


    /* Private functions and properties */

    private fun insertDefaultDataIfAbsent() {

        ditto?.store?.write { transaction ->
            val scope = transaction.scoped(COLLECTION_NAME)

            for (viewItem in itemsForView) {
                val doc = collection?.findById(viewItem.itemId)?.exec()

                if (doc == null) {
                    scope.upsert(mapOf("_id" to viewItem.itemId, "counter" to DittoCounter()), writeStrategy = DittoWriteStrategy.InsertDefaultIfAbsent)
                } else {
                    viewItem.count = doc["counter"].intValue
                }
            }
        }
    }

    private fun observeItems() {
        val query = collection?.findAll()

        subscription = query?.subscribe()

        liveQuery = query?.observeLocal { docs, event ->

            when (event) {

                is DittoLiveQueryEvent.Initial -> {
                    itemUpdateListener.setInitial(itemsForView.toMutableList())
                }

                is DittoLiveQueryEvent.Update -> {
                    event.updates.forEach { index ->
                        val doc = docs[index]
                        val count = doc["counter"].intValue

                        itemUpdateListener.updateCount(index, count)
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
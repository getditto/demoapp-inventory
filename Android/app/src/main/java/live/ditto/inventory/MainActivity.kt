package live.ditto.inventory

import android.animation.ArgbEvaluator
import android.animation.ValueAnimator
import android.annotation.SuppressLint
import android.content.Intent
import android.graphics.Color
import android.icu.text.NumberFormat
import android.icu.util.Currency
import android.os.Bundle
import android.view.LayoutInflater
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.DividerItemDecoration
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import kotlinx.coroutines.launch
import live.ditto.transports.DittoSyncPermissions
import java.util.Locale

class MainActivity : AppCompatActivity(), DittoManager.ItemUpdateListener {
    private lateinit var recyclerView: RecyclerView
    private lateinit var viewManager: RecyclerView.LayoutManager
    private lateinit var itemsAdapter: ItemsAdapter

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        checkLocationPermission()

        DittoManager.itemUpdateListener = this

        lifecycleScope.launch {
            DittoManager.startDitto(applicationContext)
        }

        setupLayout()
    }

    private fun setupLayout() {
        viewManager = LinearLayoutManager(this)
        itemsAdapter = ItemsAdapter()

        recyclerView = findViewById<RecyclerView>(R.id.recyclerView).apply {
            setHasFixedSize(true)
            layoutManager = viewManager
            adapter = itemsAdapter
        }

        recyclerView.addItemDecoration(DividerItemDecoration(this, DividerItemDecoration.VERTICAL))

        itemsAdapter.onPlusClick = { it ->
            DittoManager.increment(it.itemId)
        }
        itemsAdapter.onMinusClick = { it ->
            DittoManager.decrement(it.itemId)
        }
    }

    private fun animateGlow(index: Int) {
        val holder = recyclerView.findViewHolderForLayoutPosition(index)
        val animator = ValueAnimator.ofObject(
            ArgbEvaluator(),
            Color.WHITE,
            ContextCompat.getColor(this, R.color.colorGlow),
            Color.WHITE
        )
        animator.duration = 250
        animator.addUpdateListener {
            holder?.itemView?.setBackgroundColor(animator.animatedValue as Int)
        }
        animator.start()
    }

    override fun onCreateOptionsMenu(menu: Menu?): Boolean {
        menuInflater.inflate(R.menu.menu_main, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.show_information_view -> {
                showInformationView(); true
            }

            R.id.show_ditto_tools -> {
                showDittoTools(); true
            }

            else -> super.onOptionsItemSelected(item)
        }
    }

    private fun showInformationView() {
        val intent = DittoManager.sdkVersion?.let { DittoInfoListActivity.createIntent(this, it) }
        startActivity(intent)
    }

    private fun showDittoTools() {
        val intent = Intent(this, DittoToolsViewerActivity::class.java)
        startActivity(intent)
    }

    private fun checkLocationPermission() {
        val missing = DittoSyncPermissions(this).missingPermissions()
        if (missing.isNotEmpty()) {
            this.requestPermissions(missing, 0)
        }
    }

    /* UpdateItemListener */
    override fun setInitial(items: List<ItemModel>) {
        runOnUiThread {
            itemsAdapter.setInitial(items)
        }
    }

    override fun updateCount(index: Int, count: Int) {
        runOnUiThread {
            itemsAdapter.updateCount(index, count)
            animateGlow(index)
        }
    }
}

class ItemsAdapter : RecyclerView.Adapter<ItemsAdapter.ItemViewHolder>() {
    private val items = mutableListOf<ItemModel>()

    var onPlusClick: ((ItemModel) -> Unit)? = null
    var onMinusClick: ((ItemModel) -> Unit)? = null

    class ItemViewHolder(v: View) : RecyclerView.ViewHolder(v)

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ItemViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_view, parent, false)
        return ItemViewHolder(view)
    }

    override fun onBindViewHolder(holder: ItemViewHolder, position: Int) {
        val item = items[position]
        with(holder.itemView) {
            findViewById<TextView>(R.id.itemTitleView).text = item.title
            findViewById<TextView>(R.id.itemDescriptionView).text = item.detail
            findViewById<TextView>(R.id.quantityView).text = String.format(
                locale = Locale.getDefault(),
                format = "%s", item.count.toString()
            )
            findViewById<ImageView>(R.id.imageView).setImageResource(item.image)
            findViewById<TextView>(R.id.priceView).text = formatMoney(price = item.price)
            findViewById<Button>(R.id.plusButton).setOnClickListener {
                onPlusClick?.invoke(items[holder.bindingAdapterPosition])
            }
            findViewById<Button>(R.id.minusButton).setOnClickListener {
                onMinusClick?.invoke(items[holder.bindingAdapterPosition])
            }
        }
    }

    override fun getItemCount() = this.items.size

    fun updateCount(index: Int, count: Int): Int {
        items[index].count = count
        notifyItemChanged(index)
        return this.items.size
    }

    @SuppressLint("NotifyDataSetChanged")
    fun setInitial(items: List<ItemModel>): Int {
        this.items.addAll(items)
        notifyDataSetChanged()
        return this.items.size
    }

    private fun formatMoney(price: Double): String {
        val formatter = NumberFormat.getCurrencyInstance()
        with(formatter) {
            currency = Currency.getInstance("USD")
        }
        return formatter.format(price)
    }
}


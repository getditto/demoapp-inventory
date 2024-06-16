package live.ditto.inventory

import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import androidx.recyclerview.widget.DividerItemDecoration
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import kotlinx.android.synthetic.main.item_view.view.*
import live.ditto.*
import live.ditto.transports.DittoSyncPermissions
import android.animation.ArgbEvaluator
import android.animation.ValueAnimator
import android.annotation.SuppressLint
import android.content.Intent
import androidx.core.content.ContextCompat
import android.graphics.Color
import android.view.*
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch

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
            R.id.show_presence_view -> {
                showPresenceView(); true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }

    private fun showInformationView() {
        val intent = DittoManager.sdkVersion?.let { DittoInfoListActivity.createIntent(this, it) }
        startActivity(intent)
    }

    private fun showPresenceView() {
        val intent = Intent(this, PresenceViewerActivity::class.java)
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
        holder.itemView.itemTitleView.text = item.title
        holder.itemView.itemDescriptionView.text = item.detail
        holder.itemView.quantityView.text = item.count.toString()
        holder.itemView.imageView.setImageResource(item.image)
        holder.itemView.priceView.text = "$" + item.price.toString()

        holder.itemView.plusButton.setOnClickListener {
            onPlusClick?.invoke(items[holder.adapterPosition])
        }
        holder.itemView.minusButton.setOnClickListener {
            onMinusClick?.invoke(items[holder.adapterPosition])
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
}


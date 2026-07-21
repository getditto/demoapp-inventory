package live.ditto.inventory

import android.content.Context
import android.content.Intent
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.view.MenuItem
import android.widget.TextView
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.updatePadding

class DittoSDKInfoActivity : AppCompatActivity() {

    companion object {
        fun createIntent(context: Context, sdkInfo: String): Intent {
            return Intent(context, DittoSDKInfoActivity::class.java).apply {
                putExtra("sdkInfo", sdkInfo)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_ditto_sdk_info)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        title = "Ditto SDK Info"

        val textView = findViewById<TextView>(R.id.ditto_sdk_info_text_view)

        ViewCompat.setOnApplyWindowInsetsListener(textView) { view, windowInsets ->
            val insets = windowInsets.getInsets(WindowInsetsCompat.Type.systemBars())
            view.updatePadding(top = insets.top)
            windowInsets
        }

        intent.getStringExtra("sdkInfo")?.let { sdkInfo ->
            // Ditto.VERSION is the SDK semantic version (e.g. "5.0.2"); it no longer
            // embeds a platform prefix or commit hash.
            val parts = sdkInfo.split("_")
            val semVer = parts.getOrElse(0) { sdkInfo }
            val commitHash = parts.getOrElse(1) { "n/a" }

            textView.text = getString(R.string.sdk_info, "Android", semVer, commitHash).trimIndent()
        }
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        onBackPressedDispatcher.onBackPressed()
        return true
    }
}
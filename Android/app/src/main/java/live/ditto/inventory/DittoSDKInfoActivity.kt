package live.ditto.inventory

import android.content.Context
import android.content.Intent
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.view.MenuItem
import android.widget.TextView

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

        intent.getStringExtra("sdkInfo")?.let { sdkInfo ->
            val platform = sdkInfo.take(3)
            val versions = sdkInfo.drop(3).split("_")
            val semVer = versions[0]
            val commitHash = versions[1]

            textView.text = getString(R.string.sdk_info, platform, semVer, commitHash).trimIndent()
        }
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        onBackPressedDispatcher.onBackPressed()
        return true
    }
}
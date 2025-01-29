package live.ditto.inventory

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import live.ditto.tools.toolsviewer.DittoToolsViewer

class DittoToolsViewerActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            MaterialTheme {
                DittoManager.ditto?.let {
                    DittoToolsViewer(
                        ditto = it,
                        onExitTools = {
                            finish()
                        }
                    )
                }
            }
        }
    }
}

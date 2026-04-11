package com.example.assetcapture

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import live.ditto.tools.toolsviewer.DittoToolsViewer

class DittoToolsActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                AssetDittoManager.ditto?.let { ditto ->
                    DittoToolsViewer(ditto = ditto, onExitTools = { finish() })
                }
            }
        }
    }
}

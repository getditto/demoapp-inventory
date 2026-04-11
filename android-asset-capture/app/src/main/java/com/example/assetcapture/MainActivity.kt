package com.example.assetcapture

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import androidx.lifecycle.lifecycleScope
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import kotlinx.coroutines.launch
import live.ditto.transports.DittoSyncPermissions

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        requestDittoPermissions()

        lifecycleScope.launch {
            AssetDittoManager.startDitto(applicationContext)
        }

        setContent {
            MaterialTheme {
                val navController = rememberNavController()
                NavHost(navController = navController, startDestination = "list") {
                    composable("list") {
                        AssetListScreen(navController = navController, activity = this@MainActivity)
                    }
                    composable("new") {
                        NewAssetScreen(navController = navController)
                    }
                    composable("detail/{assetId}") { backStack ->
                        val assetId = backStack.arguments?.getString("assetId") ?: return@composable
                        AssetDetailScreen(assetId = assetId, navController = navController)
                    }
                }
            }
        }
    }

    private fun requestDittoPermissions() {
        val missing = DittoSyncPermissions(this).missingPermissions()
        if (missing.isNotEmpty()) requestPermissions(missing, 0)
    }
}

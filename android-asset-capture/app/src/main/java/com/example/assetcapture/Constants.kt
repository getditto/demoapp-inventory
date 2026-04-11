package com.example.assetcapture

import androidx.compose.ui.graphics.Color

object Constants {
    enum class Condition(val rawValue: String, val label: String, val color: Color) {
        USABLE("usable", "Usable", Color(0xFF34C759)),
        REPAIRABLE("repairable", "Repairable", Color(0xFFFF9500)),
        SCRAP("scrap", "Scrap", Color(0xFFFF3B30))
    }
}

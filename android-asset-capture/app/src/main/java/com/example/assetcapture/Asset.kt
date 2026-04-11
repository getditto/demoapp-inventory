package com.example.assetcapture

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Base64
import java.io.ByteArrayOutputStream
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

data class Asset(
    val id: String,
    var nsn: String,
    var condition: String,
    var notes: String,
    var createdAt: String,
    var deviceId: String,
    var photoJpegBase64: String? = null
) {
    val photo: Bitmap?
        get() {
            val b64 = photoJpegBase64 ?: return null
            val bytes = Base64.decode(b64, Base64.DEFAULT)
            return BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
        }

    val conditionEnum: Constants.Condition
        get() = Constants.Condition.entries.find { it.rawValue == condition }
            ?: Constants.Condition.USABLE

    val formattedDate: String
        get() = try {
            DateTimeFormatter.ofPattern("M/d/yy, h:mm a")
                .withZone(ZoneId.systemDefault())
                .format(Instant.parse(createdAt))
        } catch (_: Exception) {
            createdAt
        }

    companion object {
        fun fromMap(map: Map<String, Any?>): Asset = Asset(
            id = map["_id"] as? String ?: "",
            nsn = map["nsn"] as? String ?: "",
            condition = map["condition"] as? String ?: "usable",
            notes = map["notes"] as? String ?: "",
            createdAt = map["createdAt"] as? String ?: "",
            deviceId = map["deviceId"] as? String ?: "",
            photoJpegBase64 = map["photoJpegBase64"] as? String
        )
    }
}

fun Bitmap.resizedTo(maxDimension: Int): Bitmap {
    val scale = maxDimension.toFloat() / maxOf(width, height)
    if (scale >= 1f) return this
    return Bitmap.createScaledBitmap(this, (width * scale).toInt(), (height * scale).toInt(), true)
}

fun Bitmap.toBase64(quality: Int = 65): String {
    val out = ByteArrayOutputStream()
    compress(Bitmap.CompressFormat.JPEG, quality, out)
    return Base64.encodeToString(out.toByteArray(), Base64.NO_WRAP)
}

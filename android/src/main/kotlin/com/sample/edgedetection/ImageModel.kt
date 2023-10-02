package com.sample.edgedetection

import android.graphics.Bitmap
import com.sample.edgedetection.processor.Corners
import org.opencv.core.Mat

data class ImageModel(
    var pic: Mat? = null,
    var corners: Corners? = null,
    var croppedBitmap: Bitmap? = null,
    var path: String? = null,
    var isSelected: Boolean = false
)
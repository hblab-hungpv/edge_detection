package com.sample.edgedetection


import com.sample.edgedetection.processor.Corners
import org.opencv.core.Mat

class SourceManager {
    companion object {
        var pic: Mat? = null
        var corners: Corners? = null

        var images: ArrayList<ImageModel> = ArrayList()

        var selectedIndex = -1

        var canFinishSession = false

        // Add image to list
        fun addImage(image: ImageModel) {
            images.add(image)
        }

        // Remote image by index
        fun removeImage(index: Int) {
            images.removeAt(index)
        }

        // Update isSelected by index
        fun updateImage(index: Int, isSelected: Boolean) {
            images[index].isSelected = isSelected
        }

        // Clear all images
        fun clearImages() {
            images.clear()
        }

    }


}
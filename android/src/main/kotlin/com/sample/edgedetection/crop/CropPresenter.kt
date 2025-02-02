package com.sample.edgedetection.crop

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.Bundle
import android.util.Log
import android.view.View
import com.sample.edgedetection.ImageModel
import com.sample.edgedetection.SourceManager
import com.sample.edgedetection.base.PathUtils
import com.sample.edgedetection.processor.Corners
import com.sample.edgedetection.processor.TAG
import com.sample.edgedetection.processor.cropPicture
import com.sample.edgedetection.processor.enhancePicture
import io.reactivex.Observable
import io.reactivex.android.schedulers.AndroidSchedulers
import io.reactivex.schedulers.Schedulers
import org.opencv.android.Utils
import org.opencv.core.Mat
import java.io.File
import java.io.FileOutputStream

class CropPresenter(
    private val iCropView: ICropView.Proxy,
    private val initialBundle: Bundle,
    private val context: Context
) {
    private val picture: Mat? = SourceManager.pic

    private val corners: Corners? = SourceManager.corners
    private var croppedPicture: Mat? = null
    private var enhancedPicture: Bitmap? = null
    private var croppedBitmap: Bitmap? = null
    private var rotateBitmap: Bitmap? = null
    private var rotateBitmapDegree: Int = -90

    private var paperWidth: Int = 0
    private var paperHeight: Int = 0

    fun onViewsReady(paperWidth: Int, paperHeight: Int) {
        this.paperWidth = paperWidth
        this.paperHeight = paperHeight

        iCropView.getPaperRect().onCorners2Crop(corners, picture?.size(), paperWidth, paperHeight)
        val bitmap = Bitmap.createBitmap(
            picture?.width() ?: 1080, picture?.height() ?: 1920, Bitmap.Config.ARGB_8888
        )
        Utils.matToBitmap(picture, bitmap, true)
        iCropView.getPaper().setImageBitmap(bitmap)
    }

    fun crop() {
        if (picture == null) {
            Log.i(TAG, "picture null?")
            return
        }

        if (croppedBitmap != null) {
            Log.i(TAG, "already cropped")
            return
        }

        Observable.create<Mat> {
            it.onNext(cropPicture(picture, iCropView.getPaperRect().getCorners2Crop()))
        }.subscribeOn(Schedulers.computation()).observeOn(AndroidSchedulers.mainThread())
            .subscribe { pc ->
                Log.i(TAG, "cropped picture: $pc")
                // Update corners to SourceManager
                SourceManager.corners = Corners(
                    corners = iCropView.getPaperRect().getCorners2CropResized(),
                    size = picture.size()
                )

                // Log the corners
                Log.i(TAG, "CORNERS: ${SourceManager.corners}")

                croppedPicture = pc
                croppedBitmap =
                    Bitmap.createBitmap(pc.width(), pc.height(), Bitmap.Config.ARGB_8888)
                Utils.matToBitmap(pc, croppedBitmap)
                iCropView.getCroppedPaper().setImageBitmap(croppedBitmap)
                iCropView.getPaper().visibility = View.GONE
                iCropView.getPaperRect().visibility = View.GONE
            }
    }

    fun resetImageBeforeCrop() {
        iCropView.getPaper().visibility = View.VISIBLE
        iCropView.getPaperRect().visibility = View.VISIBLE
        iCropView.getCroppedPaper().setImageBitmap(null)

        val cornersReset = corners ?: SourceManager.corners

        iCropView.getPaperRect().onCorners2Crop(cornersReset , picture?.size(), paperWidth, paperHeight)
        val bitmap = Bitmap.createBitmap(
            picture?.width() ?: 1080, picture?.height() ?: 1920, Bitmap.Config.ARGB_8888
        )
        Utils.matToBitmap(picture, bitmap, true)
        iCropView.getPaper().setImageBitmap(bitmap)

        croppedBitmap = null
        enhancedPicture = null
        rotateBitmap = null
    }

    fun enhance() {
        if (croppedBitmap == null) {
            Log.i(TAG, "picture null?")
            return
        }

        val imgToEnhance: Bitmap? = when {
            enhancedPicture != null -> {
                enhancedPicture
            }

            rotateBitmap != null -> {
                rotateBitmap
            }

            else -> {
                croppedBitmap
            }
        }

        Observable.create<Bitmap> {
            it.onNext(enhancePicture(imgToEnhance))
        }.subscribeOn(Schedulers.io()).observeOn(AndroidSchedulers.mainThread()).subscribe { pc ->

            enhancedPicture = pc
            rotateBitmap = enhancedPicture

            iCropView.getCroppedPaper().setImageBitmap(pc)
        }
    }

    fun reset() {
        if (croppedBitmap == null) {
            Log.i(TAG, "picture null?")
            return
        }
        rotateBitmap = croppedBitmap
        enhancedPicture = croppedBitmap

        iCropView.getCroppedPaper().setImageBitmap(croppedBitmap)
    }

    fun rotate() {
        if (croppedBitmap == null && enhancedPicture == null) {
            Log.i(TAG, "picture null?")
            return
        }

        if (enhancedPicture != null && rotateBitmap == null) {
            Log.i(TAG, "enhancedPicture ***** TRUE")
            rotateBitmap = enhancedPicture
        }

        if (rotateBitmap == null) {
            Log.i(TAG, "rotateBitmap ***** TRUE")
            rotateBitmap = croppedBitmap
        }

        Log.i(TAG, "ROTATE BITMAP DEGREE --> $rotateBitmapDegree")

        rotateBitmap = rotateBitmap?.rotateInt(rotateBitmapDegree)

        iCropView.getCroppedPaper().setImageBitmap(rotateBitmap)

        enhancedPicture = rotateBitmap
        croppedBitmap = croppedBitmap?.rotateInt(rotateBitmapDegree)
    }

    fun save(onSaveSuccess: () -> Unit) {

        val path = PathUtils.getFilesDir(context)

        // Create image path by current system milliseconds and jpeg fomat:  "${(DateTime.now().millisecondsSinceEpoch / 1000).round()}.jpeg");
        val imageFilePath = "$path/${(System.currentTimeMillis() / 1000)}.jpeg"

        val defaultCorners = Corners(
            corners = iCropView.getPaperRect().getCorners2CropResized(),
            size =  picture?.size() ?: org.opencv.core.Size(0.0, 0.0)
        )

        val corners = SourceManager.corners ?: defaultCorners

        val imageModel = ImageModel(
            pic = picture, corners = corners, croppedBitmap = croppedBitmap, path = imageFilePath
        )

        if (SourceManager.selectedIndex != -1) {
            SourceManager.images[SourceManager.selectedIndex] = imageModel
            onSaveSuccess()
            return
        }

        SourceManager.addImage(imageModel)
        onSaveSuccess()
    }

    // Extension function to rotate a bitmap
    private fun Bitmap.rotateInt(degree: Int): Bitmap {
        // Initialize a new matrix
        val matrix = Matrix()

        // Rotate the bitmap
        matrix.postRotate(degree.toFloat())

        // Resize the bitmap
        val scaledBitmap = Bitmap.createScaledBitmap(
            this, width, height, true
        )

        // Create and return the rotated bitmap
        return Bitmap.createBitmap(
            scaledBitmap, 0, 0, scaledBitmap.width, scaledBitmap.height, matrix, true
        )
    }
}

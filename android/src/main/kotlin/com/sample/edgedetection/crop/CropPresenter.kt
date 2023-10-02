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

        iCropView.getPaperRect().onCorners2Crop(corners, picture?.size(), paperWidth, paperHeight)
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

    fun save(cropIndex: Int, onSaveSuccess: () -> Unit) {

        val path = PathUtils.getFilesDir(context)

        // Create image path by current system milliseconds and jpeg fomat:  "${(DateTime.now().millisecondsSinceEpoch / 1000).round()}.jpeg");
        val imageFilePath = "$path/${(System.currentTimeMillis() / 1000)}.jpeg"

        Log.i("HUNG_DEVxx", "save: $imageFilePath")

        val imageModel = ImageModel(
            pic = picture, corners = corners, croppedBitmap = croppedBitmap, path = imageFilePath
        )
        Log.i("HUNG_DEVxx", "save: $cropIndex")

        if (cropIndex != -1) {
            Log.i("HUNG_DEVxx", "save: #1")
            SourceManager.images[cropIndex] = imageModel
            onSaveSuccess()
            return
        }
        Log.i("HUNG_DEVxx", "save: #2")
        SourceManager.addImage(imageModel)
        onSaveSuccess()
        return

        // Copy from cropedBitmap to originalBitmap

        val originalBitmap: Bitmap? = croppedBitmap?.let { Bitmap.createBitmap(it) }

//        val file = File(initialBundle.getString(EdgeDetectionHandler.SAVE_TO) as String)
        val file = File(imageFilePath)

        val rotatePic = rotateBitmap
        if (null != rotatePic) {
            val outStream = FileOutputStream(file)
            rotatePic.compress(Bitmap.CompressFormat.JPEG, 100, outStream)
            outStream.flush()
            outStream.close()
            rotatePic.recycle()
            Log.i(TAG, "RotateBitmap Saved")
        } else {
            // first save enhanced picture, if picture is not enhanced, save cropped picture, otherwise nothing to do
            val pic = enhancedPicture

            if (null != pic) {
                val outStream = FileOutputStream(file)
                pic.compress(Bitmap.CompressFormat.JPEG, 100, outStream)
                outStream.flush()
                outStream.close()
                pic.recycle()
                Log.i(TAG, "EnhancedPicture Saved")
            } else {
                val cropPic = croppedBitmap
                if (null != cropPic) {
                    val outStream = FileOutputStream(file)
                    cropPic.compress(Bitmap.CompressFormat.JPEG, 100, outStream)
                    outStream.flush()
                    outStream.close()
                    cropPic.recycle()
                    Log.i(TAG, "CroppedBitmap Saved")
                }
            }
        }

//        val imageModel = ImageModel(
//            pic = picture,
//            corners = corners,
//            croppedBitmap = originalBitmap,
//            path = imageFilePath
//        )
//        SourceManager.addImage(imageModel)
//        onSaveSuccess()
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

package com.sample.edgedetection.scan

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.ImageDecoder
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.*
import android.widget.ImageView
import android.widget.TextView
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.exifinterface.media.ExifInterface
import com.sample.edgedetection.ERROR_CODE
import com.sample.edgedetection.EdgeDetectionHandler
import com.sample.edgedetection.R
import com.sample.edgedetection.REQUEST_CODE
import com.sample.edgedetection.SourceManager
import com.sample.edgedetection.base.BaseActivity
import com.sample.edgedetection.review.ReviewActivity
import com.sample.edgedetection.view.PaperRectangle
import org.opencv.android.OpenCVLoader
import org.opencv.core.Core
import org.opencv.core.CvType
import org.opencv.core.Mat
import org.opencv.core.Size
import org.opencv.imgcodecs.Imgcodecs
import java.io.*

class ScanActivity : BaseActivity(), IScanView.Proxy {

    private lateinit var mPresenter: ScanPresenter

    private lateinit var flashIcon: ImageView

    private lateinit var autoCaptureOn: View

    private lateinit var autoCaptureOff: View

    private lateinit var imagePreviewContainer: View

    private lateinit var imageCount: TextView

    private lateinit var imagePreview: ImageView

    private lateinit var initialBundle: Bundle


    override fun provideContentViewId(): Int = R.layout.activity_scan

    override fun initPresenter() {
        initialBundle = intent.getBundleExtra(EdgeDetectionHandler.INITIAL_BUNDLE) as Bundle
        mPresenter = ScanPresenter(this, this, initialBundle)
    }

    override fun prepare() {
        if (!OpenCVLoader.initDebug()) {
            Log.i(TAG, "loading opencv error, exit")
            finish()
        }
        else {
            Log.i("OpenCV", "OpenCV loaded Successfully!");
        }

        flashIcon = findViewById(R.id.flash)

        // Default flash off
        flashIcon.setImageDrawable(
            ContextCompat.getDrawable(
                this, R.drawable.ic_baseline_flash_off_24
            )
        )

        // Auto capture view
        autoCaptureOn = findViewById(R.id.auto_capture_on)

        autoCaptureOff = findViewById(R.id.auto_capture_off)

        imagePreviewContainer = findViewById(R.id.imagePreviewContainer)
        imageCount = findViewById(R.id.imageCount)
        imagePreview = findViewById(R.id.imagePreview)

        imagePreview.setOnClickListener {
            if (SourceManager.images.isNotEmpty()) {
                val intent = Intent(this, ReviewActivity::class.java)
                intent.putExtra(EdgeDetectionHandler.INITIAL_BUNDLE, this.initialBundle)
                startActivityForResult(intent, REQUEST_CODE)
            }
        }

        updateImageReview()

        // Default auto capture off
        autoCaptureOn.visibility = View.GONE
        autoCaptureOff.visibility = View.VISIBLE

        autoCaptureOn.setOnClickListener {
            onAutoCaptureClicked()
        }

        autoCaptureOff.setOnClickListener {
            onAutoCaptureClicked()
        }

        // Back button
        findViewById<View>(R.id.close).setOnClickListener {
            onBackPressed()
        }

        findViewById<View>(R.id.shut).setOnClickListener {
            if (mPresenter.canShut) {
                mPresenter.shut()
            }
        }

        // to hide the flashLight button from  SDK versions which we do not handle the permission for!
        flashIcon.visibility =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && Build.VERSION.SDK_INT <= Build.VERSION_CODES.TIRAMISU && baseContext.packageManager.hasSystemFeature(
                    PackageManager.FEATURE_CAMERA_FLASH
                )
            ) View.VISIBLE else View.GONE

        findViewById<View>(R.id.flash).setOnClickListener {
            mPresenter.toggleFlash()
            if (mPresenter.getFlashStatus()) {
                flashIcon.setImageDrawable(
                    ContextCompat.getDrawable(
                        this, R.drawable.ic_baseline_flash_on_24
                    )
                )
            } else {
                flashIcon.setImageDrawable(
                    ContextCompat.getDrawable(
                        this, R.drawable.ic_baseline_flash_off_24
                    )
                )
            }
        }

        val initialBundle = intent.getBundleExtra(EdgeDetectionHandler.INITIAL_BUNDLE) as Bundle

        if (!initialBundle.containsKey(EdgeDetectionHandler.FROM_GALLERY)) {
            this.title = initialBundle.getString(EdgeDetectionHandler.SCAN_TITLE, "") as String
        }

        findViewById<View>(R.id.gallery).visibility =
            if (initialBundle.getBoolean(EdgeDetectionHandler.CAN_USE_GALLERY, true)) View.VISIBLE
            else View.GONE

        // Hide can use gallery button
        findViewById<View>(R.id.gallery).visibility = View.GONE

        findViewById<View>(R.id.gallery).setOnClickListener {
            pickupFromGallery()
        }

        if (initialBundle.containsKey(EdgeDetectionHandler.FROM_GALLERY) && initialBundle.getBoolean(
                EdgeDetectionHandler.FROM_GALLERY, false
            )
        ) {
            pickupFromGallery()
        }
    }

    private fun onAutoCaptureClicked() {
        mPresenter.toggleAutoCapture()

        if (mPresenter.isAutoCapture) {
            autoCaptureOn.visibility = View.VISIBLE
            autoCaptureOff.visibility = View.GONE
        } else {
            autoCaptureOn.visibility = View.GONE
            autoCaptureOff.visibility = View.VISIBLE
        }
    }

    private fun pickupFromGallery() {
        mPresenter.stop()
        val gallery = Intent(
            Intent.ACTION_PICK, android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        ).apply { type = "image/*" }
        ActivityCompat.startActivityForResult(this, gallery, 1, null)
    }

    override fun onStart() {
        super.onStart()
        mPresenter.start()
    }

    override fun onStop() {
        super.onStop()
        mPresenter.stop()
    }

    override fun exit() {
        finish()
    }

    override fun getCurrentDisplay(): Display? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            this.display
        } else {
            this.windowManager.defaultDisplay
        }
    }

    override fun getSurfaceView() = findViewById<SurfaceView>(R.id.surface)

    override fun getPaperRect() = findViewById<PaperRectangle>(R.id.paper_rect)

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        Log.i("HUNG_DEV", "onActivityResult #0: " + requestCode + " " + resultCode)
        Log.i("HUNG_DEV", "REQUEST_CODE : " + REQUEST_CODE)

        if (requestCode == REQUEST_CODE) {
            Log.i("HUNG_DEV", "onActivityResult: #1")
            if (resultCode == Activity.RESULT_OK) {
                Log.i("HUNG_DEV", "onActivityResult: #2")

                setResult(Activity.RESULT_OK)
                finish()
            } else {
                if (intent.hasExtra(EdgeDetectionHandler.FROM_GALLERY) && intent.getBooleanExtra(
                        EdgeDetectionHandler.FROM_GALLERY, false
                    )
                ) finish()
            }
        }

        if (requestCode == 1) {
            Log.i("HUNG_DEV", "onActivityResult: #3")
            if (resultCode == Activity.RESULT_OK) {
                val uri: Uri = data!!.data!!
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    onImageSelected(uri)
                }
            } else {
                if (intent.hasExtra(EdgeDetectionHandler.FROM_GALLERY) && intent.getBooleanExtra(
                        EdgeDetectionHandler.FROM_GALLERY, false
                    )
                ) finish()
            }
        }
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean = when (item.itemId) {
        android.R.id.home -> {
            onBackPressed()
            true
        }

        else -> super.onOptionsItemSelected(item)
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    fun onImageSelected(imageUri: Uri) {
        try {
            val iStream: InputStream = contentResolver.openInputStream(imageUri)!!

            val exif = ExifInterface(iStream)
            var rotation = -1
            val orientation: Int = exif.getAttributeInt(
                ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_UNDEFINED
            )
            when (orientation) {
                ExifInterface.ORIENTATION_ROTATE_90 -> rotation = Core.ROTATE_90_CLOCKWISE
                ExifInterface.ORIENTATION_ROTATE_180 -> rotation = Core.ROTATE_180
                ExifInterface.ORIENTATION_ROTATE_270 -> rotation = Core.ROTATE_90_COUNTERCLOCKWISE
            }
            val mimeType = contentResolver.getType(imageUri)
            var imageWidth: Double
            var imageHeight: Double

            if (mimeType?.startsWith("image/png") == true) {
                val source = ImageDecoder.createSource(contentResolver, imageUri)
                val drawable = ImageDecoder.decodeDrawable(source)

                imageWidth = drawable.intrinsicWidth.toDouble()
                imageHeight = drawable.intrinsicHeight.toDouble()

                if (rotation == Core.ROTATE_90_CLOCKWISE || rotation == Core.ROTATE_90_COUNTERCLOCKWISE) {
                    imageWidth = drawable.intrinsicHeight.toDouble()
                    imageHeight = drawable.intrinsicWidth.toDouble()
                }
            } else {
                imageWidth = exif.getAttributeInt(ExifInterface.TAG_IMAGE_WIDTH, 0).toDouble()
                imageHeight = exif.getAttributeInt(ExifInterface.TAG_IMAGE_LENGTH, 0).toDouble()
                if (rotation == Core.ROTATE_90_CLOCKWISE || rotation == Core.ROTATE_90_COUNTERCLOCKWISE) {
                    imageWidth = exif.getAttributeInt(ExifInterface.TAG_IMAGE_LENGTH, 0).toDouble()
                    imageHeight = exif.getAttributeInt(ExifInterface.TAG_IMAGE_WIDTH, 0).toDouble()
                }
            }

            val inputData: ByteArray? = getBytes(contentResolver.openInputStream(imageUri)!!)
            val mat = Mat(Size(imageWidth, imageHeight), CvType.CV_8U)
            mat.put(0, 0, inputData)
            val pic = Imgcodecs.imdecode(mat, Imgcodecs.CV_LOAD_IMAGE_UNCHANGED)
            if (rotation > -1) Core.rotate(pic, pic, rotation)
            mat.release()

            mPresenter.detectEdge(pic)
        } catch (error: Exception) {
            val intent = Intent()
            intent.putExtra("RESULT", error.toString())
            setResult(ERROR_CODE, intent)
            finish()
        }

    }

    @Throws(IOException::class)
    fun getBytes(inputStream: InputStream): ByteArray? {
        val byteBuffer = ByteArrayOutputStream()
        val bufferSize = 1024
        val buffer = ByteArray(bufferSize)
        var len: Int
        while (inputStream.read(buffer).also { len = it } != -1) {
            byteBuffer.write(buffer, 0, len)
        }
        return byteBuffer.toByteArray()
    }


    private fun updateImageReview() {
        val images = SourceManager.images
        if (images.isEmpty()) {
            imagePreviewContainer.visibility = View.INVISIBLE
            return
        }
        imagePreviewContainer.visibility = View.VISIBLE
        imageCount.text = "${images.size}"
        imagePreview.setImageBitmap(images[0].croppedBitmap)

    }

    override fun onResume() {
        super.onResume()

        updateImageReview()
    }
}

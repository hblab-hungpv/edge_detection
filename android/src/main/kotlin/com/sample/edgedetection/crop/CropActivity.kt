package com.sample.edgedetection.crop

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import com.sample.edgedetection.EdgeDetectionHandler
import com.sample.edgedetection.R
import com.sample.edgedetection.SourceManager
import com.sample.edgedetection.base.BaseActivity
import com.sample.edgedetection.review.ReviewActivity
import com.sample.edgedetection.view.PaperRectangle

class CropActivity : BaseActivity(), ICropView.Proxy {

    private var showMenuItems = false

    private lateinit var mPresenter: CropPresenter

    private lateinit var initialBundle: Bundle

    private lateinit var closeIcon: ImageView

    private lateinit var header: TextView

    private lateinit var cropContainer: View

    private lateinit var previewContainer: View

    private lateinit var cropPreview: View

    private lateinit var donePreview: View

    private lateinit var crop: LinearLayout

    private lateinit var imagePreviewContainer: View

    private lateinit var imageCount: TextView

    private lateinit var imagePreview: ImageView

    private var cropIndex: Int = -1

    override fun prepare() {
        this.initialBundle = intent.getBundleExtra(EdgeDetectionHandler.INITIAL_BUNDLE) as Bundle
        this.cropIndex = intent.getIntExtra(EdgeDetectionHandler.CROP_INDEX, -1)
        Log.i("HUNG_DEVxx", "prepare: cropIndex: $cropIndex")
        this.title = initialBundle.getString(EdgeDetectionHandler.CROP_TITLE)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        findViewById<View>(R.id.paper).post {
            // we have to initialize everything in post when the view has been drawn and we have the actual height and width of the whole view
            mPresenter.onViewsReady(
                findViewById<View>(R.id.paper).width,
                findViewById<View>(R.id.paper).height
            )
        }
    }

    override fun provideContentViewId(): Int = R.layout.activity_crop


    override fun initPresenter() {
        val initialBundle = intent.getBundleExtra(EdgeDetectionHandler.INITIAL_BUNDLE) as Bundle
        mPresenter = CropPresenter(this, initialBundle, this)
        closeIcon = findViewById(R.id.close)
        header = findViewById(R.id.crop_header)
        cropContainer = findViewById(R.id.crop_container)
        previewContainer = findViewById(R.id.preview_container)
        cropPreview = findViewById(R.id.crop_preview)
        donePreview = findViewById(R.id.done_preview)
        crop = findViewById(R.id.crop)
        imagePreviewContainer = findViewById(R.id.imagePreviewContainer)
        imageCount = findViewById(R.id.imageCount)
        imagePreview = findViewById(R.id.imagePreview)

        closeIcon.setOnClickListener {
            finish()
        }
        crop.setOnClickListener {
            Log.e(TAG, "Crop touched!")
            mPresenter.crop()
            // Update layout after crop
            updateLayoutCrop(false)
            changeMenuVisibility(true)
        }

        cropPreview.setOnClickListener {
            updateLayoutCrop(true)
            mPresenter.resetImageBeforeCrop()
        }

        donePreview.setOnClickListener {
            /*mPresenter.rotate()
           // Delay 2s
            Handler().postDelayed({
                mPresenter.save()
                setResult(Activity.RESULT_OK)
                System.gc()
                finish()
            }, 2000)*/

            mPresenter.save(this.cropIndex, ::onSaveSuccess)
//            setResult(Activity.RESULT_OK)
//            System.gc()
//            finish()

        }

        imagePreview.setOnClickListener {
            if (SourceManager.images.isNotEmpty()) {
                val reviewIntent = Intent(this, ReviewActivity::class.java)
                reviewIntent.putExtra(EdgeDetectionHandler.INITIAL_BUNDLE, initialBundle)
                startActivity(reviewIntent)
            }
        }

        updateImageReview()
    }

    private fun onSaveSuccess() {
        if (cropIndex != -1) {
            val data = Intent()
            data.putExtra(EdgeDetectionHandler.CROP_INDEX, cropIndex)
            setResult(Activity.RESULT_OK, data)
            finish()
            return
        }
        finish()
    }

    private fun updateLayoutCrop(isCrop: Boolean) {
        if (isCrop) {
            header.text = getString(R.string.crop)
            cropContainer.visibility = View.VISIBLE
            previewContainer.visibility = View.GONE
        } else {
            header.text = getString(R.string.preview)
            cropContainer.visibility = View.GONE
            previewContainer.visibility = View.VISIBLE
        }
    }

    override fun getPaper(): ImageView = findViewById(R.id.paper)

    override fun getPaperRect() = findViewById<PaperRectangle>(R.id.paper_rect)

    override fun getCroppedPaper() = findViewById<ImageView>(R.id.picture_cropped)

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.crop_activity_menu, menu)

        menu.setGroupVisible(R.id.enhance_group, showMenuItems)

        menu.findItem(R.id.rotation_image).isVisible = showMenuItems

        menu.findItem(R.id.gray).title =
            initialBundle.getString(EdgeDetectionHandler.CROP_BLACK_WHITE_TITLE) as String
        menu.findItem(R.id.reset).title =
            initialBundle.getString(EdgeDetectionHandler.CROP_RESET_TITLE) as String

        if (showMenuItems) {
            menu.findItem(R.id.action_label).isVisible = true
            findViewById<ImageView>(R.id.crop).visibility = View.GONE
        } else {
            menu.findItem(R.id.action_label).isVisible = false
            findViewById<ImageView>(R.id.crop).visibility = View.VISIBLE
        }

        return super.onCreateOptionsMenu(menu)
    }


    private fun changeMenuVisibility(showMenuItems: Boolean) {
        this.showMenuItems = showMenuItems
        invalidateOptionsMenu()
    }

    // handle button activities
    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        when (item.itemId) {
            android.R.id.home -> {
                onBackPressed()
                return true
            }

            R.id.action_label -> {
                Log.e(TAG, "Saved touched!")
                item.isEnabled = false
                mPresenter.save(this.cropIndex, ::onSaveSuccess)
                setResult(Activity.RESULT_OK)
                System.gc()
                finish()
                return true
            }

            R.id.rotation_image -> {
                Log.e(TAG, "Rotate touched!")
                mPresenter.rotate()
                return true
            }

            R.id.gray -> {
                Log.e(TAG, "Black White touched!")
                mPresenter.enhance()
                return true
            }

            R.id.reset -> {
                Log.e(TAG, "Reset touched!")
                mPresenter.reset()
                return true
            }

            else -> return super.onOptionsItemSelected(item)
        }
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

package com.sample.edgedetection.review

import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.sample.edgedetection.EdgeDetectionHandler
import com.sample.edgedetection.ImageModel
import com.sample.edgedetection.R
import com.sample.edgedetection.SourceManager
import com.sample.edgedetection.base.BaseActivity
import com.sample.edgedetection.crop.CropActivity
import java.io.File
import java.io.FileOutputStream

class ReviewActivity : BaseActivity() {

    lateinit var paper: ImageView

    lateinit var previousImage: ImageView

    lateinit var nextImage: ImageView

    lateinit var currentPage: TextView

    lateinit var deleteButton: View

    lateinit var cropButton: View

    lateinit var rotateButton: View

    lateinit var rcImages: RecyclerView

    lateinit var saveDraft: View

    lateinit var submitButton: Button


    private var currentIndex = 0

    private lateinit var adapter: ImageAdapter

    private lateinit var initialBundle: Bundle

    private var rotateBitmapDegree: Int = -90

    companion object {
        const val CROP_REQUEST_CODE = 100
        const val SUBMIT_RESULT_CODE = "submit_result_code"
    }

    override fun provideContentViewId(): Int {
        return R.layout.activity_review
    }

    override fun initPresenter() {

        paper = findViewById(R.id.paper)
        previousImage = findViewById(R.id.previous_page)
        nextImage = findViewById(R.id.next_page)
        currentPage = findViewById(R.id.current_page)
        deleteButton = findViewById(R.id.delete_button)
        cropButton = findViewById(R.id.crop_button)
        rotateButton = findViewById(R.id.rotate_button)
        rcImages = findViewById(R.id.rc_images)
        saveDraft = findViewById(R.id.save_draft)
        submitButton = findViewById(R.id.submit_button)
    }

    override fun prepare() {

        this.initialBundle = intent.getBundleExtra(EdgeDetectionHandler.INITIAL_BUNDLE) as Bundle

        currentIndex = 0
        adapter = ImageAdapter(object : ImageAdapter.OnItemClickListener {
            override fun onItemClick(position: Int) {
                changeImageSelected(position)
            }
        })

        previousImage.setOnClickListener {
            if (currentIndex > 0) {
                currentIndex--
                changeImageSelected(currentIndex)
            }
            if (currentIndex == 0) {
                currentIndex = SourceManager.images.size - 1
            }

            changeImageSelected(currentIndex)
        }

        nextImage.setOnClickListener {
            val lastIndex = SourceManager.images.size - 1
            if (currentIndex < lastIndex) {
                currentIndex++

            }
            if (currentIndex == lastIndex) {
                currentIndex = 0
            }

            changeImageSelected(currentIndex)
        }

        deleteButton.setOnClickListener {
            SourceManager.removeImage(currentIndex)
            if (SourceManager.images.isEmpty()) {
                finish()
            } else {
                if (currentIndex > 0) {
                    currentIndex--
                }
                changeImageSelected(currentIndex)
            }
        }

        cropButton.setOnClickListener {
            SourceManager.pic = SourceManager.images[currentIndex].pic
            SourceManager.corners = SourceManager.images[currentIndex].corners
            val cropIntent = Intent(this, CropActivity::class.java)
            cropIntent.putExtra(EdgeDetectionHandler.INITIAL_BUNDLE, this.initialBundle)
            Log.i("HUNG_DEVxx", "prepare: $currentIndex")
            cropIntent.putExtra(EdgeDetectionHandler.CROP_INDEX, currentIndex)
            startActivityForResult(cropIntent, CROP_REQUEST_CODE)
        }

        rotateButton.setOnClickListener {
            // Update bitmap
            SourceManager.images[currentIndex].croppedBitmap =
                SourceManager.images[currentIndex].croppedBitmap?.rotateInt(rotateBitmapDegree)
            updateImage()
            changeImageSelected(currentIndex)
        }

        submitButton.setOnClickListener {
            saveAllImages()
        }

        // Focus first image.
        changeImageSelected(0)
        updateImages()
    }

    private fun saveAllImages() {
        SourceManager.images.forEachIndexed { index, imageModel ->
            Log.i("HUNG_DEVxx", "saveAllImages: $index")
            val file = imageModel.path?.let { File(it) }
            val cropPic = imageModel.croppedBitmap
            if (null != cropPic) {
                val outStream = FileOutputStream(file)
                cropPic.compress(Bitmap.CompressFormat.JPEG, 100, outStream)
                outStream.flush()
                outStream.close()
//                cropPic.recycle()
                Log.i(com.sample.edgedetection.processor.TAG, "CroppedBitmap Saved")
            }
        }
        setResult(RESULT_OK)
        finish()
        Log.i("HUNG_DEVxx", "saveAllImages: DONE")
    }

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

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == CROP_REQUEST_CODE) {
            if (resultCode == RESULT_OK) {
                val updatedIndex = data?.getIntExtra(EdgeDetectionHandler.CROP_INDEX, -1) ?: -1
                Log.i("HUNG_DEVxx", "onActivityResult: $updatedIndex")
                changeImageSelected(updatedIndex)
                return
            }
        }
    }

    private fun changeImageSelected(selectedIndex: Int) {
        currentIndex = selectedIndex
        updateImage()

        SourceManager.images.forEachIndexed { index, imageModel ->
            imageModel.isSelected = index == selectedIndex
        }

        // Notify adapter to update the list
        adapter.notifyDataSetChanged()
    }

    private fun updateImages() {
        rcImages.layoutManager = LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false)

        rcImages.adapter = adapter
    }

    private fun updateImage() {
        if (SourceManager.images.isEmpty()) {
            Log.i(TAG, "No images to review")
            return
        }
        val image = SourceManager.images[currentIndex]

        paper.setImageBitmap(image.croppedBitmap)
        currentPage.text = "${currentIndex + 1}/${SourceManager.images.size}"
    }

}


class ImageAdapter(private var onItemClick: OnItemClickListener) :
    RecyclerView.Adapter<ImageAdapter.ImageViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ImageViewHolder {
        return ImageViewHolder(
            LayoutInflater.from(parent.context).inflate(R.layout.item_image, parent, false)
        )
    }

    override fun getItemCount(): Int {
        return SourceManager.images.size
    }

    override fun onBindViewHolder(holder: ImageViewHolder, position: Int) {
        holder.bind(SourceManager.images[position])
    }

    inner class ImageViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        fun bind(image: ImageModel) {
            val container = itemView.findViewById<LinearLayout>(R.id.imagePreviewContainer)
            val paper = itemView.findViewById<ImageView>(R.id.imagePreview)
            if (image.croppedBitmap != null) {
                paper.setImageBitmap(image.croppedBitmap)
            }

            if (image.isSelected) {
                container.setBackgroundResource(R.drawable.image_selected_bg)
            } else {
                container.setBackgroundResource(R.drawable.image_unselected_bg)
            }

            itemView.setOnClickListener {
                onItemClick.onItemClick(adapterPosition)
            }
        }
    }

    // Create interface to handle click event
    interface OnItemClickListener {
        fun onItemClick(position: Int)
    }
}
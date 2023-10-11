//
//  EditScanViewController.swift
//  WeScan
//
//  Created by Boris Emorine on 2/12/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import AVFoundation
import UIKit

/// The `EditScanViewController` offers an interface for the user to edit the detected quadrilateral.
final class EditScanViewController: UIViewController {
    
    private let screenHeight = UIScreen.main.bounds.height
    
    private var footerHeight = CGFloat(100)
    
    private lazy var footerContainer: UIView = {
        let footerContainer = UIView()
        footerContainer.translatesAutoresizingMaskIntoConstraints = false
        footerContainer.backgroundColor = .black
        return footerContainer
    }()
    
    private lazy var contentContainer: UIView = {
        let contentContainer = UIView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.backgroundColor = .black
        return contentContainer
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.isOpaque = true
        imageView.image = image
        imageView.backgroundColor = .black
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var quadView: QuadrilateralView = {
        let quadView = QuadrilateralView()
        quadView.editable = true
        quadView.translatesAutoresizingMaskIntoConstraints = false
        return quadView
    }()

    private lazy var nextButton: UIBarButtonItem = {
        let title = NSLocalizedString("wescan.edit.button.next",
                                      tableName: nil,
                                      bundle: Bundle(for: EditScanViewController.self),
                                      value: "Next",
                                      comment: "A generic next button"
        )
        let button = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(pushReviewController))
        button.tintColor = navigationController?.navigationBar.tintColor
        return button
    }()
    
    private lazy var doneIcon: UIImageView = {
        // Create an UIImageView for the check image
        let checkImageView = UIImageView()
        checkImageView.image = UIImage(named: "done")
        checkImageView.translatesAutoresizingMaskIntoConstraints = false
        return checkImageView
    }()
    
    
    private lazy var doneLabel: UILabel = {
        // Create a UILabel for the "Done" text
        let doneLabel = UILabel()
        doneLabel.text = "Done"
        doneLabel.textColor = .white
        doneLabel.translatesAutoresizingMaskIntoConstraints = false
        return doneLabel
    }()
    
    
    private lazy var doneButtonContainer: UIView = {
       let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor(hex: 0x383838)
        // Set event click
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pushReviewController))
        container.addGestureRecognizer(tapGesture)
        return container
    }()

    private lazy var cancelButton: UIBarButtonItem = {
        // Close image
        let closeImage = UIImage(named: "close")
        
        let button = UIBarButtonItem(image: closeImage, style: .plain, target: self, action: #selector(cancelButtonTapped))
        button.tintColor = navigationController?.navigationBar.tintColor
        return button
    }()
    
    private lazy var previewImageContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
    
        let tap = UITapGestureRecognizer(target: self, action: #selector(previewImageTapped))
        view.addGestureRecognizer(tap)
        
        return view
    }()
    
    private lazy var previewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleToFill
        imageView.layer.cornerRadius = 4
        imageView.clipsToBounds = true
        imageView.backgroundColor = .black
        return imageView
    }()
    
    private lazy var countLabelView: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.text = "1"
        return label
    }()
    
    private lazy var circleLabelCountContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .red
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        return view
    }()

    /// The image the quadrilateral was detected on.
    private let image: UIImage

    /// The detected quadrilateral that can be edited by the user. Uses the image's coordinates.
    private var quad: Quadrilateral

    private var zoomGestureController: ZoomGestureController!

    private var quadViewWidthConstraint = NSLayoutConstraint()
    private var quadViewHeightConstraint = NSLayoutConstraint()
    
    private var updateIndex: Int?

    // MARK: - Life Cycle

    init(image: UIImage, quad: Quadrilateral?, rotateImage: Bool = true, updateIndex: Int = -1) {
        self.image = rotateImage ? image.applyingPortraitOrientation() : image
        self.quad = quad ?? EditScanViewController.defaultQuad(forImage: image)
        self.updateIndex = updateIndex
        
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Set footer height
        footerHeight = screenHeight / 4
        
        setupViews()
        setupConstraints()
        title = NSLocalizedString("wescan.edit.title",
                                  tableName: nil,
                                  bundle: Bundle(for: EditScanViewController.self),
                                  value: "Crop",
                                  comment: "The title of the EditScanViewController"
        )
        navigationItem.leftBarButtonItem = cancelButton
//        navigationItem.rightBarButtonItem = doneButton
//        if let firstVC = self.navigationController?.viewControllers.first, firstVC == self {
//            navigationItem.leftBarButtonItem = cancelButton
//        } else {
//            navigationItem.leftBarButtonItem = nil
//        }

        zoomGestureController = ZoomGestureController(image: image, quadView: quadView)

        let touchDown = UILongPressGestureRecognizer(target: zoomGestureController, action: #selector(zoomGestureController.handle(pan:)))
        touchDown.minimumPressDuration = 0
//        contentContainer.addGestureRecognizer(touchDown)
        quadView.addGestureRecognizer(touchDown)
        
        // Visibility of preview image container
        previewImageContainer.isHidden = DataSource.images.isEmpty
        
        // Update image preview & count label
        if(!DataSource.images.isEmpty){
            previewImageView.image = DataSource.images[0].croppedScan.image
            countLabelView.text = "\(DataSource.images.count)"
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Show navigation bar
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustQuadViewConstraints()
        displayQuad()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Work around for an iOS 11.2 bug where UIBarButtonItems don't get back to their normal state after being pressed.
        navigationController?.navigationBar.tintAdjustmentMode = .normal
        navigationController?.navigationBar.tintAdjustmentMode = .automatic
    }

    // MARK: - Setups

    private func setupViews() {
        view.addSubview(contentContainer)
        view.addSubview(footerContainer)
        view.addSubview(imageView)
        view.addSubview(quadView)
        footerContainer.addSubview(doneButtonContainer)
        doneButtonContainer.addSubview(doneIcon)
        doneButtonContainer.addSubview(doneLabel)
        
        footerContainer.addSubview(previewImageContainer)
    
        previewImageContainer.addSubview(previewImageView)
        previewImageContainer.addSubview(circleLabelCountContainer)
        circleLabelCountContainer.addSubview(countLabelView)
    }

    private func setupConstraints() {
        
        let footerContainerConstraints = [
            footerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            footerContainer.heightAnchor.constraint(equalToConstant: footerHeight)
        ]
        NSLayoutConstraint.activate(footerContainerConstraints)
        
        // Configure constraints for the contentContainer
        let contentContainerConstraints = [
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.topAnchor.constraint(equalTo: view.topAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: footerContainer.topAnchor)
        ]
        NSLayoutConstraint.activate(contentContainerConstraints)
        
        // Configure constraints for the doneButtonContainer inside and top of the footerContainer
        let doneButtonContainerConstraints = [
            doneButtonContainer.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor),
            doneButtonContainer.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),
            doneButtonContainer.topAnchor.constraint(equalTo: footerContainer.topAnchor),
            doneButtonContainer.heightAnchor.constraint(equalToConstant: 48.0)
        ]
        
        NSLayoutConstraint.activate(doneButtonContainerConstraints)
        
        // Configure constraints to position the checkImageView to the left and doneLabel to the right
        let doneItemConstraints = [
            doneIcon.centerXAnchor.constraint(equalTo: doneButtonContainer.centerXAnchor, constant: -16.0), // Adjust the spacing as needed
            doneIcon.centerYAnchor.constraint(equalTo: doneButtonContainer.centerYAnchor),
            doneLabel.leadingAnchor.constraint(equalTo: doneIcon.trailingAnchor, constant: 4.0),
            doneLabel.centerYAnchor.constraint(equalTo: doneButtonContainer.centerYAnchor)
        ]

        // Activate the constraints
        NSLayoutConstraint.activate(doneItemConstraints)
        
        let imageViewConstraints = [
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: imageView.leadingAnchor)
        ]

        quadViewWidthConstraint = quadView.widthAnchor.constraint(equalToConstant: 0.0)
        quadViewHeightConstraint = quadView.heightAnchor.constraint(equalToConstant: 0.0)

        let quadViewConstraints = [
            quadView.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            quadView.centerYAnchor.constraint(equalTo: contentContainer.centerYAnchor),
            quadViewWidthConstraint,
            quadViewHeightConstraint
        ]

        NSLayoutConstraint.activate(quadViewConstraints + imageViewConstraints)
        
        // Configure preview image container
        let previewImageContainerConstraints = [
            previewImageContainer.centerYAnchor.constraint(equalTo: footerContainer.centerYAnchor),
       
            previewImageContainer.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor, constant: -16.0),
            previewImageContainer.heightAnchor.constraint(equalToConstant: 72.0),
            previewImageContainer.widthAnchor.constraint(equalToConstant: 57.0)
        
        ]
        
        NSLayoutConstraint.activate(previewImageContainerConstraints)
        
        // Configure preview image view
        let previewImageViewConstraints = [
            previewImageView.topAnchor.constraint(equalTo: previewImageContainer.topAnchor, constant: 7.0),
            previewImageView.leadingAnchor.constraint(equalTo: previewImageContainer.leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: previewImageContainer.trailingAnchor, constant: -7.0),
            previewImageView.bottomAnchor.constraint(equalTo: previewImageContainer.bottomAnchor),
            previewImageView.widthAnchor.constraint(equalToConstant: 50.0),
            previewImageView.heightAnchor.constraint(equalToConstant: 65.0)
        
        ]
        
        NSLayoutConstraint.activate(previewImageViewConstraints)
        
        // Configure count label container top left of preview image container
        let circleLabelCountContainerConstraints = [
            circleLabelCountContainer.topAnchor.constraint(equalTo: previewImageContainer.topAnchor),
            circleLabelCountContainer.trailingAnchor.constraint(equalTo: previewImageContainer.trailingAnchor),
            circleLabelCountContainer.widthAnchor.constraint(equalToConstant: 20.0),
            circleLabelCountContainer.heightAnchor.constraint(equalToConstant: 20.0)
        ]
        
        NSLayoutConstraint.activate(circleLabelCountContainerConstraints)
        
        // Config count label
        let countLabelViewConstraints = [
            // Center label in container
            countLabelView.centerXAnchor.constraint(equalTo: circleLabelCountContainer.centerXAnchor),
            countLabelView.centerYAnchor.constraint(equalTo: circleLabelCountContainer.centerYAnchor),
        ]
        
        NSLayoutConstraint.activate(countLabelViewConstraints)
    }

    // MARK: - Actions
    @objc func cancelButtonTapped() {
//        if let imageScannerController = navigationController as? ImageScannerController {
//            imageScannerController.imageScannerDelegate?.imageScannerControllerDidCancel(imageScannerController)
//        }
        
        // Back to the previous view controller
        self.navigationController?.popViewController(animated: true)
    }
    
    // previewImageTapped
    @objc private func previewImageTapped() {
        if(DataSource.images.isEmpty){
            return
        }
        
        let confirmationVC = ConfirmationViewController(activeIndex: -1)
        self.navigationController?.pushViewController(confirmationVC, animated: true)
    }

    @objc func pushReviewController() {
        guard let quad = quadView.quad,
            let ciImage = CIImage(image: image) else {
                if let imageScannerController = navigationController as? ImageScannerController {
                    let error = ImageScannerControllerError.ciImageCreation
                    imageScannerController.imageScannerDelegate?.imageScannerController(imageScannerController, didFailWithError: error)
                }
                return
        }
        let cgOrientation = CGImagePropertyOrientation(image.imageOrientation)
        let orientedImage = ciImage.oriented(forExifOrientation: Int32(cgOrientation.rawValue))
        let scaledQuad = quad.scale(quadView.bounds.size, image.size)
        self.quad = scaledQuad

        // Cropped Image
        var cartesianScaledQuad = scaledQuad.toCartesian(withHeight: image.size.height)
        cartesianScaledQuad.reorganize()

        let filteredImage = orientedImage.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: cartesianScaledQuad.bottomLeft),
            "inputTopRight": CIVector(cgPoint: cartesianScaledQuad.bottomRight),
            "inputBottomLeft": CIVector(cgPoint: cartesianScaledQuad.topLeft),
            "inputBottomRight": CIVector(cgPoint: cartesianScaledQuad.topRight)
        ])

        let croppedImage = UIImage.from(ciImage: filteredImage)
        // Enhanced Image
        let enhancedImage = filteredImage.applyingAdaptiveThreshold()?.withFixedOrientation()
        let enhancedScan = enhancedImage.flatMap { ImageScannerScan(image: $0) }

        let results = ImageScannerResults(
            detectedRectangle: scaledQuad,
            originalScan: ImageScannerScan(image: image),
            croppedScan: ImageScannerScan(image: croppedImage),
            enhancedScan: enhancedScan
        )

        let reviewViewController = ReviewViewController(results: results, updateIndex: updateIndex ?? -1)
        navigationController?.pushViewController(reviewViewController, animated: true)
    }

    private func displayQuad() {
        let imageSize = image.size
        let imageFrame = CGRect(
            origin: quadView.frame.origin,
            size: CGSize(width: quadViewWidthConstraint.constant, height: quadViewHeightConstraint.constant)
        )

        let scaleTransform = CGAffineTransform.scaleTransform(forSize: imageSize, aspectFillInSize: imageFrame.size)
        let transforms = [scaleTransform]
        let transformedQuad = quad.applyTransforms(transforms)

        quadView.drawQuadrilateral(quad: transformedQuad, animated: false)
    }

    /// The quadView should be lined up on top of the actual image displayed by the imageView.
    /// Since there is no way to know the size of that image before run time, we adjust the constraints
    /// to make sure that the quadView is on top of the displayed image.
    private func adjustQuadViewConstraints() {
        let frame = AVMakeRect(aspectRatio: image.size, insideRect: imageView.bounds)
        quadViewWidthConstraint.constant = frame.size.width
        quadViewHeightConstraint.constant = frame.size.height
    }

    /// Generates a `Quadrilateral` object that's centered and 90% of the size of the passed in image.
    private static func defaultQuad(forImage image: UIImage) -> Quadrilateral {
        let topLeft = CGPoint(x: image.size.width * 0.05, y: image.size.height * 0.05)
        let topRight = CGPoint(x: image.size.width * 0.95, y: image.size.height * 0.05)
        let bottomRight = CGPoint(x: image.size.width * 0.95, y: image.size.height * 0.95)
        let bottomLeft = CGPoint(x: image.size.width * 0.05, y: image.size.height * 0.95)

        let quad = Quadrilateral(topLeft: topLeft, topRight: topRight, bottomRight: bottomRight, bottomLeft: bottomLeft)

        return quad
    }

}

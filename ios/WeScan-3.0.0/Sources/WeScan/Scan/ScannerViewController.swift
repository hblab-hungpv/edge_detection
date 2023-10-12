//
//  ScannerViewController.swift
//  WeScan
//
//  Created by Boris Emorine on 2/8/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//
//  swiftlint:disable line_length

import AVFoundation
import UIKit

/// The `ScannerViewController` offers an interface to give feedback to the user regarding quadrilaterals that are detected. It also gives the user the opportunity to capture an image with a detected rectangle.
public final class ScannerViewController: UIViewController {

    private var captureSessionManager: CaptureSessionManager?
    private let videoPreviewLayer = AVCaptureVideoPreviewLayer()

    /// The view that shows the focus rectangle (when the user taps to focus, similar to the Camera app)
    private var focusRectangle: FocusRectangleView!

    /// The view that draws the detected rectangles.
    private let quadView = QuadrilateralView()

    /// Whether flash is enabled
    private var flashEnabled = false

    /// The original bar style that was set by the host app
    private var originalBarStyle: UIBarStyle?
    
    private let screenHeight = UIScreen.main.bounds.height
    
    private var footerHeight = CGFloat(100)
    
    private lazy var footerContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        // Transparent background
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        
        return view
    }()
    
    private lazy var shutterButton: ShutterButton = {
        let button = ShutterButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(captureImage(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var cancelButton: UIBarButtonItem = {
       let image = UIImage(named: "close")

        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(cancelImageScannerController))
        return button
    }()

    private lazy var autoScanButton: UIBarButtonItem = {
        
        let image = UIImage(named: "autoScanOff")
        
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(toggleAutoScan))
        button.tintColor = .white

        return button
    }()

    private lazy var flashButton: UIBarButtonItem = {
        let image = UIImage(named: "flashOff")
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(toggleFlash))
        button.tintColor = .white

        return button
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
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
    

    // MARK: - Life Cycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Set footer height
        footerHeight = screenHeight / 4

        title = nil
        view.backgroundColor = UIColor.black

        setupViews()
        setupNavigationBar()
        setupConstraints()

        captureSessionManager = CaptureSessionManager(videoPreviewLayer: videoPreviewLayer, delegate: self)

        originalBarStyle = navigationController?.navigationBar.barStyle

        NotificationCenter.default.addObserver(self, selector: #selector(subjectAreaDidChange), name: Notification.Name.AVCaptureDeviceSubjectAreaDidChange, object: nil)
        
        // Visibility of preview image container
        previewImageContainer.isHidden = DataSource.images.isEmpty
        
        // Update image preview & count label
        if(!DataSource.images.isEmpty){
            previewImageView.image = DataSource.images[0].croppedScan.image
            countLabelView.text = "\(DataSource.images.count)"
        }
        
        // Update auto scan button
        updateAutoScanButton()
        
    }
    
    private func updateAutoScanButton() {
        
        let image = CaptureSession.current.isAutoScanEnabled ? UIImage(named: "autoScan") : UIImage(named: "autoScanOff")
        
        autoScanButton.image = image
        autoScanButton.tintColor = CaptureSession.current.isAutoScanEnabled ? .green : .white
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()

        CaptureSession.current.isEditing = false
        quadView.removeQuadrilateral()
        captureSessionManager?.start()
        UIApplication.shared.isIdleTimerDisabled = true

        navigationController?.navigationBar.barStyle = .blackTranslucent
        
        // Show navigation bar
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Calculate the frame for the videoPreviewLayer
        
        videoPreviewLayer.frame = view.layer.bounds
    
    }
    

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false

        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barStyle = originalBarStyle ?? .default
        captureSessionManager?.stop()
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        if device.torchMode == .on {
            toggleFlash()
        }
    }

    // MARK: - Setups

    private func setupViews() {
        view.backgroundColor = .darkGray
        view.layer.addSublayer(videoPreviewLayer)
        quadView.translatesAutoresizingMaskIntoConstraints = false
        quadView.editable = false
        view.addSubview(quadView)
        view.addSubview(footerContainer)
        footerContainer.addSubview(shutterButton)
        view.addSubview(activityIndicator)
        view.addSubview(previewImageContainer)
        
        previewImageContainer.addSubview(previewImageView)
        previewImageContainer.addSubview(circleLabelCountContainer)
        circleLabelCountContainer.addSubview(countLabelView)
    }

    private func setupNavigationBar() {
        // Close button
        navigationItem.setLeftBarButton(cancelButton, animated: false)
        
        // Setup title
        let title = NSLocalizedString("wescan.scanning.title", tableName: nil, bundle: Bundle(for: ScannerViewController.self), value: "Camera", comment: "The title of the scanner view controller")
        
        navigationItem.title = title
        
        let rightItems = [flashButton, autoScanButton]
        navigationItem.setRightBarButtonItems(rightItems, animated: false)

        if UIImagePickerController.isFlashAvailable(for: .rear) == false {
            let flashOffImage = UIImage(named: "flashOff")
            flashButton.image = flashOffImage
            flashButton.tintColor = UIColor.lightGray
        }
    }

    private func setupConstraints() {
        var footerContainerConstraints = [NSLayoutConstraint]()
        var quadViewConstraints = [NSLayoutConstraint]()
        var shutterButtonConstraints = [NSLayoutConstraint]()
        var activityIndicatorConstraints = [NSLayoutConstraint]()
        
        footerContainerConstraints = [
            footerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            footerContainer.heightAnchor.constraint(equalToConstant: footerHeight)
        ]
        
        NSLayoutConstraint.activate(footerContainerConstraints)

        // Add shutter button in center of footer container
        shutterButtonConstraints = [
            shutterButton.centerXAnchor.constraint(equalTo: footerContainer.centerXAnchor),
            shutterButton.centerYAnchor.constraint(equalTo: footerContainer.centerYAnchor),
            shutterButton.widthAnchor.constraint(equalToConstant: 65.0),
            shutterButton.heightAnchor.constraint(equalToConstant: 65.0)
        ]
        
        NSLayoutConstraint.activate(shutterButtonConstraints)
    

        quadViewConstraints = [
            quadView.topAnchor.constraint(equalTo: view.topAnchor),
            view.bottomAnchor.constraint(equalTo: quadView.bottomAnchor),
            view.trailingAnchor.constraint(equalTo: quadView.trailingAnchor),
            quadView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ]

        activityIndicatorConstraints = [
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ]

        if #available(iOS 11.0, *) {
            let shutterButtonBottomConstraint = view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: shutterButton.bottomAnchor, constant: 8.0)
            shutterButtonConstraints.append(shutterButtonBottomConstraint)
        } else {
            let shutterButtonBottomConstraint = view.bottomAnchor.constraint(equalTo: shutterButton.bottomAnchor, constant: 8.0)
            shutterButtonConstraints.append(shutterButtonBottomConstraint)
        }

        NSLayoutConstraint.activate(quadViewConstraints + activityIndicatorConstraints)
        
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

    // MARK: - Tap to Focus

    /// Called when the AVCaptureDevice detects that the subject area has changed significantly. When it's called, we reset the focus so the camera is no longer out of focus.
    @objc private func subjectAreaDidChange() {
        /// Reset the focus and exposure back to automatic
        do {
            try CaptureSession.current.resetFocusToAuto()
        } catch {
            let error = ImageScannerControllerError.inputDevice
            guard let captureSessionManager else { return }
            captureSessionManager.delegate?.captureSessionManager(captureSessionManager, didFailWithError: error)
            return
        }

        /// Remove the focus rectangle if one exists
        CaptureSession.current.removeFocusRectangleIfNeeded(focusRectangle, animated: true)
    }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        guard  let touch = touches.first else { return }
        let touchPoint = touch.location(in: view)
        let convertedTouchPoint: CGPoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: touchPoint)

        CaptureSession.current.removeFocusRectangleIfNeeded(focusRectangle, animated: false)

        focusRectangle = FocusRectangleView(touchPoint: touchPoint)
        view.addSubview(focusRectangle)

        do {
            try CaptureSession.current.setFocusPointToTapPoint(convertedTouchPoint)
        } catch {
            let error = ImageScannerControllerError.inputDevice
            guard let captureSessionManager else { return }
            captureSessionManager.delegate?.captureSessionManager(captureSessionManager, didFailWithError: error)
            return
        }
    }

    // MARK: - Actions

    @objc private func captureImage(_ sender: UIButton) {
        if(DataSource.images.count >= 10){
            // Show Toast
            showToast("You can't add more than 10 images")
            return
        }
        (navigationController as? ImageScannerController)?.flashToBlack()
        shutterButton.isUserInteractionEnabled = false
        captureSessionManager?.capturePhoto()
    }

    @objc private func toggleAutoScan() {
        if CaptureSession.current.isAutoScanEnabled {
            CaptureSession.current.isAutoScanEnabled = false
            let autoScanOffImage = UIImage(named: "autoScanOff")
            autoScanButton.image = autoScanOffImage
            autoScanButton.tintColor = .white
        } else {
            CaptureSession.current.isAutoScanEnabled = true
            let autoScanOnImage = UIImage(named: "autoScan")
            autoScanButton.image = autoScanOnImage
            autoScanButton.tintColor = .green
        }
    }

    @objc private func toggleFlash() {
        let state = CaptureSession.current.toggleFlash()

        let flashImage = UIImage(named: "flashOn")
        let flashOffImage = UIImage(named: "flashOff")

        switch state {
        case .on:
            flashEnabled = true
            flashButton.image = flashImage
            flashButton.tintColor = .white
        case .off:
            flashEnabled = false
            flashButton.image = flashOffImage
            flashButton.tintColor = .white
        case .unknown, .unavailable:
            flashEnabled = false
            flashButton.image = flashOffImage
            flashButton.tintColor = UIColor.lightGray
        }
    }

    @objc private func cancelImageScannerController() {
        guard let imageScannerController = navigationController as? ImageScannerController else { return }
        imageScannerController.imageScannerDelegate?.imageScannerControllerDidCancel(imageScannerController)
    }
    
    // previewImageTapped
    @objc private func previewImageTapped() {
        if(DataSource.images.isEmpty){
            return
        }
        
        let confirmationVC = ConfirmationViewController(activeIndex: -1)
        self.navigationController?.pushViewController(confirmationVC, animated: true)
    }
    

}

extension ScannerViewController: RectangleDetectionDelegateProtocol {
    func captureSessionManager(_ captureSessionManager: CaptureSessionManager, didFailWithError error: Error) {

        activityIndicator.stopAnimating()
        shutterButton.isUserInteractionEnabled = true

        guard let imageScannerController = navigationController as? ImageScannerController else { return }
        imageScannerController.imageScannerDelegate?.imageScannerController(imageScannerController, didFailWithError: error)
    }

    func didStartCapturingPicture(for captureSessionManager: CaptureSessionManager) {
        activityIndicator.startAnimating()
        captureSessionManager.stop()
        shutterButton.isUserInteractionEnabled = false
    }

    func captureSessionManager(_ captureSessionManager: CaptureSessionManager, didCapturePicture picture: UIImage, withQuad quad: Quadrilateral?) {
        activityIndicator.stopAnimating()

        let editVC = EditScanViewController(image: picture, quad: quad)
        navigationController?.pushViewController(editVC, animated: false)

        shutterButton.isUserInteractionEnabled = true
    }

    func captureSessionManager(_ captureSessionManager: CaptureSessionManager, didDetectQuad quad: Quadrilateral?, _ imageSize: CGSize) {
        guard let quad else {
            // If no quad has been detected, we remove the currently displayed on on the quadView.
            quadView.removeQuadrilateral()
            return
        }

        let portraitImageSize = CGSize(width: imageSize.height, height: imageSize.width)

        let scaleTransform = CGAffineTransform.scaleTransform(forSize: portraitImageSize, aspectFillInSize: quadView.bounds.size)
        let scaledImageSize = imageSize.applying(scaleTransform)

        let rotationTransform = CGAffineTransform(rotationAngle: CGFloat.pi / 2.0)

        let imageBounds = CGRect(origin: .zero, size: scaledImageSize).applying(rotationTransform)

        let translationTransform = CGAffineTransform.translateTransform(fromCenterOfRect: imageBounds, toCenterOfRect: quadView.bounds)

        let transforms = [scaleTransform, rotationTransform, translationTransform]

        let transformedQuad = quad.applyTransforms(transforms)

        quadView.drawQuadrilateral(quad: transformedQuad, animated: true)
    }

}

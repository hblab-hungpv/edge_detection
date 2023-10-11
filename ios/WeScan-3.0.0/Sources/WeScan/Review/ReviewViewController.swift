//
//  ReviewViewController.swift
//  WeScan
//
//  Created by Boris Emorine on 2/25/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit

/// The `ReviewViewController` offers an interface to review the image after it
/// has been cropped and deskewed according to the passed in quadrilateral.
final class ReviewViewController: UIViewController {
    
    private var rotationAngle = Measurement<UnitAngle>(value: 0, unit: .degrees)
    private var enhancedImageIsAvailable = false
    private var isCurrentlyDisplayingEnhancedImage = false
    
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
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.isOpaque = true
        imageView.image = results.croppedScan.image
        imageView.backgroundColor = .black
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var enhanceButton: UIBarButtonItem = {
        let image = UIImage(
            systemName: "wand.and.rays.inverse",
            named: "enhance",
            in: Bundle(for: ScannerViewController.self),
            compatibleWith: nil
        )
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(toggleEnhancedImage))
        button.tintColor = .white
        return button
    }()
    
    private lazy var rotateButton: UIBarButtonItem = {
        let image = UIImage(systemName: "rotate.right", named: "rotate", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(rotateImage))
        button.tintColor = .white
        return button
    }()
    
    private lazy var cancelButton: UIBarButtonItem = {
        // Close image
        let closeImage = UIImage(named: "close")
        
        let button = UIBarButtonItem(image: closeImage, style: .plain, target: self, action: #selector(cancelButtonTapped))
        button.tintColor = .clear
        return button
    }()
    
    private lazy var footerTopButtonContainer: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor(hex: 0x383838)
        
        return container
    }()
    
    private lazy var cropButton: UIView = {
        let cropButton = UIView()
        cropButton.translatesAutoresizingMaskIntoConstraints = false
        // Set event click
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cropButtonTapped))
        cropButton.addGestureRecognizer(tapGesture)
        return cropButton
    }()
    
    private lazy var doneButton: UIView = {
        let doneButton = UIView()
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        // Set event click
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(finishScan))
        doneButton.addGestureRecognizer(tapGesture)
        return doneButton
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
    
    private let results: ImageScannerResults
    
    private var updateIndex: Int
    
    // MARK: - Life Cycle
    
    init(results: ImageScannerResults, updateIndex: Int = -1) {
        self.results = results
        self.updateIndex = updateIndex
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set footer height
        footerHeight = screenHeight / 4
        
        enhancedImageIsAvailable = results.enhancedScan != nil
        
        setupViews()
        //        setupToolbar()
        setupConstraints()
        
        title = NSLocalizedString("wescan.review.title",
                                  tableName: nil,
                                  bundle: Bundle(for: ReviewViewController.self),
                                  value: "Preview",
                                  comment: "The review title of the ReviewController"
        )
        navigationItem.leftBarButtonItem = cancelButton
        
        
        // Visibility of preview image container
        previewImageContainer.isHidden = DataSource.images.isEmpty
        
        // Update image preview & count label
        if(!DataSource.images.isEmpty){
            previewImageView.image = DataSource.images[0].croppedScan.image
            countLabelView.text = "\(DataSource.images.count)"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // We only show the toolbar (with the enhance button) if the enhanced image is available.
        if enhancedImageIsAvailable {
            navigationController?.setToolbarHidden(false, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    // MARK: Setups
    
    private func setupViews() {
        view.addSubview(contentContainer)
        view.addSubview(footerContainer)
        
        contentContainer.addSubview(imageView)
        footerContainer.addSubview(footerTopButtonContainer)
        
        createCropButton()
        createDoneButton()
        
        footerTopButtonContainer.addSubview(cropButton)
        footerTopButtonContainer.addSubview(doneButton)
        
        footerContainer.addSubview(previewImageContainer)
    
        previewImageContainer.addSubview(previewImageView)
        previewImageContainer.addSubview(circleLabelCountContainer)
        circleLabelCountContainer.addSubview(countLabelView)
    }
    
    private func createCropButton(){
        // Create crop button include: crop icon and crop label
        let cropIcon = UIImage(named: "crop")
        let cropLabel = UILabel()
        cropLabel.text = "Crop"
        cropLabel.textColor = .white
        cropLabel.font = UIFont.systemFont(ofSize: 14)
        cropLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let cropIconView = UIImageView(image: cropIcon)
        cropIconView.translatesAutoresizingMaskIntoConstraints = false
        
        cropButton.addSubview(cropIconView)
        cropButton.addSubview(cropLabel)
        
        // Set constraints
        cropIconView.leadingAnchor.constraint(equalTo: cropButton.leadingAnchor, constant: 16).isActive = true
        cropIconView.centerYAnchor.constraint(equalTo: cropButton.centerYAnchor).isActive = true
        cropIconView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        cropIconView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        
        cropLabel.leadingAnchor.constraint(equalTo: cropIconView.trailingAnchor, constant: 8).isActive = true
        cropLabel.centerYAnchor.constraint(equalTo: cropButton.centerYAnchor).isActive = true
    }
    
    private func createDoneButton(){
        
        // Create done button include: done icon and done label
        let doneIcon = UIImage(named: "done")
        let doneLabel = UILabel()
        doneLabel.text = "Done"
        doneLabel.textColor = .white
        doneLabel.font = UIFont.systemFont(ofSize: 14)
        doneLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let doneIconView = UIImageView(image: doneIcon)
        doneIconView.translatesAutoresizingMaskIntoConstraints = false
        
        doneButton.addSubview(doneIconView)
        doneButton.addSubview(doneLabel)
        
        // Set constraints
        doneIconView.leadingAnchor.constraint(equalTo: doneButton.leadingAnchor, constant: 16).isActive = true
        doneIconView.centerYAnchor.constraint(equalTo: doneButton.centerYAnchor).isActive = true
        doneIconView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        doneIconView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        
        doneLabel.leadingAnchor.constraint(equalTo: doneIconView.trailingAnchor, constant: 8).isActive = true
        doneLabel.centerYAnchor.constraint(equalTo: doneButton.centerYAnchor).isActive = true
        
    }
    
    private func setupToolbar() {
        guard enhancedImageIsAvailable else { return }
        
        navigationController?.toolbar.barStyle = .blackTranslucent
        
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems = [fixedSpace, enhanceButton, flexibleSpace, rotateButton, fixedSpace]
    }
    
    private func setupConstraints() {
        
        // Configure constraints for the footerContainer
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
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure constraints for the imageView inside the contentContainer
        let imageViewConstraints = [
            imageView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ]
        NSLayoutConstraint.activate(imageViewConstraints)
        
        // Configure constraints for the footerTopButtonContainer inside the footerContainer
        let footerTopButtonContainerConstraints = [
            footerTopButtonContainer.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor),
            footerTopButtonContainer.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),
            footerTopButtonContainer.topAnchor.constraint(equalTo: footerContainer.topAnchor),
            footerTopButtonContainer.heightAnchor.constraint(equalToConstant: 48.0)
        ]
        NSLayoutConstraint.activate(footerTopButtonContainerConstraints)
        
        // Configure constraints for the cropButton inside left of the footerTopButtonContainer
        let cropButtonConstraints = [
            cropButton.leadingAnchor.constraint(equalTo: footerTopButtonContainer.leadingAnchor),
            cropButton.topAnchor.constraint(equalTo: footerTopButtonContainer.topAnchor),
            cropButton.bottomAnchor.constraint(equalTo: footerTopButtonContainer.bottomAnchor),
            cropButton.widthAnchor.constraint(equalToConstant: 100.0)
        ]
        NSLayoutConstraint.activate(cropButtonConstraints)
        
        // Configure constraints for the doneButton inside right of the footerTopButtonContainer
        let doneButtonConstraints = [
            
            doneButton.trailingAnchor.constraint(equalTo: footerTopButtonContainer.trailingAnchor),
            doneButton.topAnchor.constraint(equalTo: footerTopButtonContainer.topAnchor),
            doneButton.bottomAnchor.constraint(equalTo: footerTopButtonContainer.bottomAnchor),
            doneButton.widthAnchor.constraint(equalToConstant: 100.0)
            
        ]
        NSLayoutConstraint.activate(doneButtonConstraints)
        
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
        
        
        //        var imageViewConstraints: [NSLayoutConstraint] = []
        //        if #available(iOS 11.0, *) {
        //            imageViewConstraints = [
        //                view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: imageView.safeAreaLayoutGuide.topAnchor),
        //                view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: imageView.safeAreaLayoutGuide.trailingAnchor),
        //                view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: imageView.safeAreaLayoutGuide.bottomAnchor),
        //                view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: imageView.safeAreaLayoutGuide.leadingAnchor)
        //            ]
        //        } else {
        //            imageViewConstraints = [
        //                view.topAnchor.constraint(equalTo: imageView.topAnchor),
        //                view.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
        //                view.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
        //                view.leadingAnchor.constraint(equalTo: imageView.leadingAnchor)
        //            ]
        //        }
        
        //        NSLayoutConstraint.activate(imageViewConstraints)
    }
    
    // MARK: - Actions
    
    @objc private func reloadImage() {
        if enhancedImageIsAvailable, isCurrentlyDisplayingEnhancedImage {
            imageView.image = results.enhancedScan?.image.rotated(by: rotationAngle) ?? results.enhancedScan?.image
        } else {
            imageView.image = results.croppedScan.image.rotated(by: rotationAngle) ?? results.croppedScan.image
        }
    }
    
    // Crop button tapped
    @objc func cropButtonTapped() {
        //        let editScanVC = EditScanViewController(image: results.enhancedScan?.image ?? results.croppedScan.image)
        //        editScanVC.delegate = self
        //        navigationController?.pushViewController(editScanVC, animated: true)
        
        print("Crop button tapped")
        
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
    
    
    @objc func cancelButtonTapped() {
        // Back to the previous view controller
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func toggleEnhancedImage() {
        guard enhancedImageIsAvailable else { return }
        
        isCurrentlyDisplayingEnhancedImage.toggle()
        reloadImage()
        
        if isCurrentlyDisplayingEnhancedImage {
            enhanceButton.tintColor = .yellow
        } else {
            enhanceButton.tintColor = .white
        }
    }
    
    @objc func rotateImage() {
        rotationAngle.value += 90
        
        if rotationAngle.value == 360 {
            rotationAngle.value = 0
        }
        
        reloadImage()
    }
    
    @objc private func finishScan() {
        guard let imageScannerController = navigationController as? ImageScannerController else { return }
        
        var newResults = results
        newResults.croppedScan.rotate(by: rotationAngle)
        newResults.enhancedScan?.rotate(by: rotationAngle)
        newResults.doesUserPreferEnhancedScan = isCurrentlyDisplayingEnhancedImage
        //        imageScannerController.imageScannerDelegate?
        //            .imageScannerController(imageScannerController, didFinishScanningWithResults: newResults)
        
        let dataScan = DataScan(detectedRectangle: newResults.detectedRectangle, originalScan: newResults.originalScan, croppedScan: newResults.croppedScan, enhancedScan: newResults.enhancedScan, isSelected: true)
        
        if(updateIndex == -1){
            // Add to data source
            DataSource.addDataScan(dataScan: dataScan)
        }else{
            // Update data source at current index
            DataSource.updateDataScan( index: updateIndex, dataScan: dataScan)
        }
        
        // Push confirmation view controller
        let confirmationVC = ConfirmationViewController(activeIndex: updateIndex)
        self.navigationController?.pushViewController(confirmationVC, animated: true)
        // Present confirmation view controller & finish scan
        //        let confirmationVC = ConfirmationViewController()
        //        confirmationVC.modalPresentationStyle = .fullScreen
        //        self.present(confirmationVC, animated: true, completion: nil)
        //
        //        dismiss(animated: false)
    }
    
}

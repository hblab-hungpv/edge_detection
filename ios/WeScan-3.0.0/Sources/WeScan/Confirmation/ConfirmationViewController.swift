//
//  File.swift
//  
//
//  Created by Hungpv on 06/10/2023.
//

import AVFoundation
import UIKit

// Create confirmation controller
final class ConfirmationViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private var rotationAngle = Measurement<UnitAngle>(value: 0, unit: .degrees)
    
    private let screenHeight = UIScreen.main.bounds.height
    
    private var footerHeight = CGFloat(100)
    
    private var currentIndex = 0
    
    private var activeIndex = -1
    
    var collectionView: UICollectionView!
    let cellIdentifier = "ImageCollectionViewCell"
    let buttonCellIdentifier = "ButtonCollectionViewCell"
    
    init(activeIndex: Int) {
        self.activeIndex = activeIndex
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var headerContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        return view
    }()
    
    private lazy var previousButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "previous"), for: .normal)
        button.addTarget(self, action: #selector(previousButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "1/2"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        return label
    }()
    
    private lazy var nextButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "next"), for: .normal)
        button.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        return button
    }()
    
    
    private lazy var footerContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        return view
    }()
    
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .black
        return imageView
    }()
    
    private lazy var contentContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        return view
    }()
    
    // Horizontal stack view
    private lazy var horizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        return stackView
    }()
    
    private lazy var itemImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .black
        return imageView
    }()
    
    private lazy var footerTopButtonContainer: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor(hex: 0x383838)
        
        return container
    }()
    
    private lazy var deleteButton: UIView = {
        let button = UIView()
        button.translatesAutoresizingMaskIntoConstraints = false
        // Set event click
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(deleteButtonTapped))
        button.addGestureRecognizer(tapGesture)
        return button
    }()
    
    private lazy var cropButton: UIView = {
        let button = UIView()
        button.translatesAutoresizingMaskIntoConstraints = false
        // Set event click
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cropButtonTapped))
        button.addGestureRecognizer(tapGesture)
        return button
    }()
    
    private lazy var rotateButton: UIView = {
        let button = UIView()
        button.translatesAutoresizingMaskIntoConstraints = false
        // Set event click
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(rotateButtonTapped))
        button.addGestureRecognizer(tapGesture)
        return button
    }()
    
    private lazy var submitButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints =  false
        
        // title
        button.setTitle("Submit now", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        button.backgroundColor = .white
        // radius
        button.layer.cornerRadius = 24
        
        // Set event click
        button.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
        
        
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if(activeIndex > -1){
            currentIndex = activeIndex
        }else{
            // Active last item
            currentIndex = DataSource.images.count - 1
        }
        
        DataSource.activeIndex(index: currentIndex)
                
        view.backgroundColor = .black
        
        // Set footer height
        footerHeight = screenHeight / 3.5
        
        // Hide back button
        navigationItem.hidesBackButton = true
        
        setupViews()
        setUpContraints()
        updateViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Hide navigation bar
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // Mark: data
    private func updateViews() {
        
        // Update title
        updateTitle()
        
        // Update image
        updateImage()
        
    }
    
    private func updateTitle() {
        let images = DataSource.images
        let currentPageText = "\(currentIndex + 1)/\(images.count)"
        titleLabel.text = currentPageText
    }
    
    private func updateImage() {
        let images = DataSource.images
        imageView.image = images[currentIndex].croppedScan.image
    }
    
    // Mark: - Views
    private func setupViews() {
        view.addSubview(contentContainer)
        view.addSubview(footerContainer)
        
        contentContainer.addSubview(headerContainerView)
        
        createHeaderContainer()
        
        footerContainer.addSubview(footerTopButtonContainer)
        
        
        createDeleteButton()
        createCropButton()
        createRotateButton()
        
        footerTopButtonContainer.addSubview(deleteButton)
        footerTopButtonContainer.addSubview(cropButton)
        footerTopButtonContainer.addSubview(rotateButton)
        
        createImageList()
        
        footerContainer.addSubview(submitButton)
        
        contentContainer.addSubview(imageView)
        
    }
    
    private func createHeaderContainer(){
        headerContainerView.addSubview(previousButton)
        headerContainerView.addSubview(titleLabel)
        headerContainerView.addSubview(nextButton)
        
        // Create title label
        let titleLabelConstraints = [
            titleLabel.centerXAnchor.constraint(equalTo: headerContainerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerContainerView.centerYAnchor),
        ]
        
        NSLayoutConstraint.activate(titleLabelConstraints)
        
        // Create previous button
        let previousButtonConstraints = [
            previousButton.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -16),
            previousButton.centerYAnchor.constraint(equalTo: headerContainerView.centerYAnchor),
            previousButton.heightAnchor.constraint(equalToConstant: 24),
            previousButton.widthAnchor.constraint(equalToConstant: 24)
        ]
        
        NSLayoutConstraint.activate(previousButtonConstraints)
        
        
        // Create next button
        let nextButtonConstraints = [
            nextButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 16),
            nextButton.centerYAnchor.constraint(equalTo: headerContainerView.centerYAnchor),
            nextButton.heightAnchor.constraint(equalToConstant: 24),
            nextButton.widthAnchor.constraint(equalToConstant: 24)
        ]
        
        NSLayoutConstraint.activate(nextButtonConstraints)
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
        cropIconView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        cropIconView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        cropLabel.leadingAnchor.constraint(equalTo: cropIconView.trailingAnchor, constant: 8).isActive = true
        cropLabel.centerYAnchor.constraint(equalTo: cropButton.centerYAnchor).isActive = true
    }
    
    // Delete button
    private func createDeleteButton(){
        // Create delete button include: delete icon and delete label
        let deleteIcon = UIImage(named: "delete")
        let deleteLabel = UILabel()
        deleteLabel.text = "Delete"
        deleteLabel.textColor = .white
        deleteLabel.font = UIFont.systemFont(ofSize: 14)
        deleteLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let deleteIconView = UIImageView(image: deleteIcon)
        deleteIconView.translatesAutoresizingMaskIntoConstraints = false
        
        deleteButton.addSubview(deleteIconView)
        deleteButton.addSubview(deleteLabel)
        
        // Set constraints
        deleteIconView.leadingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: 16).isActive = true
        deleteIconView.centerYAnchor.constraint(equalTo: deleteButton.centerYAnchor).isActive = true
        deleteIconView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        deleteIconView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        deleteLabel.leadingAnchor.constraint(equalTo: deleteIconView.trailingAnchor, constant: 8).isActive = true
        deleteLabel.centerYAnchor.constraint(equalTo: deleteButton.centerYAnchor).isActive = true
    }
    
    // Rotate button
    
    private func createRotateButton(){
        // Create rotate button include: rotate icon and rotate label
        let rotateIcon = UIImage(named: "rotate")
        let rotateLabel = UILabel()
        rotateLabel.text = "Rotate"
        rotateLabel.textColor = .white
        rotateLabel.font = UIFont.systemFont(ofSize: 14)
        rotateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let rotateIconView = UIImageView(image: rotateIcon)
        rotateIconView.translatesAutoresizingMaskIntoConstraints = false
        
        rotateButton.addSubview(rotateIconView)
        rotateButton.addSubview(rotateLabel)
        
        // Set constraints
        rotateIconView.leadingAnchor.constraint(equalTo: rotateButton.leadingAnchor, constant: 16).isActive = true
        rotateIconView.centerYAnchor.constraint(equalTo: rotateButton.centerYAnchor).isActive = true
        rotateIconView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        rotateIconView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        rotateLabel.leadingAnchor.constraint(equalTo: rotateIconView.trailingAnchor, constant: 8).isActive = true
        rotateLabel.centerYAnchor.constraint(equalTo: rotateButton.centerYAnchor).isActive = true
    }
    
    
    private func createImageList() {
        // Create a UICollectionViewFlowLayout for horizontal scrolling
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        // Create the UICollectionView and set its properties
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: buttonCellIdentifier)
        
        // Add the UICollectionView to the view
        footerContainer.addSubview(collectionView)
        
        // Add constraints to the UICollectionView
        collectionView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func createSubmitButton() {
        
        let label = UILabel()
        label.text = "Submit now"
        // title size
        label.font = UIFont.systemFont(ofSize: 16)
        // title color
        label.textColor = .black
        
        submitButton.addSubview(label)
        
        // Set constraints
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: submitButton.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: submitButton.centerYAnchor).isActive = true
        
    }
    
    private func setUpContraints() {
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
        
        // Header container on top of contentContainer
        let navigationBarHeight = navigationController?.navigationBar.frame.height ?? 0
        
        let headerContainerConstraints = [
            headerContainerView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            headerContainerView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            headerContainerView.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: navigationBarHeight + 16),
            headerContainerView.heightAnchor.constraint(equalToConstant: navigationBarHeight)
        ]
        NSLayoutConstraint.activate(headerContainerConstraints)
        
        // Configure constraints for the imageView
        let imageViewConstraints = [
            imageView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
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
        
        // Configure constraints for delete button left of footerTopButtonContainer
        let deleteButtonConstraints = [
            deleteButton.leadingAnchor.constraint(equalTo: footerTopButtonContainer.leadingAnchor),
            deleteButton.topAnchor.constraint(equalTo: footerTopButtonContainer.topAnchor),
            deleteButton.bottomAnchor.constraint(equalTo: footerTopButtonContainer.bottomAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 100)
        ]
        
        // Configure constraints for rotate button right of footerTopButtonContainer
        let rotateButtonConstraints = [
            rotateButton.trailingAnchor.constraint(equalTo: footerTopButtonContainer.trailingAnchor),
            rotateButton.topAnchor.constraint(equalTo: footerTopButtonContainer.topAnchor),
            rotateButton.bottomAnchor.constraint(equalTo: footerTopButtonContainer.bottomAnchor),
            rotateButton.widthAnchor.constraint(equalToConstant: 100)
        ]
        
        // Configure constraints for crop button center of footerTopButtonContainer
        let cropButtonConstraints = [
            cropButton.centerXAnchor.constraint(equalTo: footerTopButtonContainer.centerXAnchor),
            cropButton.topAnchor.constraint(equalTo: footerTopButtonContainer.topAnchor),
            cropButton.bottomAnchor.constraint(equalTo: footerTopButtonContainer.bottomAnchor),
            cropButton.widthAnchor.constraint(equalToConstant: 100)
        ]
        
        // Active constraints
        NSLayoutConstraint.activate(deleteButtonConstraints)
        NSLayoutConstraint.activate(rotateButtonConstraints)
        NSLayoutConstraint.activate(cropButtonConstraints)
        
        // Configure constraints for the UICollectionView
        let collectionViewConstraints = [
            collectionView.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor, constant: 16.0),
            collectionView.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: footerTopButtonContainer.bottomAnchor, constant: 16.0),
            collectionView.heightAnchor.constraint(equalToConstant: 65.0)
        ]
        
        NSLayoutConstraint.activate(collectionViewConstraints)
        
        // Configure constraints for the submit button below the UICollectionView && center horizontal of footerContainer
        let submitButtonConstraints = [
            submitButton.centerXAnchor.constraint(equalTo: footerContainer.centerXAnchor),
            submitButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 16.0),
            
            submitButton.heightAnchor.constraint(equalToConstant: 48.0),
            submitButton.widthAnchor.constraint(equalToConstant: 140.0)
            
        ]
        
        NSLayoutConstraint.activate(submitButtonConstraints)
    }
    
    // Mark: - Actions
    @objc private func previousButtonTapped() {
        
        if(currentIndex > 0){
            currentIndex -= 1
        }else{
            currentIndex = DataSource.images.count - 1
        }
        
        updateViews()
        
    }
    
    @objc private func nextButtonTapped() {
        let lastIndex = DataSource.images.count - 1
        
        if currentIndex < lastIndex {
            currentIndex += 1
        }else{
            currentIndex = 0
        }
        
        updateViews()
    }
    
    @objc private func deleteButtonTapped() {
        
        if(DataSource.images.isEmpty){
            return
        }
        
        DataSource.images.remove(at: currentIndex)
        
        if DataSource.images.count == 0 {
            openScanViewController()
        }else{
            if(currentIndex > 0){
                currentIndex -= 1
            }else{
                currentIndex = DataSource.images.count - 1
            }
            
            updateViews()
            // Active current index
            DataSource.activeIndex(index: currentIndex)
            // update collection view
            collectionView.reloadData()
        }
    }
    
    @objc private func cropButtonTapped() {
        if(DataSource.images.isEmpty) {
            return
        }
            
        let currentImage = DataSource.images[currentIndex]
        let picture = currentImage.originalScan.image
        let quad = currentImage.detectedRectangle
        
        let editVC = EditScanViewController(image: picture, quad: quad, rotateImage: false, updateIndex: currentIndex)
        navigationController?.pushViewController(editVC, animated: false)
        
    }
    
    @objc func rotateButtonTapped() {
        
        if(DataSource.images.isEmpty){
            return
        }
        
        rotationAngle.value += 90
        
        if rotationAngle.value == 360 {
            rotationAngle.value = 0
        }
        
        reloadImage()
    }
    
    @objc private func reloadImage() {
        // Rotate current image
        DataSource.images[currentIndex].croppedScan.image = DataSource.images[currentIndex].croppedScan.image.rotated(by: rotationAngle) ??   DataSource.images[currentIndex].croppedScan.image
        
        updateViews()
    }
    
    @objc private func submitButtonTapped() {
        
        guard let imageScannerController = navigationController as? ImageScannerController else { return }
        
        imageScannerController.imageScannerDelegate?.imageScannerController(imageScannerController, didFinishScanningWithResults: [])
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return DataSource.images.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item < DataSource.images.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! ImageCollectionViewCell
            
            let item = DataSource.images[indexPath.item]
            cell.imageView.image = item.croppedScan.image
            
            if(item.isSelected){
                cell.layer.borderWidth = 1
                cell.layer.borderColor = UIColor.white.cgColor
            }else{
                cell.layer.borderWidth = 0
            }
            
            // on Cell tapped
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
            cell.imageView.isUserInteractionEnabled = true
            cell.imageView.addGestureRecognizer(tapGestureRecognizer)
            
            cell.imageView.isHidden = false
            cell.buttonView.isHidden = true
            
            return cell
            
        } else {
            // Create and configure the button cell
            let buttonCell = collectionView.dequeueReusableCell(withReuseIdentifier: buttonCellIdentifier, for: indexPath) as! ImageCollectionViewCell
            buttonCell.imageView.isHidden = true // Clear the image
            buttonCell.buttonView.isHidden = false
            
            // Add button tapped action
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addButtonTapped))
            buttonCell.buttonView.addGestureRecognizer(tapGesture)
            
            return buttonCell
        }
        
        
    }
    
    // On cell tapped
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        let tappedImage = tapGestureRecognizer.view as! UIImageView
        
        let indexPath = collectionView.indexPath(for: tappedImage.superview?.superview as! UICollectionViewCell)
        
        currentIndex = indexPath!.item
        
        // Update data is selected
        
        for i in 0..<DataSource.images.count {
            if i == currentIndex {
                DataSource.images[i].isSelected = true
            }else{
                DataSource.images[i].isSelected = false
            }
        }
        
        
        // Reload collection view
        collectionView.reloadData()
        
        updateViews()
    }
    
    // Update
    
    // On add button tapped
    @objc func addButtonTapped() {
        if(DataSource.images.count >= 10){
            // Show Toast
            showToast("You can't add more than 10 images")
            return
        }
        
        openScanViewController()
    }
    
    private func openScanViewController(){
        
        let scannerViewController = ScannerViewController()
        
        navigationController?.pushViewController(scannerViewController, animated: false)
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Set the size of each cell (you can adjust these values)
        let cellWidth: CGFloat = 48
        let cellHeight: CGFloat = 64
        return CGSize(width: cellWidth, height: cellHeight)
    }
}


class ImageCollectionViewCell: UICollectionViewCell {
    var imageView: UIImageView!
    var buttonView: UIView!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // boder radius
        
        imageView.layer.cornerRadius = 4
        imageView.clipsToBounds = true
        
        // Border radius for the cell
        layer.cornerRadius = 4
        clipsToBounds = true
        
        contentView.addSubview(imageView)
        
        // Add constraints to the imageView to fill the cell
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 14.0),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // Create and configure the buttonView (UIView)
        buttonView = DashedBorderView()
        buttonView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(buttonView)
        
        // Add constraints to center the buttonView in the cell
        NSLayoutConstraint.activate([
            buttonView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            buttonView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            buttonView.widthAnchor.constraint(equalToConstant: 46), // Adjust the size as needed
            buttonView.heightAnchor.constraint(equalToConstant: 62)
        ])
        
        
        // Create and configure the icon image view
        let iconImageView = UIImageView(image: UIImage(named: "add"))
        // Tint color
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        buttonView.addSubview(iconImageView)
        
        // Add constraints to center the iconImageView within the buttonView
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: buttonView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: buttonView.centerYAnchor),
            iconImageView.widthAnchor.constraint( equalToConstant: 18.0 ), // Adjust the size as needed
            iconImageView.heightAnchor.constraint(equalToConstant: 18.0 )
        ])
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class DashedBorderView: UIView {
    
    private let dashedLineColor = UIColor.white.cgColor
    private let dashedLinePattern: [NSNumber] = [5, 2]
    private let dashedLineWidth: CGFloat = 1
    
    private let borderLayer = CAShapeLayer()
    
    init() {
        super.init(frame: CGRect.zero)
        
        borderLayer.strokeColor = dashedLineColor
        borderLayer.lineDashPattern = dashedLinePattern
        borderLayer.backgroundColor = UIColor.clear.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = dashedLineWidth
        layer.addSublayer(borderLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        borderLayer.frame = bounds
        borderLayer.path = UIBezierPath(roundedRect: rect, cornerRadius: layer.cornerRadius).cgPath
    }
}

class ToastLabel: UILabel {
    var textInsets = UIEdgeInsets.zero {
        didSet { invalidateIntrinsicContentSize() }
    }

    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetRect = bounds.inset(by: textInsets)
        let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
        let invertedInsets = UIEdgeInsets(top: -textInsets.top, left: -textInsets.left, bottom: -textInsets.bottom, right: -textInsets.right)

        return textRect.inset(by: invertedInsets)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }
}

extension UIViewController {
    static let DELAY_SHORT = 1.5
    static let DELAY_LONG = 3.0

    func showToast(_ text: String, delay: TimeInterval = DELAY_LONG) {
        let label = ToastLabel()
        label.backgroundColor = UIColor(white: 0, alpha: 0.5)
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 15)
        label.alpha = 0
        label.text = text
        label.clipsToBounds = true
        label.layer.cornerRadius = 20
        label.numberOfLines = 0
        label.textInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        let saveArea = view.safeAreaLayoutGuide
        label.centerXAnchor.constraint(equalTo: saveArea.centerXAnchor, constant: 0).isActive = true
        label.leadingAnchor.constraint(greaterThanOrEqualTo: saveArea.leadingAnchor, constant: 15).isActive = true
        label.trailingAnchor.constraint(lessThanOrEqualTo: saveArea.trailingAnchor, constant: -15).isActive = true
        label.bottomAnchor.constraint(equalTo: saveArea.bottomAnchor, constant: -30).isActive = true

        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
            label.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.5, delay: delay, options: .curveEaseOut, animations: {
                label.alpha = 0
            }, completion: {_ in
                label.removeFromSuperview()
            })
        })
    }
}

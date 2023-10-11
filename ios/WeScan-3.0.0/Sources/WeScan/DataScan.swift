//
//  File.swift
//  
//
//  Created by Hungpv on 09/10/2023.
//

import Foundation

public final struct DataScan {
    /// The original scan taken by the user, prior to the cropping applied by WeScan.
    public var originalScan: ImageScannerScan

    /// The deskewed and cropped scan using the detected rectangle, without any filters.
    public var croppedScan: ImageScannerScan

    /// The enhanced scan, passed through an Adaptive Thresholding function.
    /// This image will always be grayscale and may not always be available.
    public var enhancedScan: ImageScannerScan?

    /// Whether the user selected the enhanced scan or not.
    /// The `enhancedScan` may still be available even if it has not been selected by the user.
    public var doesUserPreferEnhancedScan: Bool

    /// The detected rectangle which was used to generate the `scannedImage`.
    public var detectedRectangle: Quadrilateral
    
    public var path: String?
    
    public var isSelected: Bool


    init(
        detectedRectangle: Quadrilateral,
        originalScan: ImageScannerScan,
        croppedScan: ImageScannerScan,
        enhancedScan: ImageScannerScan?,
        doesUserPreferEnhancedScan: Bool = false,
        path: String = "",
        isSelected: Bool = false
    ) {
        self.detectedRectangle = detectedRectangle

        self.originalScan = originalScan
        self.croppedScan = croppedScan
        self.enhancedScan = enhancedScan

        self.doesUserPreferEnhancedScan = doesUserPreferEnhancedScan
        self.path = path
        self.isSelected = isSelected
    }
}

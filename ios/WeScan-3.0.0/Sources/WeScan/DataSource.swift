//
//  File.swift
//  
//
//  Created by Hungpv on 09/10/2023.
//

import Foundation

public final class DataSource {
    
    // Create list data scan list
    static public var images: [DataScan] = []
    
    // Add item to list data scan
    static public func addDataScan(dataScan: DataScan) {
        images.append(dataScan)
    }
    
    // Get item from list data scan
    static public func getDataScan(index: Int) -> DataScan {
        return images[index]
    }
    
    // Get list data scan
    static public func getDataScanList() -> [DataScan] {
        return images
    }
    
    // Remove item from list data scan
    static public func removeDataScan(index: Int) {
        images.remove(at: index)
    }
    
    // Clear all
    static public func clearAll() {
        images.removeAll()
    }
    
    // Active first item
    static public func activeFirstItem() {
        if images.count > 0 {
            images[0].isSelected = true
        }
    }
    
    // Active item by index
    static public func activeItem(index: Int) {
        images[index].isSelected = true
    }
    
    
    // Update item by index
    static public func updateDataScan(index: Int, dataScan: DataScan) {
        images[index] = dataScan
    }
    
    // Active index and deactive other
    static public func activeIndex(index: Int) {
        for i in 0..<images.count {
            if i == index {
                images[i].isSelected = true
            } else {
                images[i].isSelected = false
            }
        }
    }
    

}

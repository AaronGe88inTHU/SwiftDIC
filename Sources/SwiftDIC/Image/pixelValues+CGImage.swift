//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/19.
//

import Accelerate
import Surge

func pixelValues(fromCGImage imageRef: CGImage) -> Matrix<Float>?
{
    var pixelValues: [Float]?
    let width = imageRef.width
    let height = imageRef.height
    let bitsPerComponent = imageRef.bitsPerComponent
    let bytesPerRow = imageRef.bytesPerRow
    let totalBytes = height * bytesPerRow
    let bitmapInfo = imageRef.bitmapInfo
//    let format = imageRef.pixelFormatInfo
    
    //            let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colorSpace = CGColorSpaceCreateDeviceGray()
    var intensities = [UInt8](repeating: 0, count: totalBytes)
    
    let contextRef = CGContext(data: &intensities,
                               width: width,
                               height: height,
                               bitsPerComponent: bitsPerComponent,
                               bytesPerRow: bytesPerRow,
                               space: colorSpace,
                               bitmapInfo: bitmapInfo.rawValue)
    contextRef?.draw(imageRef, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)))
    
    pixelValues = intensities.map{Float($0)/255}
    
    
   
    guard let pixelValues = pixelValues else {
       return nil
    }
    
    return Matrix<Float>(rows: height, columns: width, grid:pixelValues)

}

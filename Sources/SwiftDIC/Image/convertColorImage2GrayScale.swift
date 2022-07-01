//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/19.
//

import Accelerate
import Surge


@available(iOS 13.0, *)
@available(iOS 13.0, *)
@available(iOS 13.0, *)
@available(macOS 10.15, *)
public func convertColorImage2GrayScaleMatrix(cgImage: CGImage) throws -> Matrix<Double>?
{
    
//    var pixelValues: [Float]?
    let width = cgImage.width
    let height = cgImage.height

   
    
    let redCoefficient: Float = 0.2126
    let greenCoefficient: Float = 0.7152
    let blueCoefficient: Float = 0.0722
    
    // Create a 1D matrix containing the three luma coefficients that
    // specify the color-to-grayscale conversion.
    let divisor: Int32 = 0x1000
    let fDivisor = Float(divisor)
    
    var coefficientsMatrix = [
        Int16(redCoefficient * fDivisor),
        Int16(greenCoefficient * fDivisor),
        Int16(blueCoefficient * fDivisor)
    ]
    
    /*
     The format of the source asset.
     */
    lazy var format: vImage_CGImageFormat = {
        guard
            let format = vImage_CGImageFormat(cgImage: cgImage) else {
            fatalError("Unable to create format.")
        }
        
        return format
    }()
    
    lazy var sourceBuffer: vImage_Buffer = {
        guard let sourceImageBuffer = try? vImage_Buffer(cgImage: cgImage,
                                                       format: format)
        else {
            fatalError("Unable to create source buffers.")
        }
        
        return sourceImageBuffer
    }()
    
    
    /*
     The 1-channel, 8-bit vImage buffer used as the operation destination.
     */
    lazy var destinationBuffer: vImage_Buffer = {
        guard let destinationBuffer = try? vImage_Buffer(width: Int(sourceBuffer.width),
                                                         height: Int(sourceBuffer.height),
                                                         bitsPerPixel: 8) else {
            fatalError("Unable to create destination buffers.")
        }
        
        return destinationBuffer
    }()
    
  
        
     
        // Use the matrix of coefficients to compute the scalar luminance by
        // returning the dot product of each RGB pixel and the coefficients
        // matrix.
    let preBias: [Int16] = [0, 0, 0, 0]
    let postBias: Int32 = 0
    let colorSpace = CGColorSpaceCreateDeviceGray()
    
    vImageMatrixMultiply_ARGB8888ToPlanar8(&sourceBuffer,
                                           &destinationBuffer,
                                           &coefficientsMatrix,
                                           divisor,
                                           preBias,
                                           postBias,
                                           vImage_Flags(kvImageNoFlags))
        
    // Create a 1-channel, 8-bit grayscale format that's used to
    // generate a displayable image.
    guard let monoFormat = vImage_CGImageFormat(
        bitsPerComponent: 8,
        bitsPerPixel: 8,
        colorSpace: colorSpace,
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
        renderingIntent: .defaultIntent) else {
        throw fatalError()
    }
    
    defer{
        sourceBuffer.free()
    }
        
    // Create a Core Graphics image from the grayscale destination buffer.
    guard let monoImage = try? destinationBuffer.createCGImage(format: monoFormat)
    else{
        return nil
    }
    
    let bitsPerComponent = monoImage.bitsPerComponent
    let bytesPerRow = monoImage.bytesPerRow
    let totalBytes = height * bytesPerRow
    let bitmapInfo = monoImage.bitmapInfo
   
    var intensities = [UInt8](repeating: 0, count: totalBytes)
    
    guard let contextRef = CGContext(data: &intensities,
                               width: width,
                               height: height,
                               bitsPerComponent: bitsPerComponent,
                               bytesPerRow: bytesPerRow,
                               space: colorSpace,
                               bitmapInfo: bitmapInfo.rawValue)
    else{
        return nil
    }
    
    contextRef.draw(monoImage, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)))
    let pixelValues = intensities.map{Double($0)/255}
    
    return Matrix<Double>(rows: height, columns: width, grid:pixelValues)
    
}

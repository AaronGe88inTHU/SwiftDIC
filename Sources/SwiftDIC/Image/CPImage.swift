//
//  CPImage.swift
//  ImageFilterSwiftUI
//
//  Created by Alfian Losari on 13/03/20.
//  Copyright © 2020 Alfian Losari. All rights reserved.
//
import SwiftUI

#if os(iOS)
import UIKit
public typealias CPImage = UIImage
#elseif os(OSX)
import AppKit
public typealias CPImage = NSImage
#endif

extension CPImage {
    
    var coreImage: CIImage? {
        #if os(iOS)
        guard let cgImage = self.cgImage else {
            return nil
        }
        return CIImage(cgImage: cgImage)
        #elseif os(OSX)
        guard
            let tiffData = tiffRepresentation,
            let ciImage = CIImage(data: tiffData)
            else {
                return nil
        }
        return ciImage
        #endif
    }
}

extension CGImage {
    
    var cpImage: CPImage {
        #if os(iOS)
        return UIImage(cgImage: self)
        #elseif os(OSX)
        return NSImage(cgImage: self, size: .init(width: width, height: height))
        #endif
    }
}

//extension CPImage {
//    
//    
//    func pixelData() -> [UInt8]? {
//        let size = self.size
//        let dataSize = size.width * size.height * 4
//        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
//        let colorSpace = CGColorSpaceCreateDeviceRGB()
//        let context = CGContext(data: &pixelData,
//                                width: Int(size.width),
//                                height: Int(size.height),
//                                bitsPerComponent: 8,
//                                bytesPerRow: 4 * Int(size.width),
//                                space: colorSpace,
//                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
//        
//#if os(iOS)
//        guard let cgImage = self.cgImage else { return nil }
//#elseif os(OSX)
//        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {return nil}
//#endif
////        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
//
//        return pixelData
//    }
// }

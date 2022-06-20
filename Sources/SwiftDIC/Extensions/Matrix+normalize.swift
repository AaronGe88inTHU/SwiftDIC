//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/17.
//

import Surge
import Foundation

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public func normalize(_ lhs: Matrix<Float>)  -> Matrix<Float>{
    let diff = lhs - mean(lhs)
    let value: Float = sum(pow(diff, 2))
    return diff / sqrtf(value)
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public func normalize(_ lhs: Matrix<Double>) -> Matrix<Double>{
    let diff = lhs - mean(lhs)
    let value: Double = sum(pow(diff, 2))
    return diff / sqrt(value)
}

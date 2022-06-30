//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/28.
//

import Surge
import Accelerate


@available(macOS 10.15, *)
public func calculateStrain(dv: [Double], current: Matrix<Double>, halfsize: Int, step: Int) async throws ->[Double]{
    let h = Matrix<Double>.hValues(halfsize: halfsize)
    
    let ht = transpose(h)
    return [0]
    
//    let newXs = dv[0] + dv[2] * h
////    for (dy, dx) in (-halfsize...halfsize, -halfsize...halfsize)
////            let newXs = (guess[0] + guess[2] * dx + guess[3] * dy).reduce([]) { partialResult, row in
////        partialResult + row.map{$0}
////    }
//}
//
//    let newYs = (ys + guess[1] + guess[4] * dx + guess[5] * dy).reduce([]) { partialResult, row in
//        partialResult + row.map{ $0}
//    }
//
//    vDSP.convolve(v.reduce([]) {$0  + $1}, rowCount: v.rows, columnCount: v.columns,
//                  withKernel: h.reduce([]) {$0 + $1}, kernelRowCount: h.rows, kernelColumnCount: h.columns)
}

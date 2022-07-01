//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/28.
//

import Surge
import Accelerate
import Algorithms

@available(iOS 13.0.0, *)
@available(macOS 10.15, *)
public func calculateStrain(dv: [Double], halfsize: Int, step: Int) async throws ->(exx: Double, eyy: Double, exy: Double){
    
    let countGrid = halfsize*2+1
    let h = Matrix<Double>.hValues(halfsize: halfsize) / Double(countGrid*countGrid*(halfsize+1)*halfsize*step)
        
    let hArray = h.reduce([]) {
        $0 + $1
    }
    
    let ht = transpose(h)
    let htArray = ht.reduce([]) {
        $0 + $1
    }
    
    var u = Matrix<Double>(rows: countGrid, columns:  countGrid, repeatedValue: 0)
    var v = Matrix<Double>(rows: countGrid, columns:  countGrid, repeatedValue: 0)
    
    
//    let newXs = dv[0] + dv[2] * h
    for (dy, dx) in product(-halfsize...halfsize, -halfsize...halfsize){
        u[dy+halfsize, dx+halfsize] = dv[0] + dv[2] * Double(dx) + dv[3] * Double(dy)
        v[dy+halfsize, dx+halfsize] = dv[1] + dv[4] * Double(dx) + dv[5] * Double(dy)
    }
    
    let uArray = u.reduce([]) {$0 + $1}
    let vArray = v.reduce([]) {$0 + $1}
    
//
    let exx = vDSP.convolve(uArray, rowCount: countGrid, columnCount: countGrid,
                            withKernel: hArray, kernelRowCount:countGrid, kernelColumnCount: countGrid).first {
        $0 != 0
    } ?? 0.0
    
    let eyy = vDSP.convolve(vArray, rowCount: countGrid, columnCount: countGrid,
                            withKernel: hArray, kernelRowCount:countGrid, kernelColumnCount: countGrid).first {
        $0 != 0
    } ?? 0.0
    
    let dudy = vDSP.convolve(uArray, rowCount: countGrid, columnCount: countGrid,
                            withKernel: htArray, kernelRowCount:countGrid, kernelColumnCount: countGrid).first {
        $0 != 0
        
    } ?? 0.0
    
    let dvdx = vDSP.convolve(vArray, rowCount: countGrid, columnCount: countGrid,
                            withKernel: htArray, kernelRowCount:countGrid, kernelColumnCount: countGrid).first {
        $0 != 0
    } ?? 0.0
    
    let exy = dudy + dvdx
    
    return (exx, eyy, exy)
}

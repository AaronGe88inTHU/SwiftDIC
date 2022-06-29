//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/28.
//

import Foundation
import Surge
import Accelerate

public func calculateStrain(v: Matrix<Double>, subsize: Int, step: Int) async throws ->[Matrix<Double>]{
    let halfsize = subsize/2
    let h = Matrix<Double>(rows: subsize, columns: subsize) { row, column in
        Double(column - halfsize)
    }
    return [h]
    
//    vDSP.convolve(<#T##vector: AccelerateBuffer##AccelerateBuffer#>, rowCount: <#T##Int#>, columnCount: <#T##Int#>, withKernel: <#T##AccelerateBuffer#>, kernelRowCount: <#T##Int#>, kernelColumnCount: <#T##Int#>)
}

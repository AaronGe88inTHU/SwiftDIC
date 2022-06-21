//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/20.
//


import Surge
import Accelerate
import Algorithms


@available(iOS 13.0, *)
@available(macOS 10.15, *)
public func templateMatch(templ: Matrix<Float>, image: Matrix<Float>) -> (row: Int, column: Int){
    precondition(image.rows >= templ.rows && image.columns >= templ.columns)
    let template = templ.reduce([]){ partialResult, row in
        partialResult + row.map{$0}
    }
    let vector = image.reduce([]) { partialResult,  row in
        partialResult + row.map{$0}
    }
    
    let result = vDSP.convolve(vector, rowCount: image.rows, columnCount: image.columns, withKernel: template,
                               kernelRowCount: templ.rows, kernelColumnCount: templ.columns)
    
    let maxIndex = vDSP.indexOfMaximum(result)
    
    let row =  Int(maxIndex.0) / image.columns
    let column = Int(maxIndex.0) % image.columns
    return(row, column)
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public func templateMatch(templ: Matrix<Double>, image: Matrix<Double>) -> (row: Int, column: Int){
    precondition(image.rows >= templ.rows && image.columns >= templ.columns)
//    let template = templ.reduce([]){ partialResult, row in
//        partialResult + row.map{$0}
//    }
//    let vector = image.reduce([]) { partialResult,  row in
//        partialResult + row.map{$0}
//    }
//
//    let result = vDSP.convolve(vector, rowCount: image.rows, columnCount: image.columns, withKernel: template,
//                               kernelRowCount: templ.rows, kernelColumnCount: templ.columns)
//
//
//    let maxIndex = vDSP.indexOfMaximum(result)
//
//    let row =  Int(maxIndex.0) / image.columns
//    let column = Int(maxIndex.0) % image.columns
//    return(row, column)

    let halfRow = templ.rows/2
    let halfColumn = templ.columns/2
    
    var padded = Matrix<Double>(rows: image.rows+2*halfRow, columns: image.columns+2*halfColumn, repeatedValue: 0.0)
    //
   
    
    padded[halfRow...halfRow+image.rows-1, halfColumn...halfColumn+image.columns-1] = image
    //
    var resultPadded = Matrix<Double>(rows: padded.rows, columns: padded.columns, repeatedValue: 1000)
    let normalTempl = normalize(templ)
    for (y, x) in product(halfRow..<image.rows+halfRow, halfColumn..<image.columns+halfColumn)
    {
        let subImage = padded[y-halfRow...y+halfRow, x-halfColumn...x+halfColumn]
        
        resultPadded[y, x] = sum(pow(normalize(subImage) - normalTempl, 2))
    }
    
    let result = resultPadded[halfRow...halfRow+image.rows-1, halfColumn...halfColumn+image.columns-1]
    
    return result.indexOfMinimum()
}

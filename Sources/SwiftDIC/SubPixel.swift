//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/7.
//

import Foundation
import Surge

struct SubPixel : DefaultInitializable{
    public let x: Float
    public let y: Float
    private(set) var value: Float
    private(set) var dvdx: Float? = nil
    private(set) var dvdy: Float? = nil
    
    init()
    {
        self.y = 2
        self.x = 2
        self.value = 0
    }
    
    init(_ row: Float, _ column: Float, qkCqktMap: GeneralMatrix<Matrix<Float>>)
    {
        // y, x represents row, column
        if !(row >= 2 && (Int(floor(row))+3) <= qkCqktMap.rows){
            self.y = 2
        }
        else{
            self.y = row
        }
        if !(column >= 2 && (Int(floor(column))+3) <= qkCqktMap.columns){
            self.x = 2
        }
        else{
            self.x = column
        }
        
        
        //calculate subPix
//        let localCoef = qkCqktMap[( Int(floor(y))-2 ... Int(floor(y))+3),
//                                  (Int(floor(x))-2 ... Int(floor(x))+3)]
        let localCoef = qkCqktMap [Int(floor(y)), Int(floor(x))]
        
        //
        let dx = x - floor(x)
        let dy = y - floor(y)
        let yy = Matrix<Float>(rows: 1, columns: 6, grid: (0 ... 5).map{powf(dy, Float($0))})
        let xx = Matrix<Float>(rows: 6, columns: 1, grid:  (0 ... 5).map{powf(dx, Float($0))})
//        let qk = Matrix<Float>.qk
//        let qkt = transpose(qk)
        var result = yy * localCoef * xx
        assert(result.columns == 1, "Value should be a scalar")
        assert(result.rows == 1, "Value should be a scalar")
        //            return v[0]
        self.value = result[0,0]
        
        
        if(x.isInt && y.isInt)  {
            let nd = Matrix<Float>(row: [1, 0, 0 ,0 ,0 ,0])
            let dd = Matrix<Float>(column: [0, 1, 0, 0 ,0 ,0])
            result = nd *  localCoef * dd
            assert(result.columns == 1, "Value should be a scalar")
            assert(result.rows == 1, "Value should be a scalar")
            self.dvdx = result[0,0]
            result = transpose(dd) * localCoef  * transpose(nd)
            self.dvdy = result[0, 0]
        }
        
    }
    
    
     
}

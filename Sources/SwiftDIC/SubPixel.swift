//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/7.
//

import Foundation
import Surge

struct SubPixel : DefaultInitializable{
    public let x: Double
    public let y: Double
    private(set) var value: Double
    private(set) var dvdx: Double? = nil
    private(set) var dvdy: Double? = nil
    
    init()
    {
        self.y = 2
        self.x = 2
        self.value = 0
    }
    
    init(_ row: Double, _ column: Double, qkCqktMap: GeneralMatrix<Matrix<Double>>)
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
        let yy = Matrix<Double>(rows: 1, columns: 6, grid: (0 ... 5).map{pow(dy, Double($0))})
        let xx = Matrix<Double>(rows: 6, columns: 1, grid:  (0 ... 5).map{pow(dx, Double($0))})
//        let qk = Matrix<Double>.qk
//        let qkt = transpose(qk)
        var result = yy * localCoef * xx
        assert(result.columns == 1, "Value should be a scalar")
        assert(result.rows == 1, "Value should be a scalar")
        //            return v[0]
        self.value = result[0,0]
        
        
        if(x.isInt && y.isInt)  {
            let nd = Matrix<Double>(row: [1, 0, 0 ,0 ,0 ,0])
            let dd = Matrix<Double>(column: [0, 1, 0, 0 ,0 ,0])
            result = nd *  localCoef * dd
            assert(result.columns == 1, "Value should be a scalar")
            assert(result.rows == 1, "Value should be a scalar")
            self.dvdx = result[0,0]
            result = transpose(dd) * localCoef  * transpose(nd)
            self.dvdy = result[0, 0]
        }
        
    }
    
    
     
}

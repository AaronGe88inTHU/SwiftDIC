//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/29.
//

import Surge

extension Matrix {
    public static func hValues(halfsize: Int) -> Matrix<Double>{
        let subsize = halfsize*2+1
        let h = Matrix<Double>(rows: subsize, columns: subsize) { row, column in
            Double(column - halfsize)
        }
        return h
    }
}


//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/7.
//

import Surge

extension Matrix {
    public static var qk: Matrix
    {
        let grid: [Scalar] = [1/120, 13/60, 11/20, 13/60, 1/120, 0,
                              -1/24, -5/12, 0, 5/12, 1/24, 0,
                              1/12, 1/6, -1/2, 1/6, 1/12, 0,
                              -1/12, 1/6, 0, -1/6, 1/12, 0,
                              1/24, -1/6, 1/4, -1/6, 1/24, 0,
                              -1/120, 1/24, -1/12, 1/12, -1/24, 1/120]
        return Matrix(rows: 6, columns: 6, grid: grid)
    }
}

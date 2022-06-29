//
//  File 2.swift
//  
//
//  Created by Aaron Ge on 2022/6/24.
//

import Surge

struct ROIDeformVector{
    let dfdx: Matrix<Double>
    let dfdy: Matrix<Double>
    let dfdudx: Matrix<Double>
    let dfdudy: Matrix<Double>
    let dfdvdx: Matrix<Double>
    let dfdvdy: Matrix<Double>
}

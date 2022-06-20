//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/12.
//

import Surge

extension GeneralMatrix where Element == SubPixel{
    
    func values() -> Matrix<Double>{
        .init(rows: rows, columns: columns, grid: elements.map{$0.value})
        
    }
    
    var xs: Matrix<Double>{
        .init(rows: rows, columns: columns, grid: elements.map{$0.x})
    }
    
    var ys: Matrix<Double>{
        .init(rows: rows, columns: columns, grid: elements.map{$0.y})
    }
    
    var isIntSubset: Bool{
        xs.allSatisfy {$0.allSatisfy { value in value.isInt}} &&
        ys.allSatisfy{ $0.allSatisfy { value in value.isInt}}
        
    }
    
    var dvdx: Matrix<Double>?{
        guard isIntSubset else{
            return nil
        }
        return .init(rows: rows, columns: columns, grid: elements.map{ $0.dvdx!})
        
    }
    
    var dvdy: Matrix<Double>?{
        guard isIntSubset else{
            return nil
        }
        return .init(rows: rows, columns: columns, grid: elements.map{ $0.dvdy!})
    }
}

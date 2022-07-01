//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/30.
//

import Surge

@available(macOS 10.15.0, *)
@available(iOS 13.0.0, *)
actor GeneralMatrixofMatrixActor{
    private var values : [GeneralMatrix<Matrix<Double>>]
    init(gridCount: Int, count: Int)
    {
        
        let matrix = Matrix<Double>(rows: 6,
                                         columns: 6,
                                         repeatedValue: 0)
                        
        let gMatrix = GeneralMatrix(rows: gridCount,
                            columns: gridCount,
                                    elements: .init(repeating: matrix,
                                                    count: gridCount*gridCount))
                           
        self.values = .init(repeating: gMatrix, count: count)
    }
    
    
    func setIndividualValue(_ index: Int, _ value: GeneralMatrix<Matrix<Double>>)
    {
        values[index] = value
    }
    
    func toArray () ->  [GeneralMatrix<Matrix<Double>>]{
        return values
    }
    
    
}

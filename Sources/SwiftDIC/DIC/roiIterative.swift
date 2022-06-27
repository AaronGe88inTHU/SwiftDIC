//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/27.
//
import Surge
import Accelerate
import Algorithms

@available(macOS 10.15, *)
func roiIterative(initialGuess:[Double],
                  center: (y:Int, x:Int),
                  subset: GeneralMatrix<SubPixel>,
                  dfdp: GeneralMatrix<Matrix<Double>>,
                  hassien:Matrix<Double>,
                  currentMap:GeneralMatrix<Matrix<Double>>,
                  gridCount: Int) async throws -> [Double]{
    
    guard subset.isIntSubset
    else{
        throw fatalError("reference is not a Int subset")
    }
    
    let ys = subset.ys
    let xs = subset.xs
    let dy = ys - Double(center.y)
    let dx = xs - Double(center.x)
    
    var guess = initialGuess
    var normal:Double = 1.0
    var coef:Double = 1000.0
    
    
    
    var loops = 0
    while normal > 3e-4 && coef > 1e-2 && loops <= 500{
        let newXs = (xs + guess[0] + guess[2] * dx + guess[3] * dy).reduce([]) { partialResult, row in
            partialResult + row.map{$0}
        }
        
        let newYs = (ys + guess[1] + guess[4] * dx + guess[5] * dy).reduce([]) { partialResult, row in
            partialResult + row.map{ $0}
        }
        
        guard newXs.allSatisfy({ value in
            Int(value) >= 0 && Int(value) < currentMap.columns
            
        }),
              newYs.allSatisfy({ value in
                  Int(value) >= 0  && Int(value) < currentMap.rows
                  
              })
        else{
            loops = 501
            continue
        }
        
        let deformList = zip(newYs, newXs).map {SubPixel($0.0, $0.1, qkCqktMap: currentMap)}
        
        let deformSubset = GeneralMatrix<SubPixel>(rows: gridCount , columns: gridCount, elements: deformList)
        
        let normalizedDiff = normalize(subset.values()) - normalize(deformSubset.values())
        
        coef = sum(pow(normalizedDiff, 2))
        
        var gradient = Matrix<Double>(arrayLiteral: [0,0,0,0,0,0])
        for (row, column) in product(0..<gradient.rows, 0..<gradient.columns){
            gradient +=  normalizedDiff[row, column] * dfdp[row, column]
        }
        
        
        let diff = subset.values() - mean(subset.values())
        let value: Double = sum(pow(diff, 2))
        gradient = gradient * (-2) / sqrt(value)
        
        let detlaP = solveAxb(hassien, gradient[row: 0])
        
        let wOld = Matrix<Double>(rows: 3, columns: 3, grid: [1 + guess[2], guess[3], guess[0],
                                                              guess[4], 1+guess[5], guess[1],
                                                              0,0,1])
        
        let w = Matrix<Double>(rows: 3, columns: 3, grid: [1 + detlaP[2], detlaP[3], detlaP[0],
                                                           detlaP[4], 1+detlaP[5], detlaP[1],
                                                           0,0,1])
        let wNew = wOld * inv(w)
        
        guess = [wNew[0,2], wNew[1,2], wNew[0,0]-1, wNew[0,1], wNew[1,0], wNew[1,1]-1]
        normal = sqrt(detlaP.reduce(0.0, {$0 + pow($1, 2)}))
        loops += 1
        //                print(coef)
        
    }
    if loops >= 500{
        return [0, 0 ,0, 0 ,0, 0]
    }
    else{
        return guess
    }
}

actor DeformVectorsActor{
    var deformatVectors: [[Double]]
    init(count: Int){
        deformatVectors = [[Double]](repeating: [0,0,0,0,0,0], count: count)
    }
    
    init(deformatVectors: [[Double]])
    {
        self.deformatVectors = deformatVectors
    }
    
    public func setValueByIndex(index: Int, value: [Double]){
        deformatVectors[index] = value
    }
    
    public func toArray()  -> [[Double]] {
        deformatVectors
    }
    
}




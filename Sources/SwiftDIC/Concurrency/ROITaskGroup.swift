//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/24.
//

import Surge
import Algorithms


@available(macOS 10.15, *)

struct ROITaskGroup{
    
    let roiPoints: [(y:Int, x:Int)]
    let roiSubsets: [GeneralMatrix<SubPixel>]
    let reference : Matrix<Double>
    let halfSize: Int
    var dfdxRef: Matrix<Double>
    var dfdyRef: Matrix<Double>
    fileprivate var dfdpRoi: DfdpROI
    
    init(roiPoints: [(y:Int, x:Int)],
         roiSubsets:  [GeneralMatrix<SubPixel>],
         reference : Matrix<Double>,
         halfSize: Int,
         dfdxRef: Matrix<Double>,
         dfdyRef: Matrix<Double>)
    {
        self.roiPoints = roiPoints
        self.roiSubsets = roiSubsets
        self.reference = reference
        self.halfSize = halfSize
        self.dfdxRef = dfdxRef
        self.dfdyRef = dfdyRef
        dfdpRoi = DfdpROI(halfSize: halfSize, count: roiPoints.count)
    }
    
    
    
    
    public func calculateHassien() async throws ->  [Matrix<Double>] {
        
        //        var results: [ROIDeformVector]

        
        let result = try await withThrowingTaskGroup(of: (Int, Matrix<Double>).self,
                                                     returning: [(Int, Matrix<Double>)].self) { group in
            for ii in 0 ..< roiPoints.count{
                let x = roiPoints[ii].x
                let y = roiPoints[ii].y
                let subset = roiSubsets[ii]
                let roi = reference[y-halfSize...y+halfSize, x-halfSize...x+halfSize]
                group.addTask {
                    let value = try await calculateDeformVectorAsync(y: y, x: x, halfSize: halfSize, subset: subset, dfdyRef: dfdyRef, dfdxRef: dfdxRef)
                    
                    
                    let hassien = try await calculateHassiensAsync(ii, defVec: value, refRoi: roi)
                    
                    return (ii, hassien)
                }
            }
            
            return try await group.collect()
        }
        return result.sorted(by: {$0.0 < $1.0}).map {$0.1}
        
    }
    
    public var dfdp: [GeneralMatrix<Matrix<Double>>]{
        get async throws{
            await dfdpRoi.getValue()
        }
    }
    
    
    
    private func calculateDeformVectorAsync(y:Int, x:Int,
                                            halfSize: Int, subset: GeneralMatrix<SubPixel>,
                                            dfdyRef: Matrix<Double>, dfdxRef: Matrix<Double>) async throws -> ROIDeformVector
    {
        precondition(subset.isIntSubset)
        
        let ys = subset.ys
        let xs = subset.xs
        let dy = ys - Double(y)
        let dx = xs - Double(x)
        
        let dfdyArray = subset.elements.map {dfdyRef[Int($0.y), Int($0.x)]}
        let dfdy =  Matrix<Double>(rows: halfSize*2+1, columns: halfSize*2+1, grid: dfdyArray )
        let dfdxArray = subset.elements.map {dfdxRef[Int($0.y), Int($0.x)]}
        let dfdx = Matrix<Double>(rows: halfSize*2+1, columns: halfSize*2+1, grid: dfdxArray )
        
        
        return  ROIDeformVector(dfdx: dfdx, dfdy: dfdy,
                                dfdudx: dfdx * dx, dfdudy: dfdx * dy,
                                dfdvdx: dfdy * dx, dfdvdy: dfdy * dy)
        
    }
    
    
    private func calculateHassiensAsync(_ index: Int, defVec: ROIDeformVector, refRoi: Matrix<Double>) async throws -> Matrix<Double> {
        
        //        var hessianValue : Matrix<Double> = .init(rows: 6, columns: 6, repeatedValue: 0.0)
//        let  dfdpROI = DfdpROI(halfSize: halfSize)
        
        return try await withThrowingTaskGroup(of: (Int, Matrix<Double>).self,
                                               returning: Matrix<Double>.self) { group in
            
            for (row, column) in product(0..<halfSize*2+1, 0..<halfSize*2+1){
                group.addTask {
                    let rc = row * (halfSize*2+1) + column
                    let p  =  Matrix<Double>(row: [defVec.dfdx[row, column],
                                                   defVec.dfdy[row, column],
                                                   defVec.dfdudx[row, column],
                                                   defVec.dfdudy[row, column],
                                                   defVec.dfdvdx[row, column],
                                                   defVec.dfdvdy[row, column]])
                    await dfdpRoi.setIndividualValue(index, row, column, p)
                    return (rc, transpose(p) * p)
                }
                
            }
            
            let hassien = try await group.reduce(Matrix<Double>(rows: 6, columns: 6, repeatedValue: 0)) {
                $0 + $1.1
            }
            
            guard hassien.isPositiveDefined()
            else{
                throw fatalError("not postive defined")
            }
            return hassien * 2 / refRoi.variant()
        }
    }
    
    
    
}


fileprivate actor DfdpROI{
    private var dfdp : [GeneralMatrix<Matrix<Double>>]
    init(halfSize: Int, count: Int)
    {
        
        let matrix = Matrix<Double>(rows: 6,
                                         columns: 6,
                                         repeatedValue: 0)
                        
        let gMatrix = GeneralMatrix(rows: halfSize*2+1,
                            columns: halfSize*2+1,
                                    elements: .init(repeating: matrix,
                                                    count: (halfSize*2+1)*(halfSize*2+1)))
                           
        self.dfdp = .init(repeating: gMatrix, count: count)
    }
    
    
    func setIndividualValue(_ index: Int, _ row: Int, _ column: Int, _ value: Matrix<Double>)
    {
        dfdp[index][row, column] = value
    }
    
    func getValue () ->  [GeneralMatrix<Matrix<Double>>]{
        return dfdp
    }
    
    
}

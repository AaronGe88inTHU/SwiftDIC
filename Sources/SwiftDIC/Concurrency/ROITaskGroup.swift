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
//    let roiSubsets: [GeneralMatrix<SubPixel>]
    let reference : Matrix<Double>
    let halfSize: Int
    var dfdxRef: Matrix<Double>
    var dfdyRef: Matrix<Double>
    
    let gridCount: Int
    fileprivate var dfdpRoi: DfdpROI
    
    init(roiPoints: [(y:Int, x:Int)],
//         roiSubsets:  [GeneralMatrix<SubPixel>],
         reference : Matrix<Double>,
         halfSize:Int,
         dfdxRef: Matrix<Double>,
         dfdyRef: Matrix<Double>)
    {
        self.roiPoints = roiPoints
//        self.roiSubsets = roiSubsets
        self.reference = reference
        self.halfSize = halfSize
        self.dfdxRef = dfdxRef
        self.dfdyRef = dfdyRef
        self.gridCount = 2*halfSize+1
        self.dfdpRoi = DfdpROI(gridCount: gridCount, count: roiPoints.count)
        
    }
    
    
    
    
    public func calculateHassien() async throws ->  [Matrix<Double>] {
        
        let results: MatrixsActor = .init(count: roiPoints.count)

        await withThrowingTaskGroup(of: Void.self) { group in
            for ii in 0 ..< roiPoints.count{
                let x = roiPoints[ii].x
                let y = roiPoints[ii].y
//                let subset = roiSubsets[ii]
                
                let roi = reference[y-halfSize...y+halfSize, x-halfSize...x+halfSize]
                
                group.addTask {
                    let value = try await calculateDeformVectorAsync(y: y, x: x, gridCount: gridCount, //subset: subset,
                                                                     dfdyRef: dfdyRef, dfdxRef: dfdxRef)
                    
                    
                    let hassien = try await calculateHassiensAsync(ii, defVec: value, refRoi: roi)
                    await results.setIndividualValue(ii, hassien)
                }
            }
            
        }
        return await results.toArray()
        
    }
    
    public var dfdp: [GeneralMatrix<Matrix<Double>>]{
        get async throws{
            await dfdpRoi.toArray()
        }
    }
    
    
    
     func calculateDeformVectorAsync(y:Int, x:Int,
                                            gridCount: Int,// subset: GeneralMatrix<SubPixel>,
                                            dfdyRef: Matrix<Double>, dfdxRef: Matrix<Double>) async throws -> ROIDeformVector
    {
//        precondition(subset.isIntSubset)
        
//        let ys = subset.ys
//        let xs = subset.xs
//        let dy = ys - Double(y)
//        let dx = xs - Double(x)
        
        let dx = Matrix<Double>.hValues(halfsize: gridCount/2)
        let dy = transpose(dx)
        
        let ys = dy + Double(y)
        let xs = dx + Double(x)
        
        
        var dfdy =  Matrix<Double>(rows: gridCount, columns: gridCount,repeatedValue: 0)
        var dfdx = Matrix<Double>(rows: gridCount, columns: gridCount, repeatedValue: 0)
        
        for (row, column) in product(0..<gridCount, 0..<gridCount){
            dfdy[row, column] = dfdyRef[Int(ys[row, column]), Int(xs[row, column])]
            dfdx[row, column] = dfdxRef[Int(ys[row, column]), Int(xs[row, column])]
        }
        
       
        
//        subset.elements.map {}

        
//        let dfdyArray = subset.elements.map {dfdyRef[Int($0.y), Int($0.x)]}
//        let dfdy =  Matrix<Double>(rows: gridCount, columns: gridCount, grid: dfdyArray )
//        let dfdxArray = subset.elements.map {dfdxRef[Int($0.y), Int($0.x)]}
//        let dfdx = Matrix<Double>(rows: gridCount, columns: gridCount, grid: dfdxArray )
        
        
        return  ROIDeformVector(dfdx: dfdx, dfdy: dfdy,
                                dfdudx: dfdx * dx, dfdudy: dfdx * dy,
                                dfdvdx: dfdy * dx, dfdvdy: dfdy * dy)
        
    }
    
    
    private func calculateHassiensAsync(_ index: Int, defVec: ROIDeformVector, refRoi: Matrix<Double>) async throws -> Matrix<Double> {
        
        
//        let pMatrix = PMatrix(count: <#T##Int#>)
         try await withThrowingTaskGroup(of: Matrix<Double>.self,
                                               returning: Matrix<Double>.self) { group in
            
            for (row, column) in product(0..<gridCount, 0..<gridCount){
                group.addTask {
//                    let rc = row * (gridCount) + column
                    let p  =  Matrix<Double>(row: [defVec.dfdx[row, column],
                                                   defVec.dfdy[row, column],
                                                   defVec.dfdudx[row, column],
                                                   defVec.dfdudy[row, column],
                                                   defVec.dfdvdx[row, column],
                                                   defVec.dfdvdy[row, column]])
                    await dfdpRoi.setIndividualValue(index, row, column, p)
                    return transpose(p) * p
                }
                
            }
            
            let hassien = try await group.reduce(Matrix<Double>(rows: 6, columns: 6, repeatedValue: 0)) {
                $0 + $1
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
    init(gridCount: Int, count: Int)
    {
        
        let matrix = Matrix<Double>(rows: 6,
                                         columns: 6,
                                         repeatedValue: 0)
                        
        let gMatrix = GeneralMatrix(rows: gridCount,
                            columns: gridCount,
                                    elements: .init(repeating: matrix,
                                                    count: gridCount*gridCount))
                           
        self.dfdp = .init(repeating: gMatrix, count: count)
    }
    
    
    func setIndividualValue(_ index: Int, _ row: Int, _ column: Int, _ value: Matrix<Double>)
    {
        dfdp[index][row, column] = value
    }
    
    func toArray () ->  [GeneralMatrix<Matrix<Double>>]{
        return dfdp
    }
    
    
}

fileprivate actor MatrixsActor{
    private var matrixs : [Matrix<Double>]
    init(count: Int)
    {
        self.matrixs = .init(repeating: Matrix<Double>(rows: 6, columns: 6, repeatedValue: 0), count: count)
    }
    
    init(_ matrixs: [Matrix<Double>])
    {
        self.matrixs = matrixs
    }
    
    
    func setIndividualValue(_ index: Int, _ value: Matrix<Double>)
    {
       matrixs[index] = value
    }
    
    func toArray () -> [Matrix<Double>]{
        return matrixs
    }
    
    
}

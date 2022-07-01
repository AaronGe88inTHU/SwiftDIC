//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/24.
//

import Surge
import Algorithms


@available(iOS 13.0.0, *)
@available(macOS 10.15, *)

public struct ROITaskGroup{
    
    let roiPoints: [(y:Int, x:Int)]
    let reference : Matrix<Double>
    let halfSize: Int
    var dfdxRef: Matrix<Double>
    var dfdyRef: Matrix<Double>
    let gridCount: Int
    
    
    init(roiPoints: [(y:Int, x:Int)],
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
        
    }
    
    
    
    
    public func calculateHassien() async throws -> ([Matrix<Double>], [GeneralMatrix<Matrix<Double>>]){
        
        //        let results: [Matrix<Double>] = .init(repeating: .init(rows: 6, columns: 6, repeatedValue: 0),
        //                                              count: roiPoints[ii])
        
        let hassiens = MatrixActor(count: roiPoints.count)
        let dfdp = GeneralMatrixofMatrixActor(gridCount: gridCount, count: roiPoints.count)
        
        
        await withThrowingTaskGroup(of: Void.self) { group in
            for ii in 0 ..< roiPoints.count{
                let x = roiPoints[ii].x
                let y = roiPoints[ii].y
                let roi = reference[y-halfSize...y+halfSize, x-halfSize...x+halfSize]
                
                
                group.addTask {
                    
                    let value = try calculateDeformVector(y: y,
                                                          x: x,
                                                          gridCount: gridCount,
                                                          dfdyRef: dfdyRef,
                                                          dfdxRef: dfdxRef)
                    
                    let (h, p) = try calculateHassiens(defVec: value, refRoi: roi)
                    
                    await hassiens.setIndividualValue(ii, h)
                    await dfdp.setIndividualValue(ii, p)
                }
                
            }
        }
        
        return await (hassiens.toArray(), dfdp.toArray())
        
    }
    
    
    
    
    
    func calculateDeformVector(y:Int,
                               x:Int,
                               gridCount: Int,// subset: GeneralMatrix<SubPixel>,
                               dfdyRef: Matrix<Double>,
                               dfdxRef: Matrix<Double>)  throws -> ROIDeformVector
    {
        
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
        
        return  ROIDeformVector(dfdx: dfdx, dfdy: dfdy,
                                dfdudx: dfdx * dx, dfdudy: dfdx * dy,
                                dfdvdx: dfdy * dx, dfdvdy: dfdy * dy)
        
    }
    
    
    private func calculateHassiens(defVec: ROIDeformVector,
                                   refRoi: Matrix<Double>) throws ->(hassien: Matrix<Double>,
                                                                     pMatrix: GeneralMatrix<Matrix<Double>>) {
        var ptpArray = [Matrix<Double>](repeating: .init(rows: 6, columns: 6, repeatedValue: 0),
                                        count: gridCount*gridCount)
        var pArray = ptpArray
        
        for (row, column) in product(0..<gridCount, 0..<gridCount){
            let index = row * gridCount +  column
            let p  =  Matrix<Double>(row: [defVec.dfdx[row, column],
                                           defVec.dfdy[row, column],
                                           defVec.dfdudx[row, column],
                                           defVec.dfdudy[row, column],
                                           defVec.dfdvdx[row, column],
                                           defVec.dfdvdy[row, column]])
            
            pArray[index] = p
            ptpArray[index] = transpose(p) * p
        }
        
        
        
        let hassien = ptpArray.reduce(Matrix<Double>(rows: 6, columns: 6, repeatedValue: 0)) {
            $0 + $1
        }
        
        guard hassien.isPositiveDefined()
        else{
            throw fatalError("not postive defined")
        }
        
        let pMatrix = GeneralMatrix<Matrix<Double>>(rows: gridCount,
                                                    columns: gridCount,
                                                    elements: pArray)
        return (hassien * 2 / refRoi.variant(), pMatrix)
    }
    
    //
    ////        let pMatrix = PMatrix(count: <#T##Int#>)
    //         try await withThrowingTaskGroup(of: Matrix<Double>.self,
    //                                               returning: Matrix<Double>.self) { group in
    //
    //            for (row, column) in product(0..<gridCount, 0..<gridCount){
    //                group.addTask {
    ////                    let rc = row * (gridCount) + column
    //                    let p  =  Matrix<Double>(row: [defVec.dfdx[row, column],
    //                                                   defVec.dfdy[row, column],
    //                                                   defVec.dfdudx[row, column],
    //                                                   defVec.dfdudy[row, column],
    //                                                   defVec.dfdvdx[row, column],
    //                                                   defVec.dfdvdy[row, column]])
    //                    await dfdpRoi.setIndividualValue(index, row, column, p)
    //                    return transpose(p) * p
    //                }
    //
    //            }
    //
    //            let hassien = try await group.reduce(Matrix<Double>(rows: 6, columns: 6, repeatedValue: 0)) {
    //                $0 + $1
    //            }
    //
    //            guard hassien.isPositiveDefined()
    //            else{
    //                throw fatalError("not postive defined")
    //            }
    //            return hassien * 2 / refRoi.variant()
    //        }
    
    
}






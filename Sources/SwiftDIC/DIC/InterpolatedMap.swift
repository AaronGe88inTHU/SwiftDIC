//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/7.
//

import Foundation
import Surge
import Accelerate
import ComplexModule
import Algorithms


@available(iOS 15.0, *)
@available(macOS 12.0, *)
struct InterpolatedMap{
    let gs: Matrix<Double>
    
    public init(row: Int, column: Int, value:[Double]){
        precondition(value.count == row * column)
        precondition(row >= 5 && column >= 5)
        self.gs = .init(rows: row, columns: column, grid: value)
        assert(self.gs.isFftable())
    }
    
    public init(gs: Matrix<Double>){
        precondition(gs.rows >= 5 && gs.columns >= 5)
        let row = gs.rows
        let column = gs.columns
        
        precondition(row >= 5 && column >= 5)
        
        
        precondition(gs.isFftable())
        
        self.gs = gs
    }
    
    func bSplineCoefMap() -> Matrix<Double> {
        let width = gs.columns
        let height = gs.rows

        let kernal_b: [Double] = [1.0/120, 13/60, 11/20, 13/60, 1.0/120]
        var kernal_b_x: [Double] = .init(repeating: 0, count: width)
        var kernal_b_y: [Double] = .init(repeating: 0, count: height)

        for ii in 0 ... 2{
            kernal_b_x[ii] = kernal_b[2+ii]
            kernal_b_y[ii] = kernal_b[2+ii]
        }
        
        kernal_b_x[width-2] = kernal_b[0]
        kernal_b_x[width-1] = kernal_b[1]
        
        kernal_b_y[height-2] = kernal_b[0]
        kernal_b_y[height-1] = kernal_b[1]
        
    
        var coef = Matrix<Double>(rows: gs.rows, columns: gs.columns, repeatedValue: 0)

        var kernal_b_x_fft:([Double], [Double]) = dft(kernal_b_x)!
        var kernal_b_y_fft:([Double], [Double]) = dft(kernal_b_y)!
        
        
        //MARK: Numeric methods
        
        for ii in 0 ..< height{
  
            let row = gs[row: ii]
   
            var rowFft: ([Double], [Double]) = dft(row)!
//            var rowFft: ([Double], [Double]) = fft(row)
            
            var cdft = ([Double](repeating: 0, count: gs.columns), [Double](repeating: 0, count:  gs.columns))
            //MARK: Accelerate methods
            //Start********************************************************************************************
            
            rowFft.0.withUnsafeMutableBufferPointer { arealPtr in
                rowFft.1.withUnsafeMutableBufferPointer { aimagPtr in
                    kernal_b_x_fft.0.withUnsafeMutableBufferPointer { brealPtr in
                        kernal_b_x_fft.1.withUnsafeMutableBufferPointer { bimagPtr in
                            cdft.0.withUnsafeMutableBufferPointer { crealPtr in
                                cdft.1.withUnsafeMutableBufferPointer { cimagPtr in
                                    let aSplitComplex = DSPDoubleSplitComplex(realp: arealPtr.baseAddress!,
                                                                        imagp: aimagPtr.baseAddress!)
                                    let bSplitComplex = DSPDoubleSplitComplex(realp: brealPtr.baseAddress!,
                                                                        imagp: bimagPtr.baseAddress!)
                                    var cSplitComplex = DSPDoubleSplitComplex(realp: crealPtr.baseAddress!,
                                                                        imagp: cimagPtr.baseAddress!)

                                    vDSP.divide(aSplitComplex, by: bSplitComplex, count: gs.columns, result: &cSplitComplex)
                                }
                            }
                        }
                    }
                }
            }
            
            //MARK: Numeric methods
            coef[row: ii] = idft(cdft)!
//
        }

       
        
        for ii in 0 ..< width{
  
            let column = coef[column: ii]
   
            var columnFft: ([Double], [Double]) = dft(column)!
//            var columnFft: ([Double], [Double]) = fft(column)
            
            
            var cdft = ([Double](repeating: 0, count: gs.rows), [Double](repeating: 0, count:  gs.rows))
            //MARK: Accelerate methods
            //Start********************************************************************************************
            
            columnFft.0.withUnsafeMutableBufferPointer { arealPtr in
                columnFft.1.withUnsafeMutableBufferPointer { aimagPtr in
                    kernal_b_y_fft.0.withUnsafeMutableBufferPointer { brealPtr in
                        kernal_b_y_fft.1.withUnsafeMutableBufferPointer { bimagPtr in
                            cdft.0.withUnsafeMutableBufferPointer { crealPtr in
                                cdft.1.withUnsafeMutableBufferPointer { cimagPtr in
                                    let aSplitComplex = DSPDoubleSplitComplex(realp: arealPtr.baseAddress!,
                                                                        imagp: aimagPtr.baseAddress!)
                                    let bSplitComplex = DSPDoubleSplitComplex(realp: brealPtr.baseAddress!,
                                                                        imagp: bimagPtr.baseAddress!)
                                    var cSplitComplex = DSPDoubleSplitComplex(realp: crealPtr.baseAddress!,
                                                                        imagp: cimagPtr.baseAddress!)

                                    vDSP.divide(aSplitComplex, by: bSplitComplex, count: gs.rows, result: &cSplitComplex)
                                }
                            }
                        }
                    }
                }
            }
            coef[column: ii] = idft(cdft)!
        }
    
        return coef

    }
    
    func bSplineCoefMapAsync() async throws -> Matrix<Double> {
        let width = gs.columns
        let height = gs.rows

        let kernal_b: [Double] = [1.0/120, 13/60, 11/20, 13/60, 1.0/120]
        var kernal_b_x: [Double] = .init(repeating: 0, count: width)
        var kernal_b_y: [Double] = .init(repeating: 0, count: height)

        for ii in 0 ... 2{
            kernal_b_x[ii] = kernal_b[2+ii]
            kernal_b_y[ii] = kernal_b[2+ii]
        }
        
        kernal_b_x[width-2] = kernal_b[0]
        kernal_b_x[width-1] = kernal_b[1]
        
        kernal_b_y[height-2] = kernal_b[0]
        kernal_b_y[height-1] = kernal_b[1]
        
    
        var coef = Matrix<Double>(rows: gs.rows, columns: gs.columns, repeatedValue: 0)

        let kernal_b_x_fft:([Double], [Double]) = dft(kernal_b_x)!
        let kernal_b_y_fft:([Double], [Double]) = dft(kernal_b_y)!
        let rowResults = VectorsActor(count: height, length: width)
        
        await withThrowingTaskGroup(of: Void.self) { group  in
            for ii in 0 ..< height{
                let row = gs[row: ii]
                group.addTask {
                    let value = interpolate1D(vector: row, length: gs.columns, kernal: kernal_b_x_fft)
                    await rowResults.setValueByIndex(index: ii, value: value)
                }
            }
        }
        
        let rows = await rowResults.toArray()
        
        for ii in 0 ..< gs.rows{
            coef[row: ii] = rows[ii]
        }
        
        
        let columnResults = VectorsActor(count: width, length: height)
        await withThrowingTaskGroup(of: Void.self){ group in
            for ii in 0 ..< width{
                let column = coef[column: ii]
                group.addTask {
                    let value = interpolate1D(vector: column, length: gs.rows, kernal: kernal_b_y_fft)
                    await columnResults.setValueByIndex(index: ii, value: value)
                }
            }
            
          
        }
        
        let columns = await columnResults.toArray()
        
        for ii in 0 ..< gs.columns{
            coef[column: ii] = columns[ii]
        }
        
        return coef

    }
    
    public func qkCqkt() -> GeneralMatrix<Matrix<Double>>{
        var qkCqk = GeneralMatrix<Matrix<Double>>(rows: gs.rows,
                                                 columns: gs.columns,
                                                 elements: .init(repeating: .init(rows: 6, columns: 6, repeatedValue: 0.0), count: gs.rows*gs.columns))
        let rows = (2 ..< qkCqk.rows-3).map {$0}
        let columns = (2 ..< qkCqk.columns-3).map{$0}
        let qk = Matrix<Double>.qk
        let qkt = transpose(qk)
        let bmap = bSplineCoefMap()
        for (y, x) in product(rows, columns){
            qkCqk[y, x] = (qk * bmap[(y-2 ... y+3), (x-2 ... x+3)] * qkt)
//            print(qkCqk[y, x], (qk * bmap[(y-2 ... y+3), (x-2 ... x+3)] * qkt))
        }
//        print(qkCqk)
        return qkCqk
    }
    
    
    public func qkCqktAsync () async throws -> GeneralMatrix<Matrix<Double>>{
        var qkCqk = GeneralMatrix<Matrix<Double>>(rows: gs.rows,
                                                  columns: gs.columns,
                                                  elements: .init(repeating: .init(rows: 6, columns: 6, repeatedValue: 0),
                                                                  count: gs.rows*gs.columns))
        let rows = (2 ..< qkCqk.rows-3).map {$0}
        let columns = (2 ..< qkCqk.columns-3).map{$0}
        let qk = Matrix<Double>.qk
        let qkt = transpose(qk)
        let bmap = try await bSplineCoefMapAsync()
        
        let indexedResults = try await withThrowingTaskGroup(of: (Int, Matrix<Double>).self, returning:  [(Int, Matrix<Double>)].self) { group in
            
            for (y, x) in product(rows, columns){
                let bm6 = bmap[(y-2 ... y+3), (x-2 ... x+3)]
                let index = (y-2) * (qkCqk.columns-5) + (x-2)
                group.addTask {
                    (index, qk * bm6 * qkt)
                }
            }
            
            return try await group.collect()
        }
        
        let results = indexedResults.sorted {$0.0 < $1.0}.map {
            $0.1
        }
  
        
        qkCqk[2...qkCqk.rows-4, 2...qkCqk.columns-4] = GeneralMatrix<Matrix<Double>>(rows: qkCqk.rows-5,
                                                                                     columns: qkCqk.columns-5,
                                                                                     elements: results)

        return qkCqk
       
    }
    
   
    
}

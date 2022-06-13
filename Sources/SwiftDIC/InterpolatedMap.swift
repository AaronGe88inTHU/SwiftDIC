//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/7.
//

import Foundation
import Surge
import Accelerate
import SE0288_IsPower
import ComplexModule
import Algorithms


@available(macOS 12.0, *)
struct InterpolatedMap{
    let gs: Matrix<Float>
    
    public init(row: Int, column: Int, value:[Float]){
        precondition(value.count == row * column)
        precondition(row >= 5 && column >= 5)
        self.gs = .init(rows: row, columns: column, grid: value)
        assert(self.gs.isFftable())
    }
    
    public init(gs: Matrix<Float>){
        precondition(gs.rows >= 5 && gs.columns >= 5)
        let row = gs.rows
        let column = gs.columns
        
        precondition(row >= 5 && column >= 5)
        
        precondition(row.isPower(of: 2) ? true : (row.isMultiple(of: 15) ? ((row/15).isPower(of: 2) || ((row/5).isPower(of: 2) || ((row/3).isPower(of: 2)))) : row.isMultiple(of: 5) ? ((row/5).isPower(of: 2)) : (row.isMultiple(of: 3) && (row/3).isPower(of: 2))))
        precondition(column.isPower(of: 2) ? true : (column.isMultiple(of: 15) ? ((column/15).isPower(of: 2) || ((column/5).isPower(of: 2) || ((column/3).isPower(of: 2)))) : column.isMultiple(of: 5) ? ((column/5).isPower(of: 2)) : (column.isMultiple(of: 3) && (column/3).isPower(of: 2))))
        
        self.gs = gs
    }
    
    
    
    public var bSplineCoefMap: Matrix<Float> {
        let width = gs.columns
        let height = gs.rows

        let kernal_b: [Float] = [1.0/120, 13/60, 11/20, 13/60, 1.0/120]
        var kernal_b_x: [Float] = .init(repeating: 0, count: width)
        var kernal_b_y: [Float] = .init(repeating: 0, count: height)

        for ii in 0 ... 2{
            kernal_b_x[ii] = kernal_b[2+ii]
            kernal_b_y[ii] = kernal_b[2+ii]
        }
        
        kernal_b_x[width-2] = kernal_b[0]
        kernal_b_x[width-1] = kernal_b[1]
        
        kernal_b_y[height-2] = kernal_b[0]
        kernal_b_y[height-1] = kernal_b[1]
        
    
        var coef = Matrix<Float>(rows: gs.rows, columns: gs.columns, repeatedValue: 0)

        var kernal_b_x_fft:([Float], [Float]) = dft(kernal_b_x)!
        var kernal_b_y_fft:([Float], [Float]) = dft(kernal_b_y)!
        
        
        //MARK: Numeric methods
        //Start********************************************************************************************
//        let kernal_b_x_fftComplex = zip(kernal_b_x_fft.0, kernal_b_x_fft.1).map {
//            Complex<Float>($0.0, $0.1)
//        }
//
//        let kernal_b_y_fftComplex = zip(kernal_b_y_fft.0, kernal_b_y_fft.1).map {
//            Complex<Float>($0.0, $0.1)
//        }
        //End*****************************************************************
        
        for ii in 0 ..< height{
  
            let row = gs[row: ii]
   
            var rowFft: ([Float], [Float]) = dft(row)!
            
            var cdft = ([Float](repeating: 0, count: gs.columns), [Float](repeating: 0, count:  gs.columns))
            //MARK: Accelerate methods
            //Start********************************************************************************************
            
            rowFft.0.withUnsafeMutableBufferPointer { arealPtr in
                rowFft.1.withUnsafeMutableBufferPointer { aimagPtr in
                    kernal_b_x_fft.0.withUnsafeMutableBufferPointer { brealPtr in
                        kernal_b_x_fft.1.withUnsafeMutableBufferPointer { bimagPtr in
                            cdft.0.withUnsafeMutableBufferPointer { crealPtr in
                                cdft.1.withUnsafeMutableBufferPointer { cimagPtr in
                                    let aSplitComplex = DSPSplitComplex(realp: arealPtr.baseAddress!,
                                                                        imagp: aimagPtr.baseAddress!)
                                    let bSplitComplex = DSPSplitComplex(realp: brealPtr.baseAddress!,
                                                                        imagp: bimagPtr.baseAddress!)
                                    var cSplitComplex = DSPSplitComplex(realp: crealPtr.baseAddress!,
                                                                        imagp: cimagPtr.baseAddress!)

                                    vDSP.divide(aSplitComplex, by: bSplitComplex, count: gs.columns, result: &cSplitComplex)
                                }
                            }
                        }
                    }
                }
            }
            
            //End***************************************************************************************************
            
            //MARK: Numeric methods
            //Start********************************************************************************************
//            let rowComplex = zip(rowFft.0, rowFft.1).map {Complex<Float>($0.0, $0.1)}
//
//            let cdftComplex = zip(rowComplex, kernal_b_x_fftComplex).map{$0.0 / $0.1}
//
//            cdft = (cdftComplex.map{$0.real}, cdftComplex.map{$0.imaginary})
            //End********************************************************************************************
            
        
            coef[row: ii] = idft(cdft)!
        }

       
        
        for ii in 0 ..< height{
  
            let column = coef[column: ii]
   
            var columnFft: ([Float], [Float]) = dft(column)!
            
            var cdft = ([Float](repeating: 0, count: gs.rows), [Float](repeating: 0, count:  gs.rows))
            //MARK: Accelerate methods
            //Start********************************************************************************************
            
            columnFft.0.withUnsafeMutableBufferPointer { arealPtr in
                columnFft.1.withUnsafeMutableBufferPointer { aimagPtr in
                    kernal_b_y_fft.0.withUnsafeMutableBufferPointer { brealPtr in
                        kernal_b_y_fft.1.withUnsafeMutableBufferPointer { bimagPtr in
                            cdft.0.withUnsafeMutableBufferPointer { crealPtr in
                                cdft.1.withUnsafeMutableBufferPointer { cimagPtr in
                                    let aSplitComplex = DSPSplitComplex(realp: arealPtr.baseAddress!,
                                                                        imagp: aimagPtr.baseAddress!)
                                    let bSplitComplex = DSPSplitComplex(realp: brealPtr.baseAddress!,
                                                                        imagp: bimagPtr.baseAddress!)
                                    var cSplitComplex = DSPSplitComplex(realp: crealPtr.baseAddress!,
                                                                        imagp: cimagPtr.baseAddress!)

                                    vDSP.divide(aSplitComplex, by: bSplitComplex, count: gs.rows, result: &cSplitComplex)
                                }
                            }
                        }
                    }
                }
            }
            
            //End***************************************************************************************************
            
            //MARK: Numeric methods
            //Start********************************************************************************************
//            let columnComplex = zip(columnFft.0, columnFft.1).map {Complex<Float>($0.0, $0.1)}
//
//            let cdftComplex = zip(columnComplex, kernal_b_y_fftComplex).map{$0.0 / $0.1}
//
//            cdft = (cdftComplex.map{$0.real}, cdftComplex.map{$0.imaginary})
            //End********************************************************************************************
            
        
            coef[column: ii] = idft(cdft)!
        }
    
        return coef

    }
    
    public var qkCqkt: ElementMatrix<Matrix<Float>>{
        var qkCqk = ElementMatrix<Matrix<Float>>(rows: gs.rows,
                                                 columns: gs.columns,
                                                 elements: .init(repeating: .init(rows: 6, columns: 6, repeatedValue: 0.0), count: gs.rows*gs.columns))
        let rows = (2 ..< qkCqk.rows-2).map {$0}
        let columns = (2 ..< qkCqk.columns-2).map{$0}
        let qk = Matrix<Float>.qk
        let qkt = transpose(qk)
        for (y, x) in product(rows, columns){
            qkCqk[y, x] = (qk * bSplineCoefMap[(y-2 ... y+3), (x-2 ... x+3)] * qkt)
        }
        
        return qkCqk
    }
}

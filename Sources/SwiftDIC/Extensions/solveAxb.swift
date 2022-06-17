//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/17.
//

import Surge
import Accelerate
@available(macOS 10.13, *)
func solveAxb(_ lhs: Matrix<Float>, _ rhs: [Float]) -> [Float]{
    
    precondition(lhs.rows == rhs.count)
    
    var rhsv = rhs
    
    var result = [Float](repeating: 0, count: lhs.rows)
    var (rowIndices, columnStarts, values) = toSparseFormat(lhs)
    var identifiedFlatten = Matrix<Double>.identity(size: Int(lhs.rows)).reduce([]) { partialResult, next in
        partialResult + next
    }
    
    rowIndices.withUnsafeMutableBufferPointer { rowIndicesPtr in
        columnStarts.withUnsafeMutableBufferPointer { columnStartsPtr in
            values.withUnsafeMutableBufferPointer { valuePtr in
                identifiedFlatten.withUnsafeMutableBufferPointer { idtPtr in
                    result.withUnsafeMutableBufferPointer { resPtr in
                        rhsv.withUnsafeMutableBufferPointer { rhsPtr in
                            
                            
                            
                            
                            var attributes = SparseAttributes_t()
                            attributes.triangle = SparseLowerTriangle
                            attributes.kind = SparseSymmetric
                            
                            let structure: SparseMatrixStructure =  SparseMatrixStructure(
                                rowCount: Int32(lhs.rows),
                                columnCount: Int32(lhs.columns),
                                columnStarts: columnStartsPtr.baseAddress!,
                                rowIndices: rowIndicesPtr.baseAddress!,
                                attributes: attributes,
                                blockSize: 1
                            )
                            
                            let a = SparseMatrix_Float(
                                structure: structure,
                                data: valuePtr.baseAddress!
                            )
                            
                            let llt: SparseOpaqueFactorization_Float = SparseFactor(SparseFactorizationCholesky, a)
                            
                            let x = DenseVector_Float(count: Int32(lhs.rows), data: resPtr.baseAddress!)
                            let b = DenseVector_Float(count: Int32(lhs.rows), data: rhsPtr.baseAddress!)
                            
                            SparseSolve(llt, b, x)
                            
                        }
                        
                    }
                    
                }
            }
        }
    }
    
    return result
}

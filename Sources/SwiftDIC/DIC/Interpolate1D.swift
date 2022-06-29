//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/28.
//

import Surge
import Accelerate

@available(iOS 15.0, *)
@available(macOS 12.0, *)
public func Interpolate1D (vector: [Double], length: Int,
                           kernal: ([Double], [Double])) -> [Double]{
    var rowFft: ([Double], [Double]) = dft(vector)!

    var cdft = ([Double](repeating: 0, count: length), [Double](repeating: 0, count: length))
    var kernal_fft = kernal
   
    //MARK: Accelerate methods
    //Start********************************************************************************************
    
    rowFft.0.withUnsafeMutableBufferPointer { arealPtr in
        rowFft.1.withUnsafeMutableBufferPointer { aimagPtr in
            kernal_fft.0.withUnsafeMutableBufferPointer { brealPtr in
                kernal_fft.1.withUnsafeMutableBufferPointer { bimagPtr in
                    cdft.0.withUnsafeMutableBufferPointer { crealPtr in
                        cdft.1.withUnsafeMutableBufferPointer { cimagPtr in
                            let aSplitComplex = DSPDoubleSplitComplex(realp: arealPtr.baseAddress!,
                                                                imagp: aimagPtr.baseAddress!)
                            let bSplitComplex = DSPDoubleSplitComplex(realp: brealPtr.baseAddress!,
                                                                imagp: bimagPtr.baseAddress!)
                            var cSplitComplex = DSPDoubleSplitComplex(realp: crealPtr.baseAddress!,
                                                                imagp: cimagPtr.baseAddress!)

                            vDSP.divide(aSplitComplex, by: bSplitComplex, count: length, result: &cSplitComplex)
                        }
                    }
                }
            }
        }
    }
    return idft(cdft)!
}

actor Vectors{
    var vectors : [[Double]]
    init(count: Int, length: Int) {
        vectors = [[Double]](repeating: .init(repeating: 0, count: length), count: count)
    }
    
    init(vectors: [[Double]]) {
        self.vectors = vectors
    }
    
    public func setValueByIndex(index: Int, value: [Double]){
        vectors[index] = value
    }
    
    public func toArray() -> [[Double]]{
        vectors
    }
}

//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/9.
//

import Foundation
import Surge


let fftableArray:[Int] = [8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768]
//[8, 12, 16, 20, 24, 32, 40, 48, 60, 64, 80, 96, 120, 128, 160, 192, 240, 256, 320, 384, 480, 512, 640, 768, 960, 1024, 1280, 1536, 1920, 2048, 2560, 3072, 3840, 4096, 5120, 6144, 7680, 8192, 10240, 12288, 15360, 16384, 20480, 24576, 30720, 32768]

extension Matrix{
    public  func isFftable()->Bool{
        fftableArray.contains(rows) && fftableArray.contains(columns)
        
    }
    
    public func paddingToFttable() -> Self{
        guard !self.isFftable()
        else{
            return self
        }
        
        let newRows = fftableArray.first {$0 >= rows}!
        let newColumns = fftableArray.first {$0 >= columns}!
        
        var newMatrix = Matrix(rows: newRows, columns: newColumns, repeatedValue: 0.0)
        newMatrix[0 ... rows-1, 0 ... columns-1] = self
        return newMatrix
    }
}

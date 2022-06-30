//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/30.
//

import Foundation

actor ROISubset{
    var roiSubsets: [GeneralMatrix<SubPixel>]
    init(roiSubsets: [GeneralMatrix<SubPixel>]){
        self.roiSubsets = roiSubsets
    }
    
    init(count: Int, gridCount: Int){
        roiSubsets = [GeneralMatrix<SubPixel>](repeating: .init(rows: gridCount,
                                                                columns: gridCount,
                                                                elements: .init(repeating: .init(), count: gridCount*gridCount)), count: count)
    }
    
    public func setValueByIndex(index: Int, value: GeneralMatrix<SubPixel>){
        roiSubsets[index] = value
    }
    
    public func toArray()  -> [GeneralMatrix<SubPixel>] {
        roiSubsets
    }
}

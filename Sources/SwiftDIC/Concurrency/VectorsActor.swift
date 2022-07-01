//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/30.
//

import Foundation

@available(macOS 10.15.0, *)
@available(iOS 13.0.0, *)
actor VectorsActor{
    private var vectors : [[Double]]
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

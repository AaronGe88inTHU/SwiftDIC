//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/29.
//

import Foundation
struct DICConfigure{
    let subSize: Int
    let step: Int
    let top: Int
    let left: Int 
    let bottom: Int
    let right: Int
    
    init(subSize: Int, step: Int, top: Int = 20, left: Int = 20, bottom: Int, right: Int)
    {
        self.subSize = subSize
        self.step = step
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }
    
}

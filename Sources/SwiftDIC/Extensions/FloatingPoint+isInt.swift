//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/9.
//

import Foundation


extension Float {
    
    /// A Boolean value indicating whether the instance is an int.
    var isInt: Bool {
        truncatingRemainder(dividingBy: 1.0) == 0.0
    }
}

extension Double{
    /// A Boolean value indicating whether the instance is an int.
    var isInt: Bool {
        truncatingRemainder(dividingBy: 1.0) == 0.0
    }
}

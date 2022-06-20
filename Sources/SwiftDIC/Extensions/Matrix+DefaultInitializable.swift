//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/13.
//

import Surge
import Algorithms

extension Matrix : DefaultInitializable where Scalar == Double  {
    public init()
    {
        
        self.init(arrayLiteral: [Scalar(0.0)])
        
    }
}
//
//extension Matrix: DefaultInitializable{
//    public init()
//    {
//
//        self.init(arrayLiteral: [Scalar(0.0)])
//
//    }
//}
//
//extension Matrix: DefaultInitializable where Scalar == Double {
//    public init()
//    {
//        self.init(arrayLiteral: [0.0])
//
//    }
//}
//

//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/16.
//

import Surge
@available(iOS 13.0, *)
@available(macOS 10.15, *)
extension Matrix where Scalar == Float{
    
    public func variant()->Scalar
    {
        let mean = mean(self)
        let subed = self - mean
        let subedSqrt = pow(subed, 2)
//
        let varience = sum(subedSqrt)
        assert(varience > 1e-8)
        return varience
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
extension Matrix where Scalar == Double{
    
    public func variant()->Scalar
    {
        let mean = mean(self)
        let subed = self - mean
        let subedSqrt = pow(subed, 2)
//
        let varience = sum(subedSqrt)
        assert(varience > 1e-8)
        return varience
    }
}






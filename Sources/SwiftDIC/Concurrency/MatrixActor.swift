//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/30.
//

import Surge

@available(macOS 10.15.0, *)
@available(iOS 13.0.0, *)
actor MatrixActor{
   private var matrixs : [Matrix<Double>]
   init(count: Int)
   {
       self.matrixs = .init(repeating: Matrix<Double>(rows: 6, columns: 6, repeatedValue: 0), count: count)
   }

   init(_ matrixs: [Matrix<Double>])
   {
       self.matrixs = matrixs
   }


   func setIndividualValue(_ index: Int, _ value: Matrix<Double>)
   {
      matrixs[index] = value
   }

   func toArray () -> [Matrix<Double>]{
       return matrixs
   }


}

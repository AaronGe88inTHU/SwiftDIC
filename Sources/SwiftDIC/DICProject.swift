//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/9.
//

import Surge
import Algorithms
import Foundation
import Accelerate


@available(macOS 12.0, *)
class DICProject{
    
    var configure: DICConfigure
    
    
    var centerAvailableRows : ClosedRange<Int>? = nil
    var centerAvailableColumns: ClosedRange<Int>? = nil
    
    
    var reference: Matrix<Float>? = nil
    var currents: [Matrix<Float>]? = nil
    
    var referenceMap: GeneralMatrix<Matrix<Float>>? = nil
    var currentMap : GeneralMatrix<Matrix<Float>>? = nil
    
    var referenceInSubPixels: GeneralMatrix<SubPixel>? = nil
    var currentInSubPixels: GeneralMatrix<SubPixel>? = nil
    
    var dfdxRef: Matrix<Float>? = nil
    var dfdyRef: Matrix<Float>? = nil
    
  
    
  
    
    
    var roiPoints: [(y:Int, x:Int)]?=nil
    var roiSubsets: [GeneralMatrix<SubPixel>]?=nil
    var hessanRoi: [Matrix<Float>]?=nil
    var dfdpRoi: [Matrix<Float>]?=nil
    
    
    public init(reference: Matrix<Float>?=nil,
                currents: [Matrix<Float>]? = nil,
                configure: DICConfigure = DICConfigure(subSize: 41, step: 7)) {
        self.reference = reference
        self.currents = currents
        self.configure = configure
        if currents != nil{
            precondition(Set(currents!.map {$0.rows}).count == 1 &&
                         Set(currents!.map{$0.columns}).count == 1)
            
            
            if reference != nil{
                precondition(reference!.rows == currents!.first!.rows)
                precondition(reference!.columns == currents!.first!.columns)
                
            }
        }
    }
    
    public func config(configure: DICConfigure) throws{
        self.configure = configure
        centerAvailableRows = (configure.subSize / 2+1 ... reference!.rows - configure.subSize/2-1)
        centerAvailableColumns = (configure.subSize / 2+1 ... reference!.columns - configure.subSize/2-1)
        
        try paddingToFftable()
        
        try subset_generate(bottom: reference!.rows-3, right: reference!.columns-3)
        
//        try preComputerRef()
        
        
    }
    
    private func paddingToFftable() throws
    {
        guard reference != nil
        else {
            throw fatalError("No reference founded")
        }
        guard currents != nil,
              currents!.count > 0
        else{
            throw fatalError("No current images founded")
        }
        
        if reference!.isFftable(){
            referenceMap = InterpolatedMap(gs: reference!).qkCqkt()
        }
        else{
            referenceMap = InterpolatedMap(gs: reference!.paddingToFttable()).qkCqkt()[0...reference!.rows-1, 0...reference!.columns-1]
        }
        
    }
    
    
    private func subset_generate(top: Int=2, left: Int=2, bottom: Int, right: Int) throws{
        precondition(bottom < reference!.rows && right < reference!.columns)
        let height = bottom - top
        let width = right - left
        let halfSize: Int = configure.subSize/2
        var seeds = [(y: Int, x: Int)](repeating: (-1, -1), count: (height+1) * (width+1) / (4*halfSize * halfSize))
        guard seeds.count > 0
        else{
            throw fatalError("Roi is too small")
        }
        
        let ys =  (0 ... height / configure.subSize).map {
            top + halfSize + $0*(configure.subSize+configure.step)
        }
        
        let xs = (0 ... width / configure.subSize).map {
            left + halfSize + $0*(configure.subSize+configure.step)
        }
        
        var seedCount = 0
        for (y, x) in product(ys, xs){
            if y <= bottom-halfSize && x <= right-halfSize{
                seeds[seedCount] = (y, x)
                seedCount += 1
            }
        }
        
        seeds = seeds.dropLast(seeds.count - seedCount)
        roiPoints = seeds
        
        //TODO: structure concurrency
        roiSubsets = roiPoints!.map{
            var subPixels = [SubPixel](repeating: SubPixel(), count: configure.subSize*configure.subSize)
            for ((iy, y), (ix, x)) in product(($0.0-halfSize...$0.0+halfSize).map{v in v}.indexed(),
                                              ($0.1-halfSize...$0.1+halfSize).map{v in v}.indexed()){
                
                subPixels[iy*configure.subSize+ix] = SubPixel(Float(y), Float(x), qkCqktMap: referenceMap!)
            }
            return GeneralMatrix<SubPixel>(rows: configure.subSize, columns: configure.subSize, elements:subPixels)
        }
    }
    
    func preComputerRef() throws{
        
        let rows = reference!.rows
        let columns = reference!.columns
        
        dfdxRef = Matrix<Float>(rows: rows, columns: columns, repeatedValue: 0)
        dfdyRef = Matrix<Float>(rows: rows, columns: columns, repeatedValue: 0)
    
        let nd = Matrix<Float>(row: [1, 0, 0 ,0 ,0 ,0])
        let dd = Matrix<Float>(column: [0, 1, 0, 0 ,0 ,0])
        
        //TODO: structure concurrency
        for (row, column) in product( 2 ..< rows-3, 2 ..< columns-3){
            let localCoef = referenceMap![row, column]
            dfdyRef![row, column] = (transpose(dd) * localCoef * transpose(nd))[0,0]
            dfdxRef![row, column] = (nd * localCoef * dd)[0,0]
        }
        
        
        ///parameters [u, v, du/dx, du/dy, dv/dx, dv/dy]
        ///
        var refRoi = [Matrix<Float>](repeating: .init(rows: configure.subSize, columns: configure.subSize, repeatedValue: 0.0), count: roiPoints!.count)
        var dfdyRoi = [Matrix<Float>](repeating: .init(rows: configure.subSize, columns: configure.subSize, repeatedValue: 0.0), count: roiPoints!.count)
        var dfdxRoi = [Matrix<Float>](repeating: .init(rows: configure.subSize, columns: configure.subSize, repeatedValue: 0.0), count: roiPoints!.count)
        var dfdudxRoi = [Matrix<Float>](repeating: .init(rows: configure.subSize, columns: configure.subSize, repeatedValue: 0.0), count: roiPoints!.count)
        var dfdudyRoi = [Matrix<Float>](repeating: .init(rows: configure.subSize, columns: configure.subSize, repeatedValue: 0.0), count: roiPoints!.count)
        var dfdvdxRoi = [Matrix<Float>](repeating: .init(rows: configure.subSize, columns: configure.subSize, repeatedValue: 0.0), count: roiPoints!.count)
        var dfdvdyRoi = [Matrix<Float>](repeating: .init(rows: configure.subSize, columns: configure.subSize, repeatedValue: 0.0), count: roiPoints!.count)
        hessanRoi = [Matrix<Float>](repeating: .init(rows: configure.subSize, columns: configure.subSize, repeatedValue: 0.0), count: roiPoints!.count)
        
        dfdpRoi = [Matrix<Float>](repeating: .init(rows: 1, columns: 6, repeatedValue: 0.0), count: roiPoints!.count)
        
        
        for ii in 0 ..< roiPoints!.count{
            let center = roiPoints![ii]
            let subset = roiSubsets![ii]
            guard subset.isIntSubset
            else{
                throw fatalError("reference is not a Int subset")
            }
            let halfSize = configure.subSize / 2
            refRoi[ii] = reference![Int(center.y)-halfSize ... Int(center.y)+halfSize, Int(center.x)-halfSize ... Int(center.x)+halfSize]
            
            let ys = subset.ys
            let xs = subset.xs
            let dy = ys - Float(center.y)
            let dx = xs - Float(center.x)
            
            
            let dfdyArray = subset.elements.map {dfdyRef![Int($0.y), Int($0.x)]}
            let dfdy =  Matrix<Float>(rows: configure.subSize, columns: configure.subSize, grid: dfdyArray )
            dfdyRoi[ii] = dfdy
            
            let dfdxArray = subset.elements.map {dfdxRef![Int($0.y), Int($0.x)]}
            let dfdx = Matrix<Float>(rows: configure.subSize, columns: configure.subSize, grid: dfdxArray )
            dfdxRoi[ii] = dfdx
      
            dfdudyRoi[ii] = dfdx * dy
            dfdudxRoi[ii] = dfdx * dx
            
            dfdvdyRoi[ii] = dfdy * dy
            dfdvdxRoi[ii] = dfdy * dx
            
            
            
        }
        
        for ii in 0 ..< hessanRoi!.count{
            
            var hessianValue : Matrix<Float> = .init(rows: 6, columns: 6, repeatedValue: 0.0)
            for (row, column) in product(0..<configure.subSize, 0..<configure.subSize){
                let p  =  Matrix<Float>(row: [dfdxRoi[ii][row, column],
                                              dfdyRoi[ii][row, column],
                                              dfdudxRoi[ii][row, column],
                                              dfdudyRoi[ii][row, column],
                                              dfdvdxRoi[ii][row, column],
                                              dfdvdyRoi[ii][row, column]])
                dfdpRoi![ii] = p
                
                hessianValue += transpose(p) * p
            }
            
            assert(hessianValue.isPositiveDefined())
            hessanRoi![ii] = hessianValue * 2 / refRoi[ii].variant()
        }
    }
    
    
    public func compute(index: Int) throws{
        precondition(hessanRoi != nil)
        if reference!.isFftable(){
            currentMap = InterpolatedMap(gs: currents![index]).qkCqkt()
            //            currentMaps = currents!.map{InterpolatedMap(gs:$0).bSplineCoefMap}
        }
        else{
            currentMap = InterpolatedMap(gs: currents![index].paddingToFttable()).qkCqkt()[0...reference!.rows-1, 0...reference!.columns-1]
        }
        
    }
    
    
    
    public func iterativeSearch(initialGuess:[Float]) throws{
        //MARK: intialGuess = [u, v, du/dx, du/dy, dv/dx, dv/dy]
        precondition(initialGuess.count == 6)
        
        for ii in 0 ..< roiPoints!.count{
            let center = roiPoints![ii]
            let subset = roiSubsets![ii]
            guard subset.isIntSubset
            else{
                throw fatalError("reference is not a Int subset")
            }
//            let halfSize = configure.subSize / 2
            
            
            
            let ys = subset.ys
            let xs = subset.xs
            let dy = ys - Float(center.y)
            let dx = xs - Float(center.x)
            
            var normal:Float = 1.0
            var loop = 0
            
            
            var guess = initialGuess
            while normal > 1e-5 && loop < 500 {
                let newXs = (xs + guess[0] + guess[2] * dx + guess[3] * dy).reduce([]) { partialResult, row in
                    partialResult + row.map{$0}
                }
   
                let newYs = (ys + guess[1] + guess[4] * dy + guess[5] * dy).reduce([]) { partialResult, row in
                    partialResult + row.map{ $0}
                }
                
                let deformList = zip(newYs, newXs).map {SubPixel($0.0, $0.1, qkCqktMap: currentMap!)}
                
                let deformSubset = GeneralMatrix<SubPixel>(rows: configure.subSize, columns: configure.subSize, elements: deformList)
                
                let normalizedDiff = normalize(roiSubsets![ii].values()) - normalize(deformSubset.values())

                
                let gradientList = normalizedDiff.reduce([]) { partialResult, row in
                    partialResult + row.map{$0 * dfdpRoi![ii]}
                }
                

                let zero6x1 = Matrix<Float>(row:[0,0,0,0,0,0])
                
                var gradientMatrix = gradientList.reduce(zero6x1) { partialResult, buffer in
                   partialResult + buffer
                }
                
                gradientMatrix = gradientMatrix * (-2) / sqrtf( roiSubsets![ii].values().variant())
                let detlaP = solveAxb(hessanRoi![ii], gradientMatrix[row: 0])
                
                guess = zip(guess, detlaP).map{$0.0 + $0.1}
                
                normal = sqrtf(detlaP.reduce(0.0, {$0 + powf($1, 2)}))
                loop += 1
            }
            
        }
    }
    
}


struct DICConfigure{
    let subSize: Int
    let step: Int
    
}

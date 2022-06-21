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



@available(iOS 15.0, *)
@available(macOS 12.0, *)
class DICProject{
    
    var configure: DICConfigure
    
    
    var centerAvailableRows : ClosedRange<Int>? = nil
    var centerAvailableColumns: ClosedRange<Int>? = nil
    
    
    var reference: Matrix<Double>? = nil
    var currents: [Matrix<Double>]? = nil
    
    var referenceMap: GeneralMatrix<Matrix<Double>>? = nil
    var currentMap : GeneralMatrix<Matrix<Double>>? = nil
    
    var referenceInSubPixels: GeneralMatrix<SubPixel>? = nil
    var currentInSubPixels: GeneralMatrix<SubPixel>? = nil
    
    var dfdxRef: Matrix<Double>? = nil
    var dfdyRef: Matrix<Double>? = nil
    
    var roiPoints: [(y:Int, x:Int)]?=nil
    var roiSubsets: [GeneralMatrix<SubPixel>]?=nil
    var hessanRoi: [Matrix<Double>]?=nil
    var dfdpRoi: [GeneralMatrix<Matrix<Double>>]?=nil
    
    var deformVectorRoi :[[[Double]]]?=nil
    
    
    public init(reference: Matrix<Double>?=nil,
                currents: [Matrix<Double>]? = nil,
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
        
        
        
        try subset_generate(bottom: reference!.rows-20, right: reference!.columns-20)
        
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
    
    
    private func subset_generate(top: Int=20, left: Int=20, bottom: Int, right: Int) throws{
        precondition(bottom < reference!.rows && right < reference!.columns)
        let height = bottom - top
        let width = right - left
        let halfSize: Int = configure.subSize/2
//        var seeds = [(y: Int, x: Int)](repeating: (-1, -1), count: (height+1) * (width+1) / (4*halfSize * halfSize))
        var seeds = [(y: Int, x: Int)](repeating: (-1, -1), count: (height+1) * (width+1))
        guard seeds.count > 0
        else{
            throw fatalError("Roi is too large")
        }
        
        let ys : [Int] =  (0 ... height).compactMap {
//            top + halfSize + $0*(configure.subSize+configure.step)
            let y = top + halfSize + $0 * configure.step
            return y < bottom ? y : nil
        }
        
        let xs :[Int] = (0 ... width).compactMap {
//            left + halfSize + $0*(configure.subSize+configure.step)
            let x = left + halfSize + $0 * configure.step
            return x < right ? x : nil
            
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
                
                subPixels[iy*configure.subSize+ix] = SubPixel(Double(y), Double(x), qkCqktMap: referenceMap!)
            }
            return GeneralMatrix<SubPixel>(rows: configure.subSize, columns: configure.subSize, elements:subPixels)
        }
    }
    
    func preComputerRef() throws{
        
        let rows = reference!.rows
        let columns = reference!.columns
        
        dfdxRef = Matrix<Double>(rows: rows, columns: columns, repeatedValue: 0)
        dfdyRef = Matrix<Double>(rows: rows, columns: columns, repeatedValue: 0)
    
        let nd = Matrix<Double>(row: [1, 0, 0 ,0 ,0 ,0])
        let dd = Matrix<Double>(column: [0, 1, 0, 0 ,0 ,0])
        
        //TODO: structure concurrency
        for (row, column) in product( 2 ..< rows-3, 2 ..< columns-3){
            let localCoef = referenceMap![row, column]
            dfdyRef![row, column] = (transpose(dd) * localCoef * transpose(nd))[0,0]
            dfdxRef![row, column] = (nd * localCoef * dd)[0,0]
        }
        
        
        ///parameters [u, v, du/dx, du/dy, dv/dx, dv/dy]
        ///
        var refRoi = [Matrix<Double>](repeating: .init(rows: configure.subSize, columns: configure.subSize, repeatedValue: 0.0), count: roiPoints!.count)
        var dfdyRoi = [Matrix<Double>](repeating: .init(rows: configure.subSize, columns: configure.subSize, repeatedValue: 0.0), count: roiPoints!.count)
        var dfdxRoi = [Matrix<Double>](repeating: .init(rows: configure.subSize, columns: configure.subSize, repeatedValue: 0.0), count: roiPoints!.count)
        var dfdudxRoi = [Matrix<Double>](repeating: .init(rows: configure.subSize, columns: configure.subSize, repeatedValue: 0.0), count: roiPoints!.count)
        var dfdudyRoi = [Matrix<Double>](repeating: .init(rows: configure.subSize, columns: configure.subSize, repeatedValue: 0.0), count: roiPoints!.count)
        var dfdvdxRoi = [Matrix<Double>](repeating: .init(rows: configure.subSize, columns: configure.subSize, repeatedValue: 0.0), count: roiPoints!.count)
        var dfdvdyRoi = [Matrix<Double>](repeating: .init(rows: configure.subSize, columns: configure.subSize, repeatedValue: 0.0), count: roiPoints!.count)
        hessanRoi = [Matrix<Double>](repeating: .init(rows: configure.subSize, columns: configure.subSize, repeatedValue: 0.0), count: roiPoints!.count)
        
        dfdpRoi = [GeneralMatrix<Matrix<Double>>] (repeating: GeneralMatrix<Matrix<Double>>(rows: configure.subSize, columns: configure.subSize, elements: [Matrix<Double>](repeating: Matrix<Double>(arrayLiteral: [0, 0, 0, 0, 0, 0]), count: configure.subSize*configure.subSize)), count: roiPoints!.count)
        
        
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
            let dy = ys - Double(center.y)
            let dx = xs - Double(center.x)
            
            
            let dfdyArray = subset.elements.map {dfdyRef![Int($0.y), Int($0.x)]}
            let dfdy =  Matrix<Double>(rows: configure.subSize, columns: configure.subSize, grid: dfdyArray )
            dfdyRoi[ii] = dfdy
            
            let dfdxArray = subset.elements.map {dfdxRef![Int($0.y), Int($0.x)]}
            let dfdx = Matrix<Double>(rows: configure.subSize, columns: configure.subSize, grid: dfdxArray )
            dfdxRoi[ii] = dfdx
      
            dfdudyRoi[ii] = dfdx * dy
            dfdudxRoi[ii] = dfdx * dx
            
            dfdvdyRoi[ii] = dfdy * dy
            dfdvdxRoi[ii] = dfdy * dx
            
            
            
        }
        
        for ii in 0 ..< hessanRoi!.count{
            
            var hessianValue : Matrix<Double> = .init(rows: 6, columns: 6, repeatedValue: 0.0)
            for (row, column) in product(0..<configure.subSize, 0..<configure.subSize){
                let p  =  Matrix<Double>(row: [dfdxRoi[ii][row, column],
                                              dfdyRoi[ii][row, column],
                                              dfdudxRoi[ii][row, column],
                                              dfdudyRoi[ii][row, column],
                                              dfdvdxRoi[ii][row, column],
                                              dfdvdyRoi[ii][row, column]])
                dfdpRoi![ii][row, column] = p
                
                hessianValue += transpose(p) * p
            }
            
            assert(hessianValue.isPositiveDefined())
            hessanRoi![ii] = hessianValue * 2 / refRoi[ii].variant()
        }
    }
    
    
    public func preComputeCur(index: Int) throws{
        precondition(hessanRoi != nil)
        if reference!.isFftable(){
            currentMap = InterpolatedMap(gs: currents![index]).qkCqkt()
            //            currentMaps = currents!.map{InterpolatedMap(gs:$0).bSplineCoefMap}
        }
        else{
            currentMap = InterpolatedMap(gs: currents![index].paddingToFttable()).qkCqkt()[0...reference!.rows-1, 0...reference!.columns-1]
        }
        
    }
    
    
    
    public func iterativeSearch(initialGuess:[Double]) throws{
        //MARK: intialGuess = [u, v, du/dx, du/dy, dv/dx, dv/dy]
        precondition(initialGuess.count == 6)
        if deformVectorRoi == nil{
            deformVectorRoi = [[[Double]]]()
        }
        
        var guess = initialGuess
        var deformVector = [[Double]](repeating:[Double](repeating: 0.0, count: 6), count: roiPoints!.count)
        
        let halfsize = configure.subSize/2
        let y0 = roiPoints![0].y
        let x0 = roiPoints![0].x
        
        let templ = reference![y0-halfsize...y0+halfsize, x0-halfsize...x0+halfsize]
        let (initial_y, initial_x) = templateMatch(templ: templ, image: currents![0])
        guess[0] = Double(initial_x-x0)
        guess[1] = Double(initial_y-y0)
        
        for ii in 0 ..< roiPoints!.count{
            let center = roiPoints![ii]
            let subset = roiSubsets![ii]
            
            
            guard subset.isIntSubset
            else{
                throw fatalError("reference is not a Int subset")
            }

            let ys = subset.ys
            let xs = subset.xs
            let dy = ys - Double(center.y)
            let dx = xs - Double(center.x)
            
            var normal:Double = 1.0
            var coef:Double = 1000.0
        
            var loops = 0
            while normal > 3e-4 && coef > 1e-2 && loops <= 500{
                let newXs = (xs + guess[0] + guess[2] * dx + guess[3] * dy).reduce([]) { partialResult, row in
                    partialResult + row.map{$0}
                }
   
                let newYs = (ys + guess[1] + guess[4] * dx + guess[5] * dy).reduce([]) { partialResult, row in
                    partialResult + row.map{ $0}
                }
                
                let deformList = zip(newYs, newXs).map {SubPixel($0.0, $0.1, qkCqktMap: currentMap!)}
                
                let deformSubset = GeneralMatrix<SubPixel>(rows: configure.subSize, columns: configure.subSize, elements: deformList)
                
                let normalizedDiff = normalize(roiSubsets![ii].values()) - normalize(deformSubset.values())
                
                coef = sum(pow(normalizedDiff, 2))
                
                var gradient = Matrix<Double>(arrayLiteral: [0,0,0,0,0,0])
                for (row, column) in product(0..<gradient.rows, 0..<gradient.columns){
                    gradient +=  normalizedDiff[row, column] * dfdpRoi![ii][row, column]
                }
                

                let diff = roiSubsets![ii].values() - mean(roiSubsets![ii].values())
                let value: Double = sum(pow(diff, 2))
                gradient = gradient * (-2) / sqrt(value)
                
                let detlaP = solveAxb(hessanRoi![ii], gradient[row: 0])
                
                let wOld = Matrix<Double>(rows: 3, columns: 3, grid: [1 + guess[2], guess[3], guess[0],
                                                        guess[4], 1+guess[5], guess[1],
                                                        0,0,1])
                
                let w = Matrix<Double>(rows: 3, columns: 3, grid: [1 + detlaP[2], detlaP[3], detlaP[0],
                                                     detlaP[4], 1+detlaP[5], detlaP[1],
                                                     0,0,1])
                let wNew = wOld * inv(w)
                
                guess = [wNew[0,2], wNew[1,2], wNew[0,0]-1, wNew[0,1], wNew[1,0], wNew[1,1]-1]
                normal = sqrt(detlaP.reduce(0.0, {$0 + pow($1, 2)}))
                loops += 1
//                print(coef)
                
            }
            if loops >= 500{
                deformVector[ii] = [0, 0 ,0, 0 ,0, 0]
            }
            else{
                deformVector[ii] = guess
            }
        }
        deformVectorRoi!.append(deformVector)
        
        print(deformVectorRoi!)
      
    }
    
}


struct DICConfigure{
    let subSize: Int
    let step: Int
    
}

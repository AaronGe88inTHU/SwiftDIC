//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/9.
//

import Surge
import Algorithms

@available(macOS 12.0, *)
class DICProject{
    var reference: Matrix<Float>? = nil
    var currents: [Matrix<Float>]? = nil
    
    var referenceMap: GeneralMatrix<Matrix<Float>>? = nil
    var currentMap : GeneralMatrix<Matrix<Float>>? = nil
    
    var referenceInSubPixels: GeneralMatrix<SubPixel>? = nil
    var currentInSubPixels: GeneralMatrix<SubPixel>? = nil
    
    var dfdxRef: Matrix<Float>? = nil
    var dfdyRef: Matrix<Float>? = nil
    
    var configure: DICConfigure
    
    
    var centerAvailableRows : ClosedRange<Int>? = nil
    var centerAvailableColumns: ClosedRange<Int>? = nil
    
    

    var roiPoints: [(y:Int, x:Int)]?=nil
    var roiSubsets: [GeneralMatrix<SubPixel>]?=nil
    
    
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
        
        try preComputerRef()


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
            referenceMap = InterpolatedMap(gs: reference!.paddingToFttable()).qkCqkt()
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
            for ((iy, y), (ix, x)) in product(($0.0-20...$0.0+20).map{v in v}.indexed(),
                                              ($0.1-20...$0.1+20).map{v in v}.indexed()){
                //TODO: error
                subPixels[iy*configure.subSize+ix] = SubPixel(Float(y), Float(x), qkCqktMap: referenceMap!)
            }
            return GeneralMatrix<SubPixel>(rows: configure.subSize, columns: configure.subSize, elements:subPixels)
        }
    }
    
    private func preComputerRef() throws{
       
        let rows = reference!.rows
        let columns = reference!.columns
        
        dfdxRef = Matrix<Float>(rows: rows, columns: columns, repeatedValue: 0)
        dfdyRef = Matrix<Float>(rows: rows, columns: columns, repeatedValue: 0)

//        let qk: Matrix<Float> = Matrix.qk
//        let qkt = transpose(qk)

        let nd = Matrix<Float>(row: [1, 0, 0 ,0 ,0 ,0])
        let dd = Matrix<Float>(column: [0, 1, 0, 0 ,0 ,0])
        
        //
//        let localCoefs =
        //TODO: structure concurrency
        for (row, column) in product( 2 ..< rows-3, 2 ..< columns-3){
            let localCoef = referenceMap![row, column]
            dfdyRef![row, column] = (transpose(dd) * localCoef * transpose(nd))[0,0]
            dfdxRef![row, column] = (nd * localCoef * dd)[0,0]
        }
    }
    
    public func compute(index: Int){
        if reference!.isFftable(){
            currentMap = InterpolatedMap(gs: currents![index]).qkCqkt()
//            currentMaps = currents!.map{InterpolatedMap(gs:$0).bSplineCoefMap}
        }
        else{
            currentMap = InterpolatedMap(gs: currents![index].paddingToFttable()).qkCqkt()
        }
    }
    
}


struct DICConfigure{
    let subSize: Int
    let step: Int
    
}

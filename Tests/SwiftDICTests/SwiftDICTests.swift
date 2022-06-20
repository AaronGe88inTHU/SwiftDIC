import XCTest
import Surge
import Algorithms
import Accelerate
@testable import SwiftDIC

@available(macOS 12.0, *)
@available(iOS 15.0, *)
final class SwiftDICTests: XCTestCase {
    
//    let reference = Matrix<Double>(rows: 1040, columns: 400, repeatedValue: 0)
//    let currents = (0 ... 20).map {Matrix(rows: 1040, columns: 400, repeatedValue: Double($0))}
//    let project = DICProject(reference: Matrix<Double>.random(rows: 256, columns: 128, in: 0...1) ,
//                                 currents: (0 ... 20).map { _ in Matrix<Double>.random(rows: 256, columns: 128, in: 0...1)})

    
    func test_fftable() throws{
        
        let matrix1 = Matrix<Double>(rows: 8, columns: 8, repeatedValue: 0)
        let matrix2 = Matrix<Double>(rows: 1024, columns: 1024, repeatedValue: 0)
        let matrix3 = Matrix<Double>(rows: 512, columns: 1024, repeatedValue: 0)
        let matrix4 = Matrix<Double>(rows: 16, columns: 8, repeatedValue: 0)
        
        
        
        XCTAssertTrue(matrix1.isFftable())
        XCTAssertTrue(matrix2.isFftable())
        XCTAssertTrue(matrix3.isFftable())
        XCTAssertTrue(matrix4.isFftable())
        
      
    }
    
    func test_interpolate() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        
        var matrix = Matrix<Double>(rows: 8, columns: 8, repeatedValue: 1.0)
        matrix[row: 2] = [1,1,0.95,0.35,0.02,0.24,0.85,0.85]
        matrix[row: 3] = [1,1,0.49,0,0,0,0.26,0.26]
        matrix[row: 4] = [1,1,0.41,0,0,0,0.18,0.18]
        matrix[row: 5] = [1,1,0.84,0.06, 0,0.01,0.64,0.64]
        matrix[row: 6] = [1,1,1, 0.92,0.71,0.87,1,1]
        matrix[row: 7] = [1,1,1, 0.92,0.71,0.87,1,1]
        //        print(matrix)
        
        let interpolatedMatrix = InterpolatedMap(gs: matrix)
        
        let expected:[Double] = [0.9693,    0.9817,    1.0727 ,   1.0245 ,   0.9992 ,   0.9975  ,  1.0726 ,   1.0907,
                             0.9130,    1.2010,    0.5577,    1.4429,    1.8579,    1.6642,    0.5676,    1.0536,
                             1.2122,    0.5178,    2.0574,   -0.0504 ,  -1.1518,   -0.5893,    2.0308,    0.8631,
                             1.8510,    0.9013,    0.5554,   -1.0207  ,  1.0912,   -0.7930 ,   0.6180 ,  -1.0298,
                             1.4412,    1.5040,   -0.6609,    0.9708  , -0.3925,    0.7216 ,  -0.0235 ,  -0.5207,
                             1.9377,   -0.0621,    2.9583,   -2.7504  ,  0.9394,   -2.6559  ,  2.3987 ,  -0.4473,
                             0.5555,    1.4899,    0.1035 ,   2.8358  ,  0.3457,    2.6469  ,  0.4168  ,  1.6953,
                             1.1740,    0.8451,   1.2515,    0.4647   , 0.2520,    0.3399 ,   1.2308 ,   0.6947]
        
        let expectedMatrix = Matrix(rows: 8, columns: 8, grid: expected)
//        expected = Matrix.qk * expectedMatrix * transpose(Matrix.qk)
        
        var expectedQkcqkT = GeneralMatrix<Matrix<Double>>(rows: expectedMatrix.rows,
                                                 columns: expectedMatrix.columns,
                                                 elements: .init(repeating: .init(rows: 6, columns: 6, repeatedValue: 0.0), count: expectedMatrix.rows*expectedMatrix.columns))
        
        let rows = (2 ..< expectedQkcqkT.rows-3).map {$0}
        let columns = (2 ..< expectedQkcqkT.columns-3).map{$0}
        let qk = Matrix<Double>.qk
        let qkt = transpose(qk)
        for (y, x) in product(rows, columns){
            expectedQkcqkT[y, x] = (qk * expectedMatrix[(y-2 ... y+3), (x-2 ... x+3)] * qkt)
        }
        
        
        let qkCqkt = interpolatedMatrix.qkCqkt()
        
        
        var subPixs = Matrix<Double>(rows: 3, columns: 3, repeatedValue: 0)
        
        for (rowInGlobal, columnInGlobal) in product((2 ... 4), (2 ... 4)){
            let row = rowInGlobal - 2
            let column = columnInGlobal - 2
            subPixs[row, column] = SubPixel(Double(rowInGlobal), Double(columnInGlobal), qkCqktMap: qkCqkt).value
        }
        
        
        let subPix22 = SubPixel(2.001,2.001, qkCqktMap: qkCqkt)
        let subPix55 = SubPixel(4.999, 4.999, qkCqktMap: qkCqkt)
        
        for (y, x) in product(0..<expectedMatrix.rows, 0..<expectedMatrix.columns){
            XCTAssertEqual2D(expectedQkcqkT[y, x], qkCqkt[y, x], accuracy: 1e-3)
            
        }
        
        
        XCTAssertEqual2D(matrix[(2 ... 4), (2...4)], subPixs, accuracy: 1e-5)
        XCTAssertEqual(subPix22.value, matrix[2,2], accuracy: 1e-3)
        XCTAssertEqual(subPix55.value, matrix[5,5], accuracy: 1e-3)
    }
    
    func test_subset()throws{
        var matrix = Matrix<Double>(rows: 8, columns: 8, repeatedValue: 1.0)
        matrix[row: 2] = [1,1,0.95,0.35,0.02,0.24,0.85,0.85]
        matrix[row: 3] = [1,1,0.49,0,0,0,0.26,0.26]
        matrix[row: 4] = [1,1,0.41,0,0,0,0.18,0.18]
        matrix[row: 5] = [1,1,0.84,0.06, 0,0.01,0.64,0.64]
        matrix[row: 6] = [1,1,1, 0.92,0.71,0.87,1,1]
        matrix[row: 7] = [1,1,1, 0.92,0.71,0.87,1,1]
        
        let interpolatedMatrix = InterpolatedMap(gs: matrix)
        let qkCqkt = interpolatedMatrix.qkCqkt()
        
        var subset = GeneralMatrix<SubPixel>(rows: 3, columns: 3, elements: .init(repeating: SubPixel(), count: 3*3))

        for (rowInGlobal, columnInGlobal) in product((2 ... 4).map{Double($0)}.indexed(),
                                                     (2 ... 4).map{Double($0)}.indexed()){
            subset[rowInGlobal.index, columnInGlobal.index] = SubPixel(rowInGlobal.element,
                                                                       columnInGlobal.element,
                                                                       qkCqktMap: qkCqkt)
        }
//
        let dvdx: Matrix<Double>? = subset.dvdx
        let dvdy: Matrix<Double>? = subset.dvdx
//
        XCTAssertNotNil(dvdx)
        XCTAssertNotNil(dvdy)
//
        XCTAssertEqual2D(matrix[(2 ... 4), (2...4)], subset.values(), accuracy: 1e-5)

        subset[1, 1] = SubPixel(2.1, 2.1, qkCqktMap: qkCqkt)

        let dvdxnil: Matrix<Double>? = subset.dvdx
        let dvdynil: Matrix<Double>? = subset.dvdx


        XCTAssertNil(dvdxnil)
        XCTAssertNil(dvdynil)
        
        
        
    }
    
    func test_padding() throws{
        
        let matrix = Matrix<Double>(rows: 400, columns: 1040, repeatedValue: 0)
        
        let paddedMatrix = matrix.paddingToFttable()
        XCTAssertTrue(paddedMatrix.isFftable())
        XCTAssertEqual2D(matrix, paddedMatrix[(0 ... 399), (0 ... 1039)])
    }


    
    func test_configProject() throws{
        let project = DICProject(reference: Matrix<Double>.random(rows: 256, columns: 128, in: 0...1) ,
                                     currents: (0 ... 20).map { _ in Matrix<Double>.random(rows: 256, columns: 128, in: 0...1)})
        
        XCTAssertNoThrow(try project.config(configure: .init(subSize: 21, step: 3)))
        
    }
    
    func test_projectPrecompute() throws{
        let project = DICProject(reference: Matrix<Double>.random(rows: 256, columns: 128, in: 0...1) ,
                                     currents: (0 ... 20).map { _ in Matrix<Double>.random(rows: 256, columns: 128, in: 0...1)})
        try project.config(configure: .init(subSize: 21, step: 3))
        XCTAssertNoThrow(try project.preComputerRef())
        
    }
    
    func test_createImage() throws{
        guard let refImage = CPImage(contentsOfFile: "/Users/aaronge/Documents/GitHub/SwiftDIC/ohtcfrp_01.tif"),
              let curImage = CPImage(contentsOfFile: "/Users/aaronge/Documents/GitHub/SwiftDIC/ohtcfrp_02.tif"),
              let ref = refImage.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let cur = curImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else{
           throw fatalError("Bad file")
        }
        
        guard let refGs = try? convertColorImage2GrayScaleMatrix(cgImage: ref),
              let curGs = try? convertColorImage2GrayScaleMatrix(cgImage: cur)
        else{
            throw fatalError()
        }
       
    }
    
    func test_templateMatching() throws{
        guard let refImage = CPImage(contentsOfFile: "/Users/aaronge/Documents/GitHub/SwiftDIC/ohtcfrp_01.tif"),
              let curImage = CPImage(contentsOfFile: "/Users/aaronge/Documents/GitHub/SwiftDIC/ohtcfrp_01.tif"),
              let ref = refImage.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let cur = curImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else{
            throw fatalError("Bad file")
        }

        guard let refGs = try? convertColorImage2GrayScaleMatrix(cgImage: ref),
              let curGs = try? convertColorImage2GrayScaleMatrix(cgImage: ref)
               else{
                   throw fatalError()
        }


        let (row, column) = templateMatch(templ: refGs[200-20...200+20, 60-20...60+20], image: curGs)
       
    }
    
    func test_iterativeCompute() throws{
        
//        guard let refImage = CPImage(contentsOfFile: "/Users/aaronge/Documents/GitHub/SwiftDIC/ohtcfrp_01.tif"),
//              let curImage = CPImage(contentsOfFile: "/Users/aaronge/Documents/GitHub/SwiftDIC/ohtcfrp_02.tif"),
//              let ref = refImage.cgImage(forProposedRect: nil, context: nil, hints: nil),
//              let cur = curImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
//        else{
//           throw fatalError("Bad file")
//        }
//
//        guard let refGs = try? convertColorImage2GrayScaleMatrix(cgImage: ref),
//              let curGs = try? convertColorImage2GrayScaleMatrix(cgImage: cur)
//        else{
//            throw fatalError()
//        }
        
        let reference = Matrix<Double>.random(rows: 128, columns: 128, in: 0...1)
        var current = Matrix<Double>(rows: 128, columns: 128,repeatedValue: 0.0)

        for  ii in  0 ..< current.rows-5{
            current[row: ii+5] = reference[row: ii]
        }
       
        let project = DICProject(reference: reference,
                                     currents:[current])
        try project.config(configure: .init(subSize: 41, step: 3))
        try project.preComputerRef()
        try project.compute(index: 0)
        XCTAssertNoThrow(try project.iterativeSearch(initialGuess: [0.0, 5.4, 0.0, 0.0, 0.0, 0.0]))
    }
    

    
}

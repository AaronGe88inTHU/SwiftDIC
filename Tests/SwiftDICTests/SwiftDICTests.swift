import XCTest
import Surge
import Algorithms
@testable import SwiftDIC

@available(macOS 12.0, *)
@available(iOS 15.0, *)
final class SwiftDICTests: XCTestCase {
    func test_fftable() throws{
        let matrix1 = Matrix<Float>(rows: 8, columns: 8, repeatedValue: 0)
        let matrix2 = Matrix<Float>(rows: 40, columns: 3*1024, repeatedValue: 0)
        let matrix3 = Matrix<Float>(rows: 5*1024, columns: 5*8, repeatedValue: 0)
        let matrix4 = Matrix<Float>(rows: 15*16, columns: 15*8, repeatedValue: 0)
        XCTAssertTrue(matrix1.isFftable())
        XCTAssertTrue(matrix2.isFftable())
        XCTAssertTrue(matrix3.isFftable())
        XCTAssertTrue(matrix4.isFftable())
        
      
        //        let matrix =
    }
    
    func test_interpolate() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        
        var matrix = Matrix<Float>(rows: 8, columns: 8, repeatedValue: 1.0)
        matrix[row: 2] = [1,1,0.95,0.35,0.02,0.24,0.85,0.85]
        matrix[row: 3] = [1,1,0.49,0,0,0,0.26,0.26]
        matrix[row: 4] = [1,1,0.41,0,0,0,0.18,0.18]
        matrix[row: 5] = [1,1,0.84,0.06, 0,0.01,0.64,0.64]
        matrix[row: 6] = [1,1,1, 0.92,0.71,0.87,1,1]
        matrix[row: 7] = [1,1,1, 0.92,0.71,0.87,1,1]
        //        print(matrix)
        
        let interpolatedMatrix = InterpolatedMap(gs: matrix)
        
        let expected:[Float] = [0.9693,    0.9817,    1.0727 ,   1.0245 ,   0.9992 ,   0.9975  ,  1.0726 ,   1.0907,
                             0.9130,    1.2010,    0.5577,    1.4429,    1.8579,    1.6642,    0.5676,    1.0536,
                             1.2122,    0.5178,    2.0574,   -0.0504 ,  -1.1518,   -0.5893,    2.0308,    0.8631,
                             1.8510,    0.9013,    0.5554,   -1.0207  ,  1.0912,   -0.7930 ,   0.6180 ,  -1.0298,
                             1.4412,    1.5040,   -0.6609,    0.9708  , -0.3925,    0.7216 ,  -0.0235 ,  -0.5207,
                             1.9377,   -0.0621,    2.9583,   -2.7504  ,  0.9394,   -2.6559  ,  2.3987 ,  -0.4473,
                             0.5555,    1.4899,    0.1035 ,   2.8358  ,  0.3457,    2.6469  ,  0.4168  ,  1.6953,
                             1.1740,    0.8451,   1.2515,    0.4647   , 0.2520,    0.3399 ,   1.2308 ,   0.6947]
        let expectedMatrix = Matrix(rows: 8, columns: 8, grid: expected)
        let bCoefMap = interpolatedMatrix.bSplineCoefMap
        
        
        var subPixs = Matrix<Float>(rows: 3, columns: 3, repeatedValue: 0)
        
        for (rowInGlobal, columnInGlobal) in product((2 ... 4), (2 ... 4)){
            let row = rowInGlobal - 2
            let column = columnInGlobal - 2
            subPixs[row, column] = SubPixel(Float(rowInGlobal), Float(columnInGlobal), bCoefMap: bCoefMap).value
        }
        
        
        let subPix22 = SubPixel(2.001,2.001, bCoefMap: bCoefMap)
        let subPix55 = SubPixel(4.999, 4.999, bCoefMap: bCoefMap)
        
        XCTAssertEqual2D(expectedMatrix, bCoefMap, accuracy: 1e-3)
        XCTAssertEqual2D(matrix[(2 ... 4), (2...4)], subPixs, accuracy: 1e-5)
        XCTAssertEqual(subPix22.value, matrix[2,2], accuracy: 1e-3)
        XCTAssertEqual(subPix55.value, matrix[5,5], accuracy: 1e-3)
    }
    
    func test_subset()throws{
        var matrix = Matrix<Float>(rows: 8, columns: 8, repeatedValue: 1.0)
        matrix[row: 2] = [1,1,0.95,0.35,0.02,0.24,0.85,0.85]
        matrix[row: 3] = [1,1,0.49,0,0,0,0.26,0.26]
        matrix[row: 4] = [1,1,0.41,0,0,0,0.18,0.18]
        matrix[row: 5] = [1,1,0.84,0.06, 0,0.01,0.64,0.64]
        matrix[row: 6] = [1,1,1, 0.92,0.71,0.87,1,1]
        matrix[row: 7] = [1,1,1, 0.92,0.71,0.87,1,1]
        
        let interpolatedMatrix = InterpolatedMap(gs: matrix)
        let bCoefMap = interpolatedMatrix.bSplineCoefMap
        
        var subset = ElementMatrix(rows: 3, columns: 3, subPixs: .init(repeating: SubPixel(), count: 3*3))
        
        for (rowInGlobal, columnInGlobal) in product((2 ... 4).map{Float($0)}.indexed(),
                                                     (2 ... 4).map{Float($0)}.indexed()){
            subset[rowInGlobal.index, columnInGlobal.index] = SubPixel(rowInGlobal.element,
                                                                       columnInGlobal.element,
                                                                       bCoefMap: bCoefMap)
        }
        
        let dvdx: Matrix<Float>? = subset.dvdx
        let dvdy: Matrix<Float>? = subset.dvdx
        
        XCTAssertNotNil(dvdx)
        XCTAssertNotNil(dvdy)
        
        XCTAssertEqual2D(matrix[(2 ... 4), (2...4)], subset.values, accuracy: 1e-5)
        
        subset[1, 1] = SubPixel(2.1, 2.1, bCoefMap: bCoefMap)
        
        let dvdxnil: Matrix<Float>? = subset.dvdx
        let dvdynil: Matrix<Float>? = subset.dvdx
        
      
        XCTAssertNil(dvdxnil)
        XCTAssertNil(dvdynil)
        
        
        
    }
    
    func test_padding() throws{
        
        let matrix = Matrix<Float>(rows: 720, columns: 1080, repeatedValue: 0)
        
        let paddedMatrix = matrix.paddingToFttable()
        XCTAssertTrue(paddedMatrix.isFftable())
        XCTAssertEqual2D(matrix, paddedMatrix[(0 ... 719), (0 ... 1079)])
    }
    

    
    func test_configProject() throws{
        let reference = Matrix<Float>(rows: 720, columns: 1080, repeatedValue: 0)
        let currents = (0 ... 20).map {Matrix(rows: 720, columns: 1080, repeatedValue: Float($0))}
        let project = DICProject(reference: reference, currents: currents)
        
        
        XCTAssertNoThrow(try project.config(configure: .init(subSize: 41, step: 7)))
        
    }
    
}

//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/9.
//

import Foundation
import Surge

public protocol DefaultInitializable {
    init()
}

struct GeneralMatrix<Element> where Element: DefaultInitializable{
 
    public let rows: Int
    public let columns: Int
    var elements: [Element]
    
//    init(rows: Int, columns: Int){
//        self.rows = rows
//        self.columns = columns
//        self.subPixs = .init(repeating: SubPixel(), count: rows*columns)
//    }
    
    init(rows: Int, columns: Int, elements: [Element]){
        precondition(elements.count == rows*columns)
        self.rows = rows
        self.columns = columns
        self.elements = elements
    }
    

}

extension GeneralMatrix {
    // MARK: - Subscript

    public subscript(_ row: Int, _ column: Int) -> Element {
        get {
            assert(indexIsValidForRow(row, column: column))
            return elements[(row * columns) + column]
        }

        set {
            assert(indexIsValidForRow(row, column: column))
            elements[(row * columns) + column] = newValue
        }
    }

    public subscript(row row: Int) -> [Element] {
        get {
            assert(row < rows)
            let startIndex = row * columns
            let endIndex = row * columns + columns
            return Array(elements[startIndex..<endIndex])
        }

        set {
            assert(row < rows)
            assert(newValue.count == columns)
            let startIndex = row * columns
            let endIndex = row * columns + columns
            elements.replaceSubrange(startIndex..<endIndex, with: newValue)
        }
    }

    public subscript(column column: Int) -> [Element] {
        get {
            var result = [Element](repeating: .init(), count: rows)
            for i in 0..<rows {
                let index = i * columns + column
                result[i] = self.elements[index]
            }
            return result
        }

        set {
            assert(column < columns)
            assert(newValue.count == rows)
            for i in 0..<rows {
                let index = i * columns + column
                elements[index] = newValue[i]
            }
        }
    }
    
    public subscript(row: ClosedRange<Int>, column: ClosedRange<Int>) -> GeneralMatrix {
        get {
            assert(row.map{$0 < rows && $0 >= 0}.allSatisfy{$0 == true})
            assert(column.map{$0 < columns && $0 >= 0}.allSatisfy{$0 == true})
//            var matrix = Matrix<Scalar>(rows: row.count, columns: column.count, repeatedValue: 0)
            let subRows = row.count
            let subColumns = column.count
            var result = [Element](repeating: .init(), count: subRows*subColumns)
            let r0 = row.first!
            let c0 = column.first!
            for rr in (row){
//                for co in (column){
                result[(rr-r0)*subColumns ..< (rr-r0)*subColumns+subColumns] = elements[rr*columns+c0 ..< rr*columns+c0+subColumns]
//                }
            }
            return GeneralMatrix(rows: subRows, columns: subColumns, elements: result)
        }

        set {
            assert(row.map{$0 < rows && $0 >= 0}.allSatisfy{$0 == true})
            assert(column.map{$0 < columns && $0 >= 0}.allSatisfy{$0 == true})
            assert(newValue.rows == row.count)
            assert(newValue.columns == column.count)
//            var matrix = Matrix<Scalar>(rows: row.count, columns: column.count, repeatedValue: 0)
//            let subRows = row.count
            let subColumns = column.count
//            let result = [Float](repeating: 0.0, count: subRows*subColumns)
            let r0 = row.first!
            let c0 = column.first!
            for rr in (row){
                elements[rr*columns ..< rr*columns+c0 + subColumns] = newValue.elements[(rr-r0)*subColumns ..< (rr-r0)*subColumns+subColumns]
            }

        }
    }

    private func indexIsValidForRow(_ row: Int, column: Int) -> Bool {
        return row >= 0 && row < rows && column >= 0 && column < columns
    }
}

//
//  File.swift
//  
//
//  Created by Aaron Ge on 2022/6/24.
//

import Foundation

@available(iOS 13.0, *)
@available(macOS 10.15, *)
extension AsyncSequence {
    func collect() async rethrows -> [Element] {
        try await reduce(into: [Element]()) { $0.append($1) }
    }
}

//
//  CustomFunction.swift
//  GeneticAlgorithm
//
//  Created by João Victor Ipirajá de Alencar on 07/05/23.
//

import Foundation



public func weightedRandomChoice<T, W: Numeric & Comparable >(sequence: [T], weights: [W], k: Int) -> [T] {
    var results = [T]()
    let totalWeight = weights.reduce(0.0) {$0 + Double($1 as! NSNumber)}
    for _ in 0...k {
        let randomValue = Double(arc4random_uniform(UInt32.max)) / Double(UInt32.max)
        var cumulativeWeight: Double = 0.0
        for (index, element) in sequence.enumerated() {
            cumulativeWeight += Double(weights[index] as! NSNumber) / totalWeight
            if randomValue <= cumulativeWeight {
                results.append(element)
                break
            }
        }
    }
    return results
}




public func sorted<T, V: Comparable>(_ iterable: [T], key: @escaping (T) -> V?, reverse: Bool = false) -> [T] {
    let sortedIterable = iterable.sorted {
        if let lhs = key($0), let rhs = key($1){
            if reverse {
                return lhs > rhs
            } else {
                return lhs < rhs
            }
        }else{
            return true
        }
        
       
    }
    return sortedIterable
}



extension Array{
    
//    func generateInterval<T>(ofSize size: Int, content: () -> T) -> Array<T> {
//        return (0...size).map { _ in
//            return content()
//        }
//    }
    
    func arrayChunks(of chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map { startIndex in
            let endIndex = Swift.min(startIndex + chunkSize, self.count)
            return Array(self[startIndex..<endIndex])
        }
    }
}


extension Data {

    init(copying dd: DispatchData) {
        var result = Data(count: dd.count)
        result.withUnsafeMutableBytes { buf in
            _ = dd.copyBytes(to: buf)
        }
        self = result
    }
}




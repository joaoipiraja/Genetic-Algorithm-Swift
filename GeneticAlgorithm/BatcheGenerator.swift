//
//  BatcheGenerator.swift
//  GeneticAlgorithm
//
//  Created by João Victor Ipirajá de Alencar on 19/05/23.
//

import Foundation


func bigToBatches<INPUT>(size: Int, content: @escaping () -> INPUT, completion: @escaping (Array<INPUT>, ResponsePopulation) -> ()) async{
    let batchSize = 10000
    let numBatches = Int(ceil(Double(size) / Double(batchSize)))
    
    for batchIndex in 0..<numBatches {
        let batchStartIndex = batchIndex * batchSize
        let batchEndIndex = min((batchIndex + 1) * batchSize, size)
        let batchCount = batchEndIndex - batchStartIndex
        
        

        await withTaskGroup(of: INPUT.self) { group -> () in
            for _ in 0..<batchCount {
                group.addTask { await content()}
            
            }
            
            var results: Array<INPUT> = []
            for await genome in group {
                results.append(genome)
            }
            
            completion(results, .init(current: batchIndex + 1, total: numBatches*batchSize))
            
        }
    }
    
}

//
//  GeneticAlgorithm.swift
//  GeneticAlgorithm
//
//  Created by João Victor Ipirajá de Alencar on 07/05/23.
//

import Foundation
import Combine
import SwiftUI



typealias Cromossome = Int8
typealias Genome = Array<Cromossome>
typealias Population = Array<Genome>


class Response: ObservableObject{
    
    @Published var generation: Int
    @Published var population: Population
    @Published var isRunning: Bool
    
    init(generation: Int, population: Population, isRunning: Bool = false) {
        
        self.generation = generation
        self.population = population
        self.isRunning = isRunning
    }
    
}

class ResponsePopulation: ObservableObject{
    
    @Published var currrent: Int
    @Published var total: Int
    
    init(current: Int, total: Int) {
        
        self.currrent = current
        self.total = total
    }
    
}


class Configuration: ObservableObject{
    
}

class GeneticAlgorithm<V: Numeric & Comparable,T>{
    
    private var cancellables = Set<AnyCancellable>()
    
    var subject: PassthroughSubject<Response,Never> = .init()
    var subjectPop: PassthroughSubject<ResponsePopulation,Never> = .init()

    
    var modelArray: Array<T>
    var populationSize: Int
    var generationLimit: Int
    var fitnessLimit: V
    var evaluationFunction: (Genome) -> (V)
    var genomeInterval: ClosedRange<Cromossome>
    private var stopFlag: Bool = false
    let fileManager = FileManager.default
    private var index = 0
    
    private let io: DispatchIO
    private let tempURL: URL
    
    
    public init(modelArray: Array<T>, populationSize: Int, generationLimit: Int, genomeInterval: ClosedRange<Cromossome>, fitnessLimit: V, evaluationFunction: @escaping (Genome) ->  (V)) {
        self.modelArray = modelArray
        self.populationSize = populationSize
        self.generationLimit = generationLimit
        self.fitnessLimit = fitnessLimit
        self.evaluationFunction = evaluationFunction
        self.genomeInterval = genomeInterval
        
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let tempFileName = "populations.json"
        self.tempURL =  tempDir.appendingPathComponent(tempFileName)
        
        
        self.io = .init(type: .random, path: tempURL.path , oflag: O_RDWR | O_CREAT, mode: 0o755, queue: .global(qos: .userInteractive), cleanupHandler: { _ in })!
       
    
    }
    
    
    
    
    /// Gerar genomas aleatórios de acordo com um intervalo de cromossomos
    /// - Parameter lenght: tamanho
    /// - Returns: array de inteiros randômicos num intervalo de cromossomos
    private func generateGenomes(lenght: Int) -> Genome{
        return (0..<lenght).map({ _ in
            return Cromossome.random(in: genomeInterval)
        })
    }
    
    
//    private func generatePopulation(size: Int, genomeLength: Int) async -> [URL] {
//        let batchSize = 100
//        let numBatches = Int(ceil(Double(size) / Double(batchSize)))
//        let fileManager = FileManager.default
//        let tempDir = fileManager.temporaryDirectory
//        let tempFilePrefix = "batch_"
//        var batchFiles: [URL] = []
//
//        for batchIndex in 0..<numBatches {
//            let batchStartIndex = batchIndex * batchSize
//            let batchEndIndex = min((batchIndex + 1) * batchSize, size)
//            let batchCount = batchEndIndex - batchStartIndex
//            let batch = await withTaskGroup(of: Genome.self) { group -> Population in
//                for _ in 0..<batchCount {
//                    group.addTask { [self] in await generateGenomes(lenght: genomeLength) }
//                }
//                var results: Population = []
//                for await genome in group {
//                    results.append(genome)
//                }
//                return results
//            }
//
//            //batch_
//            let batchFileName = "\(tempFilePrefix)\(batchIndex)"
//            let batchFileURL = tempDir.appendingPathComponent(batchFileName)
//            try! JSONEncoder().encode(batch).write(to: batchFileURL)
//            batchFiles.append(batchFileURL)
//
//            if self.stopFlag {
//
//                for url in batchFiles{
//                    try! fileManager.removeItem(at: url)
//                }
//
//                self.subject.send(completion: .finished)
//                break
//            }
//
//            subjectPop.send(.init(current: batchIndex + 1, total: numBatches))
//        }
//
//        subjectPop.send(completion: .finished)
//        self.subject.send(.init(generation: 0, population: []))
//        return batchFiles
//    }
    
    
    private func generatePopulation(size: Int, genomeLength: Int) async -> [(Int64, Int)] {
        
        var arrayOffSets = Array<(Int64, Int)>()
        
        let batchSize = 100
        let numBatches = Int(ceil(Double(size) / Double(batchSize)))

      
        
        var currentOffset: Int64 = 0
        
        for batchIndex in 0..<numBatches {
            let batchStartIndex = batchIndex * batchSize
            let batchEndIndex = min((batchIndex + 1) * batchSize, size)
            let batchCount = batchEndIndex - batchStartIndex
            let batch = await withTaskGroup(of: Genome.self) { group -> Population in
                for _ in 0..<batchCount {
                    group.addTask { [self] in await generateGenomes(lenght: genomeLength) }
                    
                    if stopFlag{
                        group.cancelAll()
                    }
                }
                var results: Population = []
                for await genome in group {
                    results.append(genome)
                }
                
                return results
            }
            
            let encoder = JSONEncoder()
            let data = try! encoder.encode(batch)
            let dispatchData = data.withUnsafeBytes({
                DispatchData(bytes: UnsafeRawBufferPointer(start: $0, count: data.count))
            })
            
            io.write(offset: currentOffset, data: dispatchData, queue: .global(qos: .userInteractive)) { done, _, _ in
                if done {
                    let batchSize = data.count
                    arrayOffSets.append((currentOffset, batchSize))
                    currentOffset += Int64(batchSize)
                    self.subjectPop.send(.init(current: batchIndex + 1, total: numBatches))
                }
            }
            
            if stopFlag {
                io.close()
                self.subject.send(completion: .finished)
                return []
            }
        }
        print(tempURL.absoluteString)
        
        subjectPop.send(completion: .finished)
        self.subject.send(.init(generation: 0, population: []))
        return arrayOffSets
    }

    
  
    
    
    
    private func fitness(genome: Genome) -> V {
        
        //        if genome.count != modelArray.count{
        //            throw GeneticAlgorithError.differentLenghts
        //        }
        
        return evaluationFunction(genome)
    }
    
    /// <#Description#>
    /// - Parameter population: <#population description#>
    /// - Returns: <#description#>
    private func selectionPair(population: Population)  -> Population{
        
        let weights: Array<V> = population.map({ gene in
            return fitness(genome: gene)
        })
        
        return weightedRandomChoice(
            sequence: population,
            weights: weights,
            k: 2
        )
        
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - a: <#a description#>
    ///   - b: <#b description#>
    /// - Returns: <#description#>
    func selectionPointCrossOver(a: Genome, b: Genome) -> (Genome,Genome){
        
        let lengh = a.count
        
        if lengh < 2{
            return (a,b)
        }
        
        let p = Int.random(in: 1..<lengh-1)
        
        return (Array(a[0..<p] + b[p...]), Array(b[0..<p] + a[p...]))
    }
    
    func mutation(genome:Genome) -> Genome{
        
        let num: Int = 1
        let probability: Float = 0.2
        var genomeVar = genome
        
        for _ in 0..<num{
            let index = Int.random(in: 0..<genomeVar.count)
            if Float.random(in: 0...1) > probability{
                genomeVar[index] = abs(genomeVar[index] - 1)
            }
        }
        
        
        return genomeVar
    }
    
    
    public func stopEvolution() {
        self.stopFlag = true
    }
    
    private func loadPopulationBatch(offSet: Int64, size: Int) -> Population {
        
       
        print(offSet, size)
        var population: Population = []
        
            
            
        io.read(offset: offSet, length: size, queue: .global(qos: .userInteractive)) { done, data, error in
                       
                    if let data = data{
                        
                        print(data)
                        if let genomes = try? JSONDecoder().decode(Population.self, from: Data(copying: data)){
                            population = genomes
                            print(genomes)
                        }

                    } else {
                        print("data nil")
                    }
                    
                     if done {
                         //io.close()
                     }
                 }
            
        

        
        return population
    }

    
   
    private func saveBatch(offSet: Int64, batch: Population) -> Int {
            
        let data = try! JSONEncoder().encode(batch)
        
        
        let dispatchData = data.withUnsafeBytes {
            DispatchData(bytes: UnsafeRawBufferPointer(start: $0, count: data.count))
        }
        

        io.write(offset: offSet, data: dispatchData, queue: .global(qos: .userInteractive)) { done, data, error in
            if  error != 0 {
                print("Error writing batch to disk:")
                //io.close()
            }
        }
        
        return dispatchData.count
        
    }

    public func runEvolution() async {
        self.stopFlag = false

        
        
        var populationOffsets = await self.generatePopulation(size: populationSize, genomeLength: modelArray.count)
        
        
        if !populationOffsets.isEmpty{

            for i in 1...generationLimit {


                if self.stopFlag {

//                    for url in populationOffsets{
//                        try? fileManager.removeItem(at: tempURL)
//                    }

                    self.subject.send(completion: .finished)
                    break
                }

                index = i

                var population: Population = .init()



                await withTaskGroup(of: Population.self, body: { taskGroupOne in


                    for (i,url) in populationOffsets.enumerated(){

                        taskGroupOne.addTask{ [self] in

                            var nextGeneration: Population = .init()

                            nextGeneration = loadPopulationBatch(offSet: url.0, size: url.1)

                            print(nextGeneration)

                            nextGeneration = sorted(nextGeneration, key: { genome in
                                return self.fitness(genome: genome)
                            }, reverse: true)


                            await withTaskGroup(of: (Genome, Genome).self) { taskGroup in
                                for parents in nextGeneration.arrayChunks(of: 2) {
                                    taskGroup.addTask {

                                        if  parents.count > 1 {
                                            let offSpring = self.selectionPointCrossOver(a: parents[0], b: parents[1])
                                            let offSpringAMutated = self.mutation(genome: offSpring.0)
                                            let offSpringBMutated = self.mutation(genome: offSpring.1)
                                            return (offSpringAMutated, offSpringBMutated)
                                        }else{

                                            let offSpring = self.selectionPointCrossOver(a: parents[0], b: parents[0])
                                            let offSpringAMutated = self.mutation(genome: offSpring.0)
                                            let offSpringBMutated = self.mutation(genome: offSpring.1)
                                            return (offSpringAMutated, offSpringBMutated)

                                        }


                                    }
                                }

                                for await result in taskGroup {
                                    let (offSpringAMutated, offSpringBMutated) = result
                                    //lock.lock()
                                    nextGeneration.append(offSpringAMutated)
                                    nextGeneration.append(offSpringBMutated)
                                    //lock.unlock()

                                }


                            }

                            nextGeneration = sorted(nextGeneration, key: { genome in
                                return self.fitness(genome: genome)
                            }, reverse: true)



                           // saveBatch(offSet: url.0, batch: nextGeneration)


                            nextGeneration.removeAll()

                            return nextGeneration.count > 1 ?    [nextGeneration[0]] : nextGeneration
                        }


                        for await result in taskGroupOne {
                            population += result
                        }



                    }


                    population = sorted(population, key: { genome in
                        return self.fitness(genome: genome)
                    }, reverse: true)

                    self.subject.send(.init(generation: index, population: population))


                })




            }

        }
        io.close()
        
        self.subject.send(completion: .finished)
    }
    
    
    
    
    
}

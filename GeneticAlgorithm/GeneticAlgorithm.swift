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
typealias Population = Set<Genome>


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
    
    
    
    public init(modelArray: Array<T>, populationSize: Int, generationLimit: Int, genomeInterval: ClosedRange<Cromossome>, fitnessLimit: V, evaluationFunction: @escaping (Genome) ->  (V)) {
        self.modelArray = modelArray
        self.populationSize = populationSize
        self.generationLimit = generationLimit
        self.fitnessLimit = fitnessLimit
        self.evaluationFunction = evaluationFunction
        self.genomeInterval = genomeInterval
    }
    
    
    
    
    /// Gerar genomas aleatórios de acordo com um intervalo de cromossomos
    /// - Parameter lenght: tamanho
    /// - Returns: array de inteiros randômicos num intervalo de cromossomos
    private func generateGenomes(lenght: Int) -> Genome{
        return (0..<lenght).map({ _ in
            return Cromossome.random(in: genomeInterval)
        })
    }
    
    
    /// Description
    /// - Parameters:
    ///   - size: <#size description#>
    ///   - genome_lenght: <#genome_lenght description#>
    /// - Returns: <#description#>
    
    
    //    private func generatePopulation(size: Int, genome_length: Int) async -> [[Int8]] {
    //        var population: [[Int8]] = []
    //        let batchSize = 1000 // or another value that works for your use case
    //        var batchIndex = 0
    //
    //        while population.count < size {
    //            // Generate a batch of genomes
    //            let batch = await withTaskGroup(of: [Int8].self) { group -> [[Int8]] in
    //                for _ in 0..<batchSize {
    //                    group.addTask { [self] in await generateGenomes(lenght: genome_length) }
    //                }
    //                var results: [[Int8]] = []
    //                for await genome in group {
    //                    results.append(genome)
    //                }
    //                return results
    //            }
    //
    //            // Add the batch to the population
    //            population.append(contentsOf: batch)
    //            batchIndex += 1
    //
    //            // Print progress
    //            if batchIndex % 10 == 0 {
    //                print("Generated \(population.count) of \(size) genomes...")
    //            }
    //        }
    //
    //        // Trim the population to the desired size if necessary
    //        population = Array(population.prefix(size))
    //
    //        return population
    //    }
    
    
    private func generatePopulation(size: Int, genomeLength: Int) async -> Population {
        
        var response = Population.init()
       
        await withTaskGroup(of: Genome.self) { taskGroup in
            for _ in 0...size {
                    taskGroup.addTask {
                        return self.generateGenomes(lenght: genomeLength)
                    }
                }
            
                for await result in taskGroup {
                    response.insert(result)
                }
            }

           
            
            
        return response
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
    

    
    public func runEvolution() async {
        self.stopFlag = false
        
        var population = await generatePopulation(size: self.populationSize, genomeLength: self.modelArray.count)
        
        
        
//        var index = 0
//
//        for i in 1...generationLimit {
//            index = i
//
//            self.subject.send(.init(generation: index, population: population))
//
//            //Ordena a população do maior para o menor com base nos melhores - Elitismo
//            population = population.sorted(by: { genome1, genome2 in
//                return self.fitness(genome: genome1) > self.fitness(genome: genome2)
//            })
//
//            //Se chegar naquele patamar, não precisa seguir em frente
//            //                if self.fitness(genome: population[0]) >= fitnessLimit {
//            //                    self.subject.send(completion: .finished)
//            //                    return
//            //                }
//
//            var nextGeneration = Set<Array<Int8>>()
//
//            let maxTasks = 100
//            let pairsCount = population.count
//            let batchSize = pairsCount / maxTasks
//            let remainder = pairsCount % maxTasks
//
//            var startIndex = 0
//
//            for taskIndex in 0..<maxTasks {
//
//                let endIndex = startIndex + batchSize + (taskIndex < remainder ? 1 : 0)
//
//                let parentsBatch = population.sorted()[startIndex..<endIndex].map { $0 }
//
//                print("\n")
//                print(startIndex, endIndex)
//
//                await withTaskGroup(of: (Genome, Genome).self) { taskGroup in
//                    for parents in parentsBatch.arrayChunks(of: 2) {
//                        taskGroup.addTask {
//
//                            if parents.count > 1 {
//                                let offSpring = self.selectionPointCrossOver(a: parents[0], b: parents[1])
//                                let offSpringAMutated = self.mutation(genome: offSpring.0)
//                                let offSpringBMutated = self.mutation(genome: offSpring.1)
//                                return (offSpringAMutated, offSpringBMutated)
//                            } else {
//                                let offSpring = self.selectionPointCrossOver(a: parents[0], b: parents[0])
//                                let offSpringAMutated = self.mutation(genome: offSpring.0)
//                                let offSpringBMutated = self.mutation(genome: offSpring.1)
//                                return (offSpringAMutated, offSpringBMutated)
//                            }
//                        }
//                    }
//
//                    for await result in taskGroup {
//                        let (offSpringAMutated, offSpringBMutated) = result
//                        nextGeneration.insert(offSpringAMutated)
//                        nextGeneration.insert(offSpringBMutated)
//                    }
//                }
//
//                startIndex = endIndex
//            }
//
//            population = nextGeneration
//
//            if self.stopFlag {
//                self.subject.send(completion: .finished)
//                return
//            }
//
//            self.subject.send(.init(generation: index, population: population))
//
//            if self.stopFlag {
//                self.subject.send(completion: .finished)
//                return
//            }
//        }
        
        self.subject.send(completion: .finished)
    }


    
    
//    public func runEvolution() async {
//        self.stopFlag = false
//
//        var population = self.generatePopulation(size: populationSize, genomeLength: modelArray.count)
//        population = sorted(population, key: { genome in
//            return self.fitness(genome: genome)
//        }, reverse: true)
//
//        var index = 0
//
//        for i in 1...generationLimit {
//            index = i
//
//
//
//            self.subject.send(.init(generation: index, population: population))
//
//            do {
//                //Ordena a população do maior para o menor com base nos melhores - Elitismo
//                population = sorted(population, key: { genome in
//                    return self.fitness(genome: genome)
//                }, reverse: true)
//
//                //Se chegar naquele patamar, não precisa seguir em frente
//                //                if self.fitness(genome: population[0]) >= fitnessLimit {
//                //                    self.subject.send(completion: .finished)
//                //                    return
//                //                }
//
//                var nextGeneration = Array(population[..<0])
//
//                let maxTasks = 100
//                let pairsCount = population.count
//                let batchSize = pairsCount / maxTasks
//                let remainder = pairsCount % maxTasks
//
//                var startIndex = 0
//
//                for taskIndex in 0..<maxTasks {
//
//                    let endIndex = startIndex + batchSize + (taskIndex < remainder ? 1 : 0)
//
//                    let parentsBatch = Array(population[startIndex..<endIndex])
//
//                    print("\n")
//                    print(startIndex,endIndex )
//
//                    await withTaskGroup(of: (Genome, Genome).self) { taskGroup in
//                        for parents in parentsBatch.arrayChunks(of: 2) {
//                            taskGroup.addTask {
//
//                                if  parents.count > 1 {
//                                    let offSpring = self.selectionPointCrossOver(a: parents[0], b: parents[1])
//                                    let offSpringAMutated = self.mutation(genome: offSpring.0)
//                                    let offSpringBMutated = self.mutation(genome: offSpring.1)
//                                    return (offSpringAMutated, offSpringBMutated)
//                                }else{
//
//                                    let offSpring = self.selectionPointCrossOver(a: parents[0], b: parents[0])
//                                    let offSpringAMutated = self.mutation(genome: offSpring.0)
//                                    let offSpringBMutated = self.mutation(genome: offSpring.1)
//                                    return (offSpringAMutated, offSpringBMutated)
//
//                                }
//
//
//                            }
//                        }
//
//                        for await result in taskGroup {
//                            let (offSpringAMutated, offSpringBMutated) = result
//                            //lock.lock()
//                            nextGeneration.append(offSpringAMutated)
//                            nextGeneration.append(offSpringBMutated)
//                            //lock.unlock()
//
//                        }
//                    }
//
//                    startIndex = endIndex
//                }
//
//                population = nextGeneration
//
//                if self.stopFlag {
//                    self.subject.send(completion: .finished)
//                    return
//                }
//
//            }
//
//            self.subject.send(.init(generation: index, population: population))
//
//            if self.stopFlag {
//                self.subject.send(completion: .finished)
//                return
//            }
//        }
//
//        self.subject.send(completion: .finished)
//    }
    
    
    
}

//
//  GeneticAlgorithm.swift
//  GeneticAlgorithm
//
//  Created by João Victor Ipirajá de Alencar on 07/05/23.
//

import Foundation
import Combine
import SwiftUI





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
    
    var ioOperaation: IOOperation = .init()
    private var stopFlag: Bool = false
<<<<<<< Updated upstream
    let fileManager = FileManager.default
    private var index = 0
    
    
    
=======
  
>>>>>>> Stashed changes
    public init(modelArray: Array<T>, populationSize: Int, generationLimit: Int, genomeInterval: ClosedRange<Cromossome>, fitnessLimit: V, evaluationFunction: @escaping (Genome) ->  (V)) {
        self.modelArray = modelArray
        self.populationSize = populationSize
        self.generationLimit = generationLimit
        self.fitnessLimit = fitnessLimit
        self.evaluationFunction = evaluationFunction
        self.genomeInterval = genomeInterval
<<<<<<< Updated upstream
=======
    
>>>>>>> Stashed changes
    }
    

    private func generateGenomes(lenght: Int) -> Genome{
        return (0..<lenght).map({ _ in
            return Cromossome.random(in: genomeInterval)
        })
    }
<<<<<<< Updated upstream
    
    
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
    
    
    private func generatePopulation(size: Int, genomeLength: Int) async -> [URL] {
        let batchSize = 100
        let numBatches = Int(ceil(Double(size) / Double(batchSize)))
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let tempFilePrefix = "batch_"
        var batchFiles: [URL] = []
        
        for batchIndex in 0..<numBatches {
            let batchStartIndex = batchIndex * batchSize
            let batchEndIndex = min((batchIndex + 1) * batchSize, size)
            let batchCount = batchEndIndex - batchStartIndex
            let batch = await withTaskGroup(of: Genome.self) { group -> Population in
                for _ in 0..<batchCount {
                    group.addTask { [self] in await generateGenomes(lenght: genomeLength) }
                }
                var results: Population = []
                for await genome in group {
                    results.append(genome)
                }
                return results
            }
            
            //batch_
            let batchFileName = "\(tempFilePrefix)\(batchIndex)"
            let batchFileURL = tempDir.appendingPathComponent(batchFileName)
            try! JSONEncoder().encode(batch).write(to: batchFileURL)
            batchFiles.append(batchFileURL)
            
            if self.stopFlag {
                
                for url in batchFiles{
                    try! fileManager.removeItem(at: url)
                }
                
                self.subject.send(completion: .finished)
                break
=======
  
    private func generatePopulation(size: Int, genomeLength: Int) async{
        
        let separator: Character = "\n"
            
        
        await bigToBatches(size: size) {
            return self.generateGenomes(lenght: genomeLength)
        } completion: { [self] (population, info) in
            
            let data = try! JSONEncoder().encode(population) + String(separator).data(using: .utf8)!
              
            self.ioOperaation.save(data: data)
            
            self.subjectPop.send(info)
            
            if self.stopFlag {
                self.ioOperaation.close()
                self.subject.send(completion: .finished)
>>>>>>> Stashed changes
            }
                        
            subjectPop.send(.init(current: batchIndex + 1, total: numBatches))
        }
<<<<<<< Updated upstream
        
        subjectPop.send(completion: .finished)
        
        

        
        return batchFiles
    }
    
    
    
    
    
    
    
=======
        
        
        subjectPop.send(completion: .finished)
        self.subject.send(.init(generation: 0, population: []))

    }

>>>>>>> Stashed changes
    private func fitness(genome: Genome) -> V {
        return evaluationFunction(genome)
    }

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
    
    
    func stopEvolution() {
        self.stopFlag = true
    }
    
    
<<<<<<< Updated upstream
    //    public func runEvolution() {
    //
    //        self.stopFlag = false
    //
    //        var population = self.generatePopulation(size: populationSize, genome_lenght: modelArray.count)
    //        population = sorted(population, key: { genome in
    //            return try? self.fitness(genome: genome)
    //        }, reverse: true)
    //
    //        var index = 0
    //        let queue = DispatchQueue(label: "com.geneticalgorithm.evolution", attributes: .concurrent)
    //        let group = DispatchGroup()
    //        let lock = NSLock()
    //
    //
    //
    //        for i in 1...generationLimit {
    //            index = i
    //
    //            self.subject.send(.init(generation: index, population: population))
    //
    //            do {
    //                //Ordena a população do maior para o menor com base nos melhores - Elitismo
    //                population = sorted(population, key: { genome in
    //                    return try? self.fitness(genome: genome)
    //                }, reverse: true)
    //
    //                //Se chegar naquele patamar, não precisa seguir em frente
    //                if try self.fitness(genome: population[0]) >= fitnessLimit {
    //                    self.subject.send(completion: .finished)
    //                    break
    //                }
    //
    //                var nextGeneration = Array(population[..<2])
    //
    //                for _ in 0..<population.count / 2 {
    //                    group.enter()
    //                    queue.async {
    //                        defer { group.leave() }
    //
    //                        if let parents = try? self.selectionPair(population: population){
    //
    //                            if (!parents.isEmpty) {
    //                                if let offSpring = try? self.selectionPointCrossOver(a: parents[0], b: parents[1]){
    //
    //                                    let offSpringAMutated = self.mutation(genome: offSpring.0)
    //
    //                                    let offSpringBMutated = self.mutation(genome: offSpring.1)
    //
    //                                    DispatchQueue.concurrentPerform(iterations: 2) { idx in
    //                                        lock.lock()
    //
    //                                        if idx == 0 {
    //                                            nextGeneration.append(offSpringAMutated)
    //                                        } else {
    //                                            nextGeneration.append(offSpringBMutated)
    //                                        }
    //                                        lock.unlock()
    //                                    }
    //                                }
    //                            }
    //                        }
    //                    }
    //
    //                    group.wait()
    //                    population = nextGeneration
    //
    //                    if self.stopFlag {
    //                        self.subject.send(completion: .finished)
    //                        return
    //                    }
    //                }
    //
    //            } catch let error {
    //                self.subject.send(completion: .failure(error as! Never))
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
    
    
    private func loadPopulationBatch(url: URL) -> Population{
        
        guard let batchData = try? Data(contentsOf: url) else { return [] }
        let batch = try! JSONDecoder().decode(Population.self, from: batchData)
            
        return batch
    }
    
    
    private func saveBatch(url: URL, batch: Population){
        
        try! JSONEncoder().encode(batch).write(to: url)
        
    }
    
    
=======

>>>>>>> Stashed changes
    public func runEvolution() async {
        
        
        self.stopFlag = false
<<<<<<< Updated upstream
        
        var populationURLS = await self.generatePopulation(size: populationSize, genomeLength: modelArray.count)
=======
        self.ioOperaation.open()
>>>>>>> Stashed changes
        
       await generatePopulation(size: self.populationSize ,genomeLength: self.modelArray.count)
        
<<<<<<< Updated upstream
        
       
        
        for i in 1...generationLimit {
            
            
            if self.stopFlag {
                
                for url in populationURLS{
                    try? fileManager.removeItem(at: url)
                }
                
                self.subject.send(completion: .finished)
                break
=======
        for i in 1...generationLimit {

                var population: Population = .init()


                if self.stopFlag {


                    self.subject.send(completion: .finished)
                    self.ioOperaation.close()
                    population = []
                    break
                }


                await withTaskGroup(of: Population.self, body: { taskGroupOne in
                    

                    for i in 0..<ioOperaation.offsetsSaved.count {


                        taskGroupOne.addTask{ [self] in
                            
                           
                            
                            var nextGeneration =   self.ioOperaation.read(at: i)
                                
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
                                    
                                    nextGeneration.append(offSpringAMutated)
                                    nextGeneration.append(offSpringBMutated)
                                    
                                }
                                
                                
                            }
                            
                            nextGeneration = sorted(nextGeneration, key: { genome in
                                return self.fitness(genome: genome)
                            }, reverse: true)
   

                            return nextGeneration
                        }
                        
                        
                       
                        
                        for await result in taskGroupOne {
                            
                            
                            if(!result.isEmpty){
                                population += [result[0]]

                            }
                            
                            
                        }
                

                    }


                    population = sorted(population, key: { genome in
                        return self.fitness(genome: genome)
                    }, reverse: true)


                    
                    self.subject.send(.init(generation: i, population: population))


                })




>>>>>>> Stashed changes
            }
            
            index = i
            
            var population: Population = .init()
            
            
            self.subject.send(.init(generation: 0, population: [(0...modelArray.count).map({ _ in
                return 0
            }) ]))

<<<<<<< Updated upstream
            
            await withTaskGroup(of: Population.self, body: { taskGroupOne in
                
                
                for url in populationURLS{
                    
                    taskGroupOne.addTask{ [self] in
                        
                        var nextGeneration: Population = .init()
                        
                        nextGeneration = loadPopulationBatch(url: url)
                        
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
                        
                        
                        saveBatch(url: url, batch: nextGeneration)
                        
                        let bestGenome = [nextGeneration[0]]
                        
                        nextGeneration.removeAll()
                        
                        return bestGenome
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
        
=======

        self.ioOperaation.close()
>>>>>>> Stashed changes
        self.subject.send(completion: .finished)
    }
    
    
    
    
    
}

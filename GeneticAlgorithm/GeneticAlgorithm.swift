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
    
    
    var populationSize: Int
    var generationLimit: Int
    var genomeLenght: Int = 0
    
    var fitnessLimit: V
    var evaluationFunction: ((Genome) -> (V))?
    var genomeInterval: ClosedRange<Cromossome>
    
    
    var ioOperation: CitizenViewModel = .init()
    private var stopFlag: Bool = false
    
    
    public init(populationSize: Int, generationLimit: Int, genomeInterval: ClosedRange<Cromossome>, fitnessLimit: V) {
        self.populationSize = populationSize
        self.generationLimit = generationLimit
        self.fitnessLimit = fitnessLimit
        self.genomeInterval = genomeInterval
        
    }
    
    
    private func generateGenomes(lenght: Int) -> Genome{
        
        return (0..<lenght).map({ _ in
            return Cromossome.random(in: genomeInterval)
        })
    }
    
    
    private func generatePopulation(size: Int, genomeLength: Int) async{
                
        
        await bigToBatches(size: size) {
            return self.generateGenomes(lenght: genomeLength)
        } completion: { [self] (population, info) in
            
            await CitizenViewModel(genomes: population).saveCitizen()
            self.subjectPop.send(info)
            
            if self.stopFlag {
                self.subjectPop.send(completion: .finished)
                self.subject.send(completion: .finished)
            }
            
        }
        
        subjectPop.send(completion: .finished)
        subject.send(.init(generation: 0, population: []))
        
    }
    
    
    

    //Seleção Artificial
    private func fitness(genome: Genome) -> V {
        return evaluationFunction!(genome)
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
                    genomeVar[index] = Cromossome.random(in: self.genomeInterval)
                }
            }
       
        return genomeVar
    }
    
    
    func stopEvolution() {
        self.stopFlag = true
    }
    
    
    public func runEvolution() async {
        
        
        self.stopFlag = false
        
        await self.ioOperation.deleteAll()
        
        await generatePopulation(size: self.populationSize ,genomeLength: genomeLenght)
        
            for i in 1...generationLimit {
                
                var population: Population = .init()
                
                
                if self.stopFlag {
                    
                    
                    self.subject.send(completion: .finished)
                    population = []
                    break
                }
                
                await self.ioOperation.getAllCitizens()
                
                await withTaskGroup(of: CitizenViewModel.self, body: { taskGroupOne in
                    
                    
                    for i in 0..<self.ioOperation.citizens.count-1 {
                        
                        
                        taskGroupOne.addTask{ [self] in
                    

                        
                            var nextGeneration =  await self.ioOperation.getCitizen(at: i)
                            
                            nextGeneration = sorted(nextGeneration, key: { genome in
                                return self.fitness(genome: genome)
                            }, reverse: true)
                            
                            
                            await withTaskGroup(of: (Genome, Genome).self) { taskGroup in
                                for parents in nextGeneration.arrayChunks(of: 2){
                                    
                                    // print(parents.count)
                                    taskGroup.addTask {
                                        
                                        if  parents.count > 1 {
                                            let offSpring = self.selectionPointCrossOver(a: parents[0], b: parents[1])
                                            let offSpringAMutated = self.mutation(genome: offSpring.0)
                                            let offSpringBMutated = self.mutation(genome: offSpring.1)
                                            return (offSpringAMutated, offSpringBMutated)
                                        }else{
                                            
                                            //AutoFecundação
                                            
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
                            
                           
                            
                            //elitismo
                            nextGeneration = sorted(nextGeneration, key: { genome in
                                return self.fitness(genome: genome)
                            }, reverse: true)
                            
                            let halfIndex = nextGeneration.count/2
                            nextGeneration = Array(nextGeneration[..<halfIndex])
                            
                            
                            return .init(id: self.ioOperation.citizens[i].id, genomes: nextGeneration)
                        }
                        
                        
                        
                        
                        for await result in taskGroupOne {
                            
                       

                            if(!result.genomes.isEmpty){
                                
                                population += [result.genomes[0]]
                                await result.updateCitizen()
                                
                            }
                        }
                        
                        
                    }
                    
                    
                    population = sorted(population, key: { genome in
                        return self.fitness(genome: genome)
                    }, reverse: true)
                    
                    
                    
                    self.subject.send(.init(generation: i, population: population))
                    
                    
                })
      
                
            }
            
            
            self.subject.send(completion: .finished)
 
    }
    
}


//
//  ViewModel.swift
//  GeneticAlgorithm
//
//  Created by João Victor Ipirajá de Alencar on 19/05/23.
//

import Foundation

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

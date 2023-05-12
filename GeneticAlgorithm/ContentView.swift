//
//  ContentView.swift
//  GeneticAlgorithm
//
//  Created by João Victor Ipirajá de Alencar on 07/05/23.
//

import SwiftUI
import Combine
import Foundation

struct ContentView: View {
    
    
    var things: Array<Thing>
    @State private var cancellables = Set<AnyCancellable>()
    var geneticAlg: GeneticAlgorithm<Float, Thing>? = nil

    @ObservedObject var response: Response = .init(generation: -1, population: [])
    @ObservedObject var responsePop: ResponsePopulation = .init(current: 0, total: 0)

    
    
    
    init(){
        
        self.things = [
            .init(name: "Laptop", value: 250.0, weight: 100.0),
            .init(name: "Headphones", value: 150.0, weight: 160.0),
            .init(name: "Coffe Mug", value: 60.0, weight: 350.0),
            .init(name: "Notepad", value: 40.0, weight: 333.0),
            .init(name: "Ipad", value: 1450.0, weight: 100.0),
            .init(name: "iPhone", value: 3450.0, weight: 70.0),
            .init(name: "Display", value: 22250.0, weight: 300.0),
            .init(name: "Mouse", value: 250.0, weight: 10.0),
            .init(name: "Cable", value: 1.0, weight: 0.5),
            .init(name: "Glass", value: 250.0, weight: 45.0)
        ]
        
        
        self.geneticAlg = .init(modelArray: things, populationSize: 10000000, generationLimit: 1000000000, genomeInterval: 0...10, fitnessLimit: Float(1000000000000), evaluationFunction: { [self] genome in
            
            var weight:Float = 0
            var value:Float = 0
            
            for (i, thing) in things.enumerated(){
                
                    weight += Float(genome[i])*thing.weight
                    value += Float(genome[i])*thing.value
                    
                    if weight > 1000{
                        //atribui peso 0 quando maior que 1000
                        return 0.0
                    }
                
               
                
            }
            
            return value
        })
        
       
        
        
       

        
    }
    

    
    func createOtherSink(){
        
        self.geneticAlg?.subject = .init()
        
        geneticAlg?.subject
            .receive(on: DispatchQueue.main) //
            .sink { [self] completion in
            switch completion{
            case .failure:
                print("Deu problema")
            case .finished:
                print("Finalizou")
                self.response.isRunning = false

            }
                
        } receiveValue: { [self] value in
       
            self.response.generation = value.generation
            self.response.population = value.population
            
        }.store(in: &cancellables)
        
        
        
        self.geneticAlg?.subjectPop = .init()
        
        geneticAlg?.subjectPop
            .receive(on: DispatchQueue.main) //
            .sink { [self] completion in
            switch completion{
            case .failure:
                print("Deu problema")
            case .finished:
                print("Finalizou")

            }
                
        } receiveValue: { [self] value in
       
            self.responsePop.currrent = value.currrent
            self.responsePop.total = value.total
            
        }.store(in: &cancellables)
        
        
    }
    
    
    
    
    
    var body: some View {
        VStack {
            
            VStack{
                List(things, id: \.id){ thing in
                    HStack{
                        
                        HStack{
                         
                           if !self.response.population.isEmpty{
                            Text("\(self.response.population[0] [self.things.firstIndex(where: {return $0.id == thing.id})!])").font(Font.system(.title2, design: .default))
                                   .fontWeight(.bold)
                           }
                            Text(thing.name).font(Font.system(.title2, design: .default))
                                .fontWeight(.regular)
                            Spacer()
                            VStack(alignment: .trailing){
                                Text(String(format: "%.2f g",thing.weight))
                                Text(String(format: "R$ %.2f",thing.value))
                            }
                            
                            
                        }
                        
                        
                    }
                }
                if(self.response.isRunning){
                    if(self.response.generation == -1){
                        ProgressView("Gerando população (\(responsePop.total) indivíduos)", value: Double(responsePop.currrent), total: Double(responsePop.total)).padding()
                    }else{
                        ProgressView("Epoch \(response.generation) / 1000000000", value: Double(response.generation ), total: 1000000000.0).padding()
                    }
                   
                }
                
                HStack{
                    Button("Rodar") {
                        createOtherSink()
                        
                        self.response.isRunning = true
                        self.response.generation = 0
                        self.response.population = []
                        
                        Task {
                           await geneticAlg?.runEvolution()
                        }
                        
                    }.disabled(self.response.isRunning)
                    
                    Button("Parar") {
                        self.response.isRunning = false
                        geneticAlg?.stopEvolution()
                 
                    }.disabled(!self.response.isRunning)
                }
              

            }
                        
            
        }
     
      
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

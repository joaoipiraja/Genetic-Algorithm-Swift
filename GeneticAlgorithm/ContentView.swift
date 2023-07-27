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
    
    @EnvironmentObject var thingsViewModel: ThingViewModel 
    
    @State private var cancellables = Set<AnyCancellable>()
    var geneticAlg: GeneticAlgorithm<Float, ThingViewModel>? = nil

    @ObservedObject var response: Response = .init(generation: -1, population: [])
    @ObservedObject var responsePop: ResponsePopulation = .init(current: 0, total: 0)

    
    func isFirstTimeLaunch() -> Bool {
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "HasLaunchedBefore")
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
            UserDefaults.standard.synchronize()
        }
        return isFirstLaunch
    }
    
    init(){
        
        self.geneticAlg = .init(populationSize: 10000, generationLimit: 200, genomeInterval: 0...10, fitnessLimit: Float(1000000000000))

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
           // print( value.generation)
            self.response.generation = value.generation
            self.response.population = value.population
            
        }.store(in: &cancellables)
        
        
        
        self.geneticAlg?.subjectPop = .init()
        
        geneticAlg?.subjectPop
            .receive(on: DispatchQueue.main) //
            .sink { completion in
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
        
        ZStack{
       
            VStack {
                
                
                
                VStack{
                    
                    if(self.response.population.isEmpty){
                        
                        List( self.thingsViewModel.things , id: \.id){ thing in
                        HStack{
                            
                            HStack{
                                
                              
                                Text("\(thing.name)").font(Font.system(.title2, design: .default))
                                    .fontWeight(.regular)
                                Spacer()
                                VStack(alignment: .trailing){
                                    Text(String(format: "%.2f g",thing.weight))
                                    Text(String(format: "R$ %.2f",thing.value))
                                }
                                
                                
                            }
          
                        }
                    }.background(Color(cgColor: .init(red: 250, green: 246, blue: 246, alpha: 1.0)))
                       
                    }else{
                        List(
                            Array(zip(self.thingsViewModel.things, self.response.population[0] )).sorted { rhs, lhs in
                                return rhs.1 > lhs.1
                            }
                            , id: \.0.id){ (thing,population) in
                        HStack{
                            
                            HStack{
                                
                                Text("\(population)").font(Font.system(.title2, design: .default))
                                        .fontWeight(.bold)
                                
                                Text("\(thing.name)").font(Font.system(.title2, design: .default))
                                    .fontWeight(.regular)
                                Spacer()
                                VStack(alignment: .trailing){
                                    Text(String(format: "%.2f g",thing.weight))
                                    Text(String(format: "R$ %.2f",thing.value))
                                }
                                
                                
                            }
          
                        }
                    }.background(Color(cgColor: .init(red: 250, green: 246, blue: 246, alpha: 1.0)))
                    }
                       
                  
                    if(self.response.isRunning){
                        if(self.response.generation == -1){
                            ProgressView("Gerando população (\(responsePop.total) indivíduos)", value: Double(responsePop.currrent), total: Double(responsePop.total)).padding()
                            
                        }else{
                            ProgressView("Epoch \(response.generation) / \( self.geneticAlg?.generationLimit ?? 0) ", value: Double(response.generation ), total: Double(self.geneticAlg?.generationLimit ?? 0)).padding()
                        }
                        
                    }
                    
                    HStack{
                        Button("Rodar") {
                            
                            self.geneticAlg?.genomeLenght = self.thingsViewModel.things.count
                            self.geneticAlg?.evaluationFunction = { [self] genome in
                                
                                var weight:Float = 0
                                var value:Float = 0
                                
                                for (i, thing) in self.thingsViewModel.things.enumerated(){
                                        
                                        weight += Float(genome[i])*thing.weight
                                        value += Float(genome[i])*thing.value
                                        
                                        if weight > 1000{
                                            return 0.0
                                        }
                             
                                }
                                
                                return value
                            }
                            
                            createOtherSink()
                            
                            self.response.isRunning = true
                            self.response.generation = -1
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
        
        
        .task{
            if isFirstTimeLaunch() {

                    await self.thingsViewModel.saveThing(viewModel: .init(name: "Laptop", value: 250.0, weight: 100.0))
                    await self.thingsViewModel.saveThing(viewModel: .init(name: "Headphones", value: 150.0, weight: 160.0))
                    await self.thingsViewModel.saveThing(viewModel: .init(name: "Coffe Mug", value: 60.0, weight: 350.0))
                    await self.thingsViewModel.saveThing(viewModel: .init(name: "Notepad", value: 40.0, weight: 333.0))
                    await self.thingsViewModel.saveThing(viewModel: .init(name: "Ipad", value: 1450.0, weight: 100.0))
                    await self.thingsViewModel.saveThing(viewModel: .init(name: "iPhone", value: 3450.0, weight: 70.0))
                    await self.thingsViewModel.saveThing(viewModel: .init(name: "Display", value: 22250.0, weight: 300.0))
                    await self.thingsViewModel.saveThing(viewModel: .init(name: "Mouse", value: 250.0, weight: 10.0))
                    await self.thingsViewModel.saveThing(viewModel: .init(name: "Cable", value: 1.0, weight: 0.5))
                    await self.thingsViewModel.saveThing(viewModel: .init(name: "Glass", value: 250.0, weight: 45.0))

            }

            await self.thingsViewModel.getAllThings()
            
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//
//  GeneticAlgorithmApp.swift
//  GeneticAlgorithm
//
//  Created by João Victor Ipirajá de Alencar on 07/05/23.
//

import SwiftUI

@main
struct GeneticAlgorithmApp: App {
    
    @StateObject var thingsViewModel: ThingViewModel = .init()
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(thingsViewModel)
        }
    }
}

//
//  Model.swift
//  GeneticAlgorithm
//
//  Created by João Victor Ipirajá de Alencar on 07/05/23.
//

import Foundation

public struct Thing {
    public var id: UUID
    public var name:String
    public var value: Float
    public var weight: Float

    public init(name: String, value: Float, weight: Float) {
        self.id = UUID.init()
        self.name = name
        self.value = value
        self.weight = weight
    }

}





//
//  CoreDataError.swift
//  GeneticAlgorithm
//
//  Created by João Victor Ipirajá de Alencar on 26/07/23.
//

import Foundation

enum CoreDataError: Error {
    case loadFailed
    case saveFailed
    case fetchFailed
    case fetchObjectIdFailed
    case updateFailed
    case deleteFailed
    case deleteAllFailed

    var localizedDescription: String {
        switch self {
        case .loadFailed:
            return "CoreData failed to load."
        case .saveFailed:
            return "Failed to save data."
        case .fetchFailed:
            return "Failed to fetch objects."
        case .fetchObjectIdFailed:
            return "Failed to fetch object with the given ID."
        case .updateFailed:
            return "Failed to update object."
        case .deleteFailed:
            return "Failed to delete object."
        case .deleteAllFailed:
            return "Failed to delete all objects."
        }
    }
}


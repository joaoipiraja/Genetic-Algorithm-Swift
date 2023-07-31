//
//  CloudKitError.swift
//  GeneticAlgorithm
//
//  Created by João Victor Ipirajá de Alencar on 31/07/23.
//

import Foundation
import CloudKit

extension CKManager{

    enum CloudKitAccountStatusGroup:Error {
        case noAccount
        case restricted
        case couldNotDetermine
        case unknown
        
        init(accountStatus: CKAccountStatus) {
            switch accountStatus {
            case .noAccount:
                self = .noAccount
            case .restricted:
                self = .restricted
            case .couldNotDetermine:
                self = .couldNotDetermine
            default:
                self = .unknown
            }
        }
        
        var description: String {
            switch self {
            case .noAccount:
                return "iCloud account not found."
            case .restricted:
                return "iCloud account access is restricted."
            case .couldNotDetermine:
                return "iCloud account status could not be determined."
            case .unknown:
                return "Unknown iCloud account status."
            }
        }
    }
    
    enum CKCustomError: Error {
        case internalErrors(String)
        case networkErrors(String)
        case accountErrors(String)
        case permissionErrors(String)
        case recordErrors(String)
        case assetErrors(String)
        case databaseErrors(String)
        case partialFailureErrors(String)
        case serviceErrors(String)
        case unknownErrors
        
        init(error: CKError) {
            switch error.code{
            case .internalError, .serverRejectedRequest:
                self = .internalErrors(error.localizedDescription)
            case .networkUnavailable, .networkFailure:
                self = .networkErrors(error.localizedDescription)
            case .badContainer:
                self = .accountErrors(error.localizedDescription)
            case .notAuthenticated, .missingEntitlement:
                self = .permissionErrors(error.localizedDescription)
            case .unknownItem, .invalidArguments, .resultsTruncated, .serverRecordChanged:
                self = .recordErrors(error.localizedDescription)
            case .assetFileNotFound, .assetFileModified, .incompatibleVersion, .constraintViolation,
                    .operationCancelled, .changeTokenExpired, .batchRequestFailed, .zoneBusy, .badDatabase,
                    .quotaExceeded, .zoneNotFound, .limitExceeded, .userDeletedZone, .tooManyParticipants,
                    .alreadyShared, .referenceViolation, .managedAccountRestricted, .participantMayNeedVerification,
                    .assetNotAvailable, .serverResponseLost:
                self = .assetErrors(error.localizedDescription)
            case .partialFailure:
                self = .partialFailureErrors(error.localizedDescription)
            case .serviceUnavailable, .requestRateLimited:
                self = .serviceErrors(error.localizedDescription)
            default:
                self = .unknownErrors
            }
        }
        
        
        var description: String {
            switch self {
            case .internalErrors(let description):
                return "Internal CloudKit error: \(description)"
            case .networkErrors(let description):
                return "Network error: \(description)"
            case .accountErrors(let description):
                return "Account error: \(description)"
            case .permissionErrors(let description):
                return "Permission error: \(description)"
            case .recordErrors(let description):
                return "Record error: \(description)"
            case .assetErrors(let description):
                return "Asset error: \(description)"
            case .databaseErrors(let description):
                return "Database error: \(description)"
            case .partialFailureErrors(let description):
                return "Partial failure error: \(description)"
            case .serviceErrors(let description):
                return "Service error: \(description)"
            case .unknownErrors:
                return "Unknown CloudKit error."
            }
        }
    }
}

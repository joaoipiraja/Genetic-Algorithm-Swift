//
//  CloudKit.swift
//  GeneticAlgorithm
//
//  Created by João Victor Ipirajá de Alencar on 26/07/23.
//

import Foundation
import CloudKit
import CoreData

protocol CKCodable {
    init?(record: CKRecord)
    var record: CKRecord? { get }
}

extension CKManager{
    enum iCloudKitError: LocalizedError {
        case iCloudAccountNotFound
        case iCloudAccountNotDetermined
        case iCloudAccountRestricted
        case iCloudAccountUnknown
        case iCloudAccountNoID
        case iCloudApplicationPermissionNotGranted
        case iCloudDatabaseError
    }
}
class CKManager {
    
    static let shared = CKManager()
    
    
    let defaultContainer = CKContainer.default()
    let container = CKContainer(identifier: "")
    
    var viewContext: CKContainer{
        return CKContainer.default()
    }

    
    func getiCloudStatus(completion: @escaping (Result<Bool, Error>) -> ()) {
        defaultContainer.accountStatus { accountStatus, error in
        switch accountStatus {
          case .available:
            completion(.success(true))
          case .noAccount:
            completion(.failure(iCloudKitError.iCloudAccountNotFound))
          case .couldNotDetermine:
            completion(.failure(iCloudKitError.iCloudAccountNotDetermined))
          case .restricted:
            completion(.failure(iCloudKitError.iCloudAccountRestricted))
          default:
            completion(.failure(iCloudKitError.iCloudAccountUnknown))
         }
       }
     }
    
    func requestPermission(completion: @escaping (Result<Bool, Error>) -> ()) {
  
        container.requestApplicationPermission(.userDiscoverability) { returnedStatus, error in
        if returnedStatus == .granted {
          completion(.success(true))
        } else {
          completion(.failure(iCloudKitError.iCloudApplicationPermissionNotGranted))
        }
      }
    }
    
    func getiCloudUserID(completion: @escaping(Result<CKRecord.ID, Error>) -> ()) {
        
        defaultContainer.fetchUserRecordID { userRecordID, error in
        guard let recordID = userRecordID else {
          completion(.failure(iCloudKitError.iCloudAccountNoID))
          return
        }
        completion(.success(recordID))
      }
    }
    
    func getUserName(forID userID: CKRecord.ID, completion: @escaping(Result<String, Error>) -> ()) {
      
      var givenName: String = ""
      var familyName: String = ""
      defaultContainer.discoverUserIdentity(withUserRecordID: userID) { userIndentity, error in
        if let name = userIndentity?.nameComponents?.givenName {
          givenName = name
        }
        if let surname = userIndentity?.nameComponents?.familyName {
          familyName = surname
        }
        if let error = error {
          completion(.failure(error))
        } else {
            completion(.success(givenName + " " + familyName))
        }
      }
    }
    
    func add<T: CKCodable>(item: T, completion: @escaping (Result<CKRecord?, Error>) -> ()) {
      guard let record = item.record else {
        completion(.failure(iCloudKitError.iCloudDatabaseError))
        return
      }
      save(record: record, completion: completion)
    }
    
    func addWithReference<T: CKCodable, C: CKCodable>(
      fromItem childItem: T,
      toItem parentItem: C,
      withReferenceFieldName referenceFieldName: String,
      withReferenceAction refAction: CKRecord.ReferenceAction,
      completion: @escaping (Result<CKRecord?, Error>) -> ()) {

        guard let childRecord = childItem.record else {
          completion(.failure(iCloudKitError.iCloudDatabaseError))
          return
        }
        guard let parentRecord = parentItem.record else {
          completion(.failure(iCloudKitError.iCloudDatabaseError))
          return
        }
        childRecord[referenceFieldName] = CKRecord.Reference(record: parentRecord, action: refAction)
        save(record: childRecord, completion: completion)
    }
    
    func fetch<T:CKCodable>(
      predicate: NSPredicate,
      recordType: CKRecord.RecordType,
      sortDescriptions: [NSSortDescriptor]? = nil,
      resultsLimit: Int? = nil,
      completion: @escaping(_ items: [T]) -> ()) {

        // Create operation
        let queryOperation = createOperation(
          predicate: predicate,
          recordType: recordType,
          sortDescriptions: sortDescriptions,
          resultsLimit: resultsLimit
        )

        // Get items
        var returnedItems: [T] = []
        addRecordMatchedBlock(operation: queryOperation) { item in
          returnedItems.append(item)
        }

        // Result
        addQuerryResultBlock(operation: queryOperation) { finished in
          if finished {
            completion(returnedItems)
          }
        }
            
        addOperation(operation: queryOperation)
    }
    
    func fetchReferences<T: CKCodable, C: CKCodable>(
      forItem owner: T,
      andField searchField: String,
      recordType: CKRecord.RecordType,
      sortDescriptions: [NSSortDescriptor]? = nil,
      resultsLimit: Int? = nil,
      completion: @escaping(_ items: [C]) -> ()) {

        // Check if owner exist
        guard let ownerRecord = owner.record else {
          completion([])
          return
        }
                
        // Create NSPredicate
        let recordToMatch = CKRecord.Reference(record: ownerRecord, action: .deleteSelf)
        let predicate = NSPredicate(format: "\(searchField) == %@", recordToMatch)
                
        // Create operation
        let queryOperation = createOperation(
          predicate: predicate,
          recordType: recordType,
          sortDescriptions: sortDescriptions,
          resultsLimit: resultsLimit
        )
                
        // Get items
        var returnedItems: [C] = []
        addRecordMatchedBlock(operation: queryOperation) { item in
          returnedItems.append(item)
        }
                
        // Result
        addQuerryResultBlock(operation: queryOperation) { finished in
          if finished {
            completion(returnedItems)
          }
        }
        addOperation(operation: queryOperation)
    }
    
    func update<T: CKCodable>(item: T, completion: @escaping (Result<CKRecord?, Error>) -> ()) {
      add(item: item, completion: completion)
    }
    
    func delete<T: CKCodable>(item: T, completion: @escaping (Result<Bool, Error>) -> ()) {
      guard let record = item.record else {
        completion(.failure(iCloudKitError.iCloudDatabaseError))
        return
      }
      deleteBD(record: record, completion: completion)
    }

    
    private func addRecordMatchedBlock<T:CKCodable>(
      operation: CKQueryOperation,
      completion: @escaping (_ item: T) -> ()) {
        operation.recordMatchedBlock = { (returnedRecordID, returnedResult) in
          switch returnedResult {
            case .success(let record):
              guard let item = T(record: record) else { return }
              completion(item)
            case .failure:
              break
          }
       }
    }
    
    private func addQuerryResultBlock(
      operation: CKQueryOperation,
      completion: @escaping(_ finished: Bool) -> ()) {
        operation.queryResultBlock = { returnedResult in
          completion(true)
        }
    }
    
    private func createOperation(
      predicate: NSPredicate,
      recordType: CKRecord.RecordType,
      sortDescriptions: [NSSortDescriptor]? = nil,
      resultsLimit: Int? = nil) -> CKQueryOperation {

        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = sortDescriptions
        let queryOperation = CKQueryOperation(query: query)
        if let limit = resultsLimit {
          queryOperation.resultsLimit = limit
        }
        return queryOperation
    }
    
    private func addOperation(operation: CKDatabaseOperation) {
      CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    private func save(record: CKRecord, completion: @escaping (Result<CKRecord?, Error>) -> ()) {
      let iCloudPD = CKContainer.default().publicCloudDatabase
      iCloudPD.save(record) { returnedRecord, error in
        if let error = error {
          completion(.failure(error))
        } else {
          completion(.success(returnedRecord))
        }
      }
    }
    
    private func deleteBD(record: CKRecord, completion: @escaping (Result<Bool, Error>) -> ()) {
      let iCloudPD = CKContainer.default().publicCloudDatabase
      iCloudPD.delete(withRecordID: record.recordID) { returnedID, error in
        if let error = error {
          completion(.failure(error))
        } else {
          completion(.success(true))
        }
      }
    }


    
}

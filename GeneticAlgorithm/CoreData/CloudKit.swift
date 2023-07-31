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



class CKManager {
    
    
    
    static let shared = CKManager() 
    
    let container = CKContainer(identifier: "")

    var database: CKDatabase{
        return container.database(with: .private)
    }


    func getiCloudStatus(completion: @escaping (Result<Void, CloudKitAccountStatusGroup>) -> ()) {
        container.accountStatus { accountStatus, error in
            
            if accountStatus == .available{
                completion(.success(()))
            }else{
                completion(.failure(.init(accountStatus: accountStatus)))
            }
       }
    }
    

    func getiCloudUserID(completion: @escaping(Result<CKRecord.ID, CKCustomError>) -> ()) {
        
        container.fetchUserRecordID { userRecordID, error in
        guard let ckError = error as? CKError else { return }
        guard let recordID = userRecordID else {
            completion(.failure(.init(error: ckError)))
            return
        }
        completion(.success(recordID))
      }
    }
    
    func getUserName(forID userID: CKRecord.ID, completion: @escaping(Result<String, CKCustomError>) -> ()) {
      
        var givenName: String = ""
        var familyName: String = ""
        
        container.discoverUserIdentity(withUserRecordID: userID) { userIndentity, error in
        if let name = userIndentity?.nameComponents?.givenName {
          givenName = name
        }
        if let surname = userIndentity?.nameComponents?.familyName {
          familyName = surname
        }
        if let error = error as? CKError {
            completion(.failure(.init(error: error)))
        } else {
            completion(.success(givenName + " " + familyName))
        }
      }
    }
    
    func add<T: CKCodable>(item: T, completion: @escaping (Result<CKRecord?, CKCustomError>) -> ()) {
      guard let record = item.record else {
          completion(.failure(.recordErrors("record not found")))
        return
      }
      save(record: record, completion: completion)
    }
    
    func addWithReference<T: CKCodable, C: CKCodable>(
      fromItem childItem: T,
      toItem parentItem: C,
      withReferenceFieldName referenceFieldName: String,
      withReferenceAction refAction: CKRecord.ReferenceAction,
      completion: @escaping (Result<CKRecord?, CKCustomError>) -> ()) {

        guard let childRecord = childItem.record else {
            completion(.failure(.recordErrors("child record not found")))
          return
        }
        guard let parentRecord = parentItem.record else {
            completion(.failure(.recordErrors("parental record not found")))
          return
        }
        childRecord[referenceFieldName] = CKRecord.Reference(record: parentRecord, action: refAction)
        save(record: childRecord, completion: completion)
    }
    
    func fetch<T:CKCodable>(
      query: Query,
      recordType: CKRecord.RecordType,
      sortDescriptions: [NSSortDescriptor]? = nil,
      resultsLimit: Int? = nil,
      completion: @escaping(_ items: [T]) -> ()) {

        // Create operation
        let queryOperation = createOperation(
          query: query,
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
        let query = Query(varName: searchField, operant: .equalTo, value: recordToMatch)

                
        // Create operation
        let queryOperation = createOperation(
            query: query,
          recordType: recordType,
          sortDescriptions: sortDescriptions,
          resultsLimit: resultsLimit
        )
                
        // Get items
        var returnedItems: [C] = []
        addRecordMatchedBlock(operation: queryOperation) { item in
          returnedItems.append(item)
        }
          
        //Pq as vezes os dados do banco ainda não foram carregados
                
        // Result
        addQuerryResultBlock(operation: queryOperation) { finished in
          if finished {
            completion(returnedItems)
          }
        }
        addOperation(operation: queryOperation)
    }
    
    func update<T: CKCodable>(item: T, completion: @escaping (Result<CKRecord?, CKCustomError>) -> ()) {
      add(item: item, completion: completion)
    }
    
    func delete<T: CKCodable>(item: T, completion: @escaping (Result<Bool, CKCustomError>) -> ()) {
      guard let record = item.record else {
          completion(.failure(.recordErrors("record not found")))
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
    
    
    private func awaitRecordMatchedBlock(operation: CKQueryOperation) async ->  Result<[CKRecord], Error> {
        return await withCheckedContinuation { continuation in
            var ckRecords: [CKRecord] = []
            operation.recordMatchedBlock = { (returnedRecordID, returnedResult) in
                switch returnedResult {
                    case .success(let ckRecord):
                        ckRecords.append(ckRecord)
                    case .failure(let error):
                        continuation.resume(returning: .failure(error))
                }
            }
            continuation.resume(returning: .success(ckRecords))
        }
    }

    private func addRecordMatchedBlock<T: CKCodable>(ofType: T.Type, operation: CKQueryOperation) async throws -> [T] {
        do {
            let returnedResult = await awaitRecordMatchedBlock(operation: operation)
            switch returnedResult {
            case .success(let record):
                let itens = record.compactMap(T.init)
                if itens.isEmpty{
                    throw CKCustomError.recordErrors("Failed to create item")
                }
                return itens
            case .failure(let error):
                throw CKCustomError(error: error as! CKError)
            }
        } catch {
            // Handle any potential errors if the asynchronous operation fails
            throw CKCustomError.unknownErrors
        }
    }



    private func addQuerryResultBlock(operation: CKQueryOperation) async -> Bool {
        return await withCheckedContinuation { continuation in
            operation.queryResultBlock = { _ in
                continuation.resume(returning: true)
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
      query: Query,
      recordType: CKRecord.RecordType,
      sortDescriptions: [NSSortDescriptor]? = nil,
      resultsLimit: Int? = nil) -> CKQueryOperation {

        let query = CKQuery(recordType: recordType, predicate: query.predicate)
        query.sortDescriptors = sortDescriptions
        let queryOperation = CKQueryOperation(query: query)
        if let limit = resultsLimit {
          queryOperation.resultsLimit = limit
        }
        return queryOperation
    }
    
    private func addOperation(operation: CKDatabaseOperation) {
      database.add(operation)
    }
    
    private func save(record: CKRecord, completion: @escaping (Result<CKRecord?, CKCustomError>) -> ()) {
        database.save(record) { returnedRecord, error in
        if let error = error as? CKError {
            completion(.failure(.init(error: error)))
        } else {
          completion(.success(returnedRecord))
        }
      }
    }
    
    private func deleteBD(record: CKRecord, completion: @escaping (Result<Bool, CKCustomError>) -> ()) {
        database.delete(withRecordID: record.recordID) { returnedID, error in
        if let error = error as? CKError {
            completion(.failure(.init(error: error)))
        } else {
          completion(.success(true))
        }
      }
    }

}

extension CKManager{
    func getiCloudStatus() async -> Result<Void, CloudKitAccountStatusGroup> {
          do{
              let accountStatus = try await container.accountStatus()
              
              if accountStatus == .available{
                return .success(())
              }else{
                  return .failure(.init(accountStatus: accountStatus))
              }
              
          }catch{
              return .failure(.unknown)
          }
      }

    
    
    func getiCloudUserID() async -> Result<CKRecord.ID, CKCustomError> {
        do {
            let recordID: CKRecord.ID = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKRecord.ID, Error>) in
                container.fetchUserRecordID { userRecordID, error in
                    if let error = error as? CKError {
                        continuation.resume(throwing: error)
                    } else if let userRecordID = userRecordID {
                        continuation.resume(returning: userRecordID)
                    }
                }
            }
            return .success(recordID)
        } catch {
            return .failure(.init(error: error as! CKError))
        }
    }



    func getUserName(forID userID: CKRecord.ID) async -> Result<String, CKCustomError> {
        do {
            let userIndentity = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKUserIdentity?, Error>) in
                container.discoverUserIdentity(withUserRecordID: userID) { userIndentity, error in
                    if let error = error as? CKError {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: userIndentity)
                    }
                }
            }

            if let name = userIndentity?.nameComponents?.givenName, let surname = userIndentity?.nameComponents?.familyName {
                return .success(name + " " + surname)
            } else {
                return .failure(.accountErrors("User data return nil"))
            }
        } catch {
            return .failure(.init(error: error as! CKError))
        }
    }



    func add<T: CKCodable>(item: T) async -> Result<CKRecord?, CKCustomError> {
        guard let record = item.record else {
            return .failure(.recordErrors("record not found"))
        }
        do {
            return .success(try await save(record: record))
        } catch {
            return .failure(.init(error: error as! CKError))
        }
    }

    func addWithReference<T: CKCodable, C: CKCodable>(
        fromItem childItem: T,
        toItem parentItem: C,
        withReferenceFieldName referenceFieldName: String,
        withReferenceAction refAction: CKRecord.ReferenceAction
    ) async -> Result<CKRecord?, CKCustomError> {
        guard let childRecord = childItem.record else {
            return .failure(.recordErrors("child record not found"))
        }
        guard let parentRecord = parentItem.record else {
            return .failure(.recordErrors("parental record not found"))
        }
        childRecord[referenceFieldName] = CKRecord.Reference(record: parentRecord, action: refAction)
        do {
            return .success(try await save(record: childRecord))
        } catch {
            return .failure(.init(error: error as! CKError))
        }
    }

    func fetch<T: CKCodable>(
        query: Query,
        recordType: CKRecord.RecordType,
        sortDescriptions: [NSSortDescriptor]? = nil,
        resultsLimit: Int? = nil
    ) async -> Result<[T], CKCustomError> {
        do {
            let queryOperation = createOperation(
                query: query,
                recordType: recordType,
                sortDescriptions: sortDescriptions,
                resultsLimit: resultsLimit
            )

            let returnedItems = try await addRecordMatchedBlock(ofType: T.self, operation: queryOperation)
            
            if await self.addQuerryResultBlock(operation: queryOperation){
                return .success(returnedItems)
            }else{
                return .failure(.databaseErrors(""))
            }
        
            
        } catch {
            return .failure(CKCustomError(error: error as! CKError))
        }
    }
    
    func fetchReferences<T: CKCodable, C: CKCodable>(
        forItem owner: T,
        andField searchField: String,
        recordType: CKRecord.RecordType,
        sortDescriptions: [NSSortDescriptor]? = nil,
        resultsLimit: Int? = nil
    ) async -> Result<[C], CKCustomError> {
        guard let ownerRecord = owner.record else {
            return .success([])
        }

        let recordToMatch = CKRecord.Reference(record: ownerRecord, action: .deleteSelf)
        let query = Query(varName: searchField, operant: .equalTo, value: recordToMatch)

        let queryOperation = createOperation(
            query: query,
            recordType: recordType,
            sortDescriptions: sortDescriptions,
            resultsLimit: resultsLimit
        )

    
        do {
            let returnedItems = try await addRecordMatchedBlock(ofType: C.self, operation: queryOperation)
            
            if await self.addQuerryResultBlock(operation: queryOperation){
                return .success(returnedItems)
            }else{
                return .failure(.databaseErrors(""))
            }
            
        } catch {
            return .failure(.init(error: error as! CKError))
        }
    }




    func update<T: CKCodable>(item: T) async -> Result<CKRecord?, CKCustomError> {
        return await add(item: item)
    }

    func delete<T: CKCodable>(item: T) async -> Result<Bool, CKCustomError> {
        guard let record = item.record else {
            return .failure(.recordErrors("record not found"))
        }
        do {
            return .success(try await deleteBD(record: record))
        } catch {
            return .failure(.init(error: error as! CKError))
        }
    }


    private func save(record: CKRecord) async throws -> CKRecord? {
        return try await withCheckedThrowingContinuation { continuation in
            database.save(record) { returnedRecord, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: returnedRecord)
                }
            }
        }
    }

    private func deleteBD(record: CKRecord) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            database.delete(withRecordID: record.recordID) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: true)
                }
            }
        }
    }
}



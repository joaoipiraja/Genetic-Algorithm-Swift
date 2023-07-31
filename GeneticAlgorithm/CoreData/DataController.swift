//
//  DataController.swift
//  GeneticAlgorithm
//
//  Created by João Victor Ipirajá de Alencar on 26/07/23.
//

import Foundation
import CoreData

class DataController: ObservableObject {
    
    //https://youtu.be/TsfOYHbf4Ew
    
    let container = NSPersistentContainer(name: "GeneticDatabase")
    static let shared = DataController()
    
    var viewContext: NSManagedObjectContext{
        return container.viewContext
    }
    

      init() {
            container.loadPersistentStores { _, error in
                if let error = error {
                    print("CoreData failed to load: \(error.localizedDescription)")
                    // Handle the load error more appropriately if needed
                }
            }
            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        }


        @discardableResult func save<T: NSManagedObject>(ofType: T.Type, completion: (T) -> ()) async -> Result<Void, CoreDataError> {
            completion(T.init(context: self.viewContext))

            do {
                try viewContext.performAndWait {
                    try self.viewContext.save()
                }
                return .success(())
            } catch {
                self.viewContext.rollback()
                return .failure(.saveFailed)
            }
        }

        func getAllObject<T: NSManagedObject>(ofType: T.Type) async -> Result<[T], CoreDataError> {
            var response: [T] = []
            let request: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>

            do {
                try viewContext.performAndWait {
                    response = try self.viewContext.fetch(request)
                }
                return .success(response)
            } catch {
                return .failure(.fetchFailed)
            }
        }

        func getObject<T: NSManagedObject>(ofType: T.Type, withId id: UUID) async -> Result<T?, CoreDataError> {
            var response: T? = nil
            let request: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
            request.predicate = Query(varName: "id", operant: .equalTo, value: id.uuidString).predicate
            request.fetchLimit = 1

            do {
                try self.viewContext.performAndWait {
                    response = try self.viewContext.fetch(request).first
                }
                return .success(response)
            } catch {
                return .failure(.fetchObjectIdFailed)
            }
        }
    
            func getObjects<T: NSManagedObject>(ofType: T.Type, when query: Query) async -> Result<[T], CoreDataError> {
                var response: [T] = []
                let request: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
                request.predicate = query.predicate
                request.fetchLimit = 1

                do {
                    try self.viewContext.performAndWait {
                        response = try self.viewContext.fetch(request)
                    }
                    return .success(response)
                } catch {
                    return .failure(.fetchObjectIdFailed)
                }
            }

        @discardableResult  func updateObject<T: NSManagedObject>(ofType: T.Type, withId id: UUID, completion: @escaping (T) -> ()) async -> Result<Void, CoreDataError> {
            let request: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
            request.predicate = Query(varName: "id", operant: .equalTo, value: id.uuidString).predicate
            request.fetchLimit = 1

            do {
                try viewContext.performAndWait {
                    let objects = try self.viewContext.fetch(request)
                    if let object = objects.first {
                        completion(object)
                        try self.viewContext.save()
                    }
                }
                return .success(())
            } catch {
                return .failure(.updateFailed)
            }
        }

        @discardableResult func deleteObject<T: NSManagedObject>(ofType: T.Type, onConditionThat condition: NSPredicate) async -> Result<Void, CoreDataError> {
            let request: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
            request.predicate = condition
            request.fetchLimit = 1

            do {
                try self.viewContext.performAndWait {
                    let objects = try self.viewContext.fetch(request)
                    if let object = objects.first {
                        self.viewContext.delete(object)
                    }
                    try self.viewContext.save()
                }
                return .success(())
            } catch {
                return .failure(.deleteFailed)
            }
        }

        @discardableResult func deleteAllObjects<T: NSManagedObject>(ofType: T.Type) async -> Result<Void, CoreDataError> {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = T.fetchRequest()
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try self.viewContext.performAndWait {
                    try self.viewContext.execute(batchDeleteRequest)
                    try self.viewContext.save()
                }
                return .success(())
            } catch {
                return .failure(.deleteAllFailed)
            }
        }

}

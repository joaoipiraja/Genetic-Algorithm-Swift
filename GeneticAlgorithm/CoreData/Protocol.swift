//
//  Protocols.swift
//  GeneticAlgorithm
//
//  Created by João Victor Ipirajá de Alencar on 26/07/23.
//

import CoreData

protocol Readable {
    static func getAllObjects() async -> Result<[Self], CoreDataError>
    static func getObjects(onConditionThat query: Query) async -> Result<[Self], CoreDataError>
    static func getObject(onConditionThat query: Query) async -> Result<Self, CoreDataError>
}

protocol Writeable{
    @discardableResult static func save() async -> Result<Void, CoreDataError>
}

protocol Deletable{
    @discardableResult static func deleteObject(onConditionThat query: Query) async -> Result<Void, CoreDataError>
    @discardableResult static func deleteAllObjects() async -> Result<Void, CoreDataError>
}

protocol ActiveRecordType:Readable,Writeable, Deletable{}

protocol ModelType: ActiveRecordType {
    associatedtype Context
    static var context: Self.Context { get }
}

protocol CoreDataModel: ModelType where Context == NSManagedObjectContext {}

extension CoreDataModel where Self: NSManagedObject{
    static var viewContext: NSManagedObjectContext{
        //        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        //        return appDelegate.managedObjectContext
        let container = NSPersistentContainer(name: "GeneticDatabase")
        return container.viewContext
    }
    
    @discardableResult func save() async -> Result<Void, CoreDataError> {
        
        if Self.viewContext.hasChanges{
            do {
                try Self.viewContext.performAndWait {
                    try Self.viewContext.save()
                }
                return .success(())
            } catch {
                Self.viewContext.rollback()
                return .failure(.saveFailed)
            }
        }else{
            return .success(())
        }
        
    }
    
    @discardableResult func deleteAllObjects() async -> Result<Void, CoreDataError> {
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Self.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try Self.viewContext.performAndWait {
                try Self.viewContext.execute(batchDeleteRequest)
                try Self.viewContext.save()
            }
            return .success(())
        } catch {
            return .failure(.deleteAllFailed)
        }
    }
    
    @discardableResult func deleteObject(onConditionThat query: Query) async -> Result<Void, CoreDataError> {
        
        let request: NSFetchRequest<Self> = Self.fetchRequest() as! NSFetchRequest<Self>
        request.predicate = query.predicate
        request.fetchLimit = 1
        
        do {
            try Self.viewContext.performAndWait {
                let objects = try Self.viewContext.fetch(request)
                if let object = objects.first {
                    Self.viewContext.delete(object)
                }
                try Self.viewContext.save()
            }
            return .success(())
        } catch {
            return .failure(.deleteFailed)
        }
        
    }
    
    static func getAllObjects() async -> Result<[Self], CoreDataError> {
        var response: [Self] = []
        let request: NSFetchRequest<Self> = Self.fetchRequest() as! NSFetchRequest<Self>
        
        do {
            try Self.viewContext.performAndWait {
                response = try Self.viewContext.fetch(request)
            }
            return .success(response)
        } catch {
            return .failure(.fetchFailed)
        }
    }
    
    static func getObject(onConditionThat query: Query) async -> Result<Self, CoreDataError>{
        var response: Self = Self.init()
        let request: NSFetchRequest<Self> = Self.fetchRequest() as! NSFetchRequest<Self>
        request.predicate = query.predicate
        request.fetchLimit = 1

        do {
            try viewContext.performAndWait {
                response = try viewContext.fetch(request).first!
            }
            return .success(response)
        } catch {
            return .failure(.fetchObjectIdFailed)
        }
    }
    
    static func getObjects(onConditionThat query: Query) async -> Result<[Self], CoreDataError>{
        var response: [Self] = []
        let request: NSFetchRequest<Self> = Self.fetchRequest() as! NSFetchRequest<Self>
        request.predicate = query.predicate

        do {
            try viewContext.performAndWait {
                response = try viewContext.fetch(request)
            }
            return .success(response)
        } catch {
            return .failure(.fetchObjectIdFailed)
        }
        
    }
}



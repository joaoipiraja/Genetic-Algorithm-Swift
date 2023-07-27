//
//  Protocols.swift
//  GeneticAlgorithm
//
//  Created by João Victor Ipirajá de Alencar on 26/07/23.
//

import CoreData

protocol Readable {
    func getObject<T: NSManagedObject>(ofType: T.Type) async -> Result<[T], CoreDataError>
    func getObject<T: NSManagedObject>(ofType: T.Type, withId id: UUID) async -> Result<T?, CoreDataError>
    func getObjects<T: NSManagedObject>(ofType: T.Type, when query: Query) async -> Result<[T], CoreDataError>
}

protocol Writeable{
    @discardableResult func save<T: NSManagedObject>(ofType: T.Type, completion: (T) -> ()) async -> Result<Void, CoreDataError>
    @discardableResult  func updateObject<T: NSManagedObject>(ofType: T.Type, withId id: UUID, completion: @escaping (T) -> ()) async -> Result<Void, CoreDataError>
}

protocol Deletable{
    @discardableResult func deleteObject<T: NSManagedObject>(ofType: T.Type, onConditionThat condition: NSPredicate) async -> Result<Void, CoreDataError>
    @discardableResult func deleteAllObjects<T: NSManagedObject>(ofType: T.Type) async -> Result<Void, CoreDataError>
}

protocol ActiveRecordType:Readable,Writeable, Deletable{}

protocol ModelType: ActiveRecordType {
    associatedtype Context
    static var context: Self.Context { get }
}

protocol CoreDataModel: ModelType {
    typealias Context = NSManagedObjectContext
}

extension CoreDataModel where Self: NSManagedObject{
    static var viewContext: NSManagedObjectContext{
//        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
//        return appDelegate.managedObjectContext
        let container = NSPersistentContainer(name: "GeneticDatabase")
        return container.viewContext
    }
}



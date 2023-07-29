//
//  Task.swift
//  GeneticAlgorithm
//
//  Created by João Victor Ipirajá de Alencar on 16/05/23.
//

import Foundation
import CoreData







class ThingViewModel: ObservableObject{
    
    
    @Published var things: [ThingViewModel] = []

    var id: UUID
    var name: String
    var value: Float
    var weight: Float

    
    init(thing: Thing){
        self.id = thing.id ?? .init()
        self.name = thing.name ?? ""
        self.value = thing.value
        self.weight = thing.weight
    }
    
    init(){
        self.id = .init()
        self.name = ""
        self.value = 0.0
        self.weight = 0.0
    }
    
    init(id: UUID = .init(), name: String, value: Float, weight: Float){
        self.id = id
        self.name = name
        self.value = value
        self.weight = weight
    }
    
    
    func getAllThings() async{
        
        let result = await DataController.shared.getAllObject(ofType: Thing.self)
        
        switch result{
            
        case .success(let thing):
            DispatchQueue.main.async {
                self.things = thing.map(ThingViewModel.init)
            }

        case .failure(let error):
            print(error.localizedDescription)
        }
        
      
    }
    
    func saveThing(viewModel: ThingViewModel) async{
        await DataController.shared.save(ofType: Thing.self){ thing in
            thing.id = viewModel.id
            thing.name = viewModel.name
            thing.value = viewModel.value
            thing.weight = viewModel.weight
        }
       
    }
    
    func updateThing() async{
        
        await DataController.shared.updateObject(ofType: Thing.self, withId: id, completion: { [self] thing in
            thing.name = self.name
            thing.value = self.value
            thing.weight = self.weight
        })

    }
    
  
    
}


class CitizenViewModel{
    
    var citizens: [CitizenViewModel] = []

    var id: UUID
    var genomes: Array<Array<Int8>>

    
    init(citizens: Citizens){
        self.id = citizens.id ?? .init()
        self.genomes = citizens.genomes ?? []
    }
    
    init(id: UUID = .init(), genomes: Array<Array<Int8>>){
        self.id = id
        self.genomes = genomes
    }
    
    
    
    init(){
        self.id = .init()
        self.genomes = []
    }
    
    
    func getAllCitizens() async{
        
        let result = await DataController.shared.getAllObject(ofType: Citizens.self)
        switch result{
            case .success(let citizen):
                self.citizens = citizen.map(CitizenViewModel.init)
            case .failure(let error):
                print(error.localizedDescription)
        }
        
    }
    
    func getCitizen(at index:Int) async  -> Array<Array<Int8>> {
        
        let result = await DataController.shared.getObject(ofType: Citizens.self, withId: self.citizens[index].id)
        
        switch result{
            case .success(let citizen):
                return citizen?.genomes ?? []
            case .failure(let error):
                print(error.localizedDescription)
        }

        return []
    }
    
    
    func saveCitizen() async {
        await DataController.shared.save(ofType: Citizens.self){ citizen in
            citizen.id = id
            citizen.genomes = genomes
        }
    }
    
    func updateCitizen() async{
        
        await DataController.shared.updateObject(ofType: Citizens.self, withId: id, completion: { [self] citizen in
            citizen.genomes = self.genomes
        })
      
    }
    
    func deleteAll() async{
        await DataController.shared.deleteAllObjects(ofType: Citizens.self)
    }
    
}














////
////extension FileHandle{
////    func read(tillFind character: Character) -> Data{
////        var jsonData = Data()
////        while true {
////            let buffer = self.readData(ofLength: 1)
////            guard !buffer.isEmpty else {
////                break
////            }
////            let byte = buffer.first!
////            if byte == character.asciiValue {
////                break
////            }
////            jsonData.append(buffer)
////        }
////        return jsonData
////    }
////}
//
//
//class AsyncSemaphore {
//    private let semaphore: DispatchSemaphore
//
//    init(value: Int = 1) {
//        semaphore = DispatchSemaphore(value: value)
//    }
//
//    func wait() async {
//        await withCheckedContinuation { continuation in
//            semaphore.wait()
//            continuation.resume()
//        }
//    }
//
//    func signal() {
//        semaphore.signal()
//    }
//}
//
//
//
//
//extension Array<Int>{
//
//    func calculateOffSet(index: Int) async -> UInt64 {
//        let result = await withTaskGroup(of: Int.self) { group in
//            var sum: Int = 0
//
//            // Iterate from 0 to index and add each element to the group
//            for i in 0...index {
//                group.addTask {
//                    return self[i]
//                }
//            }
//
//            // Process the results from the group
//            for await value in group {
//                sum += value
//            }
//
//            return sum
//        }
//
//        return UInt64(result)
//    }
//
//    func calculateOffSet(range: Range<Int>) async -> Int {
//        return await calculateOffSet(range: ClosedRange(range))
//    }
//
//    func calculateOffSet(range: ClosedRange<Int>) async -> Int {
//        let result = await withTaskGroup(of: Int.self) { group in
//            var sum: Int = 0
//
//            // Iterate over the provided range and add each element to the group
//            for i in range {
//                group.addTask {
//                    return self[i]
//                }
//            }
//
//            // Process the results from the group
//            for await value in group {
//                sum += value
//            }
//
//            return sum
//        }
//
//        return result
//    }
//
//
//
//
//}
//
//
//class IOOperation{
//
//    var dataSizes: Array<Int>
//    private let fileManager = FileManager.default
//    //private var fileHandle: FileHandle
//    var fileDescriptor: Int32
//    let queue = DispatchQueue.global(qos: .userInitiated)
//    var ioChannel: DispatchIO
//
//    var semExclusao = AsyncSemaphore(value: 1)
//    var semLeitores = AsyncSemaphore(value: 1)
//    var leitoresAtivos = 0
//
//    let url: URL
//
//    init() {
//
//        let tempDir = fileManager.temporaryDirectory
//        let tempFileName = "populations.json"
//        self.url =  tempDir.appendingPathComponent(tempFileName)
//
//        if fileManager.fileExists(atPath: url.path()) {
//            do {
//                try fileManager.removeItem(atPath: url.path())
//                print("File deleted successfully.")
//            } catch {
//                print("Error deleting file: \(error)")
//            }
//        }
//
//        fileManager.createFile(atPath: url.path(), contents: nil, attributes: nil)
//
//        self.fileDescriptor = Darwin.open(url.path(), O_RDWR)
//        self.ioChannel = DispatchIO(type: .random, fileDescriptor: fileDescriptor, queue: queue, cleanupHandler: { error in
//            if error != 0 {
//            }
//        })
//
//      //  self.fileHandle = try! FileHandle(forUpdating: self.url)
//
//        self.dataSizes = []
//
//
//    }
//
//    func open(){
//
//        self.dataSizes = []
//
//
//        if fileManager.fileExists(atPath: url.path()) {
//            do {
//                try fileManager.removeItem(atPath: url.path())
//                print("File deleted successfully.")
//            } catch {
//                print("Error deleting file: \(error)")
//            }
//        }
//
//        fileManager.createFile(atPath: url.path(), contents: nil, attributes: nil)
//
////        self.fileHandle = try! FileHandle(forUpdating: self.url)
//        self.fileDescriptor = Darwin.open(url.path(), O_RDWR)
//        self.ioChannel = DispatchIO(type: .random, fileDescriptor: fileDescriptor, queue: queue, cleanupHandler: { error in
//            if error != 0 {
//            }
//        })
//
//        self.dataSizes.append(0)
//
//    }
//
//    func save(data: Data) async{
//        let offsets =  await self.dataSizes.calculateOffSet(index: self.dataSizes.count-1)
//
//        print("save", offsets)
//
//
//        await withCheckedContinuation{ [self] continuation in
//
//            let dispatchData = data.withUnsafeBytes {
//                DispatchData(bytes: $0)
//            }
//
//            self.dataSizes.append(data.count)
//
//            self.ioChannel.write(offset: off_t(offsets), data: dispatchData, queue: queue) { done, data, error in
//                if done{
//                    continuation.resume()
//                }
//            }
//        }
//    }
//
//    func update(data: Data, at index: Int) async{
//
//        await self.semExclusao.wait()
//
//
//        let sum1 =  await self.dataSizes.calculateOffSet(range: 0...index)
//        let sum21 = await self.dataSizes.calculateOffSet(range: 0...index+1)
//        let sum2 =  await self.dataSizes.calculateOffSet(range: index+2..<self.dataSizes.count)
//
//        var dispatchData = DispatchData.empty
//        let dataUpdated = data.withUnsafeBytes {
//            DispatchData(bytes: $0)
//        }
//
//
//        await withCheckedContinuation{ [self] continuation in
//
//            ioChannel.read(offset: 0, length: sum1, queue: queue){ done, dataStart, error in
//                if done{
//
//
//                    self.ioChannel.read(offset: off_t(sum21), length: sum2, queue: self.queue) { done, dataFinal, error in
//
//
//                        if done{
//                            dispatchData.append(dataStart!)
//                            dispatchData.append(dataUpdated)
//                            dispatchData.append(dataFinal!)
//
//                            self.ioChannel.write(offset: 0, data:  dispatchData, queue: self.queue) { done, data, error in
//                                if done{
//
//                                    let size = dataUpdated.count
//                                    self.dataSizes[index+1] = size
//
//                                    self.semExclusao.signal()
//
//                                    continuation.resume()
//                                }
//                            }
//
//                        }
//                    }
//                }
//            }
//
//
//        }
//
//    }
//
//    func read(at index: Int) async -> Population{
//
//        await self.semLeitores.wait()
//        self.leitoresAtivos += 1
//
//
//        if self.leitoresAtivos == 1{
//            await self.semExclusao.wait()
//        }
//
//        self.semLeitores.signal()
//
//
//        let offsets =  await self.dataSizes.calculateOffSet(range: 0...index)
//
//        let pop = await withCheckedContinuation{ [self] continuation in
//
//            print("read", index, offsets,  self.dataSizes[index+1])
//
//            self.ioChannel.read(offset: off_t(offsets), length: self.dataSizes[index+1], queue: queue) { done, data, error in
//
//
//                if done{
//
//                    if let data = data, let dataDecoded = try? JSONDecoder().decode(Population.self, from: Data(copying: data)){
//                        continuation.resume(with: .success(dataDecoded))
//
//                    }else if let data = data{
//                        continuation.resume(with: .success([]))
//                        print("Error \(index) \(self.dataSizes[index])->", String(data: Data(copying: data), encoding: .isoLatin1)!.prefix(40))
//
//                    }
//
//                }
//
//            }
//
//        }
//
//
//
//        self.semLeitores.signal()
//        self.leitoresAtivos -= 1
//        if self.leitoresAtivos == 0{
//            self.semExclusao.signal()
//        }
//        self.semLeitores.signal()
//
//        return pop
//
//
//    }
//
//
//    func close() async{
//
//        await withCheckedContinuation{ [self] continuation in
//            self.ioChannel.close()
//            self.dataSizes = []
//            continuation.resume()
//        }
//
//    }
//
//}

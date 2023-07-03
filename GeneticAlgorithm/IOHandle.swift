//
//  Task.swift
//  GeneticAlgorithm
//
//  Created by João Victor Ipirajá de Alencar on 16/05/23.
//

import Foundation


extension FileHandle{
    func read(tillFind character: Character) -> Data{
        var jsonData = Data()
    
        while true {
            let buffer = self.readData(ofLength: 1)
            guard !buffer.isEmpty else {
                break
            }
            let byte = buffer.first!
            if byte == character.asciiValue {
                break
            }
            jsonData.append(buffer)
        }
        return jsonData
    }
}


class IOOperation{
    
    var offsetsSaved: Array<UInt64>
    private let fileManager = FileManager.default
    private var fileHandle: FileHandle
    private var ioQueue: DispatchQueue = .init(label: "com.geneticAlg.io")

    let url: URL
    
    init() {
        
        let tempDir = fileManager.temporaryDirectory
        let tempFileName = "populations.json"
        self.url =  tempDir.appendingPathComponent(tempFileName)
        
        if fileManager.fileExists(atPath: url.path()) {
            do {
                try fileManager.removeItem(atPath: url.path())
                print("File deleted successfully.")
            } catch {
                print("Error deleting file: \(error)")
            }
        }

        fileManager.createFile(atPath: url.path(), contents: nil, attributes: nil)
        
        
        self.fileHandle = try! FileHandle(forUpdating: self.url)
        self.offsetsSaved = []


    }
    
    func open(){
        
        self.offsetsSaved = []


        if fileManager.fileExists(atPath: url.path()) {
            do {
                try fileManager.removeItem(atPath: url.path())
                print("File deleted successfully.")
            } catch {
                print("Error deleting file: \(error)")
            }
        }

        fileManager.createFile(atPath: url.path(), contents: nil, attributes: nil)
        
        self.fileHandle = try! FileHandle(forUpdating: self.url)

    }
    
    func save(data: any DataProtocol){
        
        offsetsSaved.append(self.fileHandle.offsetInFile)
        try! self.fileHandle.write(contentsOf: data)
    }
    
    func update(data: any DataProtocol, at index: Int){
        
            self.fileHandle.seek(toFileOffset:  self.offsetsSaved[index])
            try!  self.fileHandle.write(contentsOf: data)
            self.offsetsSaved[index] = self.fileHandle.offsetInFile
 
    }
    
    func read(at index: Int) -> Population{
        self.fileHandle.seek(toFileOffset: self.offsetsSaved[index])
        
        let jsonData = self.fileHandle.read(tillFind: "\n")

        
        var population: Population = []
        do{
            population = try JSONDecoder().decode(Population.self, from: jsonData)
            if(population.isEmpty){
                print("Error \(self.offsetsSaved[index])-> Empty")
            }
        }catch{
            print("Error \(self.offsetsSaved[index])->")
            print(String(data: jsonData, encoding: .isoLatin1)!.prefix(40))
        }
        
        return population
    }
    
    
    func close(){
        try! self.fileHandle.close()
        self.offsetsSaved = []
    }
    
}

//
//  Query.swift
//  GeneticAlgorithm
//
//  Created by João Victor Ipirajá de Alencar on 26/07/23.
//

import Foundation

class Query {
    var model: [Model]
    var separator: [MergeOperator]
    var value: [Any]
    
    init(varName: String, operant: Query.Model.Operator, value: Any){
        self.model = [.init(varName: varName, operant: operant)]
        self.separator = []
        self.value = [value]
    }
    
    
    init(){
        self.model = []
        self.separator = []
        self.value = []
    }

    var predicate: NSPredicate {
        let predicateFormat = model.enumerated().map { (index, m) in
            return (index < model.count - 1) ? "\(m.toString)\(separator[index].rawValue)" : m.toString
        }.joined()

        return NSPredicate(format: predicateFormat, argumentArray: value)
    }
}

extension Query {
    enum MergeOperator: String {
        case and = "&&"
        case or = "||"
    }
}

extension Query {
    struct Model {
        enum Operator: String  {
            case equalTo = "=="
            case greaterThan = ">"
            case greaterThanOrEqualTo = ">="
            case lessThan = "<"
            case lessThanOrEqualTo = "<="
            case like = "LIKE[d]"
            case beginsWith = "BEGINSWITH"
            case matches = "MATCHES"
            case contains = "CONTAINS"
        }

        var varName: String
        var operant: Operator?

        var toString: String {
            return " \(varName) \(operant?.rawValue ?? "") %@ "
        }
    }
}

extension Query {
    
    static func +(lhs:Query, rhs: Query) -> Query{
        let query = Query()
        query.model = lhs.model + rhs.model
        query.value = lhs.value + rhs.value
        query.separator = lhs.separator + rhs.separator
        return query
    }
    static func &&(lhs: Query, rhs: Query) -> Query {
        let query = lhs + rhs
        query.separator.append(.and)
        return query
    }

    static func ||(lhs: Query, rhs: Query) -> Query {
        let query = lhs + rhs
        query.separator.append(.or)
        return query
    }
}

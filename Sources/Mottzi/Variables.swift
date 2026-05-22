import Vapor

extension Application {
    
    func useVariables() throws {
        
        for variable in Variables.allCases {
            guard Environment.get(variable.rawValue) == nil else { continue }
            throw VariableError.variableNotFound
        }
    }
    
    enum Variables: String, CaseIterable {
        case TEST_1
        case TEST_2

        var value: String { Environment.get(self.rawValue)! }
    }
    
    enum VariableError: Error {
        case variableNotFound
    }
    
}


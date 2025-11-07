//
//  AutoEncodable.swift
//  mottzi
//
//  Created by Berken Sayilir on 07.11.2025.
//


// File: Mist/Sources/Mist/MistAutoEncode.swift

import Foundation

/// Add this to any Mist.Model to automatically encode all properties (stored + computed)
public protocol AutoEncodable: Encodable {}

public extension AutoEncodable {
    func encode(to encoder: Encoder) throws {
        let mirror = Mirror(reflecting: self)
        var container = encoder.container(keyedBy: DynamicKey.self)
        
        for child in mirror.children {
            guard let label = child.label else { continue }
            
            // Skip Fluent internal properties
            guard !label.hasPrefix("_") && !label.hasPrefix("$") else { continue }
            
            let key = DynamicKey(stringValue: label)!
            
            if let value = child.value as? (any Encodable) {
                try value.encode(to: container.superEncoder(forKey: key))
            }
        }
    }
}

private struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}
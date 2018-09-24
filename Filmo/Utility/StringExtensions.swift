//
//  StringExtensions.swift
//  Filmo
//
//  Created by Benjamin Frost on 24/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation
import PromiseKit

extension String {
    
    func firstGroupFromMatching(pattern: String) throws -> String {
        let range = NSRange.init(location: 0, length: self.count)
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        guard let match = regex.firstMatch(in: self, options: [], range: range) else {
            throw NSError(domain: "NSRegularExpression", code: 1234, userInfo: nil)
        }
        guard let swiftRange = Range.init(match.range(at: 1), in: self) else {
            throw NSError(domain: "NSRegularExpression", code: 4321, userInfo: nil)
        }
        return String(self[swiftRange])
    }
    
}


extension Promise {
    func peek(_ fn: @escaping (T) -> Void) -> Promise<T> {
        return self.map({ (value) -> T in
            fn(value)
            return value
        })
    }
}

//
//  Person.swift
//  Filmo
//
//  Created by Benjamin Frost on 24/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation

extension Array where Element == PersonReference {
    var names: String { return self.compactMap({ $0.name }).joined(separator: ", ") }
}

struct PersonReference {
    let id: String
    let name: String?
}

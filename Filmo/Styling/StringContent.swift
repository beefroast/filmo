//
//  StringContent.swift
//  Filmo
//
//  Created by Benjamin Frost on 8/10/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation

class ParentStringProvider {
    
    fileprivate let content: StringIndexable
    
    required init(content: StringIndexable) {
        self.content = content
    }
    
    fileprivate func child<T: ParentStringProvider>(_ name: String) -> T {
        return T(content: self.content.indexableChild(index: name))
    }
}

class Strings: ParentStringProvider, StringContentProvider {
    
    subscript(index: String) -> String? {
        return index.components(separatedBy: ".")
            .reduce(self.content) { (content, path) -> StringIndexable in content.indexableChild(index: path) }
            .stringValue
    }
    
    var registration: RegistrationStringProvider { get { return child("registration") }}
    
}








class RegistrationStringProvider: ParentStringProvider {
    var login: LoginStringProvider { get { return child("login") }}
}

class LoginStringProvider: ParentStringProvider {
    var signup: String? { get { return content.indexableChild(index: "signup").stringValue }}
}

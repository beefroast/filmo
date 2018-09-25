//
//  Backend.swift
//  Filmo
//
//  Created by Benjamin Frost on 25/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation
import PromiseKit

enum BackendError: Error {
    case notImplemented
    case notAuthenticated
    case invalidPayload(Any?)
}

protocol Backend {
    
    func login(user: String, password: String) -> Promise<Void>
    func register(user: String, password: String) -> Promise<Void>
    
    func getSavedFilms() -> Promise<Array<String>>
    func save(film: String) -> Promise<Array<String>>
    func remove(film: String) -> Promise<Array<String>>

}

class StubBackend: Backend {
    
    func login(user: String, password: String) -> Promise<Void> {
        return Promise()
    }
    
    func register(user: String, password: String) -> Promise<Void> {
        return Promise()
    }
    
    var savedFilms: [String] = ["tt6998518"]
    
    func getSavedFilms() -> Promise<Array<String>> {
        return Promise<Array<String>>.value(savedFilms)
    }
 
    func save(film: String) -> Promise<Array<String>> {
        savedFilms.append(film)
        return self.getSavedFilms()
    }
    
    func remove(film: String) -> Promise<Array<String>> {
        if let i = savedFilms.index(of: film) {
            savedFilms.remove(at: i)
        }
        return self.getSavedFilms()
    }
    
}

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

struct FriendReference {}

protocol Backend {
    
    // Authentication...
    
    func isUserLoggedIn() -> Guarantee<Bool>
    func login(user: String, password: String) -> Promise<Void>
    func logout() -> Promise<Void>
    func register(user: String, password: String) -> Promise<Void>
    func deregister() -> Promise<Void>
    
    func getSavedFilms() -> Promise<Array<String>>
    func save(film: String) -> Promise<Array<String>>
    func remove(film: String) -> Promise<Array<String>>
    
    func getFilmListReferences() -> Promise<Array<FilmListReference>>
    func getFilmList(id: String) -> Promise<FilmList>
    
    func createListWith(name: String) -> Promise<FilmListReference>
    func delete(list: FilmListReference) -> Promise<Void>
    func rename(list: FilmListReference, name: String) -> Promise<Void>
    func add(film: FilmReference, toList: FilmListReference) -> Promise<Void>
    func remove(film: FilmReference, fromList: FilmListReference) -> Promise<Void>
}

extension Backend {
    
    func getFilmLists() -> Promise<Array<FilmList>> {
        return self.getFilmListReferences().then({ (listRefs) -> Promise<Array<FilmList>> in
            let promises = listRefs.map({ (liftRef) -> Promise<FilmList> in
                return self.getFilmList(id: liftRef.id)
            })
            return when(fulfilled: promises)
        })
    }
    
    func getInitialFilmList() -> Promise<FilmList?> {
        return self.getFilmListReferences().then({ (references) -> Promise<FilmList?> in
            guard let ref = references.first else { return Promise<FilmList?>.value(nil) }
            return self.getFilmList(id: ref.id).map({ (list) -> FilmList? in
                return list
            })
        })
    }
}

class StubBackend: Backend {
    
    func isUserLoggedIn() -> Guarantee<Bool> {
        return Guarantee<Bool>.value(false)
    }
    
    func logout() -> Promise<Void> {
        return BackendError.notImplemented.toPromise()
    }
    
    func login(user: String, password: String) -> Promise<Void> {
        return Promise()
    }
    
    func register(user: String, password: String) -> Promise<Void> {
        return Promise()
    }
    
    func deregister() -> Promise<Void> {
        return BackendError.notImplemented.toPromise()
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
    
    func getFilmListReferences() -> Promise<Array<FilmListReference>> {
        return BackendError.notImplemented.toPromise()
    }
    
    func getFilmList(id: String) -> Promise<FilmList> {
        return BackendError.notImplemented.toPromise()
    }
    
    
    func createListWith(name: String) -> Promise<FilmListReference> {
        return BackendError.notImplemented.toPromise()
    }
    
    func delete(list: FilmListReference) -> Promise<Void> {
        return BackendError.notImplemented.toPromise()
    }
    
    func rename(list: FilmListReference, name: String) -> Promise<Void> {
        return BackendError.notImplemented.toPromise()
    }
    
    func add(film: FilmReference, toList: FilmListReference) -> Promise<Void> {
        return BackendError.notImplemented.toPromise()
    }
    
    func remove(film: FilmReference, fromList: FilmListReference) -> Promise<Void> {
        return BackendError.notImplemented.toPromise()
    }
    
}
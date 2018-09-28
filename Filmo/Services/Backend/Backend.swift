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
}

class FriendReference {
    let id: String
    let name: String?
    
    init(id: String, name: String? = nil) {
        self.id = id
        self.name = name
    }
}

protocol Backend {
    
    // Authentication...
    
    func isUserLoggedIn() -> Guarantee<Bool>
    func login(user: String, password: String) -> Promise<Void>
    func logout() -> Promise<Void>
    func register(user: String, password: String) -> Promise<Void>
    func deregister() -> Promise<Void>
    
    func getFilmListReferences() -> Promise<Array<FilmListReference>>
    
    // Film lists
    
    func getFilmList(id: String) -> Promise<FilmList>
    func update(filmList: FilmList) -> Promise<Void>
    func createListWith(name: String) -> Promise<FilmListReference>
    func delete(list: FilmListReference) -> Promise<Void>
    func registerFilmList(listener: FilmListUpdateListenerDelegate, forList: FilmListReference) -> Any
    
    // Friends
    
    func getFriends() -> Promise<Array<FriendReference>>
}


extension Backend {

    func getFilmList(ref: FilmListReference) -> Promise<FilmList> {
        if let x = ref as? FilmList { return Promise<FilmList>.value(x) }
        return self.getFilmList(id: ref.id)
    }

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



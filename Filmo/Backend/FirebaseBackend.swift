//
//  FirebaseBackend.swift
//  Filmo
//
//  Created by Benjamin Frost on 25/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation
import PromiseKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

protocol FirebaseInitialiser {
    func initialiseIfNeeded()
}

extension DatabaseReference {
    
    func setValuePromise(value: Any?) -> Promise<Void> {
        return Promise { seal in
            self.setValue(value) { (error, ref) in
                if let err = error {
                    seal.reject(err)
                    return
                } else {
                    seal.fulfill(())
                }
            }
        }
    }
    
    func removeValuePromise() -> Promise<Void> {
        return Promise { seal in
            self.removeValue(completionBlock: { (error, ref) in
                if let err = error {
                    seal.reject(err)
                    return
                } else {
                    seal.fulfill(())
                }
            })
        }
    }
}

extension DatabaseQuery {
    func observeSingleEventPromise<T>(of type: DataEventType) -> Promise<T> {
        return Promise { seal in
            self.observeSingleEvent(of: type, with: { (snapshot) in
                guard let x = snapshot.value as? T else {
                    seal.reject(BackendError.invalidPayload(snapshot))
                    return
                }
                seal.fulfill(x)
            }) { (error) in
                seal.reject(error)
            }
        }
    }
}

class DefaultFirebaseInitialiser: FirebaseInitialiser {
    
    lazy var hasInitialised: Bool = {
        FirebaseApp.configure()
        return true
    }()
 
    func initialiseIfNeeded() {
        let _ = self.hasInitialised
    }
}




class FirebaseBackend: Backend {
    
    
    

    
    
    lazy var database = Database.database().reference()
    
    init(initialiser: FirebaseInitialiser) {
        initialiser.initialiseIfNeeded()
    }
    
    func isUserLoggedIn() -> Guarantee<Bool> {
        return Guarantee<Bool>.value(Auth.auth().currentUser != nil)
    }
    
    func login(user: String, password: String) -> Promise<Void> {
        
        return Promise<Void> { seal in
            Auth.auth().signIn(withEmail: user, password: password, completion: { (result, error) in
                
                if let err = error {
                    seal.reject(err)
                }
                
                seal.fulfill(())
            })
        }
    }
    
    func logout() -> Promise<Void> {
        return Promise.from {
            try Auth.auth().signOut()
        }
    }
    
    func register(user: String, password: String) -> Promise<Void> {
        
        guard Auth.auth().currentUser == nil else {
            return Promise()
        }
        
        return Promise<Void> { seal in
            Auth.auth().createUser(withEmail: user, password: password, completion: { (result, error) in
                
                if let err = error {
                    seal.reject(err)
                }
                
                seal.fulfill(())
            })
        }
    }
    
    func deregister() -> Promise<Void> {
        
        guard let user = Auth.auth().currentUser else {
            return Promise.init(error: BackendError.notAuthenticated)
        }
        
        return Promise { (seal) in
            user.delete(completion: { (error) in
                if let err = error {
                    seal.reject(err)
                } else {
                    seal.fulfill(())
                }
            })
        }
    }



    
    func getSavedFilms() -> Promise<Array<String>> {
        
        guard let user = Auth.auth().currentUser else {
            return Promise.init(error: BackendError.notAuthenticated)
        }
        
        return database.child("filmList/\(user.uid)").observeSingleEventPromise(of: .value)
    }
    
    func save(film: String) -> Promise<Array<String>> {
        
        guard let user = Auth.auth().currentUser else {
            return Promise.init(error: BackendError.notAuthenticated)
        }
        
        return self.getSavedFilms().then { (films) -> Promise<Array<String>> in            
            let editedFilms = films + [film]
            
            return self.database.child("filmList/\(user.uid)").setValuePromise(value: editedFilms).map({ (_) -> [String] in
                editedFilms
            })
        }
    }
    
    func remove(film: String) -> Promise<Array<String>> {
        
        guard let user = Auth.auth().currentUser else {
            return Promise.init(error: BackendError.notAuthenticated)
        }
        
        return self.getSavedFilms().then { (films) -> Promise<Array<String>> in
            
            guard let i = films.index(of: film) else {
                return Promise<Array<String>>.value(films)
            }
            
            var editedFilms = films
            editedFilms.remove(at: i)

            return self.database.child("filmList/\(user.uid)").setValuePromise(value: editedFilms).map({ (_) -> [String] in
                return editedFilms
            })
        }
    }
    
    
    
    // GETS FILM REFERENCES
    
    func getFilmListReferences() -> Promise<Array<FilmListReference>> {
        
        guard let user = Auth.auth().currentUser else {
            return Promise.init(error: BackendError.notAuthenticated)
        }
        
        return database.child("members/\(user.uid)").observeSingleEventPromise(of: .value).map { (dictionary: [String: [String: Any]]) -> [FilmListReference] in
            return dictionary.map({ (id, values) -> FilmListReference in
                return FilmListReference(
                    id: id,
                    name: values["name"] as? String,
                    isOwner: values["owner"] as? Bool
                )
            })
        }
    }
    
    func getFilmList(id: String) -> Promise<FilmList> {
        
        guard let user = Auth.auth().currentUser else {
            return Promise.init(error: BackendError.notAuthenticated)
        }
        
        return database.child("filmLists/\(id)").observeSingleEventPromise(of: .value).map({ (dictionary: [String: Any]) -> FilmList in
            
            let filmReferences = (dictionary["films"] as? [String: Any])?.map({ (key, value) -> FilmReference in
                return FilmReference(id: key, name: value as? String)
            })
            
            return FilmList(
                id: id,
                name: dictionary["name"] as? String,
                owner: User(id: ""),
                members: [],
                films: filmReferences ?? []
            )
        })
    }
    
    
    
    func add(film: FilmReference, toList list: FilmListReference) -> Promise<Void> {
        // https://filmo-d8c5a.firebaseio.com/filmLists/111/films/tt0268126/name
        let value: Any = film.name ?? false
        return database.child("filmLists/\(list.id)/films/\(film.id)").setValuePromise(value: value)
    }
    
    func remove(film: FilmReference, fromList list: FilmListReference) -> Promise<Void> {
        return database.child("filmLists/\(list.id)/films/\(film.id))").removeValuePromise()
    }
    
    
}

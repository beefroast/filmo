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



extension Error {
    var isMissingSnapshotError: Bool {
        get {
            switch (self as? FirebaseBackendError) {
            case .some(.noSnapshotExists): return true
            default: return false
            }
        }
    }
}

enum FirebaseBackendError: Error {
    case noSnapshotExists
    case invalidPayload(Any?)
    case notAuthenticated
    case addedRecordMissingKey
}

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
                
                guard snapshot.exists() else {
                    seal.reject(FirebaseBackendError.noSnapshotExists)
                    return
                }
                
                guard let x = snapshot.value as? T else {
                    seal.reject(FirebaseBackendError.invalidPayload(snapshot))
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
            return Promise.init(error: FirebaseBackendError.notAuthenticated)
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
            return Promise.init(error: FirebaseBackendError.notAuthenticated)
        }
        
        return database.child("filmList/\(user.uid)").observeSingleEventPromise(of: .value)
    }
    
    func save(film: String) -> Promise<Array<String>> {
        
        guard let user = Auth.auth().currentUser else {
            return Promise.init(error: FirebaseBackendError.notAuthenticated)
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
            return Promise.init(error: FirebaseBackendError.notAuthenticated)
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
            return Promise.init(error: FirebaseBackendError.notAuthenticated)
        }
        
        return database.child("members/\(user.uid)").observeSingleEventPromise(of: .value).map { (dictionary: [String: [String: Any]]) -> [FilmListReference] in
            return dictionary.map({ (id, values) -> FilmListReference in
                return FilmListReference(
                    id: id,
                    name: values["name"] as? String,
                    owner: values["owner"] as? String
                )
            })
        }.recover({ (error) -> Guarantee<[FilmListReference]> in
            guard error.isMissingSnapshotError else { throw error }
            return Guarantee<[FilmListReference]>.value([])
        })
    }
    
    func getFilmList(id: String) -> Promise<FilmList> {
        
        guard let user = Auth.auth().currentUser else {
            return Promise.init(error: FirebaseBackendError.notAuthenticated)
        }
        
        return database.child("filmLists/\(id)").observeSingleEventPromise(of: .value).map({ (dictionary: [String: Any]) -> FilmList in
            
            let filmReferences = (dictionary["films"] as? [String: Any])?.map({ (key, value) -> FilmReference in
                return FilmReference(id: key, name: value as? String)
            })
            
            return FilmList(
                id: id,
                name: dictionary["name"] as? String,
                owner: dictionary["owner"] as? String,
                films: filmReferences
            )
        })
    }
    
    func createListWith(name: String) -> Promise<FilmListReference> {
        
        guard let user = Auth.auth().currentUser else {
            return Promise.init(error: FirebaseBackendError.notAuthenticated)
        }
        
        let databaseReference = database.child("filmLists").childByAutoId()
        
        let data = [
            "name": name,
            "owner": user.uid
        ]
        
        return databaseReference.setValuePromise(value: data).map({ () -> FilmListReference in
            
            guard let id = databaseReference.key else {
                throw FirebaseBackendError.addedRecordMissingKey
            }
            
            return FilmListReference(id: id, name: name, owner: user.uid)
        })
    }
    
    func delete(list: FilmListReference) -> Promise<Void> {
        return database.child("filmLists/\(list.id)").removeValuePromise()
    }
    
    func rename(list: FilmListReference, name: String) -> Promise<Void> {
        return database.child("filmLists/\(list.id)/name").setValuePromise(value: name)
    }
    
    func add(film: FilmReference, toList list: FilmListReference) -> Promise<Void> {
        // https://filmo-d8c5a.firebaseio.com/filmLists/111/films/tt0268126/name
        let value: Any = film.name ?? false
        return database.child("filmLists/\(list.id)/films/\(film.id)").setValuePromise(value: value)
    }
    
    func remove(film: FilmReference, fromList list: FilmListReference) -> Promise<Void> {
        return database.child("filmLists/\(list.id)/films/\(film.id)").removeValuePromise()
    }
    
    
    func getFriends() -> Promise<Array<FriendReference>> {
        
        guard let user = Auth.auth().currentUser else {
            return Promise.init(error: FirebaseBackendError.notAuthenticated)
        }
        
        return database.child("users/\(user.uid)/friends").observeSingleEventPromise(of: .value).map { (dict: [String: String]) -> [FriendReference] in
            return dict.map({ (id, name) -> FriendReference in
                FriendReference(id: id, name: name)
            })
        }

    }
    
    
}

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
    
    func observeSingleEventPromise<T>(of type: DataEventType) -> Promise<T> {
        return Promise { seal in
            self.observe(type, with: { (snapshot) in
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
    
    
    func login(user: String, password: String) -> Promise<Void> {
        
        guard Auth.auth().currentUser == nil else {
            return Promise()
        }
        
        return Promise<Void> { seal in
            Auth.auth().signIn(withEmail: user, password: password, completion: { (result, error) in
                
                if let err = error {
                    seal.reject(err)
                }
                
                seal.fulfill(())
            })
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
    
    
    func logout() -> Promise<Void> {
        return Promise.from {
            try Auth.auth().signOut()
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
    
    
    
}

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


extension EnumeratedSequence {
    
    func toDictionary<TKey: Hashable, TVal>(makeKey: ((Int, Base.Element) -> TKey), makeValue: ((Int, Base.Element) -> TVal)) -> [TKey: TVal] {
        var dict = [TKey: TVal]()
        self.forEach { (i, elt) in
            dict[makeKey(i, elt)] = makeValue(i, elt)
        }
        return dict
    }
}

extension DataSnapshot {
    
    func mapChildren<T>(_ fn: ((DataSnapshot) -> T)) -> [T] {
        return self.children.compactMap { (x) -> T? in
            guard let elt = x as? DataSnapshot else {
                return nil
            }
            return fn(elt)
        }
    }
    
    func compactMapChildren<T>(_ fn: ((DataSnapshot) -> T?)) -> [T] {
        return self.children.compactMap({ (x) -> T? in
            guard let elt = x as? DataSnapshot else {
                return nil
            }
            return fn(elt)
        })
    }
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
    

    
    func observeSingleEventPromise(of type: DataEventType) -> Promise<DataSnapshot> {
        return Promise { seal in
            self.observeSingleEvent(of: type, with: { (snapshot) in
                seal.fulfill(snapshot)
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



    

    
    
    
    
    // GETS FILM REFERENCES
    
    func getFilmListReferences() -> Promise<Array<FilmListReference>> {
        
        guard let user = Auth.auth().currentUser else {
            return Promise.init(error: FirebaseBackendError.notAuthenticated)
        }
        
        return database.child("members/\(user.uid)").observeSingleEventPromise(of: .value).map({ (snapshot) -> [FilmListReference] in
            
            return snapshot.mapChildren({ (s) -> FilmListReference in
                FilmListReference(
                    id: s.key,
                    name: s.childSnapshot(forPath: "name").value as? String,
                    owner: s.childSnapshot(forPath: "owner").value as? String
                )
            })
        })
    }
    
    func filmListFor(snapshot: DataSnapshot) -> FilmList {
        
        let name = snapshot.childSnapshot(forPath: "name").value as? String
        let owner = snapshot.childSnapshot(forPath: "owner").value as? String
        
        snapshot.childSnapshot(forPath: "films").children.forEach({ (x) in
            print(x)
        })
        
        return FilmList(
            id: snapshot.key,
            name: snapshot.childSnapshot(forPath: "name").value as? String,
            owner: snapshot.childSnapshot(forPath: "owner").value as? String,
            films: snapshot.childSnapshot(forPath: "films").compactMapChildren({ (snapshot) -> FilmReference? in
                guard let id = snapshot.childSnapshot(forPath: "filmId").value as? String else { return nil }
                return FilmReference(
                    id: id,
                    name: snapshot.childSnapshot(forPath: "name").value as? String
                )
            })
        )
    }
    
    func getFilmList(id: String) -> Promise<FilmList> {
        
        guard let user = Auth.auth().currentUser else {
            return Promise.init(error: FirebaseBackendError.notAuthenticated)
        }
        
        return database.child("filmLists/\(id)").observeSingleEventPromise(of: .value).map({ (snapshot: DataSnapshot) -> FilmList in
            return self.filmListFor(snapshot: snapshot)
        })
    }
    
    func update(filmList: FilmList) -> Promise<Void> {
        
        guard Auth.auth().currentUser != nil else {
            return Promise.init(error: FirebaseBackendError.notAuthenticated)
        }

        // Convert to a dictionary
        
        let dictionary: [String: Any] = [
            "name": filmList.name,
            "owner": filmList.owner,
            "films": filmList.films?.enumerated().toDictionary(makeKey: { (i, _) -> String in
                return "\(i)"
            }, makeValue: { (_, ref) -> [String: Any] in
                return [
                    "filmId": ref.id,
                    "name": ref.name
                ]
            })
        ]
        
        return database.child("filmLists/\(filmList.id)").setValuePromise(value: dictionary)
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

    func registerFilmList(listener: FilmListUpdateListenerDelegate, forList list: FilmListReference) -> Any {
        
        let handle = database.child("filmLists/\(list.id)").observe(.value, with: { [weak listener] (snapshot) in
            let filmList = self.filmListFor(snapshot: snapshot)
            listener?.onFilmListUpdated(filmList: filmList)
        }) { (error) in
            // TODO: Handle me
        }
        
        return DeathRattler(onDeath: {
            self.database.removeObserver(withHandle: handle)
        })
    }
    
    

    
    func getFriends() -> Promise<Array<FriendReference>> {
        
        guard let user = Auth.auth().currentUser else {
            return Promise.init(error: FirebaseBackendError.notAuthenticated)
        }

        return database.child("users/\(user.uid)/friends").observeSingleEventPromise(of: .value).map { (snapshot) -> [FriendReference] in
            return snapshot.mapChildren({ (snapshot) -> FriendReference in
                return FriendReference(
                    id: snapshot.key,
                    name: snapshot.value as? String
                )
            })
        }
    }
    
    
}


class DeathRattler {
    let onDeath: (() -> Void)
    init(onDeath: @escaping (() -> Void)) { self.onDeath = onDeath }
    deinit {
        self.onDeath()
    }
}

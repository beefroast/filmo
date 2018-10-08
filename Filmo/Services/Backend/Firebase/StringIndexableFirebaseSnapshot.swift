//
//  StringIndexableFirebaseSnapshot.swift
//  Filmo
//
//  Created by Benjamin Frost on 8/10/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation
import FirebaseDatabase
import PromiseKit

class StringIndexableFirebaseSnapshot: StringIndexable {
    
    let snapshot: DataSnapshot?
    
    init(snapshot: DataSnapshot? = nil) {
        self.snapshot = snapshot
    }
    
    var stringValue: String? {
        get { return snapshot?.value as? String }
    }
    
    func indexableChild(index: String) -> StringIndexable {
        return StringIndexableFirebaseSnapshot(snapshot: snapshot?.childSnapshot(forPath: index))
    }
    
    static func getDefault(firebaseInitialiser: FirebaseInitialiser) -> PromisedStringIndexable {
        
        firebaseInitialiser.initialiseIfNeeded()
        
        let getStringIndexable = Database.database().reference().child("strings").observeSingleEventPromise(of: .value).map { (snapshot) -> StringIndexableFirebaseSnapshot in
            StringIndexableFirebaseSnapshot(snapshot: snapshot)
        }
        
        return PromisedStringIndexable(promise: getStringIndexable.map({ $0 as StringIndexable }))
    }
}

class PromisedStringIndexable: StringIndexable {
    
    let backup: StringIndexable?
    let promise: Promise<StringIndexable>
    
    init(promise: Promise<StringIndexable>, backup: StringIndexable? = nil) {
        self.promise = promise
        self.backup = backup
    }
    
    var stringValue: String? {
        get { return self.promise.value?.stringValue ?? self.backup?.stringValue }
    }
    
    func indexableChild(index: String) -> StringIndexable {
        return self.promise.value?.indexableChild(index: index)
            ?? self.backup?.indexableChild(index: index)
            ?? self
    }
    
}



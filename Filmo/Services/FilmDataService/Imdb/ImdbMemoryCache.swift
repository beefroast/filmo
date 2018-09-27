//
//  ImdbMemoryCache.swift
//  Filmo
//
//  Created by Benjamin Frost on 24/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation
import PromiseKit


class ImdbMemoryCache: ImdbWrapper {
    
    var cachedFilms: [String: Promise<Film>] = [:]
    
    let filmCache: PromiseCache<String, Film>
    let personCache: PromiseCache<String, Person>
    
    override init(imdb: Imdb) {
        self.filmCache = PromiseCache()
        self.personCache = PromiseCache()
        super.init(imdb: imdb)
    }
    
    override func getFilmWith(id: String) -> Promise<Film> {
        return self.filmCache.getFromCache(input: id) { (id) -> Promise<Film> in
            super.getFilmWith(id: id)
        }
    }
    
    override func getPersonWith(id: String) -> Promise<Person> {
        return self.personCache.getFromCache(input: id, withMakePromise: { (id) -> Promise<Person> in
            super.getPersonWith(id: id)
        })
    }
    
}




class PromiseCache<TIn: Hashable, TOut> {
    
    fileprivate var cache: [TIn : Promise<TOut>] = [:]

    func getFromCache(input: TIn, withMakePromise: ((TIn) -> Promise<TOut>)) -> Promise<TOut> {
        
        // Return a non rejected promise
        if let result = cache[input] {
            if result.isRejected == false {
                return result
            }
        }
        
        // Make the promise, and stash it
        let promise = withMakePromise(input)
        cache[input] = promise
        
        // When the promise is done, replace it with just
        // a simple value promise...
        
        promise.done { [weak self] (value) in
            self?.cache[input] = Promise<TOut>.value(value)
        }.catch { [weak self] (error) in
            self?.cache[input] = nil
        }
        
        return promise
    }
    
}

extension Imdb {
    func withInMemoryCache() -> ImdbMemoryCache {
        return ImdbMemoryCache(imdb: self)
    }
}

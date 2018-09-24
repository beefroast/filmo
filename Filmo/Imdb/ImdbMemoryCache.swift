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
    
    override func getFilmWith(id: String) -> Promise<Film> {
        
        // Return a non rejected promise
        if let result = cachedFilms[id] {
            if result.isRejected == false {
                return result
            }
        }
        
        // Make the promise, and stash it
        let promise = super.getFilmWith(id: id)
        cachedFilms[id] = promise
        
        // When the promise is done, replace it with just
        // a simple value promise...
        
        promise.peek({ (film) in
            self.cachedFilms[id] = Promise<Film>.value(film)
        })
        
        return promise
    }
    
    override func getFilmTitlesMatching(search: String) -> Promise<Array<MediaSearchResult>> {
        return super.getFilmTitlesMatching(search: search)
    }
}

extension Imdb {
    func withInMemoryCache() -> ImdbMemoryCache {
        return ImdbMemoryCache(imdb: self)
    }
}

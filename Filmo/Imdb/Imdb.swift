//
//  Imdb.swift
//  Filmo
//
//  Created by Benjamin Frost on 24/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation
import PromiseKit

protocol Imdb {
    func getFilmWith(id: String) -> Promise<Film>
    func getFilmTitlesMatching(search: String) -> Promise<Array<MediaSearchResult>>
}

class ImdbWrapper: Imdb {
    
    let imdb: Imdb
    
    init(imdb: Imdb) {
        self.imdb = imdb
    }
    
    func getFilmWith(id: String) -> Promise<Film> {
        return imdb.getFilmWith(id: id)
    }
    
    func getFilmTitlesMatching(search: String) -> Promise<Array<MediaSearchResult>> {
        return imdb.getFilmTitlesMatching(search: search)
    }
}

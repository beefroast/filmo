//
//  FilmList.swift
//  Filmo
//
//  Created by Benjamin Frost on 25/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation


class FilmListReference {
    
    let id: String
    let name: String?
    let owner: String?
    
    init(
        id: String,
        name: String? = nil,
        owner: String? = nil) {
    
        self.id = id
        self.name = name
        self.owner = owner
    }
}


class FilmList: FilmListReference {
    
    let films: [FilmReference]?
    
    init(
        id: String,
        name: String? = nil,
        owner: String? = nil,
        films: [FilmReference]? = nil) {
        
        self.films = films
        super.init(
            id: id,
            name: name,
            owner: owner
        )
    }

    func with(name: String) -> FilmList {
        return FilmList(
            id: self.id,
            name: name,
            owner: self.owner,
            films: self.films
        )
    }
    
    func with(films: [FilmReference]) -> FilmList {
        return FilmList(
            id: self.id,
            name: self.name,
            owner: self.owner,
            films: films
        )
    }
    
    func byAdding(film: FilmReference) -> FilmList {
        return FilmList(
            id: self.id,
            name: self.name,
            owner: self.owner,
            films: self.films.map({ [film] + $0 }) ?? [film]
        )
    }
    
    func byRemoving(film: FilmReference) -> FilmList {
        return FilmList(
            id: self.id,
            name: self.name,
            owner: self.owner,
            films: self.films?.filter({ $0.id != film.id })
        )
    }

    
}







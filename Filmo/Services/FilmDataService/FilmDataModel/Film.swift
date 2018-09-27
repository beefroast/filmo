//
//  Film.swift
//  Filmo
//
//  Created by Benjamin Frost on 24/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation

class FilmReference {
    
    let id: String
    let name: String?
    
    init(
        id: String,
        name: String?) {
        
        self.id = id
        self.name = name
    }
}

class Film: FilmReference {
    
    let year: String?
    let released: String?
    let runtime: String?
    let genres: String?
    let directors: [PersonReference]?
    let writers: [PersonReference]?
    let stars: [PersonReference]?
    let language: String?
    let country: String?
    let awards: String?
    let rating: String?
    let imagePath: String?
    let resourcePath: String?
    let synopsis: String?
    
    init(
        id: String,
        name: String?,
        year: String? = nil,
        released: String? = nil,
        runtime: String? = nil,
        genres: String? = nil,
        directors: [PersonReference]? = nil,
        writers: [PersonReference]? = nil,
        stars: [PersonReference]? = nil,
        language: String? = nil,
        country: String? = nil,
        awards: String? = nil,
        rating: String? = nil,
        imagePath: String? = nil,
        resourcePath: String? = nil,
        synopsis: String? = nil) {
        
        self.year = year
        self.released = released
        self.runtime = runtime
        self.genres = genres
        self.directors = directors
        self.writers = writers
        self.stars = stars
        self.language = language
        self.country = country
        self.awards = awards
        self.rating = rating
        self.imagePath = imagePath
        self.resourcePath = resourcePath
        self.synopsis = synopsis
        
        super.init(
            id: id,
            name: name
        )
    }
    
}



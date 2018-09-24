//
//  Film.swift
//  Filmo
//
//  Created by Benjamin Frost on 24/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation

struct FilmReference {
    let id: String
    let name: String?
}

struct Film {
    let id: String
    let name: String?
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
}



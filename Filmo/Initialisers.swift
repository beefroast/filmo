//
//  Initialisers.swift
//  Filmo
//
//  Created by Benjamin Frost on 25/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation



let sharedImdbInstance = ImdbScraper.init(
    filmScraper: ImdbFilmScraper().typeErased()
).withInMemoryCache()

extension ImdbProvider {
    convenience init() {
        self.init(imdb: sharedImdbInstance)
    }
}

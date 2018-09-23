//
//  ImdbPageScraper.swift
//  Filmo
//
//  Created by Benjamin Frost on 22/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation
import Fuzi
import PromiseKit


protocol ImdbPageScraper {
    associatedtype ScrapedType
    func parse(document: HTMLDocument) throws -> ScrapedType
}

struct AnyScraper<T>: ImdbPageScraper {
    
    let _parse: (HTMLDocument) throws -> T
    
    init<U: ImdbPageScraper>(scraper: U) where U.ScrapedType == T {
        _parse = scraper.parse
    }
    
    func parse(document: HTMLDocument) throws -> T {
        return try _parse(document)
    }
}

extension ImdbPageScraper {
    func typeErased() -> AnyScraper<ScrapedType> {
        return AnyScraper(scraper: self)
    }
}

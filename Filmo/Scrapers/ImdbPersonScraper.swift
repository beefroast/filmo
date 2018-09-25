//
//  ImdbPersonScraper.swift
//  Filmo
//
//  Created by Benjamin Frost on 25/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation
import Fuzi

class ImdbPersonScraper: ImdbPageScraper {
    
    typealias ScrapedType = PersonFromId
    
    func parse(document: HTMLDocument) throws -> PersonFromId {
        
        let name = document.firstChild(xpath: "//*[@id=\"overview-top\"]/h1/span")?.stringValue
        let bio = document.firstChild(xpath: "//*[@id=\"name-bio-text\"]/div/div")?.stringValue
        
        // TODO: Remove hyperlinks from bio...
        
        let imageUrl = document.firstChild(xpath: "//*[@id=\"name-poster\"]")?.attr("src")
        
        
        return { (id) -> Person in
            Person(
                id: id,
                name: name,
                bio: bio,
                birthdate: nil,
                birthplace: nil,
                imageUrl: imageUrl,
                filmography: nil
            )
        }
    }
}

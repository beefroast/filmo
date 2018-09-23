//
//  ImdbFilmScraper.swift
//  Filmo
//
//  Created by Benjamin Frost on 22/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation
import Fuzi

class ImdbFilmScraper: ImdbPageScraper {

    typealias ScrapedType = ((String) -> Film)
    
    func parse(document: HTMLDocument) throws -> ((String) -> Film) {

        let namePath = "//*[@id=\"title-overview-widget\"]/div[2]/div[2]/div/div[2]/div[2]/h1"
        let yearPath = "//*[@id=\"titleYear\"]"
        let runTimePath = "//*[@id=\"title-overview-widget\"]/div[2]/div[2]/div/div[2]/div[2]/div[2]/time"
        let ratingPath = "//*[@id=\"title-overview-widget\"]/div[2]/div[2]/div/div[1]/div[1]/div[1]/strong/span"
        let synopsisPath = "//*[@id=\"title-overview-widget\"]/div[3]/div[1]/div[1]"
        let imagePath = "//*[@id=\"title-overview-widget\"]/div[2]/div[3]/div[1]/a/img"
        let resourcesPath = "//*[@id=\"title-overview-widget\"]/div[2]/div[3]/div[1]/a"
        let genrePath = "//*[@id=\"title-overview-widget\"]/div[2]/div[2]/div/div[2]/div[2]/div/a"
        
        let genres = document.xpath(genrePath).filter({ (xml) -> Bool in
            xml.attr("href")?.starts(with: "/genre") ?? false
        }).compactMap { (xml) -> String in
            xml.stringValue
        }.joined(separator: ", ")
        
        let resources = document.firstChild(xpath: resourcesPath).flatMap { (xml) -> String? in
            xml.attr("href")
        }
        
        return { (id) in
            return Film(
                id: id,
                name: document.firstChild(xpath: namePath)?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
                year: document.firstChild(xpath: yearPath)?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
                released: nil,
                runtime: document.firstChild(xpath: runTimePath)?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
                genres: genres,
                director: nil,
                writer: nil,
                language: nil,
                country: document.firstChild(xpath: ratingPath)?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
                awards: nil,
                rating: document.firstChild(xpath: ratingPath)?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
                imagePath: document.firstChild(xpath: imagePath)?.attr("src"),
                resourcePath: resources,
                synopsis: document.firstChild(xpath: synopsisPath)?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
    }
}

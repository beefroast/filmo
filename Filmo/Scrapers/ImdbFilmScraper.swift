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

        let ratingPath = "//*[@id=\"title-overview-widget\"]/div[2]/div[2]/div/div[1]/div[1]/div[1]/strong/span"
        let synopsisPath = "//*[@id=\"title-overview-widget\"]/div[3]/div[1]/div[1]"
        let imagePath = "//*[@id=\"title-overview-widget\"]/div[2]/div[3]/div[1]/a/img"
        let resourcesPath = "//*[@id=\"title-overview-widget\"]/div[2]/div[3]/div[1]/a"
        let genrePath = "//*[@id=\"title-overview-widget\"]/div[2]/div[2]/div/div[2]/div[2]/div/a"
        
        let name = document.firstChild(xpath: "//*[@id=\"title-overview-widget\"]/div[2]/div[2]/div/div[2]/div[2]/h1")?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let year = document.firstChild(xpath: "//*[@id=\"titleYear\"]")?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let released = document.firstChild(xpath: "//*[@id=\"title-overview-widget\"]/div[2]/div[2]/div/div[2]/div[2]/div/a[4]")?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let runtime = document.firstChild(xpath: "//*[@id=\"title-overview-widget\"]/div[2]/div[2]/div/div[2]/div[2]/div[2]/time")?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let genres = document.xpath(genrePath).filter({ (xml) -> Bool in
            xml.attr("href")?.starts(with: "/genre") ?? false
        }).compactMap { (xml) -> String in
            xml.stringValue
        }.joined(separator: ", ")
        
        let creditSummaryDivs = document.xpath("//*[@id=\"title-overview-widget\"]/div[3]/div[1]/div[@class=\"credit_summary_item\"]")
        
        var director: [PersonReference]? = nil
        var writer: [PersonReference]? = nil
        var stars: [PersonReference]? = nil
        
        creditSummaryDivs.forEach { (creditSummary) in
            
            print(creditSummary)
            
            guard let type = creditSummary.firstChild(xpath: "h4")?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            
            let hrefs = creditSummary.xpath("a")
            
            let people = hrefs.compactMap({ (element) -> PersonReference? in
                
                guard let ref = element.attr("href") else { return nil }
                guard let id = try? ref.firstGroupFromMatching(pattern: "/name/(.*)/.*") else { return nil }
                
                return PersonReference(
                    id: id,
                    name: element.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            })
            
            if type.lowercased().starts(with: "director") {
                director = people
            } else if type.lowercased().starts(with: "writer") {
                writer = people
            } else if type.lowercased().starts(with: "star") {
                stars = people
            }
        }
        
        let resources = document.firstChild(xpath: resourcesPath).flatMap { (xml) -> String? in
            xml.attr("href")
        }
        
        return { (id) in
            return Film(
                id: id,
                name: name,
                year: year,
                released: released,
                runtime: runtime,
                genres: genres,
                directors: director,
                writers: writer,
                stars: stars,
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

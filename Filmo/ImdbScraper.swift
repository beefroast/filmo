//
//  ImdbScraper.swift
//  Filmo
//
//  Created by Benjamin Frost on 22/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation
import PromiseKit
import Alamofire
import Fuzi
import WebKit





enum ScraperError: Error {
    case unknown
    case invalidQuery(String)
    case invalidUrlString(String)
    case cannotConvertDataToString(Data)
    case invalidRegexPattern(String)
    case noMatchingPattern
    case couldntGet(URLConvertible, Error)
}





protocol ImdbPageFinder {
    func getSearchPageWith(search: String) -> Promise<HTMLDocument>
    func getUrlFor(resource: String) -> Promise<URLConvertible>
}


class ImdbSearchPageFinder: ImdbPageFinder {
    
    let sessionManager: Alamofire.SessionManager
    
    init(sessionManager: Alamofire.SessionManager) {
        self.sessionManager = sessionManager
    }
    
    func getSearchUrlForResource(resource: String) throws -> URLConvertible {
        
        guard let query = resource.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw ScraperError.invalidQuery(resource)
        }
        
        let urlString = "https://www.imdb.com/find?&q=\(query)"
        guard let url = URL(string: urlString) else {
            throw ScraperError.invalidUrlString(urlString)
        }
        
        return url
    }
    
    func getSearchPageWith(search: String) -> Promise<HTMLDocument> {
        
        return Promise.from(fn: { try getSearchUrlForResource(resource: search) }).then { (url) in
            return self.sessionManager.requestPromise(url: url).recover({ (err) -> Guarantee<Data> in
                throw ScraperError.couldntGet(url, err)
            })
        }.map { (data) -> HTMLDocument in
            return try HTMLDocument(data: data)
        }
    }
    
    func getUrlFor(resource: String) -> Promise<URLConvertible> {
        
        return self.getSearchPageWith(search: resource).map { (document) -> URLConvertible in
            
            let path = "//*[@id=\"main\"]/div/div[2]/table/tr[1]/td[2]/a"
            
            guard let child = document.firstChild(xpath: path) else {
                throw ScraperError.unknown
            }
            
            guard let href = child.attr("href") else {
                throw ScraperError.unknown
            }
            
            return "https://www.imdb.com/" + href
        }
    }
    

}



typealias FilmFromId = ((String) -> Film)
typealias PersonFromId = ((String) -> Person)

class ImdbProvider {
    
    let imdb: Imdb
    
    init(imdb: Imdb) {
        self.imdb = imdb
    }
    
    func get() -> Imdb {
        return self.imdb
    }
}


class ImdbScraper: Imdb {

    
    
    let filmScraper: AnyScraper<FilmFromId>
    
    init(filmScraper: AnyScraper<FilmFromId>) {
        
        self.filmScraper = filmScraper
    }
    
    
    // TODO: Inject
    lazy var sessionManager = Alamofire.SessionManager(configuration: URLSessionConfiguration.default)
    lazy var searchPageFinder: ImdbPageFinder = ImdbSearchPageFinder(sessionManager: self.sessionManager)
    
    func getImdbPageFor(resource: String) -> Promise<HTMLDocument> {
        
        return self.searchPageFinder.getUrlFor(resource: resource).then { (imdbUrl) -> Promise<Data> in
            return self.sessionManager.requestPromise(url: imdbUrl).recover({ (err) -> Guarantee<Data> in
                throw ScraperError.couldntGet(imdbUrl, err)
            })
                
        }.map { (data) -> HTMLDocument in
            return try HTMLDocument(data: data)
        }
    }
    
    
    func getImdbPageForTitle(id: String) -> Promise<HTMLDocument> {
        // https://www.imdb.com/title/tt6998518
        return self.sessionManager.requestPromise(url: "https://www.imdb.com/title/\(id)").map { (data) -> HTMLDocument in
            return try HTMLDocument(data: data)
        }
    }
    
    func getImdbPageForPerson(id: String) -> Promise<HTMLDocument> {
        // https://www.imdb.com/name/nm0181903
        return self.sessionManager.requestPromise(url: "https://www.imdb.com/name/\(id)").map { (data) -> HTMLDocument in
            return try HTMLDocument(data: data)
        }
    }
    
    func getFilmWith(id: String) -> Promise<Film> {
        return self.getFilmWith(id: id, scraper: self.filmScraper)
    }
    
    func getFilmWith(id: String, scraper: AnyScraper<FilmFromId>) -> Promise<Film> {
        return self.getImdbPageForTitle(id: id).map { (document) -> Film in
            return try scraper.parse(document: document)(id)
        }
    }
    
    func getPersonWith(id: String) -> Promise<Person> {
        fatalError()
    }
    
    func getPersonWith(id: String, scraper: AnyScraper<PersonFromId>) -> Promise<Person> {
        return self.getImdbPageForPerson(id: id).map({ (document) -> Person in
            return try scraper.parse(document: document)(id)
        })
    }

    
    func getFilmTitlesMatching(search: String) -> Promise<Array<MediaSearchResult>> {
        
        return self.searchPageFinder.getSearchPageWith(search: search).map { (document) -> [MediaSearchResult] in
            
            let nodes = try document.tryXPath("//*[@id=\"main\"]/div/div")
            
            guard let titlesNode = nodes.first(where: { (xml) -> Bool in
                guard let h3 = xml.firstChild(xpath: "h3") else {
                    return false
                }
                return h3.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) == "Titles"
            }) else {
                return []
            }
            
            let tableRows = try titlesNode.tryXPath("table/tr")
            
            return try tableRows.compactMap({ (xml) -> MediaSearchResult? in
                
                let title = xml.firstChild(xpath: "td[2]/a")?.stringValue
                let fudge = xml.firstChild(xpath: "td[2]/a")?.attr("href")?.split(separator: "/")[1]
                let uuid = fudge.map({ String($0) })
                
                
                let pattern = "\\(([^\\)]+)\\)"
                
                if let yearAndType = xml.firstChild(xpath: "td[2]")?.stringValue {
                    let range = NSRange.init(location: 0, length: yearAndType.count)
                    let regex = try NSRegularExpression(pattern: pattern, options: [])
                    let results = regex.matches(in: yearAndType, options: [], range: range)
                    
                    let stringos = results.map({ (result) -> String in
                        let range = Range.init(result.range, in: yearAndType)
                        let x = yearAndType[range!]
                        return String(x)
                    })
                    
                    let year = stringos.first.map({
                        String($0.dropLast().dropFirst())
                    }) ?? ""
                    
                    let type = stringos.second.map({
                        String($0.dropLast().dropFirst())
                    }) ?? "Film"
                    
                    
                    return MediaSearchResult(
                        id: uuid ?? "",
                        title: title ?? "",
                        year: year,
                        type: type
                    )
                } else {
                    return MediaSearchResult(
                        id: uuid ?? "",
                        title: title ?? "",
                        year: "",
                        type: "")
                }
            })
        }
    }
    
    func getResource<T>(scraper: AnyScraper<T>, resource: String) -> Promise<T> {
        return self.getImdbPageFor(resource: resource).map { (document) -> T in
            return try scraper.parse(document: document)
        }
    }

    func getImageFor(resourcesPath: URLConvertible) -> Promise<UIImage> {
        
        let url = "https://imdb.com\(resourcesPath)"
        
        return self.sessionManager.requestPromise(url: url).map({ (data) -> HTMLDocument in
            return try HTMLDocument(data: data)
            
        }).map({ (document) -> String in
            
            guard let src = document.firstChild(xpath: "//*[@id=\"photo-container\"]/div/div[2]/div/div[2]/div[1]/div[2]/div/img[2]")?.attr("src") else {
                throw ScraperError.unknown
            }
            return src
            
        }).then { (imgPath) -> Promise<UIImage> in
            return UIImage.from(imagePath: imgPath)
        }
    }
    
    
    
}

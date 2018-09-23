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


struct Film {
    let id: String
    let name: String?
    let year: String?
    let released: String?
    let runtime: String?
    let genres: String?
    let director: String?
    let writer: String?
    let language: String?
    let country: String?
    let awards: String?
    let rating: String?
    let imagePath: String?
    let synopsis: String?
}




struct MediaSearchResult {
    let id: String
    let title: String
    let year: String
    let type: String
}

enum ScraperError: Error {
    case unknown
    case invalidQuery(String)
    case invalidUrlString(String)
    case cannotConvertDataToString(Data)
    case invalidRegexPattern(String)
    case noMatchingPattern
    case couldntGet(URLConvertible, Error)
}

extension Array {
    var second: Element? {
        get {
            guard self.count >= 2 else { return nil }
            return self[1]
        }
    }
}

extension Promise {
    
    static func from(fn: (() throws -> T)) -> Promise<T> {
        do {
            return Promise<T>.value(try fn())
        } catch {
            return Promise<T>.init(error: error)
        }
    }
    
    func guarantee() -> Guarantee<T?> {
        return self.map { (value) -> T? in
            return value
        }.recover { (_) -> Guarantee<T?> in
            return Guarantee.value(nil)
        }
    }
    
}

extension SessionManager {
    
    func requestPromise(url: URLConvertible, method: HTTPMethod = .get) -> Promise<Data> {
        return Promise<Data> { seal in
            self.request(url, method: method).validate().responseData(completionHandler: { (dataResponse) in
                
                if let error = dataResponse.error {
                    seal.reject(error)
                    return
                }
                
                seal.fulfill(dataResponse.data ?? Data())
            })
        }
    }

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






class ImdbScraper {
    
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
    
    func getFilmWith(id: String) -> Promise<Film> {
        return self.getFilmWith(id: id, scraper: ImdbFilmScraper().typeErased())
    }
    
    func getFilmWith(id: String, scraper: AnyScraper<((String) -> Film)>) -> Promise<Film> {
        return self.getImdbPageForTitle(id: id).map { (document) -> Film in
            return try scraper.parse(document: document)(id)
        }
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
                let uuid = xml.firstChild(xpath: "td[2]/a")?.attr("href")
                
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
    
    func filmDataFrom(htmlDocument: HTMLDocument) -> Film {
        
        fatalError()
        
        
    }
    
    
    
}

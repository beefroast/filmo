//
//  StringExtensions.swift
//  Filmo
//
//  Created by Benjamin Frost on 24/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation
import PromiseKit
import Alamofire

extension String {
    
    func firstGroupFromMatching(pattern: String) throws -> String {
        let range = NSRange.init(location: 0, length: self.count)
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        guard let match = regex.firstMatch(in: self, options: [], range: range) else {
            throw NSError(domain: "NSRegularExpression", code: 1234, userInfo: nil)
        }
        guard let swiftRange = Range.init(match.range(at: 1), in: self) else {
            throw NSError(domain: "NSRegularExpression", code: 4321, userInfo: nil)
        }
        return String(self[swiftRange])
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
    
    func peek(_ fn: @escaping (T) -> Void) -> Promise<T> {
        return self.map({ (value) -> T in
            fn(value)
            return value
        })
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


extension Array {
    var second: Element? {
        get {
            guard self.count >= 2 else { return nil }
            return self[1]
        }
    }
}






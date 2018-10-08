//
//  Initialisers.swift
//  Filmo
//
//  Created by Benjamin Frost on 25/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation
import UIKit


let sharedImdbInstance = ImdbScraper.init(filmScraper: ImdbFilmScraper().typeErased())
    .withInMemoryCache()

let firebaseInitialiser = DefaultFirebaseInitialiser()

let sharedBackend = FirebaseBackend(initialiser: firebaseInitialiser)

//        E37222
//        07889B
//        66B9BF
//        EEAA7B


let strings = Strings(content: StringIndexableFirebaseSnapshot.getDefault(firebaseInitialiser: firebaseInitialiser))

let sharedNodeStyler = FourColorStyler(
    headerFont: UIFont(name: "YeonSung-Regular", size: 40) ?? UIFont.systemFont(ofSize: 14),
    bodyFont: UIFont(name: "Lato-Light", size: 18)!,
    highlightABold: UIColor(hex: 0x07889B /*0xE372228*/),
    highlightBBold: UIColor(hex: 0x07889B),
    highlightALight: UIColor(hex: 0x66B9BF),
    highlightBLight: UIColor(hex: 0xEEAA7B),
    stringContentProvider: strings
)

extension ServiceProvider {
    convenience init() {
        self.init(
            backend: sharedBackend,
            imdb: sharedImdbInstance
        )
    }
}

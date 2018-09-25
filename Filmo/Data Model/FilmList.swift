//
//  FilmList.swift
//  Filmo
//
//  Created by Benjamin Frost on 25/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation

//"filmList": {
//    "filmListId": {
//        "name": "Watch List",
//        "owner": "ownerId",
//        "members": [
//        "memberId",
//        "anotherMemberId"
//        ],
//        "films": [
//        "filmId",
//        "anotherFilmId"
//        ]
//    }
//}

struct FilmList {
    let id: String
    let name: String?
    let owner: User
    let members: [User]
    let films: [FilmReference]
}


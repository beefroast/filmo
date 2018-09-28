//
//  FilmListUpdateListener.swift
//  Filmo
//
//  Created by Benjamin Frost on 28/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation


protocol FilmListUpdateListenerDelegate: AnyObject {
    func onFilmListUpdated(filmList: FilmList)
}

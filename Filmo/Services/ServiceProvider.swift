//
//  ServiceProvider.swift
//  Filmo
//
//  Created by Benjamin Frost on 25/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation




class ServiceProvider {
    
    let backend: Backend
    let imdb: Imdb
    
    init(backend: Backend,
         imdb: Imdb) {
        
        self.backend = backend
        self.imdb = imdb
    }
}

extension ServiceProvider {
    
    
    
}

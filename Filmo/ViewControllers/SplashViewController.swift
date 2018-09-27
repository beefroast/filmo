//
//  SplashViewController.swift
//  Filmo
//
//  Created by Benjamin Frost on 27/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()        
        ServiceProvider().backend.isUserLoggedIn().done { (loggedIn) in
            self.performSegue(withIdentifier: loggedIn ? "skipLogin" : "login", sender: self)
        }
    }
}

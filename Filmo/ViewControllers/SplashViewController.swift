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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {

            let backend = ServiceProvider().backend
            
            backend.isUserLoggedIn().done { (loggedIn) in
                
                guard loggedIn else {
                    self.performSegue(withIdentifier: "login", sender: self)
                    return
                }
                
                self.setupForLogin(sender: self)
            }
        }
    }
    
    func setupForLogin(sender: UIViewController) {
        
        let backend = ServiceProvider().backend

        backend.getFilmListReferences().reportProgress().done { (lists) in
            guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "main") as? MainTabBarViewController else { return }
            vc.lists = lists
            self.present(vc, animated: true, completion: nil)
        }.cauterize()
    }
    
    
}

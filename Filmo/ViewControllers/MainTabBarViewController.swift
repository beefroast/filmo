//
//  MainTabBarViewController.swift
//  Filmo
//
//  Created by Benjamin Frost on 27/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import UIKit

class MainTabBarViewController: UITabBarController {
    
    var lists: [FilmListReference]? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Setup the main page...
        
        let pages = [getMainPage()].compactMap({ $0 })
        self.setViewControllers(pages, animated: false)
    }
    
    func getMainPage() -> UIViewController? {
        
        guard let lists = self.lists,
            let nav = self.storyboard?.instantiateViewController(withIdentifier: "listNavStack") as? UINavigationController,
            let listListVc = nav.rootViewController() as? ListListViewController,
            let listVc = self.storyboard?.instantiateViewController(withIdentifier: "listViewController") as? ListViewController else { return nil }
        
        listListVc.lists = lists
        listListVc.title = "My Lists"
        
        guard let list = lists.first else {
            return nav
        }
        
        listVc.filmListPromise = ServiceProvider().backend.getFilmList(id: list.id)
        nav.pushViewController(listVc, animated: false)
        
        return nav
    }



}

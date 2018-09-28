//
//  MainTabBarViewController.swift
//  Filmo
//
//  Created by Benjamin Frost on 27/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import UIKit
import Toast_Swift



class MainTabBarViewController: UITabBarController, ListListViewControllerDelegate, FilmSearchViewControllerDelegate, FilmDetailsViewControllerDelegate {
    
    var lists: [FilmListReference]? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Setup the main page...
        
        let pages = [
            getMainPage(),
            getSearchPage(),
            getFriendsPage(),
            getSettingsPage()
            ].compactMap({ $0 })
        
        self.setViewControllers(pages, animated: false)
    }
    
    func getMainPage() -> UIViewController? {
        
        guard let lists = self.lists,
            let nav = self.storyboard?.instantiateViewController(withIdentifier: "listNavStack") as? UINavigationController,
            let listListVc = nav.rootViewController() as? ListListViewController,
            let listVc = self.storyboard?.instantiateViewController(withIdentifier: "listViewController") as? ListViewController else { return nil }
        
        listListVc.lists = lists
        listListVc.title = "My Lists"
        listListVc.delegate = self
        
        let button = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonSystemItem.add,
            target: listListVc,
            action: #selector(ListListViewController.onAddListPressed(sender:))
        )
        
        listListVc.navigationItem.setRightBarButton(button, animated: false)
        
        guard let list = lists.first else {
            return nav
        }
        
        listVc.filmListPromise = ServiceProvider().backend.getFilmList(id: list.id)
        nav.pushViewController(listVc, animated: false)
        
        return nav
    }
    
    func getSearchPage() -> UIViewController? {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "search")
        vc?.title = "Search"
        (vc as? FilmSearchViewController)?.delegate = self
        return vc.map({ UINavigationController(rootViewController: $0) })
    }
    
    func getFriendsPage() -> UIViewController? {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "friends")
        vc?.title = "Friends"
        return vc
    }
    
    func getSettingsPage() -> UIViewController? {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "settings")
        vc?.title = "Settings"
        return vc
    }
    
    // MARK: - ListListViewControllerDelegate
    
    func listList(viewController: ListListViewController, selectedList list: FilmListReference) {
        viewController.performSegue(withIdentifier: "showList", sender: list)
    }
    
    func listList(viewController: ListListViewController, decorateCell cell: ListListViewControllerTableViewCell, forList list: FilmListReference) {
        cell.accessoryType = .disclosureIndicator
    }
    
    func listList(viewController: ListListViewController, pressedAdd: UIBarButtonItem?) {
        
        let alertCon = UIAlertController(title: "Add List", message: nil, preferredStyle: .alert)
        
        alertCon.addTextField { (txt) in
            txt.placeholder = "Name"
        }
        
        alertCon.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            // Do nothing
        }))
        
        alertCon.addAction(UIAlertAction(title: "Add", style: .default, handler: { (action) in
            
            guard let name = alertCon.textFields?.first?.text else { return }
            
            ServiceProvider().backend.createListWith(name: name).lockView(view: self.view).reportProgress().done({ (list) in
                self.lists?.append(list)
                viewController.lists?.append(list)
            }).cauterize()
            
        }))
            
        viewController.present(alertCon, animated: true, completion: nil)
    }

    // MARK: - FilmSearchViewControllerDelegate
    
    func filmSelected(sender: FilmSearchViewController?, searchResult result: MediaSearchResult) {
        
        guard let vc = sender?.storyboard?.instantiateViewController(withIdentifier: "FilmDetails") as? FilmDetailsViewController else { return }
        
        vc.filmPromise = ServiceProvider().imdb.getFilmWith(id: result.id)
        vc.title = result.title
        vc.delegate = self
        
        sender?.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: FilmDetailsViewControllerDelegate

    func addButtonPressed(sender: FilmDetailsViewController?, button: UIButton?) {
        
        let alertCon = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        guard let film = sender?.filmPromise?.value else { return }
        
        alertCon.addAction(UIAlertAction(title: "Add to list", style: .default, handler: { [weak self] (action) in
           
            guard let vc = self?.storyboard?.instantiateViewController(withIdentifier: "ListList") as? ListListViewController else { return }
            
            vc.lists = self?.lists
            vc.title = "Select List"
            vc.delegate = ListListViewControllerClosureDelegate(onListSelected: { (vc, list) in
                ServiceProvider().backend.add(film: film, toList: list).lockView(view: vc.view).reportProgress().done({ (_) in
                    guard let vc = sender else { return }
                    vc.navigationController?.popToViewController(vc, animated: true)
                    try? vc.view.toastViewForMessage("\(film.name ?? "Film") added to \(list.name ?? "list")", title: "Added", image: nil, style: ToastStyle())
                }).cauterize()
            })
            
            sender?.navigationController?.pushViewController(vc, animated: true)
        }))
        
        alertCon.addAction(UIAlertAction(title: "Add to new list", style: .default, handler: { (action) in
            // TODO
        }))
        
        alertCon.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in  }))
        
        sender?.present(alertCon, animated: true, completion: nil)
    }
    
}

class ListListViewControllerClosureDelegate: ListListViewControllerDelegate {
    
    
    
    let onListSelected: ((ListListViewController, FilmListReference) -> Void)
    
    init(onListSelected: @escaping ((ListListViewController, FilmListReference) -> Void)) {
        self.onListSelected = onListSelected
    }
    
    func listList(viewController: ListListViewController, selectedList: FilmListReference) {
        self.onListSelected(viewController, selectedList)
    }
    
    func listList(viewController: ListListViewController, decorateCell: ListListViewControllerTableViewCell, forList: FilmListReference) {
        // Do nothing
    }
    
    func listList(viewController: ListListViewController, pressedAdd: UIBarButtonItem?) {
        // Do nothing
    }
}



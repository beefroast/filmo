//
//  ListListViewController.swift
//  Filmo
//
//  Created by Benjamin Frost on 27/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import UIKit

class ListListViewControllerTableViewCell: UITableViewCell {
    
    @IBOutlet weak var lblTitle: UILabel?
}

class ListListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView?
    
    var lists: [FilmListReference]? = nil {
        didSet {
            self.tableView?.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ServiceProvider().backend.getFilmListReferences().reportProgress().done { [weak self] (lists) in
            self?.lists = lists
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.lists?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let list = self.lists?[indexPath.row] else { return UITableViewCell() }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? ListListViewControllerTableViewCell else { return UITableViewCell() }
        
        cell.lblTitle?.text = list.name ?? list.id
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let list = self.lists?[indexPath.row] else { return }
        self.performSegue(withIdentifier: "showList", sender: list)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let vc = segue.destination as? ListViewController,
            let list = sender as? FilmListReference {
        
            vc.title = list.name
            vc.filmListPromise = ServiceProvider().backend.getFilmList(id: list.id)
        }
    }
    
    
    

 
}

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


protocol ListListViewControllerDelegate: AnyObject {
    func listList(viewController: ListListViewController, selectedList: FilmListReference)
    func listList(viewController: ListListViewController, decorateCell: ListListViewControllerTableViewCell, forList: FilmListReference)
    func listList(viewController: ListListViewController, pressedAdd: UIBarButtonItem?)
}

class ListListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView?
    
    var delegate: ListListViewControllerDelegate? = nil
    
    var lists: [FilmListReference]? = nil {
        didSet {
            self.tableView?.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.tableFooterView = UIView()
    }
    
    func listFor(indexPath: IndexPath) -> FilmListReference? {
        guard let lists = self.lists else { return nil }
        guard indexPath.row < lists.count else { return nil }
        return lists[indexPath.row]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.lists?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let list = self.listFor(indexPath: indexPath) else { return UITableViewCell() }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? ListListViewControllerTableViewCell else { return UITableViewCell() }
        
        cell.lblTitle?.text = list.name
        self.delegate?.listList(viewController: self, decorateCell: cell, forList: list)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView?.deselectRow(at: indexPath, animated: true)
        guard let list = self.listFor(indexPath: indexPath) else { return }
        self.delegate?.listList(viewController: self, selectedList: list)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        guard let list = self.listFor(indexPath: indexPath) else { return }
        
        switch editingStyle {
            
        case .delete:
            ServiceProvider().backend.delete(list: list).lockView(view: self.view).reportProgress().done { [weak self] (_) in
                self?.lists = self?.lists?.filter({ $0.id != list.id })
            }.cauterize()
            
        default: return
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let vc = segue.destination as? ListViewController,
            let list = sender as? FilmListReference {
        
            vc.title = list.name
            vc.filmListPromise = ServiceProvider().backend.getFilmList(id: list.id)
        }
    }
    
    
    @objc func onAddListPressed(sender: Any?) {
        self.delegate?.listList(viewController: self, pressedAdd: sender as? UIBarButtonItem)
    }
    
    
    

 
}

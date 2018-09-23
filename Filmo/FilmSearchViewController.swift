//
//  FilmSearchViewController.swift
//  Filmo
//
//  Created by Benjamin Frost on 23/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import UIKit
import PromiseKit

class FilmSearchViewControllerCell: UITableViewCell {
    @IBOutlet weak var lblTitle: UILabel?
    @IBOutlet weak var lblSynopsis: UILabel?
}


class PromiseDebouncer {
    
    enum DebouncerError: Error {
        case cancelled
    }
    
    let timeInterval: TimeInterval
  
    var currentWaitPromise: Guarantee<Void>? = nil
    
    init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }
    
    func debouncedPromise<T>(input: T) -> Promise<T> {
        
        let wait = self.waitPromise()
        self.currentWaitPromise = wait
        
        return wait.then({ [weak self] (_) -> Promise<T> in
            guard let this = self, this.currentWaitPromise === wait else {
                throw DebouncerError.cancelled
            }
            
            return Promise.value(input)
        })
    }
    
    func waitPromise() -> Guarantee<Void> {
        return Guarantee<Void> { fulfil in
            DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval, execute: {
                fulfil(())
            })
        }
    }
    
}

class FilmSearchViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {

    lazy var imdb = ImdbScraper()
    lazy var promiseDebouncer = PromiseDebouncer(timeInterval: 1.0)
    
    @IBOutlet var tableView: UITableView?
    @IBOutlet var searchBar: UISearchBar?
    
    var searchResults: [MediaSearchResult]? = nil {
        didSet {
            self.tableView?.reloadData()
        }
    }
    
    override func viewDidLoad() {
        self.tableView?.tableFooterView = UIView()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchResults?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? FilmSearchViewControllerCell else {
            return UITableViewCell()
        }
        
        guard let result = self.searchResults?[indexPath.row] else {
            return UITableViewCell()
        }
        
        cell.lblTitle?.text = result.title
        cell.lblSynopsis?.text = result.year + " " + result.type
        
        return cell
    }

    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let result = self.searchResults?[indexPath.row] else { return }
        guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "FilmDetails") as? FilmDetailsViewController else { return }
        
        vc.filmPromise = imdb.getFilmWith(id: result.id)
        vc.title = result.title
        
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.promiseDebouncer.debouncedPromise(input: searchText).then { (search) -> Promise<Array<MediaSearchResult>> in
            return self.imdb.getFilmTitlesMatching(search: search)
        }.done { (result) in
            self.searchResults = result
        }.cauterize()
    }
    
}

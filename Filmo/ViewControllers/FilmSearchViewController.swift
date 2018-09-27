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


protocol FilmSearchViewControllerDelegate {
    func filmSelected(sender: FilmSearchViewController?, searchResult: MediaSearchResult)
}

class FilmSearchViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, FilmSearchViewControllerDelegate {
    

    

    lazy var imdb = ServiceProvider().imdb
    lazy var promiseDebouncer = PromiseDebouncer(timeInterval: 1.0)
    var delegate: FilmSearchViewControllerDelegate? = nil
    
    
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var searchBar: UISearchBar?
    @IBOutlet weak var lblStatus: UILabel?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    
    var searchResults: [MediaSearchResult]? = nil {
        didSet {
            self.tableView?.reloadData()
        }
    }
    
    override func viewDidLoad() {
        self.tableView?.tableFooterView = UIView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.searchBar?.becomeFirstResponder()
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
        
        self.delegate?.filmSelected(sender: self, searchResult: result)
        
        
    }
    
    
    func filmSelected(sender: FilmSearchViewController?, searchResult result: MediaSearchResult) {
        
        guard let vc = sender?.storyboard?.instantiateViewController(withIdentifier: "FilmDetails") as? FilmDetailsViewController else { return }
        
        vc.filmPromise = imdb.getFilmWith(id: result.id)
        vc.title = result.title
        
        sender?.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    
    
    var currentPromise: Promise<Array<MediaSearchResult>>? = nil
    
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard text != "" else {
            self.lblStatus?.text = "Enter the name of a film to begin searching..."
            self.searchResults = nil
            self.activityIndicator?.stopAnimating()
            self.currentPromise = nil
            return
        }
        
        self.lblStatus?.text = nil
        
        let prom = self.promiseDebouncer.debouncedPromise(input: text).then { (search) -> Promise<Array<MediaSearchResult>> in
            self.activityIndicator?.startAnimating()
            self.searchResults = nil
            return self.imdb.getFilmTitlesMatching(search: search)
        }
        
        self.currentPromise = prom
        
        prom.done { (result) in
            
            guard self.currentPromise === prom else {
                throw PromiseDebouncer.DebouncerError.cancelled
            }
            
            self.activityIndicator?.stopAnimating()
            
            guard result.count > 0 else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Zero results for '\(searchText)'."])
            }
            
            self.searchResults = result
            
        }.catch { (err) in
            if let error = err as? PromiseDebouncer.DebouncerError {
                if error == PromiseDebouncer.DebouncerError.cancelled {
                    return
                }
            }
            self.lblStatus?.text = err.localizedDescription
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
}

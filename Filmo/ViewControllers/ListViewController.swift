//
//  ListViewController.swift
//  Filmo
//
//  Created by Benjamin Frost on 9/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import UIKit
import PromiseKit


class FilmTableViewCell: UITableViewCell {
    @IBOutlet weak var imgViewBackground: UIImageView?
    @IBOutlet weak var lblTitle: UILabel?
    @IBOutlet weak var lblDescription: UILabel?
}

struct FilmTableViewCellData {
    let id: String
    let name: Promise<String?>
    let descriptionPromise: Promise<String?>
    let imagePromise: Promise<UIImage?>
}


extension Result {
    var value: T? {
        get {
            switch self {
            case .fulfilled(let value): return value
            case .rejected(_): return nil
            }
        }
    }
}

extension UIImage {
    static func from(imagePath: String) -> Promise<UIImage> {
        return Promise<UIImage> { seal in
            DispatchQueue.global().async {
                do {
                    guard let url = URL(string: imagePath) else { throw ScraperError.unknown }
                    let data = try Data(contentsOf: url)
                    guard let image = UIImage(data: data) else { throw ScraperError.unknown }
                    seal.fulfill(image)
                } catch {
                    seal.reject(error)
                }
            }
        }
    }
}

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var getStartedView: UIView?

    lazy var imdb = ServiceProvider().imdb
    
    
    var filmListPromise: Promise<FilmList>? = nil {
        didSet {
            guard let prom = filmListPromise else {
                return
            }
            
            prom.reportProgress().done { [weak self] (list) in
                guard prom === self?.filmListPromise else { return }
                self?.title = list.name ?? self?.title
                self?.filmList = list.films
            }
        }
    }
    
    fileprivate var filmList: [FilmReference]? = nil {
        didSet {
            
            self.udpateGetStartedView()
            
            guard let films = self.filmList else { return }
            
            self.filmData = films.map({ (films) -> FilmTableViewCellData in
                self.cellDataForFilm(withId: films.id)
            })
        }
    }
    
    fileprivate var filmData: [FilmTableViewCellData]? = nil {
        didSet {
            self.tableView?.reloadData()
        }
    }
    
    func udpateGetStartedView() {
        guard let films = self.filmList else {
            self.getStartedView?.isHidden = true
            return
        }
        self.getStartedView?.isHidden = films.count > 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.separatorStyle = UITableViewCellSeparatorStyle.none
        self.udpateGetStartedView()
    }
    

    func cellDataForFilm(withId: String) -> FilmTableViewCellData {
        
        let getFilmPromise = imdb.getFilmWith(id: withId)
        
        let imagePromise = getFilmPromise.then { (film) -> Guarantee<UIImage?> in
            guard let path = film.imagePath else {
                return Guarantee<UIImage?>.value(nil)
            }
            return UIImage.from(imagePath: path).guarantee()
        }
        
        return FilmTableViewCellData(
            id: withId,
            name: getFilmPromise.map({ $0.name }),
            descriptionPromise: getFilmPromise.map({ $0.synopsis }),
            imagePromise: imagePromise
        )
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filmData?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? FilmTableViewCell else {
            return UITableViewCell()
        }
        
        cell.selectionStyle = .none
        
        guard let filmData = self.filmData?[indexPath.row] else {
            return cell
        }
        
        if let name = filmData.name.value {
            cell.lblTitle?.text = name
        } else {
            cell.lblTitle?.text = "Loading..."
            filmData.name.done({
                cell.lblTitle?.text = $0
                tableView.beginUpdates()
                tableView.endUpdates()
            }).catch { (error) in
                cell.lblDescription?.text = error.localizedDescription
            }
        }
        
        if let desc = filmData.descriptionPromise.value {
            cell.lblDescription?.text = desc
        } else {
            cell.lblDescription?.text = nil
            filmData.descriptionPromise.done({
                cell.lblDescription?.text = $0
                tableView.beginUpdates()
                tableView.endUpdates()
            }).catch { (error) in
                cell.lblDescription?.text = error.localizedDescription
            }
        }
        
        cell.imgViewBackground?.image = nil
        filmData.imagePromise.done({ cell.imgViewBackground?.image = $0 })
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vc = FilmDetailsViewController.filmDetailsViewController() else { return }
        guard let filmData = self.filmList?[indexPath.row] else { return }
        self.navigationController?.pushViewController(vc, animated: true)
        vc.title = filmData.name ?? vc.title
        vc.filmPromise = imdb.getFilmWith(id: filmData.id)
        
        vc.delegate = ViewFilmDetailsViewControllerDelegate(onDeleteFilm: { [weak self] (film) in
            
            guard let list = self?.filmListPromise?.value else { return }
            let listRef = FilmListReference(id: list.id, name: nil, owner: nil)
            let backend = ServiceProvider().backend
            
            backend.remove(film: film, fromList: listRef).reportProgress().done({ [weak self] () in
                guard let this = self else { return }
                this.navigationController?.popToViewController(this, animated: true)
            }).cauterize()
        })
    }
    
    @IBAction func onAddFilmPressed() -> Void {
        
        let delegate = AddFilmToListSearchViewControllerDelegate { [weak self] (film) in
            
            guard let list = self?.filmListPromise?.value else { return }
            
            let backend = ServiceProvider().backend
            let addFilm = backend.add(film: film, toList: FilmListReference(id: list.id, name: list.name, owner: nil))
            
            addFilm.reportProgress().done { [weak self] () in
                guard let this = self else { return }
                this.navigationController?.popToViewController(this, animated: true)
                this.filmList = this.filmList.map({ $0 + [film] })
            }.cauterize()
        }
        
        self.performSegue(withIdentifier: "search", sender: delegate)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? FilmSearchViewController {
            vc.delegate = sender as? FilmSearchViewControllerDelegate
        }
    }
    
}


class ViewFilmDetailsViewControllerDelegate: FilmDetailsViewControllerDelegate {
    
    let onDeleteFilm: ((FilmReference) -> Void)
    
    init(onDeleteFilm: @escaping ((FilmReference) -> Void)) {
        self.onDeleteFilm = onDeleteFilm
    }
    
    func addButtonPressed(sender: FilmDetailsViewController?, button: UIButton?) {
        guard let film = sender?.filmPromise?.value else { return }
        let filmRef = FilmReference(id: film.id, name: film.name)
        self.onDeleteFilm(filmRef)
    }
}

class AddFilmToListSearchViewControllerDelegate: FilmSearchViewControllerDelegate, FilmDetailsViewControllerDelegate {
    
    let onAddFilm: ((FilmReference) -> Void)
    
    init(onAddFilm: @escaping ((FilmReference) -> Void)) {
        self.onAddFilm = onAddFilm
    }
    
    func filmSelected(sender: FilmSearchViewController?, searchResult result: MediaSearchResult) {
        guard let vc = sender?.storyboard?.instantiateViewController(withIdentifier: "FilmDetails") as? FilmDetailsViewController else { return }
        
        vc.filmPromise = ServiceProvider().imdb.getFilmWith(id: result.id)
        vc.title = result.title
        vc.delegate = self
        
        sender?.navigationController?.pushViewController(vc, animated: true)
    }
    
    func addButtonPressed(sender: FilmDetailsViewController?, button: UIButton?) {
        guard let film = sender?.filmPromise?.value else { return }
        let filmRef = FilmReference(id: film.id, name: film.name)
        self.onAddFilm(filmRef)
    }
}











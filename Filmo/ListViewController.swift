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

    lazy var imdb = ServiceProvider().imdb
    
    var filmList: [FilmReference]? = nil {
        didSet {
            guard let films = self.filmList else { return }
            self.filmData = films.map({ (films) -> FilmTableViewCellData in
                self.cellDataForFilm(withId: films.id)
            })
        }
    }
    
    var filmData: [FilmTableViewCellData]? = nil {
        didSet {
            self.tableView?.reloadData()
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView?.separatorColor = UIColor.clear
        
        let backend = ServiceProvider().backend
        
        backend.login(user: "benjamin.frost.dev@gmail.com", password: "testpassword").then { () -> Promise<Array<FilmList>> in
            return backend.getFilmLists()
        }.done { (films) in
            print(films)
        }.catch { (error) in
            print("Error")
        }

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
        vc.filmPromise = imdb.getFilmWith(id: filmData.id)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

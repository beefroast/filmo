//
//  FilmDetailsViewController.swift
//  Filmo
//
//  Created by Benjamin Frost on 23/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit

protocol FilmDetailsViewControllerDelegate {
    func addButtonPressed(sender: FilmDetailsViewController?, button: UIButton?)
}

class FilmDetailsViewController: UIViewController {
    
    @IBOutlet weak var imgViewPoster: UIImageView?
    @IBOutlet weak var lblTitle: UILabel?
    @IBOutlet weak var lblSynopsis: UILabel?
    @IBOutlet weak var lblGenres: UILabel?
    @IBOutlet weak var lblDirector: UILabel?
    @IBOutlet weak var lblWriter: UILabel?
    @IBOutlet weak var lblStars: UILabel?
    @IBOutlet weak var lblLanguage: UILabel?
    @IBOutlet weak var lblCountry: UILabel?
    @IBOutlet weak var lblAwards: UILabel?
    @IBOutlet weak var lblRating: UILabel?
    @IBOutlet weak var lblRuntime: UILabel?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    
    var delegate: FilmDetailsViewControllerDelegate? = nil {
        didSet {
            // Enable the button
        }
    }
    
    lazy var imdb = ServiceProvider().imdb
    
    var optionalFields: [UILabel?] {
        get {
            return [
                self.lblGenres,
                self.lblDirector,
                self.lblWriter,
                self.lblStars,
                self.lblLanguage,
                self.lblCountry,
                self.lblAwards,
                self.lblRating,
                self.lblRuntime,
            ]
        }
    }
    
    var filmPromise: Promise<Film>? {
        didSet {
            let prom = self.filmPromise
            
            if prom != nil {
                self.activityIndicator?.startAnimating()
            } else {
                self.activityIndicator?.stopAnimating()
            }
            
            prom?.done({ [weak self] (film) in
                guard prom === self?.filmPromise else { return }
                self?.updateWithFilm(film: film)
            })
        }
    }
    
    var imagePromise: Promise<UIImage>? {
        didSet {
            let prom = self.imagePromise
            
            if prom != nil {
                self.activityIndicator?.startAnimating()
            } else {
                self.activityIndicator?.stopAnimating()
            }
            
            
            
            prom?.ensure({ [weak self] () -> Void in
                guard prom === self?.imagePromise else { return }
                self?.activityIndicator?.stopAnimating()
            }).done({ [weak self] (image) in
                self?.imgViewPoster?.image = image
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.optionalFields.compactMap({ $0?.superview }).forEach { (v) in
            v.isHidden = true
        }
        
        if let film = self.filmPromise?.value {
            self.updateWithFilm(film: film)
        } else {
            self.lblTitle?.text = nil
            self.lblSynopsis?.text = nil
        }
    }
    
    
    
    func updateWithFilm(film: Film) {
        
        self.lblTitle?.text = film.name
        self.lblSynopsis?.text = film.synopsis //, film.synopsis, film.synopsis].compactMap({ $0 }).joined(separator: "\n\n")
        self.lblSynopsis?.isHidden = (film.synopsis == nil)
        
        self.imagePromise = film.imagePath.map({ (path) -> Promise<UIImage> in
            return UIImage.from(imagePath: path)
        })
        
        self.setOrHide(label: self.lblGenres, value: film.genres)
        self.setOrHide(label: self.lblDirector, value: film.directors?.names)
        self.setOrHide(label: self.lblWriter, value: film.writers?.names)
        self.setOrHide(label: self.lblStars, value: film.stars?.names)
        self.setOrHide(label: self.lblLanguage, value: film.language)
        self.setOrHide(label: self.lblCountry, value: film.country)
        self.setOrHide(label: self.lblAwards, value: film.awards)
        self.setOrHide(label: self.lblRating, value: film.rating)
        self.setOrHide(label: self.lblRuntime, value: film.runtime)
    }
    
    func setOrHide(label: UILabel?, value: String?) {
        label?.text = value
        label?.superview?.isHidden = (value == nil)
    }
    
    @IBAction func onAddButtonPressed(sender: Any?) {
        self.delegate?.addButtonPressed(sender: self, button: sender as? UIButton)
    }
    
    static func filmDetailsViewController(storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)) -> FilmDetailsViewController? {
        return storyboard.instantiateViewController(withIdentifier: "FilmDetails") as? FilmDetailsViewController
    }
}

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

class FilmDetailsViewController: UIViewController {
    
    @IBOutlet weak var imgViewPoster: UIImageView?
    @IBOutlet weak var lblTitle: UILabel?
    @IBOutlet weak var lblSynopsis: UILabel?
    @IBOutlet weak var lblGenres: UILabel?
    @IBOutlet weak var lblDirector: UILabel?
    @IBOutlet weak var lblWriter: UILabel?
    @IBOutlet weak var lblLanguage: UILabel?
    @IBOutlet weak var lblCountry: UILabel?
    @IBOutlet weak var lblAwards: UILabel?
    @IBOutlet weak var lblRating: UILabel?
    @IBOutlet weak var lblRuntime: UILabel?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    
    var optionalFields: [UILabel?] {
        get {
            return [
                self.lblGenres,
                self.lblDirector,
                self.lblWriter,
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
            
            prom?.done({ [weak self] (image) in
                guard prom === self?.imagePromise else { return }
                self?.imgViewPoster?.image = image
                self?.activityIndicator?.stopAnimating()
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.optionalFields.compactMap({ $0?.superview }).forEach { (v) in
            v.isHidden = true
        }
        self.activityIndicator?.startAnimating()
        
        if let film = self.filmPromise?.value {
            self.updateWithFilm(film: film)
        } else {
            self.lblTitle?.text = nil
            self.lblSynopsis?.text = nil
        }
        
        // Testing
        self.filmPromise = imdb.getFilmWith(id: "tt6998518")
    }
    
    lazy var imdb = ImdbScraper()
    
    func updateWithFilm(film: Film) {
        
        self.lblTitle?.text = film.name
        self.lblSynopsis?.text = film.synopsis
        self.lblSynopsis?.isHidden = (film.synopsis == nil)
        
        self.imagePromise = film.imagePath.map({ (imagePath) -> Promise<UIImage> in
            return UIImage.from(imagePath: imagePath)
        })
        
        self.setOrHide(label: self.lblGenres, value: film.genres)
        self.setOrHide(label: self.lblDirector, value: film.director)
        self.setOrHide(label: self.lblWriter, value: film.writer)
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
}

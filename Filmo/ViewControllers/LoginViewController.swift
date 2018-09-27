//
//  LoginViewController.swift
//  Filmo
//
//  Created by Benjamin Frost on 27/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import UIKit
import PromiseKit

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var txtEmail: UITextField?
    @IBOutlet weak var txtPassword: UITextField?
    
    lazy var backend = ServiceProvider.init().backend
    

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.txtEmail?.becomeFirstResponder()
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let listRef = sender as? FilmListReference else { return }
        guard let vc = (segue.destination as? UITabBarController)?.viewControllers?.first?.rootViewController() as? ListViewController else { return }
        vc.filmListPromise = self.backend.getFilmList(id: listRef.id)
    }
    
    func attemptLogin() {
        
        guard let user = self.txtEmail?.text, let pass = self.txtPassword?.text else { return }
        
        
        
        let backend = self.backend
        
        backend.login(user: user, password: pass).recover { (error) -> Promise<Void> in
            
            // TODO: Maybe not auto register...
            return backend.register(user: user, password: pass)
        
        }.then({ () -> Promise<Array<FilmListReference>> in
            return backend.getFilmListReferences()
            
        }).reportProgress().done({ (filmLists) in
            let list = filmLists.first
            self.performSegue(withIdentifier: "mainScreen", sender: list)
            
        }).lockView(view: self.view).cauterize()
    }

    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === self.txtEmail {
            self.txtPassword?.becomeFirstResponder()
        } else if textField === self.txtPassword {
            self.attemptLogin()
        }
        return true
    }
    
}

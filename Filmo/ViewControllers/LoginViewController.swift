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
    
    override func viewDidLoad() {
        super.viewDidLoad()   
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.txtEmail?.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func attemptLogin() {
        
        guard let user = self.txtEmail?.text, let pass = self.txtPassword?.text else { return }
        
        self.backend.login(user: user, password: pass).recover { (error) -> Promise<Void> in
            // TODO: Maybe not auto register...
            return self.backend.register(user: user, password: pass)
        }.done { (_) in
            self.performSegue(withIdentifier: "mainScreen", sender: self)
        }.catch { (error) in
            // TODO: Handle this error!
        }
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

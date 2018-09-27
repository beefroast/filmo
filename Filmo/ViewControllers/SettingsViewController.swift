//
//  SettingsViewController.swift
//  Filmo
//
//  Created by Benjamin Frost on 27/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func logoutPressed(_ sender: Any) {
        
        guard let loginViewController = self.storyboard?.instantiateViewController(withIdentifier: "login") else {
            return
        }
        
        ServiceProvider().backend.logout().done { (_) in
            UIApplication.shared.keyWindow?.rootViewController = loginViewController
        }.cauterize()
    }
    
}

//
//  ListViewController.swift
//  Filmo
//
//  Created by Benjamin Frost on 9/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import UIKit


class FilmTableViewCell: UITableViewCell {
    @IBOutlet weak var imgViewBackground: UIImageView?
    @IBOutlet weak var lblTitle: UILabel?
    @IBOutlet weak var lblDescription: UILabel?
}


class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

            self.tableView?.separatorColor = UIColor.clear
        
        // Do any additional setup after loading the view.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? FilmTableViewCell else {
            return UITableViewCell()
        }
        
        cell.selectionStyle = .none
        
        let img = UIImage(named: "testImage\((indexPath.row % 2) == 1 ? "" : "2")")
        
        cell.imgViewBackground?.image = img
        
        cell.lblTitle?.text = (indexPath.row % 2) == 1
            ? "A Very Long Title For Testing Autoscaling Cells"
            : "Pigeo-bro"
        
        
//        let label = UILabel.init()
//        label.shadowOffset
//        label.shadowColor
//
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
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

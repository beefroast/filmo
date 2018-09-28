//
//  FriendsViewController.swift
//  Filmo
//
//  Created by Benjamin Frost on 28/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import UIKit

class FriendsViewControllerTableViewCell: UITableViewCell {
    @IBOutlet weak var lblName: UILabel?
}

class FriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView?
    
    var friends: [FriendReference]? {
        didSet {
            self.tableView?.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshFriends()
        self.tableView?.tableFooterView = UIView()
    }
    
    func refreshFriends() {
        ServiceProvider().backend.getFriends().reportProgress().done { (friends) in
            self.friends = friends
        }.cauterize()
    }
    
    func friendFor(indexPath: IndexPath) -> FriendReference? {
        guard let friends = self.friends else { return nil }
        guard indexPath.row < friends.count else { return nil }
        return friends[indexPath.row]
    }

    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.friends?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = self.tableView?.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? FriendsViewControllerTableViewCell else { return UITableViewCell() }
        
        guard let friend = self.friendFor(indexPath: indexPath) else { return UITableViewCell() }
        
        cell.lblName?.text = friend.name
        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        
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
    }

}

//
//  UIViewControllerExtensions.swift
//  Filmo
//
//  Created by Benjamin Frost on 27/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    func rootViewController() -> UIViewController? {
        if let nav = self as? UINavigationController {
            return nav.viewControllers.first
        }
        return self
    }
    
}

//
//  PromiseToastExtensions.swift
//  Filmo
//
//  Created by Benjamin Frost on 27/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation
import PromiseKit
import Toast_Swift

extension Promise {
    
    func lockView(view: UIView) -> Promise<T> {
        
        guard self.isResolved == false else { return self }
        
        view.endEditing(true)
        view.isUserInteractionEnabled = false
        
        return self.ensure({
            view.isUserInteractionEnabled = true
        })
    }
    
    func reportProgress(view: UIView? = UIApplication.shared.windows.first?.subviews.first) -> Promise<T> {
        
        guard let v = view else { return self }
        
        guard self.isResolved == false else { return self }
        
        v.makeToastActivity(.center)
        
        return self.ensure {
            v.hideToastActivity()
        }.recover({ (error) -> Promise<T> in
            v.makeToast(error.localizedDescription, duration: 3.0, position: .top, title: "Error", image: nil, style: ToastStyle(), completion: nil)
            throw error
        })
    }
    
}

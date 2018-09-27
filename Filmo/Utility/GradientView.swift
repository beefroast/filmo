//
//  GradientView.swift
//  Filmo
//
//  Created by Benjamin Frost on 9/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import UIKit

@IBDesignable class GradientView: UIView {

    @IBInspectable var topColor: UIColor? {
        didSet { self.setupGradient() }
    }
    
    @IBInspectable var bottomColor: UIColor? {
        didSet { self.setupGradient() }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupGradient()
    }
    
    lazy var gradient: CAGradientLayer = {
        let gradient = CAGradientLayer()
        self.layer.insertSublayer(gradient, at: 0)
        return gradient
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.gradient.frame = self.bounds
    }
    
    func setupGradient() {

        let top = self.topColor?.cgColor ?? UIColor.clear.cgColor
        let bottom = self.bottomColor?.cgColor ?? UIColor.clear.cgColor
        
        gradient.frame = self.bounds
        gradient.colors = [top, bottom]
        
    }
    
}

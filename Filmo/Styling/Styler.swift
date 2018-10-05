//
//  Styler.swift
//  Filmo
//
//  Created by Benjamin Frost on 27/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation
import UIKit

protocol Stylable {
    var style: String? { get set }
}

protocol Styler {
    func style(item: Any, withStyle: String?)
}

extension Styler {
    func style(item: Stylable) {
        self.style(item: item, withStyle: item.style)
    }
}

protocol TextColorable { func set(textColor: UIColor?) }
protocol BackgroundColorable { func set(backgroundColor: UIColor?) }
protocol BorderColorable { func set(borderColor: UIColor?) }
protocol FontChangable { func set(font: UIFont?) }

extension UIControlState {
    static var all: [UIControlState] {
        get { return [.disabled, .focused, .highlighted, .normal, .selected] }
    }
}

class StylableLabel: StringMappableLabel, Stylable, TextColorable, BackgroundColorable, FontChangable {
    
    @IBInspectable var style: String? { didSet { sharedNodeStyler.style(item: self) }}
    
    func set(textColor: UIColor?) {
        self.textColor = textColor ?? self.textColor
    }
    
    func set(backgroundColor: UIColor?) {
        self.backgroundColor = backgroundColor
    }
    
    func set(font: UIFont?) {
        self.font = font ?? self.font
    }
    
}

class StylableView: UIView, Stylable, BackgroundColorable {
    
    @IBInspectable var style: String? { didSet { sharedNodeStyler.style(item: self) }}
    
    func set(backgroundColor: UIColor?) {
        self.backgroundColor = backgroundColor
    }
}

class StylableButton: StringMappableButton, Stylable, TextColorable, BackgroundColorable, FontChangable {
    
    @IBInspectable var style: String? { didSet { sharedNodeStyler.style(item: self) }}
    
    func set(textColor: UIColor?) {
        UIControlState.all.forEach { self.setTitleColor(textColor, for: $0) }
    }
    
    func set(backgroundColor: UIColor?) {
        self.backgroundColor = backgroundColor
    }
    
    func set(font: UIFont?) {
        self.titleLabel?.font = font ?? self.titleLabel?.font
    }
}

class StylableTextField: StringMappableTextField, Stylable, TextColorable, BackgroundColorable, FontChangable {
    
    @IBInspectable var style: String? { didSet { sharedNodeStyler.style(item: self) }}
    
    func set(textColor: UIColor?) {
        self.textColor = textColor ?? self.textColor
    }
    
    func set(backgroundColor: UIColor?) {
        self.backgroundColor = backgroundColor
    }
    
    func set(font: UIFont?) {
        self.font = font
    }
}













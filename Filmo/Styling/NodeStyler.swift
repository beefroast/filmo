//
//  NodeStyler.swift
//  Filmo
//
//  Created by Benjamin Frost on 27/9/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation
import UIKit

class NodeStyler: Styler {
    
    let rootNode: StyleNode
    
    init(rootNode: StyleNode) {
        self.rootNode = rootNode
    }
    
    func style(item: Any, withStyle: String?) {
        guard let paths = withStyle?.components(separatedBy: "/") else { return }
        for path in paths {
            self.style(item: item, comps: path.components(separatedBy: "."))
        }
    }
    
    func style(item: Any, comps: [String]) {
        self.style(item: item, comps: comps, i: 0, node: rootNode)
    }
    
    func style(item: Any, comps: [String], i: Int, node: StyleNode) {
        node.style(item)
        guard i < comps.count else { return }
    
        guard let next = node.children[comps[i]] else { return }
        style(item: item, comps: comps, i: i+1, node: next)
    }
}

class StyleNode {
    
    let children: [String: StyleNode]
    let style: ((Any) -> Void)
    
    init(children: [String: StyleNode], style: @escaping ((Any) -> Void)) {
        self.children = children
        self.style = style
    }
    
    convenience init(style: @escaping ((Any) -> Void)) {
        self.init(children: [:], style: style)
    }
    
    convenience init() {
        self.init(children: [:]) { (_) in }
    }
    
    static func withStyle<T>(style: @escaping ((T) -> Void)) -> StyleNode {
        return StyleNode(children: [:], style: { (x) in
            guard let elt = x as? T else { return }
            style(elt)
        })
    }
    
    func addStyle<T>(style: @escaping ((T) -> Void)) -> StyleNode {
        return StyleNode(children: self.children, style: { (x) in
            self.style(x)
            guard let elt = x as? T else { return }
            style(elt)
        })
    }
    
    func withChild(_ name: String, make: (() -> StyleNode)) -> StyleNode {
        var c = self.children
        c[name] = make()
        return StyleNode(children: c, style: self.style)
    }
}

extension StyleNode {
    static func with(textColor: UIColor?) -> StyleNode {
        return StyleNode.withStyle(style: { (x: TextColorable) in
            x.set(textColor: textColor)
        })
    }
}

class FourColorStyler: NodeStyler {
    
    convenience init(
        headerFont: UIFont,
        bodyFont: UIFont,
        highlightABold: UIColor,
        highlightBBold: UIColor,
        highlightALight: UIColor,
        highlightBLight: UIColor,
        stringContentProvider: StringContentProvider) {
        
        self.init(
            rootNode: StyleNode.withStyle { (x: IStringMappable) in
                var elt = x
                elt.stringMapper = stringContentProvider
            }.withChild("h1") {
                StyleNode.withStyle { (x: FontChangable) in
                    x.set(font: headerFont.withSize(36))
                }
            }.withChild("h2") {
                StyleNode.withStyle { (x: FontChangable) in
                    x.set(font: headerFont.withSize(30))
                }
            }.withChild("p1") {
                StyleNode.withStyle { (x: FontChangable) in
                    x.set(font: bodyFont.withSize(16))
                }
            }.withChild("highlightA") {
                StyleNode.withStyle { (x: BackgroundColorable) in
                    x.set(backgroundColor: highlightABold)
                }
            }.withChild("white") {
                StyleNode.withStyle { (x: TextColorable) in
                    x.set(textColor: UIColor.white)
                }
            }
        )
    }
    
    
}


extension UIColor {
    
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(hex: Int) {
        self.init(
            red: (hex >> 16) & 0xFF,
            green: (hex >> 8) & 0xFF,
            blue: hex & 0xFF
        )
    }
}










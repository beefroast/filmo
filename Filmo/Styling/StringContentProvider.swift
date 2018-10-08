//
//  StringContent.swift
//  Filmo
//
//  Created by Benjamin Frost on 5/10/18.
//  Copyright © 2018 Benjamin Frost. All rights reserved.
//

import Foundation
import UIKit

protocol StringContentProvider {
    subscript(index: String) -> String? { get }
}



protocol StringIndexable {
    var stringValue: String? { get }
    func indexableChild(index: String) -> StringIndexable
}

//          NOTE: This doesn't quite work until conditional conformance
//extension Optional: StringIndexable where Wrapped == String {
//    var stringValue: String? { return self }
//    func indexableChild(index: String) -> StringIndexable { return Optional<String>.none }}
//
//
//extension Dictionary: StringIndexable where Key == String {
//    var stringValue: String? { return nil }
//    func indexableChild(index: String) -> StringIndexable { return self[index] as? StringIndexable ?? Optional<String>.none }
//}

enum StringContentNode {
    case none
    case leaf(String)
    case fork([String: StringContentNode])
}

extension StringContentNode: StringIndexable {
    
    var stringValue: String? {
        switch self {
        case .leaf(let x): return x
        default: return nil
        }
    }
    
    func indexableChild(index: String) -> StringIndexable {
        switch self {
        case .fork(let dict): return dict[index] ?? .none
        default: return self
        }
    }
}

class KeyRepeater: StringIndexable {
    
    let index: String?
    
    init(index: String? = nil) {
        self.index = index
    }
    
    var stringValue: String? { return index }
    
    func indexableChild(index: String) -> StringIndexable {
        return KeyRepeater(index: self.index.map({ "\($0).\(index)" }) ?? index)
    }
}

class StringIndexableBackup: StringIndexable {
    
    let primary: StringIndexable
    let backup: StringIndexable
    
    init(primary: StringIndexable, backup: StringIndexable) {
        self.primary = primary
        self.backup = backup
    }
    
    var stringValue: String? {
        get { return self.primary.stringValue ?? self.backup.stringValue }
    }
    
    func indexableChild(index: String) -> StringIndexable {
        return StringIndexableBackup(
            primary: self.primary.indexableChild(index: index),
            backup: self.backup.indexableChild(index: index)
        )
    }
}











protocol IStringMappable {
    var stringMapper: StringContentProvider? { get set }
}

extension IStringMappable {
    
    func valueForKey(key: String?) -> String? {
        guard let map = self.stringMapper,
            let key = key else { return nil }
        return map[key]
    }
}

class StringMappableLabel: UILabel, IStringMappable {
    
    var stringMapper: StringContentProvider? {
        didSet {
            guard let key = self.textKey else { return }
            self.text = self.stringMapper?[key]
        }
    }
    
    @IBInspectable var textKey: String? {
        didSet {
            guard let key = self.textKey else { return }
            self.text = self.stringMapper?[key]
        }
    }
}

extension UIButton {
    func setTitle(_ title: String?) {
        UIControlState.all.forEach { (state) in
            self.setTitle(title, for: state)
        }
    }
}

class StringMappableButton: UIButton, IStringMappable {
    
    var stringMapper: StringContentProvider? {
        didSet {
            guard let key = self.textKey else { return }
            self.setTitle(self.stringMapper?[key])
        }
    }
    
    @IBInspectable var textKey: String? {
        didSet {
            guard let key = self.textKey else { return }
            self.setTitle(self.stringMapper?[key])
        }
    }
}

class StringMappableTextField: UITextField, IStringMappable {
    
    var stringMapper: StringContentProvider? {
        didSet {
            guard let key = self.placeholderKey else { return }
            self.placeholder = self.stringMapper?[key]
        }
    }
    
    @IBInspectable var placeholderKey: String? {
        didSet {
            guard let key = self.placeholderKey else { return }
            self.placeholder = self.stringMapper?[key]
        }
    }
}













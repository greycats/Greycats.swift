//
//  FormField.swift
//  Greycats
//
//  Created by Rex Sheng on 2/5/16.
//  Copyright (c) 2016 Interactive Labs. All rights reserved.
//

import UIKit

public protocol FormFieldGroup: class {
    func validate() -> Bool
    func onChange(_ closure: @escaping (Bool) -> ()) -> Self
    func onSubmit(_ closure: @escaping () -> ()) -> Self
}

extension FormFieldGroup {
    public func bindButton(_ button: UIControl?) -> Self {
        weak var button = button
        return onChange { button?.isEnabled = $0 }
            .onSubmit { button?.sendActions(for: .touchUpInside) }
    }
}

class _FormFieldGroup: FormFieldGroup {
    var _onSubmit: (() -> ())?
    var _onChange: ((Bool) -> ())?
    let valid: () -> (Bool)
    
    fileprivate init(closure: @escaping () -> Bool) {
        valid = closure
    }
    
    func validate() -> Bool {
        let v = valid()
        _onChange?(v)
        return v
    }
    
    func onSubmit(_ closure: @escaping () -> ()) -> Self {
        _onSubmit = closure
        return self
    }
    
    func onChange(_ closure: @escaping (Bool) -> ()) -> Self {
        _onChange = closure
        let _ = validate()
        return self
    }
}

@IBDesignable
open class FormField: NibView, UITextFieldDelegate {
    
    @IBOutlet weak open var captionLabel: UILabel?
    @IBOutlet weak open var field: UITextField!
    @IBOutlet weak open var line: UIView!
    open var regex: Regex = ".*"
    @IBInspectable open var invalidErrorMessage: String?
    @IBOutlet weak open var redLine: UIView?
    @IBOutlet weak open var errorLabel: UILabel?
    @IBOutlet weak open var errorHeight: NSLayoutConstraint?
    @IBInspectable open var pattern: String = ".*" {
        didSet {
            if pattern == "EmailRegex" {
                regex = Regex.Email
            } else {
                regex = Regex(pattern)
            }
        }
    }
    
    @IBInspectable open var enabled: Bool {
        get { return field.isEnabled }
        set(value) { field.isEnabled = value }
    }
    
    weak var group: _FormFieldGroup?
    
    open var error: String? {
        didSet {
            if let error = error {
                errorHeight?.constant = 16
                redLine?.isHidden = false
                errorLabel?.isHidden = false
                errorLabel?.text = error
            } else {
                errorHeight?.constant = 0
                redLine?.isHidden = true
                errorLabel?.isHidden = true
            }
        }
    }
    var everEdited = false
    var onReturn: (() -> Bool)?
    fileprivate var triggers: [() -> ()] = []
    
    @IBAction func valueUpdated(_ sender: Any) {
        triggers.forEach { $0() }
        let _ = group?.validate()
    }
    
    open var handle: (UITextField) -> Bool = { _ in true }
    
    @IBAction func didBeginEditing(_ sender: Any) {
        everEdited = true
        triggers.forEach { $0() }
        let _ = group?.validate()
    }
    
    open func pass(_ validateText: String = "", reportError: Bool = true) -> Bool {
        let allowsError = everEdited == true && field.isFirstResponder == false
        let passed = (field.text ?? "") =~ regex
        if !passed {
            if allowsError && reportError {
                if !field.hasText {
                    error = "\(validateText)\(placeholder.lowercased()) is required."
                } else if let invalidMessage = invalidErrorMessage , invalidMessage.count > 0 {
                    error = invalidMessage.replacingOccurrences(of: ":value", with: field.text!)
                } else {
                    error = "Invalid \(validateText)\(placeholder.lowercased())."
                }
            } else {
                error = nil
            }
        }
        return passed
    }
    
    @IBInspectable open var secure: Bool = false {
        didSet {
            field.isSecureTextEntry = secure
            field.clearButtonMode = secure ? .never : .whileEditing
        }
    }
    
    open var text: String? {
        get {
            return field.text
        }
        set(value) {
            field.text = value
        }
    }
    
    @IBInspectable open var keyboardType: Int {
        get { return field.keyboardType.rawValue }
        set(value) {
            if let keyboardType = UIKeyboardType(rawValue: value) {
                field.keyboardType = keyboardType
            }
        }
    }
    
    @IBInspectable open var autocorrection: Int {
        get { return field.autocorrectionType.rawValue }
        set(value) {
            if let type = UITextAutocorrectionType(rawValue: value) {
                field.autocorrectionType = type
            }
        }
    }
    
    @IBInspectable open var autocapitalizationType: Int {
        get { return field.autocapitalizationType.rawValue }
        set(value) {
            if let type = UITextAutocapitalizationType(rawValue: value) {
                field.autocapitalizationType = type
            }
        }
    }
    
    @IBInspectable open var keyboardApperance: Int {
        get { return field.keyboardAppearance.rawValue }
        set(value) {
            if let type = UIKeyboardAppearance(rawValue: value) {
                field.keyboardAppearance = type
            }
        }
    }
    
    @IBInspectable open var placeholder: String = "Email Address" {
        didSet {
            if let captionLabel = captionLabel {
                captionLabel.text = placeholder
            } else {
                field.placeholder = placeholder
            }
        }
    }
    
    @IBInspectable open var textColor: UIColor? {
        didSet {
            field.textColor = textColor
        }
    }
    
    @IBInspectable open var lineColor: UIColor? {
        didSet {
            line.backgroundColor = lineColor
        }
    }
    
    open func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return handle(textField)
    }
    
    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return onReturn?() ?? true
    }
}

public protocol FormFieldData {
    mutating func parse(_ input: String)
    var text: String? { get }
    init()
}

extension String: FormFieldData {
    public mutating func parse(_ input: String) { self = input }
    public var text: String? { return self }
}

extension FormField {
    public func bind<T: FormFieldData>(_ value: UnsafeMutablePointer<T?>) {
        triggers.append {[weak self] in
            if let input = self?.text {
                if value.pointee == nil {
                    value.initialize(to: T())
                }
                value.pointee?.parse(input)
            }
        }
        field.text = value.pointee?.text
    }
}

extension Collection {
    public func every(closure: (Self.Iterator.Element) throws -> Bool) rethrows -> Bool {
        return try filter { try !closure($0) }.count == 0
    }
}

private var formKey: Void?

extension Collection where Iterator.Element: FormField, Index == Int {
    public func createForm(_ submitType: UIReturnKeyType = .send, validatePrefix: String = "", reportsError: Bool = true) -> FormFieldGroup {
        let group = _FormFieldGroup(closure: { self.every { $0.pass(validatePrefix, reportError: reportsError) } })
        let total = endIndex
        enumerated().forEach { index, item in
            item.group = group
            if index != total {
                weak var nextField = self[index + 1].field
                item.field.returnKeyType = .next
                item.onReturn = {
                    nextField?.becomeFirstResponder()
                    return true
                }
            } else {
                item.field.returnKeyType = submitType
                item.onReturn = {[weak item] in
                    guard let item = item, let group = item.group else {
                        return false
                    }
                    if group.valid() {
                        item.field.resignFirstResponder()
                        group._onSubmit?()
                        return true
                    } else {
                        return false
                    }
                }
            }
        }
        let _ = group.validate()
        return group
    }
    
    public func createForm(_ target: NSObjectProtocol, submitType: UIReturnKeyType = .send, validatePrefix: String = "", reportsError: Bool = true) -> FormFieldGroup {
        let group = createForm(submitType, validatePrefix: validatePrefix, reportsError: reportsError)
        objc_setAssociatedObject(target, &formKey, group, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return group
    }
}

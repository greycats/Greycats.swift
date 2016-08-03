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
    func onChange(closure: (Bool) -> ()) -> Self
    func onSubmit(closure: () -> ()) -> Self
}

extension FormFieldGroup {
    public func bindButton(button: UIControl?) -> Self {
        weak var button = button
        onChange { button?.enabled = $0 }
        onSubmit { button?.sendActionsForControlEvents(.TouchUpInside) }
        return self
    }
}

class _FormFieldGroup: FormFieldGroup {
    var _onSubmit: (() -> ())?
    var _onChange: ((Bool) -> ())?
    let valid: () -> (Bool)

    private init(closure: () -> Bool) {
        valid = closure
    }

    func validate() -> Bool {
        let v = valid()
        _onChange?(v)
        return v
    }

    func onSubmit(closure: () -> ()) -> Self {
        _onSubmit = closure
        return self
    }

    func onChange(closure: (Bool) -> ()) -> Self {
        _onChange = closure
        validate()
        return self
    }
}

@IBDesignable
public class FormField: NibView, UITextFieldDelegate {

    @IBOutlet weak public var captionLabel: UILabel?
    @IBOutlet weak public var field: UITextField!
    @IBOutlet weak public var line: UIView!
    public var regex: Regex = ".*"
    @IBInspectable public var invalidErrorMessage: String?
    @IBOutlet weak public var redLine: UIView?
    @IBOutlet weak public var errorLabel: UILabel?
    @IBOutlet weak public var errorHeight: NSLayoutConstraint?
    @IBInspectable public var pattern: String = ".*" {
        didSet {
            if pattern == "EmailRegex" {
                regex = Regex.Email
            } else {
                regex = Regex(pattern)
            }
        }
    }

    @IBInspectable public var enabled: Bool {
        get { return field.enabled }
        set(value) { field.enabled = value }
    }

    weak var group: _FormFieldGroup?

    public var error: String? {
        didSet {
            if let error = error {
                errorHeight?.constant = 16
                redLine?.hidden = false
                errorLabel?.hidden = false
                errorLabel?.text = error
            } else {
                errorHeight?.constant = 0
                redLine?.hidden = true
                errorLabel?.hidden = true
            }
        }
    }
    var everEdited = false
    var onReturn: (() -> Bool)?
    private var triggers: [() -> ()] = []

    @IBAction func valueUpdated(sender: AnyObject) {
        triggers.forEach { $0() }
        group?.validate()
    }

    public var handle: (UITextField) -> Bool = { _ in true }

    @IBAction func didBeginEditing(sender: AnyObject) {
        everEdited = true
        triggers.forEach { $0() }
        group?.validate()
    }

    public func pass(validateText: String = "", reportError: Bool = true) -> Bool {
        let allowsError = everEdited == true && field.isFirstResponder() == false
        let passed = field.text ?? "" =~ regex
        if !passed {
            if allowsError && reportError {
                if !field.hasText() {
                    error = "\(validateText)\(placeholder.lowercaseString) is required."
                } else if let invalidMessage = invalidErrorMessage where invalidMessage.characters.count > 0 {
                    error = invalidMessage.stringByReplacingOccurrencesOfString(":value", withString: field.text!)
                } else {
                    error = "Invalid \(validateText)\(placeholder.lowercaseString)."
                }
            } else {
                error = nil
            }
        }
        return passed
    }

    @IBInspectable public var secure: Bool = false {
        didSet {
            field.secureTextEntry = secure
            field.clearButtonMode = secure ? .Never : .WhileEditing
        }
    }

    public var text: String? {
        get {
            return field.text
        }
        set(value) {
            field.text = value
        }
    }

    @IBInspectable public var keyboardType: Int {
        get { return field.keyboardType.rawValue }
        set(value) {
            if let keyboardType = UIKeyboardType(rawValue: value) {
                field.keyboardType = keyboardType
            }
        }
    }

    @IBInspectable public var autocorrection: Int {
        get { return field.autocorrectionType.rawValue }
        set(value) {
            if let type = UITextAutocorrectionType(rawValue: value) {
                field.autocorrectionType = type
            }
        }
    }

    @IBInspectable public var autocapitalizationType: Int {
        get { return field.autocapitalizationType.rawValue }
        set(value) {
            if let type = UITextAutocapitalizationType(rawValue: value) {
                field.autocapitalizationType = type
            }
        }
    }

    @IBInspectable public var keyboardApperance: Int {
        get { return field.keyboardAppearance.rawValue }
        set(value) {
            if let type = UIKeyboardAppearance(rawValue: value) {
                field.keyboardAppearance = type
            }
        }
    }

    @IBInspectable public var placeholder: String = "Email Address" {
        didSet {
            if let captionLabel = captionLabel {
                captionLabel.text = placeholder
            } else {
                field.placeholder = placeholder
            }
        }
    }

    @IBInspectable public var textColor: UIColor? {
        didSet {
            field.textColor = textColor
        }
    }

    @IBInspectable public var lineColor: UIColor? {
        didSet {
            line.backgroundColor = lineColor
        }
    }

    public func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        return handle(textField)
    }

    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        return onReturn?() ?? true
    }
}

public protocol FormFieldData {
    mutating func parse(input: String)
    var text: String? { get }
    init()
}

extension String: FormFieldData {
    public mutating func parse(input: String) { self = input }
    public var text: String? { return self }
}

extension FormField {
    public func bind<T: FormFieldData>(value: UnsafeMutablePointer<T!>) {
        triggers.append {[weak self] _ in
            if let input = self?.text {
                if value.memory == nil {
                    value.initialize(T())
                }
                value.memory.parse(input)
            }
        }
        field.text = value.memory?.text
    }
}

extension CollectionType {
    public func every(@noescape closure: (Self.Generator.Element) throws -> Bool) rethrows -> Bool {
        return try filter { try !closure($0) }.count == 0
    }
}

private var formKey: Void?

extension CollectionType where Generator.Element: FormField, Index == Int {
    public func createForm(submitType: UIReturnKeyType = .Send, validatePrefix: String = "", reportsError: Bool = true) -> FormFieldGroup {
        let group = _FormFieldGroup(closure: { self.every { $0.pass(validatePrefix, reportError: reportsError) } })
        let total = count
        enumerate().forEach { index, item in
            item.group = group
            if index != total {
                weak var nextField = self[index + 1].field
                item.field.returnKeyType = .Next
                item.onReturn = {
                    nextField?.becomeFirstResponder()
                    return true
                }
            } else {
                item.field.returnKeyType = submitType
                item.onReturn = {[weak item] in
                    guard let item = item, group = item.group else {
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
        group.validate()
        return group
    }
    
    public func createForm(target: NSObjectProtocol, submitType: UIReturnKeyType = .Send, validatePrefix: String = "", reportsError: Bool = true) -> FormFieldGroup {
        let group = createForm(submitType, validatePrefix: validatePrefix, reportsError: reportsError)
        objc_setAssociatedObject(target, &formKey, group, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return group
    }
}
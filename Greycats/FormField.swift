//
//  FormField.swift
//  Greycats
//
//  Created by Rex Sheng on 2/5/16.
//  Copyright (c) 2016 Interactive Labs. All rights reserved.
//

public let EmailRegex = Regex("(?:[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}" +
	"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\" +
	"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-zA-Z0-9](?:[a-" +
	"zA-Z0-9-]*[a-zA-Z0-9])?\\.)+[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?|\\[(?:(?:25[0-5" +
	"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-" +
	"9][0-9]?|[a-zA-Z0-9-]*[a-zA-Z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21" +
	"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])")

@IBDesignable
public class FormField: NibView, UITextFieldDelegate {
	@IBOutlet weak public var captionLabel: UILabel?
	@IBOutlet weak public var field: UITextField!
	@IBOutlet weak public var line: UIView!
	public var regex: Regex = ".*"
	@IBOutlet weak public var redLine: UIView!
	@IBOutlet weak public var errorLabel: UILabel!
	@IBOutlet weak public var errorHeight: NSLayoutConstraint!
	@IBInspectable public var pattern: String = ".*" {
		didSet {
			if pattern == "EmailRegex" {
				regex = EmailRegex
			} else {
				regex = Regex(pattern)
			}
		}
	}

	public var error: String? {
		didSet {
			if let error = error {
				errorHeight.constant = 16
				redLine.hidden = false
				errorLabel.hidden = false
				errorLabel.text = error
			} else {
				errorHeight.constant = 0
				redLine.hidden = true
				errorLabel.hidden = true
			}
		}
	}
	var everEdited = false
	var onReturn: (() -> Bool)?
	private var triggerValidate: (() -> (Bool))?

	@IBAction func valueUpdated(sender: AnyObject) {
		triggerValidate?()
	}

	public var handle: (UITextField) -> Bool = { _ in return true }

	@IBAction func didBeginEditing(sender: AnyObject) {
		everEdited = true
		triggerValidate?()
	}

	public func pass(validateText: String = "", reportError: Bool = true) -> Bool {
		let allowsError = everEdited == true && field.isFirstResponder() == false
		let passed = field.text ?? "" =~ regex
		if !passed {
			if allowsError && reportError {
				if !field.hasText() {
					error = "\(validateText)\(placeholder.lowercaseString) is required."
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

public protocol TextValueFieldContainer {
	var containingField: UITextField? { get }
}

extension FormField: TextValueFieldContainer {
	public var containingField: UITextField? { return field }
}

extension UITextField {
	public func nextField<T: CollectionType where T.Generator.Element: TextValueFieldContainer>(options: T) -> UITextField? {
		var g = options.generate()
		while let o = g.next() {
			if o.containingField == self {
				return g.next()?.containingField
			}
		}
		return nil
	}
}

public class FormFieldGroup {
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

	public func onSubmit(closure: () -> ()) -> Self {
		_onSubmit = closure
		return self
	}

	public func onChange(closure: (Bool) -> ()) -> Self {
		_onChange = closure
		validate()
		return self
	}

	public func bindButton(button: UIControl?) -> Self {
		weak var button = button
		return onChange { valid in
			button?.enabled = valid
		}.onSubmit {
			button?.sendActionsForControlEvents(.TouchUpInside)
		}
	}
}

private var formKey: Void?
extension CollectionType where Generator.Element: FormField, Index == Int {
	public func createForm(target: NSObjectProtocol, submitType: UIReturnKeyType = .Send, validatePrefix: String = "", reportsError: Bool = true) -> FormFieldGroup {
		let group = FormFieldGroup {
			return self.filter { !$0.pass(validatePrefix, reportError: reportsError) }.count == 0
		}
		for item in self {
			item.triggerValidate = {[weak group] in
				return group?.validate() ?? false
			}
			if let next = item.field.nextField(self) {
				item.field.returnKeyType = .Next
				item.onReturn = {
					next.becomeFirstResponder()
					return true
				}
			} else {
				item.field.returnKeyType = submitType
				let field = item.field
				item.onReturn = {[weak group] in
					guard let this = group else { return false }
					if this.valid() {
						field.resignFirstResponder()
						this._onSubmit?()
						return true
					} else {
						return false
					}
				}
			}
		}
		group.validate()
		objc_setAssociatedObject(target, &formKey, group, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		return group
	}
}
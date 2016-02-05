//
//  Keyboard.swift
//  Greycats
//
//  Created by Rex Sheng on 2/5/16.
//  Copyright (c) 2016 Interactive Labs. All rights reserved.
//
// available in pod 'Greycats', '~> 2.3.0'

public protocol KeyboardResponder: NSObjectProtocol {
	var keyboardHeight: NSLayoutConstraint! { get }
	func keyboardWillChange(notif: NSNotification)
}

public protocol AutoFocus: NSObjectProtocol {
	func activeField() -> UIView?
	func scrollingView() -> UIScrollView?
}

private protocol _KeyboardResponder: AnyObject {
	var gc_view: UIView! { get }
}

private var observerKey: Void?

extension KeyboardResponder {
	public func registerKeyboard() {
		let observer = NSNotificationCenter.defaultCenter().addObserverForName(UIKeyboardWillChangeFrameNotification, object: nil, queue: .mainQueue()) {[weak self] notif in
				self?.keyboardWillChange(notif)
		}
		unregisterKeyboard()
		objc_setAssociatedObject(self, &observerKey, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
	}

	public func unregisterKeyboard() {
		if let observer = objc_getAssociatedObject(self, &observerKey) {
			NSNotificationCenter.defaultCenter().removeObserver(observer, name: UIKeyboardWillChangeFrameNotification, object: nil)
		}
	}

	private func _keyboardWillChange(notif: NSNotification, view: UIView) {
		if let info = notif.userInfo {
			var kbRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
			kbRect = view.convertRect(kbRect, fromView: view.window)
			let height = view.bounds.size.height - kbRect.origin.y
			if let constraint = keyboardHeight {
				if constraint.constant != height {
					print(notif)
					print("height to bottom layout = \(height)")
					view.layoutIfNeeded()
					constraint.constant = height
					UIView.animateWithDuration(info[UIKeyboardAnimationDurationUserInfoKey] as! NSTimeInterval, delay: 0, options: UIViewAnimationOptions(rawValue: info[UIKeyboardAnimationCurveUserInfoKey] as! UInt), animations: {
						view.layoutIfNeeded()
						}, completion: nil)
				}
				return
			}
			if let this = self as? AutoFocus,
				scrollView = this.scrollingView() {
					let insets = UIEdgeInsetsMake(0, 0, height, 0)
					scrollView.contentInset = insets
					scrollView.scrollIndicatorInsets = insets
					if let field = this.activeField() {
						let frame = field.convertRect(field.bounds, toView: view)
						scrollView.scrollRectToVisible(frame, animated: true)
					}
			}
		}
		UIView.setAnimationsEnabled(true)
	}
}

extension KeyboardResponder where Self: UIView {
	public func keyboardWillChange(notif: NSNotification) {
		_keyboardWillChange(notif, view: self)
	}
}

extension KeyboardResponder where Self: UIViewController {
	public func keyboardWillChange(notif: NSNotification) {
		_keyboardWillChange(notif, view: view)
	}
}
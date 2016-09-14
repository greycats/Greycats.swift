//
//  Keyboard.swift
//  Greycats
//
//  Created by Rex Sheng on 2/5/16.
//  Copyright (c) 2016 Interactive Labs. All rights reserved.
//
// available in pod 'Greycats', '~> 2.3.0'

import UIKit

public protocol KeyboardResponder: NSObjectProtocol {
	var keyboardHeight: NSLayoutConstraint! { get }
	func keyboardWillChange(_ notif: Notification)
	func keyboardHeightDidUpdate(_ height: CGFloat)
}

public protocol AutoFocus: NSObjectProtocol {
	func activeField() -> UIView?
	func scrollingView() -> UIScrollView?
}

private var observerKey: Void?

extension KeyboardResponder {
	public func keyboardHeightDidUpdate(_ height: CGFloat) {

	}

	public func registerKeyboard() {
		let observer = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil, queue: .main) { [weak self] notif in
				self?.keyboardWillChange(notif)
		}
		unregisterKeyboard()
		objc_setAssociatedObject(self, &observerKey, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
	}

	public func unregisterKeyboard() {
		if let observer = objc_getAssociatedObject(self, &observerKey) {
			NotificationCenter.default.removeObserver(observer, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
		}
	}

	fileprivate func _keyboardWillChange(_ notif: Notification, view: UIView) {
		if let info = (notif as NSNotification).userInfo {
			var kbRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
			kbRect = view.convert(kbRect, from: view.window)
			let height = view.bounds.size.height - kbRect.origin.y
			if let constraint = keyboardHeight {
				if constraint.constant != height {
					print(notif)
					print("height to bottom layout = \(height)")
					keyboardHeightDidUpdate(height)
					view.layoutIfNeeded()
					constraint.constant = height
					UIView.animate(withDuration: info[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval, delay: 0, options: UIViewAnimationOptions(rawValue: info[UIKeyboardAnimationCurveUserInfoKey] as! UInt), animations: {
						view.layoutIfNeeded()
						}, completion: nil)
				}
				return
			}
			if let this = self as? AutoFocus,
				let scrollView = this.scrollingView() {
					let insets = UIEdgeInsetsMake(0, 0, height, 0)
					scrollView.contentInset = insets
					scrollView.scrollIndicatorInsets = insets
					if let field = this.activeField() {
						let frame = field.convert(field.bounds, to: view)
						scrollView.scrollRectToVisible(frame, animated: true)
					}
			}
		}
		UIView.setAnimationsEnabled(true)
	}
}

extension KeyboardResponder where Self: UIView {
	public func keyboardWillChange(_ notif: Notification) {
		_keyboardWillChange(notif, view: self)
	}
}

extension KeyboardResponder where Self: UIViewController {
	public func keyboardWillChange(_ notif: Notification) {
		_keyboardWillChange(notif, view: view)
	}
}

//
//  Keyboard.swift
//  Greycats
//
//  Created by Rex Sheng on 2/5/16.
//  Copyright (c) 2016 Interactive Labs. All rights reserved.
//
// available in pod 'Greycats', '~> 2.3.0'

import UIKit

public protocol KeyboardResponder {
    func keyboardHeight() -> NSLayoutConstraint?
    func keyboardWillChange(_ notif: Notification)
    func keyboardHeightDidUpdate(_ height: CGFloat)
}

public protocol AutoFocus {
    func activeField() -> UIView?
    func scrollingView() -> UIScrollView?
}

private var observerKey: Void?

extension KeyboardResponder where Self: UIViewController {

    public func keyboardHeight() -> NSLayoutConstraint? {
        return nil
    }

    public func keyboardHeightDidUpdate(_ height: CGFloat) {
    }

    public func registerKeyboard() {
        let observer = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main) { [weak self] notif in
            self?.keyboardWillChange(notif)
        }
        unregisterKeyboard()
        objc_setAssociatedObject(self, &observerKey, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    public func unregisterKeyboard() {
        if let observer = objc_getAssociatedObject(self, &observerKey) {
            NotificationCenter.default.removeObserver(observer, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        }
    }

    public func keyboardWillChange(_ notif: Notification) {
        _keyboardWillChange(notif, view: view)
    }

    fileprivate func _keyboardWillChange(_ notif: Notification, view: UIView) {
        if let info = (notif as NSNotification).userInfo {
            var kbRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            kbRect = view.convert(kbRect, from: view.window)
            let height = view.bounds.size.height - kbRect.origin.y
            if let constraint = keyboardHeight() {
                if constraint.constant != height {
                    print("Bottom layout constant = \(height)")
                    keyboardHeightDidUpdate(height)
                    view.layoutIfNeeded()
                    constraint.constant = height
                    UIView.animate(withDuration: info[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval, delay: 0, options: UIView.AnimationOptions(rawValue: info[UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt), animations: {
                        view.layoutIfNeeded()
                        }, completion: nil)
                }
                return
            }
            if let this = self as? AutoFocus,
                let scrollView = this.scrollingView() {
                let insets = UIEdgeInsets(top: 0, left: 0, bottom: height, right: 0)
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

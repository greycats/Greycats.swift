//
//  ReactControls.swift
//	Greycats
//
//  Created by Rex Sheng on 7/1/15.
//  Copyright (c) 2016 Interactive Labs. All rights reserved.
//

import UIKit

@available(*, deprecated=2.7, message="in favor of UIButton.svg")
public class ReactControls: NSObject {
	weak var a: UIControl!
	weak var b: UIControl!
	public init(a: UIControl, b: UIControl) {
		super.init()
		self.a = a
		self.b = b
		a.addTarget(self, action: #selector(sendBTouchUpInside), forControlEvents: .TouchUpInside)
		a.addObserver(self, forKeyPath: "highlighted", options: .New, context: nil)
		b.addObserver(self, forKeyPath: "highlighted", options: .New, context: nil)
	}
	
	func sendBTouchUpInside() {
		b.sendActionsForControlEvents(.TouchUpInside)
	}
	
	deinit {
		a.removeObserver(self, forKeyPath: "highlighted")
		b.removeObserver(self, forKeyPath: "highlighted")
	}
	
	override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		if keyPath == "highlighted" {
			if object as? UIControl == a {
				b.highlighted = a.highlighted
			} else {
				if b.highlighted {
					UIView.animateWithDuration(0.02) {
						self.a.alpha = 0.2
					}
				} else {
					UIView.animateWithDuration(0.02, delay: 0.04, options: [], animations: {
						self.a.alpha = 1
						}, completion: nil)
				}
			}
		} else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
		}
	}
}

@available(*, deprecated=2.7, message="in favor of UIButton.svg")
public func +(lhs: UIControl?, rhs: UIControl?) -> AnyObject? {
	if let a = lhs, let b = rhs {
		return ReactControls(a: a, b: b)
	}
	return nil
}
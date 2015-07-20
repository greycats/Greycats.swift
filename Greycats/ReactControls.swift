//
//  ReactControls.swift
//  Trusted
//
//  Created by Rex Sheng on 7/1/15.
//  Copyright (c) 2015 Trusted. All rights reserved.
//

import UIKit

public class ReactControls: NSObject {
	weak var a: UIControl!
	weak var b: UIControl!
	public init(a: UIControl, b: UIControl) {
		super.init()
		self.a = a
		self.b = b
		b.addObserver(self, forKeyPath: "highlighted", options: .New, context: nil)
	}
	
	deinit {
		b.removeObserver(self, forKeyPath: "highlighted")
	}
	
	override public func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
		if keyPath == "highlighted" {
			if b.highlighted {
				UIView.animateWithDuration(0.02) {
					self.a.alpha = 0.2
				}
			} else {
				UIView.animateWithDuration(0.02, delay: 0.05, options: nil, animations: {
					self.a.alpha = 1
					}, completion: nil)
			}
		} else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
		}
	}
}


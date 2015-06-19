//
//  AutolayoutStack.swift
//
//  Created by Rex Sheng on 3/25/15.
//  Copyright (c) 2015 Rex Sheng. All rights reserved.
//

// available in pod 'Greycats', '~> 0.3.0'

import UIKit

func _id<T: AnyObject>(object: T) -> String {
	return "<\(_stdlib_getDemangledTypeName(object)): 0x\(String(ObjectIdentifier(object).uintValue, radix: 16))>"
}

extension UIView {
	func horizontalStack(views: [UIView], marginX: CGFloat = 0) -> [NSLayoutConstraint] {
		for v in subviews {
			v.removeFromSuperview()
		}
		var previous: UIView? = nil
		var constraints: [NSLayoutConstraint] = []
		for view in views {
			view.setTranslatesAutoresizingMaskIntoConstraints(false)
			addSubview(view)
			constraints.append(NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0))
			constraints.append(NSLayoutConstraint(item: view, attribute: .Height, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: 1, constant: -2))
			constraints.append(NSLayoutConstraint(item: view, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: -2))
			
			if let previous = previous {
				constraints.append(NSLayoutConstraint(item: view, attribute: .Left, relatedBy: .Equal, toItem: previous, attribute: .Right, multiplier: 1, constant: 2 * marginX))
			} else {
				constraints.append(NSLayoutConstraint(item: view, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1, constant: marginX))
			}
			previous = view
		}
		if let previous = previous {
			let constraint = NSLayoutConstraint(item: previous, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1, constant: -marginX)
			constraint.priority = 999
			constraints.append(constraint)
		}
		addConstraints(constraints)
		return constraints
	}
	
	func verticalStack(views: [UIView], marginX: CGFloat = 0) {
		for v in subviews {
			v.removeFromSuperview()
		}
		var previous: UIView? = nil
		for view in views {
			insertViewVertically(view, after: previous, marginX: marginX)
			previous = view
		}
	}
	
	func _previousView(view: UIView, axis: UILayoutConstraintAxis) -> NSLayoutConstraint? {
		let gaps = constraints() as! [NSLayoutConstraint]
		for gap in gaps {
			if gap.firstAttribute == .Top && gap.firstItem as? UIView == view {
				return gap
			}
		}
		return nil
	}
	
	func _firstView(axis: UILayoutConstraintAxis) -> NSLayoutConstraint? {
		let gaps = constraints() as! [NSLayoutConstraint]
		for gap in gaps {
			if gap.secondAttribute == .Top && gap.secondItem as? UIView == self {
				return gap
			}
		}
		return nil
	}
	
	func _lastView(axis: UILayoutConstraintAxis) -> NSLayoutConstraint? {
		let gaps = constraints() as! [NSLayoutConstraint]
		for gap in gaps {
			if gap.firstAttribute == .Bottom && gap.firstItem as? UIView == self {
				return gap
			}
		}
		return nil
	}
	
	func _nextView(view: UIView, axis: UILayoutConstraintAxis) -> NSLayoutConstraint? {
		let gaps = constraints() as! [NSLayoutConstraint]
		for gap in gaps {
			if gap.secondAttribute == .Bottom && gap.secondItem as? UIView == view {
				return gap
			}
		}
		return nil
	}
	
	func insertViewVertically(view: UIView, after previous: UIView?, marginX: CGFloat = 0) {
		view.setTranslatesAutoresizingMaskIntoConstraints(false)
		addSubview(view)
		addConstraint(NSLayoutConstraint(item: view, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: marginX))
		addConstraint(NSLayoutConstraint(item: view, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: -marginX))
		addConstraint(NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 1, constant: -2 * marginX))
		
		let gaps: [NSLayoutConstraint] = constraintsAffectingLayoutForAxis(.Vertical) as! [NSLayoutConstraint]
		if let previous = previous {
			// let us found original next view, and link it to this view
			if let c = _nextView(previous, axis: .Vertical) {
				removeConstraint(c)
				addConstraint(NSLayoutConstraint(item: c.firstItem, attribute: c.firstAttribute, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1, constant: c.constant))
			}
			let top = NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: previous, attribute: .Bottom, multiplier: 1, constant: 0)
			addConstraint(top)
		} else {
			// view is gonna be first, find current first and unlink it
			if let c = _firstView(.Vertical) {
				addConstraint(NSLayoutConstraint(item: c.firstItem, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1, constant: 0))
				removeConstraint(c)
			} else {
				let bottom = NSLayoutConstraint(item: self, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1, constant: 2)
				addConstraint(bottom)
			}
			let top = NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0)
			addConstraint(top)
		}
	}
}

infix operator |< {}
func |< (view: UIView, views: [UIView]) {
	view.verticalStack(views, marginX: 0)
}

infix operator -< {}
func -< (view: UIView, views: [UIView]) {
	view.horizontalStack(views, marginX: 0)
}


//
//  AutolayoutStack.swift
//
//  Created by Rex Sheng on 3/25/15.
//  Copyright (c) 2015 Rex Sheng. All rights reserved.
//

import UIKit

@IBDesignable
class BoxView: UIView {
	@IBInspectable dynamic var borderColor: UIColor? {
		get { return UIColor(CGColor: layer.borderColor) }
		set(value) { layer.borderColor = value!.CGColor }
	}
	@IBInspectable dynamic var borderWidth: CGFloat {
		get { return layer.borderWidth }
		set(value) { layer.borderWidth = value }
	}
	@IBInspectable dynamic var cornerRadius: CGFloat {
		get { return layer.cornerRadius }
		set(value) { layer.cornerRadius = value; layer.masksToBounds = true }
	}
}

func _id<T: AnyObject>(object: T) -> String {
	return "<\(_stdlib_getDemangledTypeName(object)): 0x\(String(ObjectIdentifier(object).uintValue(), radix: 16))>"
}

private func _attr(attr: NSLayoutAttribute) -> String {
	return attr == .Top ? "top" : "bottom"
}

private var boxesKey: UInt8 = 0x01

extension UIView {
	func horizontalStack(views: [UIView], marginX: CGFloat) -> [NSLayoutConstraint] {
		var previous: UIView? = nil
		var constraints: [NSLayoutConstraint] = []
		for view in views {
			view.setTranslatesAutoresizingMaskIntoConstraints(false)
			self.addSubview(view)
			constraints.append(NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0))
			constraints.append(NSLayoutConstraint(item: view, attribute: .Height, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: 1, constant: -2))
			constraints.append(NSLayoutConstraint(item: view, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: -2))
			if self is UIScrollView {
				constraints.append(NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 1, constant: -2 * marginX))
			} else {
				if let previous = previous {
					constraints.append(NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: previous, attribute: .Width, multiplier: 1, constant: 0))
				}
			}
			if let previous = previous {
				constraints.append(NSLayoutConstraint(item: view, attribute: .Left, relatedBy: .Equal, toItem: previous, attribute: .Right, multiplier: 1, constant: 2 * marginX))
			} else {
				constraints.append(NSLayoutConstraint(item: view, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1, constant: marginX))
			}
			previous = view
		}
		if let previous = previous {
			constraints.append(NSLayoutConstraint(item: previous, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1, constant: -marginX))
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
		let gaps = constraints() as [NSLayoutConstraint]
		for gap in gaps {
			if gap.firstAttribute == .Top && gap.firstItem as? UIView == view {
				return gap
			}
		}
		return nil
	}
	
	func _firstView(axis: UILayoutConstraintAxis) -> NSLayoutConstraint? {
		let gaps = constraints() as [NSLayoutConstraint]
		for gap in gaps {
			if gap.secondAttribute == .Top && gap.secondItem as? UIView == self {
				return gap
			}
		}
		return nil
	}
	
	func _lastView(axis: UILayoutConstraintAxis) -> NSLayoutConstraint? {
		let gaps = constraints() as [NSLayoutConstraint]
		for gap in gaps {
			if gap.firstAttribute == .Bottom && gap.firstItem as? UIView == self {
				return gap
			}
		}
		return nil
	}
	
	func _nextView(view: UIView, axis: UILayoutConstraintAxis) -> NSLayoutConstraint? {
		let gaps = constraints() as [NSLayoutConstraint]
		for gap in gaps {
			if gap.secondAttribute == .Bottom && gap.secondItem as? UIView == view {
				return gap
			}
		}
		return nil
	}
	
	func _removeView(view: UIView, axis: UILayoutConstraintAxis, adjustBoxes: Bool = true) {
		if let prev = _previousView(view, axis: axis) {
			if let next = _nextView(view, axis: axis) {
				removeConstraint(prev)
				removeConstraint(next)
				let prevView: AnyObject = prev.secondItem!
				let nextView: AnyObject = next.firstItem
				println("removing \(_id(view))")
				if adjustBoxes {
					if prevView.dynamicType === view.dynamicType {
						_adjustBoxes(view, with: prevView as UIView)
					} else if nextView.dynamicType === view.dynamicType {
						_adjustBoxes(view, with: nextView as UIView)
					}
				}
				let newConstraint = NSLayoutConstraint(item: nextView, attribute: next.firstAttribute, relatedBy: .Equal, toItem: prevView, attribute: prev.secondAttribute, multiplier: 1, constant: 0)
				println("connecting: \(_id(prevView)).\(_attr(prev.secondAttribute)) == \(_id(nextView)).\(_attr(next.firstAttribute))")
				addConstraint(newConstraint)
			}
		}
	}
	
	func insertViewVertically(view: UIView, after previous: UIView?, marginX: CGFloat = 0) {
		view.setTranslatesAutoresizingMaskIntoConstraints(false)
		addSubview(view)
		addConstraint(NSLayoutConstraint(item: view, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: marginX))
		addConstraint(NSLayoutConstraint(item: view, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: -marginX))
		addConstraint(NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 1, constant: -2 * marginX))
		
		let gaps: [NSLayoutConstraint] = constraintsAffectingLayoutForAxis(.Vertical) as [NSLayoutConstraint]
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
	var boxes: [String: BoxView] {
		get {
			if let cache = objc_getAssociatedObject(self, &boxesKey) as? [String: BoxView] {
				return cache
			} else {
				var newValue: [String: BoxView] = [:]
				objc_setAssociatedObject(self, &boxesKey, newValue, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN))
				return newValue
			}
		}
		set(newValue) {
			objc_setAssociatedObject(self, &boxesKey, newValue, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN))
		}
	}
	
	func removeBox(identifier: String) {
		if let box = boxes[identifier] {
			box.removeFromSuperview()
		}
		boxes[identifier] = nil
	}
	
	func box<T: UIView>(from: T, _ to: T, identifier: String, insets: UIEdgeInsets = UIEdgeInsetsZero) {
		if let box = boxes[identifier] {
			box.removeFromSuperview()
		}
		let box = BoxView()
		boxes[identifier] = box
		println("box \(identifier)")
		box.backgroundColor = UIColor.whiteColor()
		insertSubview(box, atIndex: 0)
		box.setTranslatesAutoresizingMaskIntoConstraints(false)
		addConstraint(NSLayoutConstraint(item: box, attribute: .Top, relatedBy: .Equal, toItem: from, attribute: .Top, multiplier: 1, constant: insets.top))
		addConstraint(NSLayoutConstraint(item: box, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1, constant: insets.left))
		addConstraint(NSLayoutConstraint(item: self, attribute: .Right, relatedBy: .Equal, toItem: box, attribute: .Right, multiplier: 1, constant: insets.right))
		addConstraint(NSLayoutConstraint(item: to, attribute: .Bottom, relatedBy: .Equal, toItem: box, attribute: .Bottom, multiplier: 1, constant: insets.bottom))
	}
	
	private func _adjustBoxes<T: UIView>(view: T, with newView: T) {
		for c in self.constraints() as [NSLayoutConstraint] {
			if c.firstAttribute == .Top && c.secondAttribute == .Top && c.secondItem as? T === view {
				if let box = c.firstItem as? BoxView {
					println("adjust box \(_id(box)).top = \(_id(newView)).top")
					removeConstraint(c)
					addConstraint(NSLayoutConstraint(item: box, attribute: .Top, relatedBy: .Equal, toItem: newView, attribute: .Top, multiplier: c.multiplier, constant: c.constant))
				}
			}
			if c.firstAttribute == .Bottom && c.secondAttribute == .Bottom && c.firstItem as? T === view {
				if let box = c.secondItem as? BoxView {
					println("adjust box \(_id(box)).bottom = \(_id(newView)).bottom")
					removeConstraint(c)
					addConstraint(NSLayoutConstraint(item: newView, attribute: .Bottom, relatedBy: .Equal, toItem: box, attribute: .Bottom, multiplier: c.multiplier, constant: c.constant))
				}
			}
		}
	}
}
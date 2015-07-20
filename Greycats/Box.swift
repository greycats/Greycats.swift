//
//  Box.swift
//
//  Created by Rex Sheng on 5/1/15.
//  Copyright (c) 2015 Interactive Labs. All rights reserved.
//

import UIKit

public extension UIView {
	@IBInspectable public dynamic var borderColor: UIColor? {
		get { return UIColor(CGColor: layer.borderColor) }
		set(value) { layer.borderColor = value!.CGColor }
	}
	@IBInspectable public dynamic var borderWidth: CGFloat {
		get { return layer.borderWidth }
		set(value) { layer.borderWidth = value / UIScreen.mainScreen().scale }
	}
	@IBInspectable public dynamic var cornerRadius: CGFloat {
		get { return layer.cornerRadius }
		set(value) {
			layer.cornerRadius = value
			layer.masksToBounds = layer.shadowOpacity == 0
		}
	}
	@IBInspectable public dynamic var shadowOffset: CGPoint {
		get { return CGPoint(x: layer.shadowOffset.width * UIScreen.mainScreen().scale, y: layer.shadowOffset.height * UIScreen.mainScreen().scale) }
		set(value) { layer.shadowOffset = CGSize(width: value.x / UIScreen.mainScreen().scale, height: value.y / UIScreen.mainScreen().scale) }
	}
	@IBInspectable public dynamic var shadowOpacity: Float {
		get { return layer.shadowOpacity }
		set(value) {
			layer.shadowOpacity = value
			layer.masksToBounds = false
			if value > 0 {
				layer.shouldRasterize = true
				layer.rasterizationScale = UIScreen.mainScreen().scale
			} else {
				layer.shouldRasterize = false
			}
		}
	}
	@IBInspectable public dynamic var shadowRadius: CGFloat {
		get { return layer.shadowRadius }
		set(value) { layer.shadowRadius = value }
	}
}

@IBDesignable
public class BoxView: UIView {
}

private var boxesKey: UInt8 = 0x01

private func _attr(attr: NSLayoutAttribute) -> String {
	return attr == .Top ? "top" : "bottom"
}

extension UIView {
	public var boxes: [String: BoxView] {
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
	
	public func removeBox(identifier: String) {
		if let box = boxes[identifier] {
			box.removeFromSuperview()
		}
		boxes[identifier] = nil
	}
	
	public func box<T: UIView>(from: T, _ to: T, identifier: String, insets: UIEdgeInsets = UIEdgeInsetsZero) {
		if let box = boxes[identifier] {
			box.removeFromSuperview()
		}
		let box = BoxView()
		boxes[identifier] = box
		print("box \(identifier)")
		box.backgroundColor = UIColor.whiteColor()
		insertSubview(box, atIndex: 0)
		box.setTranslatesAutoresizingMaskIntoConstraints(false)
		addConstraint(NSLayoutConstraint(item: box, attribute: .Top, relatedBy: .Equal, toItem: from, attribute: .Top, multiplier: 1, constant: insets.top))
		addConstraint(NSLayoutConstraint(item: box, attribute: .Left, relatedBy: .Equal, toItem: self, attribute: .Left, multiplier: 1, constant: insets.left))
		addConstraint(NSLayoutConstraint(item: self, attribute: .Right, relatedBy: .Equal, toItem: box, attribute: .Right, multiplier: 1, constant: insets.right))
		addConstraint(NSLayoutConstraint(item: to, attribute: .Bottom, relatedBy: .Equal, toItem: box, attribute: .Bottom, multiplier: 1, constant: insets.bottom))
	}
	
	private func _adjustBoxes<T: UIView>(view: T, with newView: T) {
		for c in self.constraints() as! [NSLayoutConstraint] {
			if c.firstAttribute == .Top && c.secondAttribute == .Top && c.secondItem as? T === view {
				if let box = c.firstItem as? UIView {
					print("adjust box \(_id(box)).top = \(_id(newView)).top")
					removeConstraint(c)
					addConstraint(NSLayoutConstraint(item: box, attribute: .Top, relatedBy: .Equal, toItem: newView, attribute: .Top, multiplier: c.multiplier, constant: c.constant))
				}
			}
			if c.firstAttribute == .Bottom && c.secondAttribute == .Bottom && c.firstItem as? T === view {
				if let box = c.secondItem as? UIView {
					print("adjust box \(_id(box)).bottom = \(_id(newView)).bottom")
					removeConstraint(c)
					addConstraint(NSLayoutConstraint(item: newView, attribute: .Bottom, relatedBy: .Equal, toItem: box, attribute: .Bottom, multiplier: c.multiplier, constant: c.constant))
				}
			}
		}
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
						_adjustBoxes(view, with: prevView as! UIView)
					} else if nextView.dynamicType === view.dynamicType {
						_adjustBoxes(view, with: nextView as! UIView)
					}
				}
				let newConstraint = NSLayoutConstraint(item: nextView, attribute: next.firstAttribute, relatedBy: .Equal, toItem: prevView, attribute: prev.secondAttribute, multiplier: 1, constant: 0)
				println("connecting: \(_id(prevView)).\(_attr(prev.secondAttribute)) == \(_id(nextView)).\(_attr(next.firstAttribute))")
				addConstraint(newConstraint)
			}
		}
	}
}
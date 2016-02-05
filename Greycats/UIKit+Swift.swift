//
//  UIKit+Swift.swift
//  Greycats
//
//  Created by Rex Sheng on 3/11/15.
//  Copyright (c) 2016 Interactive Labs. All rights reserved.
//

public let LineWidth = 1 / UIScreen.mainScreen().scale
public let ScreenSize = UIScreen.mainScreen().bounds.size
public let iOS8Less = (UIDevice.currentDevice().systemVersion as NSString).floatValue < 8

extension UIView {
	public func fullDimension() {
		translatesAutoresizingMaskIntoConstraints = false
		let views = ["v": self]
		let parent = self.superview!
		parent.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[v]|", options: [], metrics: nil, views: views))
		parent.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[v]|", options: [], metrics: nil, views: views))
	}

	public func bottom(height: CGFloat = 1) {
		translatesAutoresizingMaskIntoConstraints = false
		let views = ["v": self]
		let parent = self.superview!
		parent.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[v]|", options: [], metrics: nil, views: views))
		parent.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[v(h)]|", options: [], metrics: ["h": height / UIScreen.mainScreen().scale], views: views))
	}

	public func right(width: CGFloat = 1, margin: CGFloat = 0) {
		translatesAutoresizingMaskIntoConstraints = false
		let views = ["v": self]
		let parent = self.superview!
		parent.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-m-[v]-m-|", options: [], metrics: ["m": margin], views: views))
		parent.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[v(w)]|", options: [], metrics: ["w": width / UIScreen.mainScreen().scale], views: views))
	}
}

extension NSObjectProtocol {
	public func loadFromNib(nibName: String, index: Int = 0) -> UIView {
		let buddle = NSBundle(forClass: self.dynamicType)
		let nib = UINib(nibName: nibName, bundle: buddle)
		let view = nib.instantiateWithOwner(self, options: nil)[index] as! UIView
		return view
	}
}

extension UIStoryboardSegue {
	public func topViewController<T>() -> T? {
		var dest: T? = nil
		if let controller = destinationViewController as? T {
			dest = controller
		} else {
			if let controller = destinationViewController as? UINavigationController {
				if let controller = controller.topViewController as? T {
					dest = controller
				}
			}
		}
		return dest
	}
}

public protocol _NibView {
	var nibName: String { get }
}

public class NibView: UIView, _NibView {
	public var nibName: String { return "-" }
	var nibIndex: Int { return 0 }
	public var view: UIView!

	public convenience init() {
		self.init(frame: .zero)
	}

	public override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}

	@IBOutlet var lineWidth: [NSLayoutConstraint]!

	public func setup() {
		view = loadFromNib(nibName, index: nibIndex)
		view.frame = bounds
		view.backgroundColor = nil
		view.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
		if lineWidth != nil {
			for c in lineWidth {
				c.constant = LineWidth
			}
		}
		insertSubview(view, atIndex: 0)
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
}

extension UITextView {
	public func notEditable() {
		textContainerInset = UIEdgeInsetsZero
		editable = false
	}
}

@IBDesignable
public class StyledView: UIView {
	@IBInspectable public var layout: String = "" {
		didSet {
			if oldValue != layout {
				setup()
			}
		}
	}
	weak public var view: UIView!
	public var nibNamePrefix: String { return "" }

	public func setup() {
		if view != nil {
			view.removeFromSuperview()
		}
		view = loadFromNib("\(nibNamePrefix)\(layout)", index: 0)
		view.frame = bounds
		view.backgroundColor = nil
		view.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
		insertSubview(view, atIndex: 0)
	}

	override public init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
}
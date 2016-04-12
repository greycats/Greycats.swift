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
	func setup()
	var nibName: String { get }
}

private var viewKey: Void?
extension _NibView where Self: UIView {
	private func replaceFirstChildWith<T: UIView>(nibName: String) -> T {
		if let view = objc_getAssociatedObject(self, &viewKey) as? T {
			view.removeFromSuperview()
		}
		let buddle = NSBundle(forClass: self.dynamicType)
		let nib = UINib(nibName: nibName, bundle: buddle)
		let view = nib.instantiateWithOwner(self, options: nil).first as! T
		view.frame = bounds
		view.backgroundColor = nil
		view.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
		insertSubview(view, atIndex: 0)
		objc_setAssociatedObject(self, &viewKey, view, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		return view
	}
}

public class NibView: UIView, _NibView {
	public var nibName: String { return String(self.dynamicType) }

	public convenience init() {
		self.init(frame: .zero)
	}

	public override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}

	@IBOutlet var lineWidth: [NSLayoutConstraint]!

	public func setup() {
		replaceFirstChildWith(nibName)
		if lineWidth != nil {
			for c in lineWidth {
				c.constant = LineWidth
			}
		}
	}
}

@IBDesignable
public class StyledView: NibView {
	public override var nibName: String { return "\(nibNamePrefix)\(layout)" }
	public var nibNamePrefix: String { return String(self.dynamicType) }
	@IBInspectable public var layout: String = "" {
		didSet {
			if oldValue != layout {
				setup()
			}
		}
	}
}

@IBDesignable
public class KernLabel: UILabel {
	@IBInspectable public var kern: Float = 0 {
		didSet { updateAttributedText() }
	}
	public override var text: String? {
		didSet { updateAttributedText() }
	}

	func updateAttributedText() {
		if let text = text {
			attributedText = NSAttributedString(string: text, attributes: [
				NSFontAttributeName: font,
				NSForegroundColorAttributeName: textColor,
				NSKernAttributeName: kern
				])
		}
	}
}

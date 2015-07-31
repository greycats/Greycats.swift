//
//  UIKit+Swift.swift
//  ThinkSpider
//
//  Created by Rex Sheng on 3/11/15.
//  Copyright (c) 2015 Rex Sheng. All rights reserved.
//

// available in pod 'Greycats', '~> 0.4.0'

import UIKit

public let LineWidth = 1 / UIScreen.mainScreen().scale
public let ScreenSize = UIScreen.mainScreen().bounds.size
public let iOS8Less = (UIDevice.currentDevice().systemVersion as NSString).floatValue < 8

public func dispatch_time_in(delay: Double) -> dispatch_time_t {
	return dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
}

public func delay(delay: Double, closure: dispatch_block_t) {
	dispatch_after(dispatch_time_in(delay), dispatch_get_main_queue(), closure)
}

public func background(closure: dispatch_block_t) {
	dispatch_async(dispatch_get_global_queue(0, 0), closure)
}

public func foreground(closure: dispatch_block_t) {
	dispatch_async(dispatch_get_main_queue(), closure)
}

extension UIColor {
	public convenience init(hexRGB hex: UInt, alpha: CGFloat = 1) {
		let ff: CGFloat = 255.0;
		let r = CGFloat((hex & 0xff0000) >> 16) / ff
		let g = CGFloat((hex & 0xff00) >> 8) / ff
		let b = CGFloat(hex & 0xff) / ff
		self.init(red: r, green: g, blue: b, alpha: alpha)
	}
}

private var bitmapInfo: CGBitmapInfo = {
	var bitmapInfo = CGBitmapInfo.ByteOrder32Little
	bitmapInfo &= ~CGBitmapInfo.AlphaInfoMask
	bitmapInfo |= CGBitmapInfo(CGImageAlphaInfo.PremultipliedFirst.rawValue)
	return bitmapInfo
	}()

extension CGImage {
	public func blend(mode: CGBlendMode, color: CGColor, alpha: CGFloat = 1) -> CGImage {
		let colourSpace = CGColorSpaceCreateDeviceRGB()
		let width = CGImageGetWidth(self)
		let height = CGImageGetHeight(self)
		let rect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
		let context = CGBitmapContextCreate(nil, width, height, CGImageGetBitsPerComponent(self), width * 4, colourSpace, bitmapInfo)
		
		CGContextSetFillColorWithColor(context, color)
		CGContextFillRect(context, rect)
		CGContextSetBlendMode(context, mode)
		CGContextSetAlpha(context, alpha)
		CGContextDrawImage(context, rect, self)
		return CGBitmapContextCreateImage(context)
	}
	
	public static func op(width: Int, _ height: Int, closure: (CGContextRef) -> Void) -> CGImage! {
		let colourSpace = CGColorSpaceCreateDeviceRGB()
		let rect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
		let context = CGBitmapContextCreate(nil, width, height, 8, width * 4, colourSpace, bitmapInfo)
		closure(context)
		return CGBitmapContextCreateImage(context)
	}
	
	public static func create(color: CGColor, size: CGSize) -> CGImage! {
		return op(Int(size.width), Int(size.height)) { (context) in
			let rect = CGRect(origin: .zeroPoint, size: size)
			CGContextSetFillColorWithColor(context, color)
			CGContextFillRect(context, rect)
		}
	}
}

extension UIView {
	public func fullDimension() {
		setTranslatesAutoresizingMaskIntoConstraints(false)
		let views = ["v": self]
		let parent = self.superview!
		parent.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[v]|", options: nil, metrics: nil, views: views))
		parent.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[v]|", options: nil, metrics: nil, views: views))
	}
	
	public func bottom(height: CGFloat = 1) {
		setTranslatesAutoresizingMaskIntoConstraints(false)
		let views = ["v": self]
		let parent = self.superview!
		parent.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[v]|", options: nil, metrics: nil, views: views))
		parent.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[v(h)]|", options: nil, metrics: ["h": height / UIScreen.mainScreen().scale], views: views))
	}
	
	public func right(width: CGFloat = 1, margin: CGFloat = 0) {
		setTranslatesAutoresizingMaskIntoConstraints(false)
		let views = ["v": self]
		let parent = self.superview!
		parent.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-m-[v]-m-|", options: nil, metrics: ["m": margin], views: views))
		parent.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[v(w)]|", options: nil, metrics: ["w": width / UIScreen.mainScreen().scale], views: views))
	}
}

extension NSObject {
	public func loadFromNib(nibName: String, index: Int = 0) -> UIView {
		let buddle = NSBundle(forClass: self.dynamicType)
		let nib = UINib(nibName: nibName, bundle: buddle)
		let view = nib.instantiateWithOwner(self, options: nil)[index] as! UIView
		return view
	}
}

extension UIStoryboardSegue {
	public func topViewController<T>(type: T.Type) -> T? {
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
		self.init(frame: .zeroRect)
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
		view.autoresizingMask = .FlexibleHeight | .FlexibleWidth
		if lineWidth != nil {
			for c in lineWidth {
				c.constant = LineWidth
			}
		}
		insertSubview(view, atIndex: 0)
	}
	
	public required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
}

extension UIImage {
	public func blend(color: UIColor) -> UIImage? {
		return blend(kCGBlendModeDestinationIn, color: color)
	}
	
	public func blend(mode: CGBlendMode, color: UIColor, alpha: CGFloat = 1) -> UIImage? {
		let cgImage = CGImage.blend(mode, color: color.CGColor, alpha: alpha)
		let image = UIImage(CGImage: cgImage, scale: scale, orientation: imageOrientation)
		return image
	}
	
	public convenience init?(fromColor: UIColor) {
		self.init(CGImage: CGImageRef.create(fromColor.CGColor, size: CGSizeMake(1, 1)))
	}
}

private var labelTimer: UInt8 = 0
extension UILabel {
	public func keepUpdating(time: NSTimeInterval, closure: (NSTimeInterval) -> (String)) {
		let timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue())
		dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, NSEC_PER_SEC, 0)
		objc_setAssociatedObject(self, &labelTimer, timer, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN))
		weak var weakLabel = self
		dispatch_source_set_event_handler(timer) {
			weakLabel?.text = closure(time - NSDate.timeIntervalSinceReferenceDate())
			return
		}
		dispatch_resume(timer)
	}
}

extension UITextView {
	public func notEditable() {
		textContainerInset = UIEdgeInsetsZero
		editable = false
	}
}


extension UIView {
	public func registerKeyboard() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillChange:", name: UIKeyboardWillChangeFrameNotification, object: nil)
	}
	
	public func unregisterKeyboard() {
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
	}
	public func keyboardConstraint() -> NSLayoutConstraint? {
		return nil
	}
	
	public func keyboardWillChange(notif: NSNotification) {
		if let info = notif.userInfo {
			var kbRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
			kbRect = convertRect(kbRect, fromView: window)
			var height = bounds.size.height - kbRect.origin.y
			if let constraint = keyboardConstraint() {
				constraint.constant = height
				UIView.animateWithDuration(info[UIKeyboardAnimationDurationUserInfoKey] as! NSTimeInterval, delay: 0, options: UIViewAnimationOptions(info[UIKeyboardAnimationCurveUserInfoKey] as! UInt), animations: {
					self.layoutIfNeeded()
					}, completion: nil)
				return
			}
		}
		UIView.setAnimationsEnabled(true)
	}
}

extension UIViewController {
	public func registerKeyboard() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillChange:", name: UIKeyboardWillChangeFrameNotification, object: nil)
	}
	
	public func unregisterKeyboard() {
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
	}
	
	public func activeField() -> UIView? {
		return nil
	}
	
	public func scrollingView() -> UIScrollView? {
		return nil
	}
	
	public func keyboardConstraint() -> NSLayoutConstraint? {
		return nil
	}
	
	public func keyboardHeightDidUpdate(height: CGFloat) {
	}
	
	public func keyboardWillChange(notif: NSNotification) {
		if let info = notif.userInfo {
			var kbRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
			kbRect = view.convertRect(kbRect, fromView: view.window)
			var height = view.bounds.size.height - kbRect.origin.y
			if let constraint = keyboardConstraint() {
				println(notif)
				println("height to bottom layout = \(height)")
				constraint.constant = height
				keyboardHeightDidUpdate(height)
				UIView.animateWithDuration(info[UIKeyboardAnimationDurationUserInfoKey] as! NSTimeInterval, delay: 0, options: UIViewAnimationOptions(info[UIKeyboardAnimationCurveUserInfoKey] as! UInt), animations: {
					self.view.layoutIfNeeded()
					}, completion: nil)
				return
			}
			let insets = UIEdgeInsetsMake(0, 0, height, 0)
			if let scrollView = self.scrollingView() {
				scrollView.contentInset = insets
				scrollView.scrollIndicatorInsets = insets
				if let field = self.activeField() {
					let frame = field.convertRect(field.bounds, toView:self.view)
					scrollView.scrollRectToVisible(frame, animated: true)
				}
			}
		}
		UIView.setAnimationsEnabled(true)
	}
}

@IBDesignable
public class GradientView: UIView {
	@IBInspectable public var color1: UIColor = UIColor.whiteColor() { didSet { setNeedsDisplay() } }
	@IBInspectable public var color2: UIColor = UIColor.whiteColor() { didSet { setNeedsDisplay() } }
	@IBInspectable public var loc1: CGPoint = CGPointMake(0, 0) { didSet { setNeedsDisplay() } }
	@IBInspectable public var loc2: CGPoint = CGPointMake(1, 1) { didSet { setNeedsDisplay() } }
	
	override public func drawRect(rect: CGRect) {
		let context = UIGraphicsGetCurrentContext()
		CGContextSaveGState(context)
		let gradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), [color1.CGColor, color2.CGColor], [0, 1])
		CGContextDrawLinearGradient(context, gradient,
			CGPointMake(rect.size.width * loc1.x, rect.size.height * loc1.y),
			CGPointMake(rect.size.width * loc2.x, rect.size.height * loc2.y),
			UInt32(kCGGradientDrawsBeforeStartLocation) | UInt32(kCGGradientDrawsAfterEndLocation))
		CGContextRestoreGState(context)
		super.drawRect(rect)
	}
}

public struct Polar {
	public let r: CGFloat
	public var θ: CGFloat
	
	public init(_ a: CGFloat, _ b: CGFloat) {
		r = sqrt(pow(a, 2) + pow(b, 2))
		θ = atan2(b, a)
	}
	
	public mutating func rotate(angle: CGFloat) {
		θ -= angle
	}
	
	public var x: CGFloat {
		return r * cos(θ)
	}
	
	public var y: CGFloat {
		return r * sin(θ)
	}
}

@IBDesignable
public class _Control: UIControl {
	override public func tintColorDidChange() {
		setNeedsDisplay()
	}
	
	@IBInspectable public var disabledColor: UIColor = UIColor.grayColor()
	
	@IBInspectable public var desiredWidth: CGFloat = 0 {
		didSet { setNeedsDisplay() }
	}
	
	@IBInspectable public var angle: CGFloat = 0 {
		didSet { setNeedsDisplay() }
	}
	
	required override public init(frame: CGRect) {
		super.init(frame: frame)
		if iOS8Less {
			contentMode = .Redraw
		}
		opaque = false
	}
	
	required public init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		if iOS8Less {
			contentMode = .Redraw
		}
		opaque = false
	}
	
	public func centerScale(originalSize: CGSize, closure: (scale: CGFloat) -> ()) {
		var width = desiredWidth
		let rect = self.bounds
		if width == 0 {
			width = rect.size.width
		}
		let scale = width / originalSize.width
		let context = UIGraphicsGetCurrentContext()
		CGContextSaveGState(context)
		CGContextTranslateCTM(context, (rect.size.width - width) / 2, (rect.size.height - width * originalSize.height / originalSize.width) / 2)
		CGContextScaleCTM(context, scale, scale)
		if enabled {
			tintColor.setFill()
			tintColor.setStroke()
		} else {
			disabledColor.setFill()
			disabledColor.setStroke()
		}
		closure(scale: scale)
		CGContextRestoreGState(context)
	}
}

@IBDesignable
public class StyledView: UIView {
	@IBInspectable public var layout: String = "" { didSet { setup() } }
	weak public var view: UIView!
	public var nibNamePrefix: String { return "" }
	
	public func setup() {
		if view != nil {
			view.removeFromSuperview()
		}
		view = loadFromNib("\(nibNamePrefix)\(layout)", index: 0)
		view.frame = bounds
		view.backgroundColor = nil
		view.autoresizingMask = .FlexibleHeight | .FlexibleWidth
		insertSubview(view, atIndex: 0)
	}
	
	override public init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}
	
	required public init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
}
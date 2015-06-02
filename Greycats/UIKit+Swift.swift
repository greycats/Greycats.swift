//
//  UIKit+Swift.swift
//  ThinkSpider
//
//  Created by Rex Sheng on 3/11/15.
//  Copyright (c) 2015 Rex Sheng. All rights reserved.
//

// available in pod 'Greycats', '~> 0.2.0'

import UIKit
let iOS8Less = (UIDevice.currentDevice().systemVersion as NSString).floatValue < 8

func dispatch_time_in(delay: Double) -> dispatch_time_t {
	return dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
}

func delay(delay: Double, closure: dispatch_block_t) {
	dispatch_after(dispatch_time_in(delay), dispatch_get_main_queue(), closure)
}

func background(closure: dispatch_block_t) {
	dispatch_async(dispatch_get_global_queue(0, 0), closure)
}

func foreground(closure: dispatch_block_t) {
	dispatch_async(dispatch_get_main_queue(), closure)
}

extension UIColor {
	convenience init(hexRGB hex: UInt, alpha: CGFloat = 1) {
		let ff: CGFloat = 255.0;
		let r = CGFloat((hex & 0xff0000) >> 16) / ff
		let g = CGFloat((hex & 0xff00) >> 8) / ff
		let b = CGFloat(hex & 0xff) / ff
		self.init(red: r, green: g, blue: b, alpha: alpha)
	}
}

var bitmapInfo: CGBitmapInfo = {
	var bitmapInfo = CGBitmapInfo.ByteOrder32Little
	bitmapInfo &= ~CGBitmapInfo.AlphaInfoMask
	bitmapInfo |= CGBitmapInfo(CGImageAlphaInfo.PremultipliedFirst.rawValue)
	return bitmapInfo
	}()

extension CGImage {
	func blend(mode: CGBlendMode, color: CGColor, alpha: CGFloat = 1) -> CGImage {
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
	
	class func op(width: Int, _ height: Int, closure: (CGContextRef) -> Void) -> CGImage! {
		let colourSpace = CGColorSpaceCreateDeviceRGB()
		let rect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
		let context = CGBitmapContextCreate(nil, width, height, 8, width * 4, colourSpace, bitmapInfo)
		closure(context)
		return CGBitmapContextCreateImage(context)
	}
	
	class func create(color: CGColor, size: CGSize) -> CGImage! {
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
	func loadFromNib(nibName: String, index: Int = 0) -> UIView {
		let buddle = NSBundle(forClass: self.dynamicType)
		let nib = UINib(nibName: nibName, bundle: buddle)
		let view = nib.instantiateWithOwner(self, options: nil)[index] as! UIView
		return view
	}
}

protocol _NibView {
	var nibName: String { get }
}

class NibView: UIView, _NibView {
	var nibName: String { return "-" }
	var nibIndex: Int { return 0 }
	var view: UIView!
	
	convenience init() {
		self.init(frame: .zeroRect)
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}
	
	func setup() {
		view = loadFromNib(nibName, index: nibIndex)
		view.frame = bounds
		view.autoresizingMask = .FlexibleHeight | .FlexibleWidth
		addSubview(view)
	}
	
	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
}

extension UIImage {
	func blend(color: UIColor) -> UIImage? {
		return blend(kCGBlendModeDestinationIn, color: color)
	}
	
	func blend(mode: CGBlendMode, color: UIColor, alpha: CGFloat = 1) -> UIImage? {
		let cgImage = CGImage.blend(mode, color: color.CGColor, alpha: alpha)
		let image = UIImage(CGImage: cgImage, scale: scale, orientation: imageOrientation)
		return image
	}
	
	convenience init?(fromColor: UIColor) {
		self.init(CGImage: CGImageRef.create(fromColor.CGColor, size: CGSizeMake(1, 1)))
	}
}

private var labelTimer: UInt8 = 0
extension UILabel {
	func keepUpdating(time: NSTimeInterval, closure: (NSTimeInterval) -> (String)) {
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
	func notEditable() {
		textContainerInset = UIEdgeInsetsZero
		editable = false
	}
}

extension UIViewController {
	func registerKeyboard() {
		NSNotificationCenter.defaultCenter() .addObserver(self, selector: "keyboardDidShow:", name: UIKeyboardWillChangeFrameNotification, object: nil)
		NSNotificationCenter.defaultCenter() .addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object: nil)
	}
	
	func unregisterKeyboard() {
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
	}
	
	func activeField() -> UIView? {
		return nil
	}
	
	func scrollingView() -> UIScrollView? {
		return nil
	}
	
	func keyboardConstraint() -> NSLayoutConstraint? {
		return nil
	}
	
	func keyboardHeightDidUpdate(height: CGFloat) {
	}
	
	func keyboardDidShow(notif: NSNotification) {
		if let info = notif.userInfo {
			var kbRect = (info["UIKeyboardBoundsUserInfoKey"] as! NSValue).CGRectValue()
			kbRect = self.view.convertRect(kbRect, fromView: nil)
			if let constraint = keyboardConstraint() {
				let height = kbRect.size.height
				constraint.constant = height
				keyboardHeightDidUpdate(height)
				UIView.animateWithDuration(info[UIKeyboardAnimationDurationUserInfoKey] as! Double, delay: 0, options: UIViewAnimationOptions(info[UIKeyboardAnimationCurveUserInfoKey] as! UInt), animations: {
					self.view.layoutIfNeeded()
					}, completion: nil)
				return
			}
			let insets = UIEdgeInsetsMake(0, 0, kbRect.size.height, 0)
			self.scrollingView()?.contentInset = insets
			self.scrollingView()?.scrollIndicatorInsets = insets
			
			if let field = self.activeField() {
				let frame = field.convertRect(field.bounds, toView:self.view)
				self.scrollingView()?.scrollRectToVisible(frame, animated: true)
			}
		}
	}
	
	func keyboardWillBeHidden(notif: NSNotification) {
		if let info = notif.userInfo {
			let insets = UIEdgeInsetsZero
			if let constraint = keyboardConstraint() {
				constraint.constant = 0
				keyboardHeightDidUpdate(0)
				UIView.animateWithDuration(info[UIKeyboardAnimationDurationUserInfoKey] as! Double) {
					self.view.layoutIfNeeded()
				}
				return
			}
			self.scrollingView()?.contentInset = insets
			self.scrollingView()?.scrollIndicatorInsets = insets
		}
	}
}

@IBDesignable
class GradientView: UIView {
	@IBInspectable var color1: UIColor = UIColor.whiteColor() { didSet { setNeedsDisplay() } }
	@IBInspectable var color2: UIColor = UIColor.whiteColor() { didSet { setNeedsDisplay() } }
	@IBInspectable var loc1: CGPoint = CGPointMake(0, 0) { didSet { setNeedsDisplay() } }
	@IBInspectable var loc2: CGPoint = CGPointMake(1, 1) { didSet { setNeedsDisplay() } }
	
	override func drawRect(rect: CGRect) {
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

@IBDesignable
class Gradient4View: UIView {
	@IBInspectable var color1: UIColor = UIColor.whiteColor() { didSet { setNeedsDisplay() } }
	@IBInspectable var color2: UIColor = UIColor.whiteColor() { didSet { setNeedsDisplay() } }
	@IBInspectable var color3: UIColor = UIColor.whiteColor() { didSet { setNeedsDisplay() } }
	@IBInspectable var color4: UIColor = UIColor.whiteColor() { didSet { setNeedsDisplay() } }
	@IBInspectable var loc1: CGPoint = CGPointMake(0, 0.5) { didSet { setNeedsDisplay() } }
	@IBInspectable var loc2: CGPoint = CGPointMake(0.22, 0.5) { didSet { setNeedsDisplay() } }
	@IBInspectable var loc3: CGPoint = CGPointMake(0.41, 0.5) { didSet { setNeedsDisplay() } }
	@IBInspectable var loc4: CGPoint = CGPointMake(1, 0.5) { didSet { setNeedsDisplay() } }
	
	override func drawRect(rect: CGRect) {
		let context = UIGraphicsGetCurrentContext()
		CGContextSaveGState(context)
		let gradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), [color1.CGColor, color2.CGColor, color3.CGColor, color4.CGColor], [loc1.x, loc2.x, loc3.x, loc4.x])
		CGContextDrawLinearGradient(context, gradient,
			CGPointMake(rect.size.width * loc1.x, rect.size.height * loc1.y),
			CGPointMake(rect.size.width * loc4.x, rect.size.height * loc4.y),
			UInt32(kCGGradientDrawsBeforeStartLocation) | UInt32(kCGGradientDrawsAfterEndLocation))
		CGContextRestoreGState(context)
		super.drawRect(rect)
	}
}

struct Polar {
	let r: CGFloat
	var θ: CGFloat
	
	init(_ a: CGFloat, _ b: CGFloat) {
		r = sqrt(pow(a, 2) + pow(b, 2))
		θ = atan2(b, a)
	}
	
	mutating func rotate(angle: CGFloat) {
		θ -= angle
	}
	
	var x: CGFloat {
		return r * cos(θ)
	}
	
	var y: CGFloat {
		return r * sin(θ)
	}
}

@IBDesignable
class _Control: UIControl {
	override func tintColorDidChange() {
		setNeedsDisplay()
	}
	
	@IBInspectable var disabledColor: UIColor = UIColor.grayColor()
	
	@IBInspectable var desiredWidth: CGFloat = 0 {
		didSet { setNeedsDisplay() }
	}
	
	@IBInspectable var angle: CGFloat = 0 {
		didSet { setNeedsDisplay() }
	}
	
	required override init(frame: CGRect) {
		super.init(frame: frame)
		if iOS8Less {
			contentMode = .Redraw
		}
		opaque = false
	}
	
	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		if iOS8Less {
			contentMode = .Redraw
		}
		opaque = false
	}
	
	func centerScale(originalSize: CGSize, closure: (scale: CGFloat) -> ()) {
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

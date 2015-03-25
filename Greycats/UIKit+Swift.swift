//
//  UIKit+Swift.swift
//
//  Created by Rex Sheng on 3/11/15.
//  Copyright (c) 2015 Rex Sheng. All rights reserved.
//

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

private var bitmapInfo: CGBitmapInfo = {
	var bitmapInfo = CGBitmapInfo.ByteOrder32Little
	bitmapInfo &= ~CGBitmapInfo.AlphaInfoMask
	bitmapInfo |= CGBitmapInfo(CGImageAlphaInfo.PremultipliedFirst.rawValue)
	return bitmapInfo
	}()

extension CGImage {
	func blend(mode: CGBlendMode, color: CGColor) -> CGImage {
		let colourSpace = CGColorSpaceCreateDeviceRGB()
		let width = CGImageGetWidth(self)
		let height = CGImageGetHeight(self)
		let rect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
		let context = CGBitmapContextCreate(nil, width, height, CGImageGetBitsPerComponent(self), width * 4, colourSpace, CGImageGetBitmapInfo(self))
		
		CGContextSetFillColorWithColor(context, color)
		CGContextFillRect(context, rect)
		CGContextSetBlendMode(context, mode)
		CGContextDrawImage(context, rect, self)
		return CGBitmapContextCreateImage(context)
	}
	
	class func op(width: UInt, _ height: UInt, closure: (CGContextRef) -> Void) -> CGImage! {
		let colourSpace = CGColorSpaceCreateDeviceRGB()
		let rect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
		let context = CGBitmapContextCreate(nil, width, height, 8, width * 4, colourSpace, bitmapInfo)
		closure(context)
		return CGBitmapContextCreateImage(context)
	}
	
	class func create(color: CGColor, size: CGSize) -> CGImage! {
		return op(UInt(size.width), UInt(size.height)) { (context) in
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

extension UIView {
	func loadFromNib(nibName: String, index: Int = 0) -> UIView {
		let buddle = NSBundle(forClass: self.dynamicType)
		let nib = UINib(nibName: nibName, bundle: buddle)
		let view = nib.instantiateWithOwner(self, options: nil)[index] as UIView
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
	
	convenience override init() {
		self.init(frame: .zeroRect)
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}
	
	func setup() {
		view = loadFromNib(nibName, index: nibIndex)
		view.frame = self.bounds
		view.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
		addSubview(view)
	}
	
	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}
}

extension UIImage {
	func blend(color: UIColor) -> UIImage? {
		let cgImage = self.CGImage.blend(kCGBlendModeDestinationIn, color: color.CGColor)
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
	
	func scrollView() -> UIScrollView? {
		return nil
	}
	
	func keyboardConstraint() -> NSLayoutConstraint? {
		return nil
	}
	
	func keyboardHeightDidUpdate(height: CGFloat) {
		keyboardConstraint()?.constant = height
	}
	
	func keyboardDidShow(notif: NSNotification) {
		if let info = notif.userInfo {
			var kbRect = (info["UIKeyboardBoundsUserInfoKey"] as NSValue).CGRectValue()
			kbRect = self.view.convertRect(kbRect, fromView: nil)
			if let constraint = keyboardConstraint() {
				//				println(info)
				keyboardHeightDidUpdate(kbRect.size.height)
				UIView.animateWithDuration(info[UIKeyboardAnimationDurationUserInfoKey] as Double, delay: 0, options: UIViewAnimationOptions(info[UIKeyboardAnimationCurveUserInfoKey] as UInt), animations: {
					self.view.layoutIfNeeded()
					}, completion: nil)
				return
			}
			let insets = UIEdgeInsetsMake(0, 0, kbRect.size.height, 0)
			self.scrollView()?.contentInset = insets
			self.scrollView()?.scrollIndicatorInsets = insets
			
			if let field = self.activeField() {
				let frame = field.convertRect(field.bounds, toView:self.view)
				self.scrollView()?.scrollRectToVisible(frame, animated: true)
			}
		}
	}
	
	func keyboardWillBeHidden(notif: NSNotification) {
		if let info = notif.userInfo {
			let insets = UIEdgeInsetsZero
			if let constraint = keyboardConstraint() {
				keyboardHeightDidUpdate(0)
				UIView.animateWithDuration(info[UIKeyboardAnimationDurationUserInfoKey] as Double) {
					self.view.layoutIfNeeded()
				}
				return
			}
			self.scrollView()?.contentInset = insets
			self.scrollView()?.scrollIndicatorInsets = insets
		}
	}
}
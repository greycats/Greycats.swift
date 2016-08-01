//
//  Box.swift
//	Greycats
//
//  Created by Rex Sheng on 5/1/15.
//  Copyright (c) 2015 Interactive Labs. All rights reserved.
//

import UIKit

public extension UIView {

	@IBInspectable public var borderColor: UIColor? {
		get { if let color = layer.borderColor { return UIColor(CGColor: color) } else { return nil } }
		set(value) { if let value = value { layer.borderColor = value.CGColor } }
	}

	@IBInspectable public var borderWidth: CGFloat {
		get { return layer.borderWidth }
		set(value) { layer.borderWidth = value }
	}

	@IBInspectable public var relativeBorderWidth: CGFloat {
		get { return layer.borderWidth * UIScreen.mainScreen().scale }
		set(value) { layer.borderWidth = value / UIScreen.mainScreen().scale }
	}

	@IBInspectable public var cornerRadius: CGFloat {
		get { return layer.cornerRadius }
		set(value) {
			layer.cornerRadius = value
		}
	}
	
	@IBInspectable public var masksToBounds: Bool {
		get { return layer.masksToBounds }
		set(value) {
			layer.masksToBounds = value
		}
	}

	@IBInspectable public var shadowColor: UIColor? {
		get { if let color = layer.shadowColor { return UIColor(CGColor: color) } else { return nil } }
		set(value) { if let value = value { layer.shadowColor = value.CGColor } }
	}

	@IBInspectable public var shadowOffset: CGPoint {
		get { return CGPoint(x: layer.shadowOffset.width, y: layer.shadowOffset.height) }
		set(value) { layer.shadowOffset = CGSize(width: value.x, height: value.y) }
	}

	@IBInspectable public var relativeShadowOffset: CGPoint {
		get { return CGPoint(x: layer.shadowOffset.width * UIScreen.mainScreen().scale, y: layer.shadowOffset.height * UIScreen.mainScreen().scale) }
		set(value) { layer.shadowOffset = CGSize(width: value.x / UIScreen.mainScreen().scale, height: value.y / UIScreen.mainScreen().scale) }
	}

	@IBInspectable public var shadowOpacity: Float {
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

	@IBInspectable public var shadowRadius: CGFloat {
		get { return layer.shadowRadius }
		set(value) { layer.shadowRadius = value }
	}

	@IBInspectable public var relativeShadowRadius: CGFloat {
		get { return layer.shadowRadius * UIScreen.mainScreen().scale }
		set(value) { layer.shadowRadius = value / UIScreen.mainScreen().scale }
	}
}

@IBDesignable
public class BoxView: UIView {
	@IBInspectable public var cornerRadii: CGSize = CGSize(width: 4, height: 4)
	@IBInspectable public var corners: UInt = 0 {
		didSet {
			updateCorners()
		}
	}
	private func updateCorners() {
		if corners > 0 {
			let shape = CAShapeLayer()
			shape.path = UIBezierPath(roundedRect: bounds, byRoundingCorners: UIRectCorner(rawValue: corners), cornerRadii: cornerRadii).CGPath
			layer.mask = shape
		}
	}
}

@IBDesignable
public class GradientView: UIView {
	@IBInspectable public var color1: UIColor = UIColor.whiteColor() { didSet { setNeedsDisplay() } }
	@IBInspectable public var color2: UIColor = UIColor.whiteColor() { didSet { setNeedsDisplay() } }
	@IBInspectable public var loc1: CGPoint = CGPointMake(0, 0) { didSet { setNeedsDisplay() } }
	@IBInspectable public var loc2: CGPoint = CGPointMake(1, 1) { didSet { setNeedsDisplay() } }

	override public func drawRect(rect: CGRect) {
		drawGradient(rect)
		super.drawRect(rect)
	}

	public func drawGradient(rect: CGRect, @noescape closure: () -> () = {}) {
		let context = UIGraphicsGetCurrentContext()

		CGContextSaveGState(context)
		closure()
		let gradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), [color1.CGColor, color2.CGColor], [0, 1])
		CGContextDrawLinearGradient(context, gradient,
		                            CGPointMake(rect.size.width * loc1.x, rect.size.height * loc1.y),
		                            CGPointMake(rect.size.width * loc2.x, rect.size.height * loc2.y),
		                            [.DrawsBeforeStartLocation, .DrawsAfterEndLocation])
		CGContextRestoreGState(context)
	}
}
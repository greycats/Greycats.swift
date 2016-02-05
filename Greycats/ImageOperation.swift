//
//  ImageOperation.swift
//  Greycats
//
//  Created by Rex Sheng on 2/5/16.
//  Copyright (c) 2016 Interactive Labs. All rights reserved.
//

extension UIColor {
	public convenience init(hexRGB hex: UInt, alpha: CGFloat = 1) {
		let ff: CGFloat = 255.0;
		let r = CGFloat((hex & 0xff0000) >> 16) / ff
		let g = CGFloat((hex & 0xff00) >> 8) / ff
		let b = CGFloat(hex & 0xff) / ff
		self.init(red: r, green: g, blue: b, alpha: alpha)
	}
}

private var bitmapInfo: UInt32 = {
	var bitmapInfo = CGBitmapInfo.ByteOrder32Little.rawValue
	bitmapInfo &= ~CGBitmapInfo.AlphaInfoMask.rawValue
	bitmapInfo |= CGImageAlphaInfo.PremultipliedFirst.rawValue
	return bitmapInfo
}()

extension CGImage {
	public func blend(mode: CGBlendMode, color: CGColor, alpha: CGFloat = 1) -> CGImage? {
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

	public static func op(width: Int, _ height: Int, closure: (CGContextRef?) -> Void) -> CGImage? {
		let colourSpace = CGColorSpaceCreateDeviceRGB()
		let context = CGBitmapContextCreate(nil, width, height, 8, width * 4, colourSpace, bitmapInfo)
		closure(context)
		return CGBitmapContextCreateImage(context)
	}

	public static func create(color: CGColor, size: CGSize) -> CGImage? {
		return op(Int(size.width), Int(size.height)) { (context) in
			let rect = CGRect(origin: .zero, size: size)
			CGContextSetFillColorWithColor(context, color)
			CGContextFillRect(context, rect)
		}
	}
}

extension UIImage {
	public func blend(color: UIColor) -> UIImage? {
		return blend(CGBlendMode.DestinationIn, color: color)
	}

	public func blend(mode: CGBlendMode, color: UIColor, alpha: CGFloat = 1) -> UIImage? {
		if let cgImage = CGImage?.blend(mode, color: color.CGColor, alpha: alpha) {
			let image = UIImage(CGImage: cgImage, scale: scale, orientation: imageOrientation)
			return image
		}
		return nil
	}

	public convenience init?(fromColor: UIColor) {
		if let cgImage = CGImageRef.create(fromColor.CGColor, size: CGSizeMake(1, 1)) {
			self.init(CGImage: cgImage)
		} else {
			return nil
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
		let context = UIGraphicsGetCurrentContext()
		CGContextSaveGState(context)
		let gradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), [color1.CGColor, color2.CGColor], [0, 1])
		CGContextDrawLinearGradient(context, gradient,
			CGPointMake(rect.size.width * loc1.x, rect.size.height * loc1.y),
			CGPointMake(rect.size.width * loc2.x, rect.size.height * loc2.y),
			CGGradientDrawingOptions.DrawsBeforeStartLocation.union(CGGradientDrawingOptions.DrawsAfterEndLocation))
		CGContextRestoreGState(context)
		super.drawRect(rect)
	}
}
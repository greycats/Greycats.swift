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

	public func overlay(color: UIColor) -> UIColor {
		var ra: CGFloat = 0, ga: CGFloat = 0, ba: CGFloat = 0, aa: CGFloat = 0
		var rb: CGFloat = 0, gb: CGFloat = 0, bb: CGFloat = 0, ab: CGFloat = 0
		color.getRed(&ra, green: &ga, blue: &ba, alpha: &aa)
		func blend(b: CGFloat, _ a: CGFloat) -> CGFloat {
			if a < 0.5 {
				return 2 * a * b
			} else {
				return 1 - 2 * (1 - a) * (1 - b)
			}
		}
		getRed(&rb, green: &gb, blue: &bb, alpha: &ab)
		let r = blend(ra, rb)
		let g = blend(ga, gb)
		let b = blend(ba, bb)
		let a = blend(aa, ab)
		return UIColor(red: r, green: g, blue: b, alpha: a)
	}
}

private var bitmapInfo: UInt32 = {
	var bitmapInfo = CGBitmapInfo.ByteOrder32Little.rawValue
	bitmapInfo &= ~CGBitmapInfo.AlphaInfoMask.rawValue
	bitmapInfo |= CGImageAlphaInfo.PremultipliedFirst.rawValue
	return bitmapInfo
}()

public protocol SVG {
	var path: UIBezierPath { get }
	init()
}

extension UIButton {
	@IBInspectable public var svg: String? {
		get { return nil }
		set(value) {
			if let value = value,
				svg = NSClassFromString(value) as? SVG.Type {
				let path = svg.init().path
				setImage(UIImage.fillPath(path, color: tintColor), forState: .Normal)
			}
		}
	}
}

extension UIImage {
	public static func fillPath(path: UIBezierPath, color: UIColor) -> UIImage? {
		let size = path.bounds.size
		let image = CGImageRef.op(Int(ceil(size.width)), Int(ceil(size.height))) { context in
			CGContextSetFillColorWithColor(context, color.CGColor)
			CGContextAddPath(context, path.CGPath)
			CGContextFillPath(context)
		}
		let uiimage = image.flatMap { UIImage(CGImage: $0, scale: UIScreen.mainScreen().scale, orientation: .Up) }
		return uiimage
	}
}

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
		let scale = UIScreen.mainScreen().scale
		let w = width * Int(scale)
		let h = height * Int(scale)
		let colourSpace = CGColorSpaceCreateDeviceRGB()
		let context = CGBitmapContextCreate(nil, w, h, 8, w * 8, colourSpace, bitmapInfo)
		CGContextTranslateCTM(context, 0, CGFloat(h))
		CGContextScaleCTM(context, scale, -scale)
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
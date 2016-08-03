//
//  Graphics.swift
//  Greycats
//
//  Created by Rex Sheng on 8/1/16.
//  Copyright (c) 2016 Interactive Labs. All rights reserved.
//

import UIKit

private var bitmapInfo: UInt32 = {
	var bitmapInfo = CGBitmapInfo.ByteOrder32Little.rawValue
	bitmapInfo &= ~CGBitmapInfo.AlphaInfoMask.rawValue
	bitmapInfo |= CGImageAlphaInfo.PremultipliedFirst.rawValue
	return bitmapInfo
}()

extension CGImage {
	public func op(@noescape closure: (CGContext?, CGRect) -> ()) -> CGImage? {
		let width = CGImageGetWidth(self)
		let height = CGImageGetHeight(self)
		let colourSpace = CGColorSpaceCreateDeviceRGB()
		let context = CGBitmapContextCreate(nil, width, height, 8, width * 8, colourSpace, bitmapInfo)
		let rect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
		closure(context, rect)
		return CGBitmapContextCreateImage(context)
	}

	public static func op(width: Int, _ height: Int, @noescape closure: CGContext? -> ()) -> CGImage? {
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
}

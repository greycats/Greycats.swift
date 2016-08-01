//
//  Path.swift
//  Greycats
//
//  Created by Rex Sheng on 8/1/16.
//  Copyright (c) 2016 Interactive Labs. All rights reserved.
//

import UIKit

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
				setImage(UIImage(path: path, color: tintColor), forState: .Normal)
			}
		}
	}
}

extension UIImage {
	public convenience init?(path: UIBezierPath, color: UIColor) {
		let size = path.bounds.size
		let image = CGImageRef.op(Int(ceil(size.width)), Int(ceil(size.height))) { context in
			CGContextSetFillColorWithColor(context, color.CGColor)
			CGContextAddPath(context, path.CGPath)
			CGContextFillPath(context)
		}
		if let image = image {
			self.init(CGImage: image, scale: UIScreen.mainScreen().scale, orientation: .Up)
		} else {
			return nil
		}
	}
}


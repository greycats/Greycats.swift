//
//  Box.swift
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
	@IBInspectable public var shadowOffset: CGPoint {
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
}

@IBDesignable
public class BoxView: UIView {
}
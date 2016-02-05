//
//  _Control.swift
//  Greycats
//
//  Created by Rex Sheng on 2/5/16.
//  Copyright (c) 2016 Interactive Labs. All rights reserved.
//

@IBDesignable
public class _Control: UIControl {
	override public func tintColorDidChange() {
		setNeedsDisplay()
	}

	@IBInspectable public var disabledColor: UIColor = UIColor.grayColor()

	@IBInspectable public var respectHeight: Bool = false {
		didSet { setNeedsDisplay() }
	}

	@IBInspectable public var desiredWidth: CGFloat = 0 {
		didSet { setNeedsDisplay() }
	}

	@IBInspectable public var scaleBoost: CGFloat = 1 {
		didSet { setNeedsDisplay() }
	}

	@IBInspectable public var angle: CGFloat = 0 {
		didSet { setNeedsDisplay() }
	}

	required override public init(frame: CGRect) {
		super.init(frame: frame)
		contentMode = .Redraw
		opaque = false
	}

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		contentMode = .Redraw
		opaque = false
	}

	public func centerScale(originalSize: CGSize, @noescape closure: (scale: CGFloat) -> ()) {
		let rect = bounds
		let scale: CGFloat
		let width: CGFloat
		let height: CGFloat
		if respectHeight {
			height = rect.size.width * scaleBoost
			scale = height / originalSize.height
			width = height * originalSize.width / originalSize.height
		} else {
			if desiredWidth == 0 {
				width = rect.size.width * scaleBoost
			} else {
				width = desiredWidth * scaleBoost
			}
			scale = width / originalSize.width
			height = width * originalSize.height / originalSize.width
		}
		let context = UIGraphicsGetCurrentContext()
		CGContextSaveGState(context)
		CGContextTranslateCTM(context, (rect.size.width - width) / 2, (rect.size.height - height) / 2)
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
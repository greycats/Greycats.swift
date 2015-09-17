//
//  TextField.swift
//  Trusted
//
//  Created by Rex Sheng on 5/19/15.
//  Copyright (c) 2015 Trusted. All rights reserved.
//

import UIKit

@IBDesignable
public class TextField: UITextField {
	@IBInspectable public var placeholderAlpha: CGFloat = 0.5
	
	override public func drawPlaceholderInRect(rect: CGRect) {
		if let placeholder = placeholder {
			let color = textColor!.colorWithAlphaComponent(placeholderAlpha)
			NSAttributedString(string: placeholder, attributes: [
				NSFontAttributeName: font!,
				NSForegroundColorAttributeName: color
				]).drawInRect(rect)
		}
	}
}
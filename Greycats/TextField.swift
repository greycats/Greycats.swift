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
	@IBInspectable public var placeholderAlpha: CGFloat = 0.5 {
		didSet {
			updatePlaceholder()
		}
	}

	private func updatePlaceholder() {
		if let placeholder = placeholder, font = font, textColor = textColor {
			attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [
				NSFontAttributeName: font,
				NSForegroundColorAttributeName: textColor.colorWithAlphaComponent(placeholderAlpha)
				])
		}
	}

	override public var placeholder: String? {
		didSet {
			updatePlaceholder()
		}
	}

	override public var font: UIFont? {
		didSet {
			updatePlaceholder()
		}
	}

	override public var textColor: UIColor? {
		didSet {
			updatePlaceholder()
		}
	}
}
//
//  Breadcrumb.swift
//  Greycats
//
//  Created by Rex Sheng on 2/2/15.
//  Copyright (c) 2015 Interactive Labs. All rights reserved.
//

// available in pod 'Greycats', '~> 0.1.5'

public protocol BreadcrumbPickle {
	init(pickle: [String: AnyObject])
	func pickle() -> [String: AnyObject]
}

class TapTap: NSObject {
	var block: (UIGestureRecognizer -> Void)?
	func tapped(tap: UITapGestureRecognizer!) {
		self.block?(tap)
	}
}

public class Breadcrumb<T: NSCoding> {
	private let attributes: [String: AnyObject]
	private let highlightAttributes: [String: AnyObject]?
	private let transform: T -> String
	public var slash = " / "
	public var dots = "..."
	public var within: CGSize = CGSizeMake(CGFloat.max, CGFloat.max)
	
	public init(attributes: [String: AnyObject], highlightAttributes: [String: AnyObject] = [:], transform: T -> String) {
		self.attributes = attributes
		self.highlightAttributes = highlightAttributes
		self.transform = transform
	}
	
	func join(elements: [T]) -> (NSMutableAttributedString, [NSRange]) {
		let attempt = NSMutableAttributedString()
		let slash = NSAttributedString(string: "\(self.slash)", attributes: attributes)
		let lastIndex = elements.count - 1
		var ranges: [NSRange] = []
		
		for (index, el) in elements.enumerate() {
			let str = transform(el)
			var attr = attributes
			let data = NSMutableData()
			let coder = NSKeyedArchiver(forWritingWithMutableData: data)
			el.encodeWithCoder(coder)
			coder.finishEncoding()
			attr["archived-data"] = data
			let text = NSMutableAttributedString(string: str, attributes: attr)
			let loc = attempt.length
			attempt.appendAttributedString(text)
			if index != lastIndex {
				attempt.appendAttributedString(slash)
				ranges.append(NSMakeRange(loc, text.length + 1))
			} else {
				ranges.append(NSMakeRange(loc, text.length))
			}
		}
		return (attempt, ranges)
	}
	
	func _highlight(text: NSMutableAttributedString, range: NSRange?, highlight: NSRegularExpression?) {
		if let highlight = highlight {
			if let highlightAttributes = highlightAttributes {
				if let r = range {
					let matches = highlight.matchesInString(text.string, options: [], range: r)
					for match in matches {
						for i in 1..<match.numberOfRanges {
							text.addAttributes(highlightAttributes, range: match.rangeAtIndex(i))
						}
					}
				}
			}
		}
	}
	
	func fit(attr: NSAttributedString) -> Bool {
		let rect = attr.boundingRectWithSize(CGSizeMake(within.width, CGFloat.max), options: .UsesLineFragmentOrigin, context: nil)
		//		println("\"\(attr.string)\" rect = \(rect)")
		return rect.size.height <= within.height
	}
	
	func _cut(attempt: NSMutableAttributedString, ranges: [NSRange]) {
		let dots = NSAttributedString(string: "\(self.dots)\(self.slash)", attributes: attributes)
		if fit(attempt) {
			return
		}
		for range in ranges {
			attempt.deleteCharactersInRange(NSMakeRange(0, range.length))
			attempt.insertAttributedString(dots, atIndex: 0)
			if fit(attempt) {
				return
			} else {
				attempt.deleteCharactersInRange(NSMakeRange(0, dots.length))
			}
		}
	}
	
	public func create(elements: [T], highlight: NSRegularExpression? = nil) -> NSMutableAttributedString {
		let (attempt, ranges) = join(elements)
		_highlight(attempt, range: ranges.last, highlight: highlight)
		_cut(attempt, ranges: ranges)
		return attempt
	}
	
	public func onClick(textView: UITextView, block: T -> Void) -> AnyObject {
		let taptap = TapTap()
		textView.addGestureRecognizer(UITapGestureRecognizer(target: taptap, action: #selector(TapTap.tapped(_:))))
		taptap.block = {[unowned textView] tap in
			var loc = tap.locationInView(textView)
			loc.x -= textView.textContainerInset.left
			loc.y -= textView.textContainerInset.top
			let index = textView.layoutManager.characterIndexForPoint(loc, inTextContainer: textView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
			if index < textView.textStorage.length {
				if let value = textView.attributedText.attribute("archived-data", atIndex: index, effectiveRange: nil) as? NSData {
					let coder = NSKeyedUnarchiver(forReadingWithData: value)
					if let category = T(coder: coder) {
						block(category)
					}
					print("click \(value)")
				}
			}
		}
		return taptap
	}
}
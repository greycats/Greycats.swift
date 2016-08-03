//
//  Breadcrumb.swift
//  Greycats
//
//  Created by Rex Sheng on 2/2/15.
//  Copyright (c) 2015 Interactive Labs. All rights reserved.
//

// available in pod 'Greycats', '~> 0.1.5'

import Foundation
import UIKit

class TapTap: NSObject {
    var block: (UIGestureRecognizer -> Void)?

    func tapped(tap: UITapGestureRecognizer!) {
        block?(tap)
    }
}

public protocol BreadcrumbPipeline {
    func process(string: NSMutableAttributedString, ranges: [NSRange])
}

public protocol Breadcrumb: NSCoding {
}

public struct BreadcrumbHighlightPipeline: BreadcrumbPipeline {
    public let attributes: [String: AnyObject]
    public let pattern: NSRegularExpression

    public func process(string: NSMutableAttributedString, ranges: [NSRange]) {
        if let range = ranges.last {
            pattern.matchesInString(string.string, options: [], range: range).forEach { match in
                for i in 1..<match.numberOfRanges {
                    string.addAttributes(attributes, range: match.rangeAtIndex(i))
                }
            }
        }
    }
}

public struct BreadcrumbTrailingPipeline: BreadcrumbPipeline {
    public let trailingString: String
    public let attributes: [String: AnyObject]
    public let maxSize: CGSize

    func fit(attr: NSAttributedString) -> Bool {
        let rect = attr.boundingRectWithSize(CGSizeMake(maxSize.width, CGFloat.max), options: .UsesLineFragmentOrigin, context: nil)
        //		println("\"\(attr.string)\" rect = \(rect)")
        return rect.size.height <= maxSize.height
    }

    public func process(string: NSMutableAttributedString, ranges: [NSRange]) {
        let suffix = NSAttributedString(string: trailingString, attributes: attributes)

        if fit(string) {
            return
        }
        for range in ranges {
            string.deleteCharactersInRange(NSMakeRange(0, range.length))
            string.insertAttributedString(suffix, atIndex: 0)
            if fit(string) {
                return
            } else {
                string.deleteCharactersInRange(NSMakeRange(0, suffix.length))
            }
        }
    }
}

extension NSAttributedString {
    public convenience init<T: Breadcrumb>(elements: [T], attributes: [String: AnyObject], transform: T -> String, separator: String, pipelines: [BreadcrumbPipeline]?) {
        let string = NSMutableAttributedString()
        let slash = NSAttributedString(string: separator, attributes: attributes)
        let lastIndex = elements.count - 1

        func attributedStringWithEncodedData(t: T) -> NSAttributedString {
            let str = transform(t)
            var attr = attributes
            let data = NSMutableData()
            let coder = NSKeyedArchiver(forWritingWithMutableData: data)
            t.encodeWithCoder(coder)
            coder.finishEncoding()
            attr["archived-data"] = data
            return NSMutableAttributedString(string: str, attributes: attr)
        }

        let ranges: [NSRange] = elements.enumerate().map { index, element in
            let text = attributedStringWithEncodedData(element)
            let loc = string.length
            string.appendAttributedString(text)
            if index != lastIndex {
                string.appendAttributedString(slash)
                return NSMakeRange(loc, text.length + 1)
            } else {
                return NSMakeRange(loc, text.length)
            }
        }

        pipelines?.forEach { $0.process(string, ranges: ranges) }
        self.init(attributedString: string)
    }

    public func breadcrumbData<T: Breadcrumb>(atIndex index: Int) -> T? {
        if let value = attribute("archived-data", atIndex: index, effectiveRange: nil) as? NSData {
            let coder = NSKeyedUnarchiver(forReadingWithData: value)
            return T(coder: coder)
        }
        return nil
    }
}

public class Breadcrumbs<T: Breadcrumb> {
    let attributeGenerator: ([T]) -> NSAttributedString
    weak var container: UITextView!
    let taptap = TapTap()

    public init(attributes: [String: AnyObject], transform: T -> String, container: UITextView, onClick: (T) -> Void, separator: String = " / ", pipelines: [BreadcrumbPipeline]? = nil) {
        self.container = container
        attributeGenerator = { elements in
            NSAttributedString(elements: elements, attributes: attributes, transform: transform, separator: separator, pipelines: pipelines)
        }
        container.addGestureRecognizer(UITapGestureRecognizer(target: taptap, action: #selector(TapTap.tapped)))
        taptap.block = {[weak container] tap in
            guard let container = container else { return }
            var loc = tap.locationInView(container)
            loc.x -= container.textContainerInset.left
            loc.y -= container.textContainerInset.top
            let index = container.layoutManager.characterIndexForPoint(loc, inTextContainer: container.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            if index < container.textStorage.length {
                if let t: T = container.attributedText.breadcrumbData(atIndex: index) {
                    onClick(t)
                }
            }
        }
    }

    public func build(breadcrumbs: [T]) {
        container.attributedText = attributeGenerator(breadcrumbs)
    }
}
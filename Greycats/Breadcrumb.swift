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

public protocol BreadcrumbPipeline {
    func process(_ string: NSMutableAttributedString, ranges: [NSRange])
}

public protocol Breadcrumb: NSCoding {
}

public struct BreadcrumbHighlightPipeline: BreadcrumbPipeline {
    public let attributes: [String: Any]
    public let pattern: NSRegularExpression
    
    public func process(_ string: NSMutableAttributedString, ranges: [NSRange]) {
        if let range = ranges.last {
            pattern.matches(in: string.string, options: [], range: range).forEach { match in
                for i in 1..<match.numberOfRanges {
                    string.addAttributes(attributes, range: match.rangeAt(i))
                }
            }
        }
    }
}

public struct BreadcrumbTrailingPipeline: BreadcrumbPipeline {
    public let trailingString: String
    public let attributes: [String: Any]
    public let maxSize: CGSize
    
    func fit(_ attr: NSAttributedString) -> Bool {
        let rect = attr.boundingRect(with: CGSize(width: maxSize.width, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
        //		println("\"\(attr.string)\" rect = \(rect)")
        return rect.size.height <= maxSize.height
    }
    
    public func process(_ string: NSMutableAttributedString, ranges: [NSRange]) {
        let suffix = NSAttributedString(string: trailingString, attributes: attributes)
        
        if fit(string) {
            return
        }
        for range in ranges {
            string.deleteCharacters(in: NSMakeRange(0, range.length))
            string.insert(suffix, at: 0)
            if fit(string) {
                return
            } else {
                string.deleteCharacters(in: NSMakeRange(0, suffix.length))
            }
        }
    }
}

extension NSAttributedString {
    public convenience init<T: Breadcrumb>(elements: [T], attributes: [String: Any], transform: @escaping (T) -> String, separator: String, pipelines: [BreadcrumbPipeline]?) {
        let string = NSMutableAttributedString()
        let slash = NSAttributedString(string: separator, attributes: attributes)
        let lastIndex = elements.count - 1
        
        func attributedStringWithEncodedData(_ t: T) -> NSAttributedString {
            let str = transform(t)
            var attr = attributes
            let data = NSMutableData()
            let coder = NSKeyedArchiver(forWritingWith: data)
            t.encode(with: coder)
            coder.finishEncoding()
            attr["archived-data"] = data
            return NSMutableAttributedString(string: str, attributes: attr)
        }
        
        let ranges: [NSRange] = elements.enumerated().map { index, element in
            let text = attributedStringWithEncodedData(element)
            let loc = string.length
            string.append(text)
            if index != lastIndex {
                string.append(slash)
                return NSMakeRange(loc, text.length + 1)
            } else {
                return NSMakeRange(loc, text.length)
            }
        }
        
        pipelines?.forEach { $0.process(string, ranges: ranges) }
        self.init(attributedString: string)
    }
    
    public func breadcrumbData<T: Breadcrumb>(atIndex index: Int) -> T? {
        if let value = attribute("archived-data", at: index, effectiveRange: nil) as? Data {
            let coder = NSKeyedUnarchiver(forReadingWith: value)
            return T(coder: coder)
        }
        return nil
    }
}

class Tap {
    var block: ((UIGestureRecognizer) -> Void)?
    
    @objc func tapped(_ tap: UITapGestureRecognizer!) {
        block?(tap)
    }
}

extension UITextView {
    public func tapOnBreadcrumb<T: Breadcrumb>(_ clousure: @escaping (T) -> Void) -> Any {
        let tap = Tap()
        addGestureRecognizer(UITapGestureRecognizer(target: tap, action: #selector(Tap.tapped)))
        tap.block = {[weak self] tap in
            guard let container = self else { return }
            var loc = tap.location(in: container)
            loc.x -= container.textContainerInset.left
            loc.y -= container.textContainerInset.top
            let index = container.layoutManager.characterIndex(for: loc, in: container.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            if index < container.textStorage.length {
                if let t: T = container.attributedText.breadcrumbData(atIndex: index) {
                    clousure(t)
                }
            }
        }
        return tap
    }
}

open class Breadcrumbs<T: Breadcrumb> {
    let attributeGenerator: ([T]) -> NSAttributedString
    weak var container: UITextView!
    let tap: Any
    
    public init(attributes: [String: Any], transform: @escaping (T) -> String, container: UITextView, onClick: @escaping (T) -> Void, separator: String = " / ", pipelines: [BreadcrumbPipeline]? = nil) {
        self.container = container
        attributeGenerator = { elements in
            NSAttributedString(elements: elements, attributes: attributes, transform: transform, separator: separator, pipelines: pipelines)
        }
        tap = container.tapOnBreadcrumb(onClick)
    }
    
    open func build(_ breadcrumbs: [T]) {
        container.attributedText = attributeGenerator(breadcrumbs)
    }
}

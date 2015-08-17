//
//  Regex.swift
//  Trusted
//
//  Created by Rex Sheng on 6/12/15.
//  Copyright (c) 2015 Trusted. All rights reserved.
//
//

import Foundation

public final class Regex {
	let internalExpression: NSRegularExpression
	let pattern: String
	
	public init(_ pattern: String) {
		self.pattern = pattern
		var error: NSError?
		internalExpression = NSRegularExpression(pattern: pattern, options: .CaseInsensitive, error: &error)!
	}
	
	public func test(input: String) -> Bool {
		let matches = internalExpression.matchesInString(input, options: nil, range:NSMakeRange(0, count(input)))
		return matches.count > 0
	}
	
	public func exec(input: String) -> [String]? {
		if let match = internalExpression.firstMatchInString(input, options: nil, range: NSMakeRange(0, count(input))) {
			var results: [String] = []
			for i in 1..<match.numberOfRanges {
				let r = match.rangeAtIndex(i)
				results.append((input as NSString).substringWithRange(r))
			}
			return results
		}
		return nil
	}
}

extension Regex: StringLiteralConvertible {
	public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
	public typealias UnicodeScalarLiteralType = StringLiteralType
	public convenience init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
		self.init(value)
	}
	
	public convenience init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
		self.init(value)
	}
	
	public convenience init(stringLiteral value: StringLiteralType) {
		self.init(value)
	}
}

infix operator =~ {}
public func =~ (input: String, pattern: Regex) -> Bool {
	return pattern.test(input)
}

public func =~ (input: AnyObject?, pattern: Regex) -> Bool {
	if let input = input as? String {
		return pattern.test(input)
	}
	return false
}

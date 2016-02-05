//
//  Regex.swift
//	Greycats
//
//  Created by Rex Sheng on 6/12/15.
//  Copyright (c) 2016 Interactive Labs. All rights reserved.
//

public final class Regex {
	let internalExpression: NSRegularExpression
	let pattern: String
	
	public init(_ pattern: String) {
		self.pattern = pattern
		internalExpression = try! NSRegularExpression(pattern: pattern, options: [.CaseInsensitive, .AnchorsMatchLines])
	}
	
	public func test(input: String) -> Bool {
		let matches = internalExpression.matchesInString(input, options: [], range:NSMakeRange(0, input.characters.count))
		return matches.count > 0
	}
	
	public func exec(input: String) -> [String]? {
		if let match = internalExpression.firstMatchInString(input, options: [], range: NSMakeRange(0, input.characters.count)) {
			var results: [String] = []
			for i in 1..<match.numberOfRanges {
				let r = match.rangeAtIndex(i)
				if r.location != Int.max {
					results.append((input as NSString).substringWithRange(r))
				}
			}
			return results
		}
		return nil
	}
	
	public func findall(input: String) -> [[String]] {
		let matches = internalExpression.matchesInString(input, options: [], range: NSMakeRange(0, input.characters.count))
		return matches.map { match in
			var results: [String] = []
			for i in 1..<match.numberOfRanges {
				let r = match.rangeAtIndex(i)
				if r.location != Int.max {
					results.append((input as NSString).substringWithRange(r))
				}
			}
			return results
		}
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

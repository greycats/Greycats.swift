//
//  Regex.swift
//  Trusted
//
//  Created by Rex Sheng on 6/12/15.
//  Copyright (c) 2015 Trusted. All rights reserved.
//
//

import Foundation

public class Regex {
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

infix operator =~ {}
public func =~ (input: String, pattern: String) -> Bool {
	return Regex(pattern).test(input)
}

public func =~ (input: String, pattern: Regex) -> Bool {
	return pattern.test(input)
}

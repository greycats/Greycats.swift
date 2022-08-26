//
//  Regex.swift
//	Greycats
//
//  Created by Rex Sheng on 6/12/15.
//  Copyright (c) 2016 Interactive Labs. All rights reserved.
//

import Foundation

public final class Regex {
    
    public static let Email = Regex("(?:[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}" +
        "~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\" +
        "x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-zA-Z0-9](?:[a-" +
        "zA-Z0-9-]*[a-zA-Z0-9])?\\.)+[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?|\\[(?:(?:25[0-5" +
        "]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-" +
        "9][0-9]?|[a-zA-Z0-9-]*[a-zA-Z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21" +
        "-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])")
    
    let internalExpression: NSRegularExpression
    let pattern: String
    
    public init(_ pattern: String) {
        self.pattern = pattern
        internalExpression = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .anchorsMatchLines])
    }
    
    public func test(_ input: String) -> Bool {
        let matches = internalExpression.matches(in: input, options: [], range:NSMakeRange(0, input.count))
        return matches.count > 0
    }
    
    public func exec(_ input: String) -> [String]? {
        if let match = internalExpression.firstMatch(in: input, options: [], range: NSMakeRange(0, input.count)) {
            var results: [String] = []
            for i in 1..<match.numberOfRanges {
                let r = match.range(at: i)
                if r.location != Int.max {
                    results.append((input as NSString).substring(with: r))
                }
            }
            return results
        }
        return nil
    }
    
    public func findall(_ input: String) -> [[String]] {
        let matches = internalExpression.matches(in: input, options: [], range: NSMakeRange(0, input.count))
        return matches.map { match in
            var results: [String] = []
            for i in 1..<match.numberOfRanges {
                let r = match.range(at: i)
                if r.location != Int.max {
                    results.append((input as NSString).substring(with: r))
                }
            }
            return results
        }
    }
}

extension Regex: ExpressibleByStringLiteral {
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

infix operator =~
public func =~ (input: String, pattern: Regex) -> Bool {
    return pattern.test(input)
}

public func =~ (input: Any?, pattern: Regex) -> Bool {
    if let input = input as? String {
        return pattern.test(input)
    }
    return false
}
